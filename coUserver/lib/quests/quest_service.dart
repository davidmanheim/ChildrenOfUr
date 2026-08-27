part of quests;

Map<String, Quest> quests = {};

@app.Group("/quest")
class QuestService extends Object with MetabolicsChange {
	@app.Route("/completed/:email")
	@Encode()
	Future<List<Quest>> getCompleted(String email) async {
		return await _getQuestList(email, 'completed_list');
	}

	@app.Route("/inProgress/:email")
	@Encode()
	Future<List<Quest>> getInProgress(String email) async {
		return await _getQuestList(email, 'in_progress_list');
	}

	@app.Route("/getQuestLog/:email")
	@Encode()
	Future<UserQuestLog> getQuestLog(String email) async {
		return await loadQuestLog(email);
	}

	/// Shared non-HTTP lookup used by the quest websocket and quest tracking.
	static Future<UserQuestLog> loadQuestLog(String email) async {
		PostgreSql dbConn = await dbManager.getConnection();
		String query = "SELECT q.* from user_quests q JOIN users u ON u.id = user_id where u.email = @email";
		List<UserQuestLog> questLogs;
		try {
			questLogs = (await dbConn.query(query, UserQuestLog, {'email':email})).cast<UserQuestLog>();
		} finally {
			await dbManager.closeConnection(dbConn);
		}

		// Do not hold the lookup connection while creating a missing record:
		// local deployments use a small pool and that pattern deadlocks on a
		// player's first quest websocket connection.
		return questLogs.isNotEmpty ? questLogs.first : await createQuestLog(email);
	}

	@app.Route("/updateQuestLog", methods: const[app.POST])
	Future<bool> updateQuestLog(@Decode() UserQuestLog questLog) async {
		return await saveQuestLog(questLog);
	}

	/// Shared non-HTTP update used by quest tracking.
	static Future<bool> saveQuestLog(UserQuestLog questLog) async {
		PostgreSql dbConn = await dbManager.getConnection();
		String query = "UPDATE user_quests SET completed_list = @completed_list, in_progress_list = @in_progress_list where id = @id";
		int numUpdated = await dbConn.execute(query, questLog);
		await dbManager.closeConnection(dbConn);

		if(numUpdated < 1) {
			return false;
		} else {
			return true;
		}
	}

	@app.Route('/pieces')
	Map<String, String> getQuestPieces() {
		Map<String, String> pieces = {
			'getItem_<Item>' : 'Aquire Item',
			'makeRecipe_<Item>' : 'Make Recipe',
			'treePet<Tree>' : 'Pet Tree',
			'location_<Location>' : 'Goto Location',
			'sendMail_<Player>_containingItems_<List_Item>_currants_<int>' : 'Send Mail',
		};

		return pieces;
	}

	@app.Route('/createQuestItem', methods: const[app.POST])
	Future createQuestItem(@Decode() Quest quest) async {
		int imgCost = quest.rewards.img + 300 * quest.requirements.length + 500;
		int currantCost = quest.rewards.currants;

		//we are setting the id = the creator's email on the client
		String email = quest.id;
		String username = await User.getUsernameFromEmail(email);
		quest.id = username + new DateTime.now().millisecondsSinceEpoch.toString();

		//fix up the conversation ids
		quest.conversation_start.id = quest.id + '-CS';
		quest.conversation_end.id = quest.id + '-CE';

		bool success = await trySetMetabolics(email, imgMin: -imgCost, currants: -currantCost);
		if (success) {
			//create the item and give it to the user
			Item questItem = new Item.clone('user_made_quest');
			questItem.metadata['questData'] = jsonEncode(encode(quest));
			await InventoryV2.addItemToUser(email, questItem.getMap(), 1);
		}
	}

	static Future<UserQuestLog> createQuestLog(String email) async {
		PostgreSql dbConn = await dbManager.getConnection();
		String query = "SELECT * FROM users where email = @email";
		List<User> users = (await dbConn.query(query, User, {'email':email})).cast<User>();
		if(users.length > 0) {
			int userId = users.first.id;
			query = "INSERT INTO user_quests(user_id) VALUES(@id)";
			await dbConn.execute(query,{'id':userId});
		}
		await dbManager.closeConnection(dbConn);

		return await loadQuestLog(email);
	}

	static Future<List<Quest>> _getQuestList(String email, String listType) async {
		PostgreSql dbConn = await dbManager.getConnection();
		String query = "SELECT q.* FROM user_quests q JOIN users u ON u.id = user_id WHERE u.email = @email";
		List<UserQuestLog> results = (await dbConn.query(query, UserQuestLog, {'email':email})).cast<UserQuestLog>();
		await dbManager.closeConnection(dbConn);
		if (results.length <= 0) {
			return [];
		}

		if (listType == 'completed_list') {
			return results.first.completedQuests;
		} else if (listType == 'in_progress_list') {
			return results.first.inProgressQuests;
		} else {
			return [];
		}
	}

	static Future<int> loadQuests() async {
		// Ignore messages about quest requirements being completed when not on the quest
		messageBus.undeliverableHandler = (_) {};

		try {
			String directory = Platform.script.toFilePath();
			directory = directory.substring(0, directory.lastIndexOf(Platform.pathSeparator));
			Directory questsDirectory = new Directory(path.join(directory,'lib', 'quests', 'json'));
			await for(FileSystemEntity entity in questsDirectory.list(recursive: true)) {
				if (entity is File) {
					// load quests
					Quest q = decode(jsonDecode(await entity.readAsString()), Quest);
					q.requirements = (q.requirements ?? []).map((dynamic requirement) {
						return requirement is Requirement
							? requirement
							: decode(new Map<String, dynamic>.from(requirement as Map), Requirement);
					}).toList();
					quests[q.id] = q;
				}
			}

			Log.verbose('[QuestService] Loaded ${quests.length} quests');
		} catch (e, st) {
			Log.error('Problem loading quests', e, st);
		}

		return quests.length;
	}
}
