part of quests;

@app.Group('/quests')
class QuestEndpoint {
	static Map<String, WebSocket> userSockets = {};
	static Map<String, UserQuestLog> questLogCache = {};

	static void handle(WebSocket ws) {
		ws.listen((message) async {
			try {
				await processMessage(ws, message);
			} catch (error, stackTrace) {
				// A malformed or incomplete quest payload must not become an
				// unhandled asynchronous exception and terminate the server.
				Log.error('Processing quest websocket message', error, stackTrace);
				cleanupList(ws);
			}
		},
		          onError: (error) => cleanupList(ws),
		          onDone: () => cleanupList(ws));
	}

	static void cleanupList(WebSocket ws) {
		String leavingUser;

		// `socket = null` here would reassign only the forEach callback's own
		// local parameter, not the map entry -- a harmless but pointless
		// no-op (the real removal already happens below via
		// `userSockets.remove`). Simplified to just find the matching email.
		userSockets.forEach((String email, WebSocket socket) {
			if (ws == socket) {
				leavingUser = email;
			}
		});

		if (leavingUser != null) {
			try {
				questLogCache[leavingUser]?.stopTracking();
			} catch (error, stackTrace) {
				// A bad persisted quest must not be able to terminate the process
				// merely because a browser websocket closes.
				Log.error('Cleaning up quests for <email=$leavingUser>', error, stackTrace);
			}
			questLogCache.remove(leavingUser);
			userSockets.remove(leavingUser);
		}
	}

	static Future processMessage(WebSocket ws, String message) async {
		Map map = jsonDecode(message);
		if (map['connect'] != null) {
			String email = map['email'];

			// A previous `connect` for this same email (a reconnect: hard
			// refresh, network blip, or any prior session that never got a
			// clean `onDone`/cleanupList) may have already left a
			// UserQuestLog here, fully subscribed to the message bus via
			// startTracking(). Overwriting the cache entry without first
			// stopping that one leaves its entire subscription tree (the
			// quest log itself, each in-progress Quest, each of their
			// Requirements) as permanent zombie listeners nobody ever
			// unsubscribes -- confirmed live: after this session's many
			// reconnects, a single tree-pet fired the Tree Petter quest's
			// completion popup once per accumulated zombie generation,
			// reported as "that wasn't too hard... shows up every single
			// time." stopTracking() is safe to call even on a log that was
			// never actually tracking (Trackable's default state).
			questLogCache[email]?.stopTracking();

			//setup our associative data structures
			userSockets[email] = ws;
			questLogCache[email] = await QuestService.loadQuestLog(email);

			//start tracking this user's quest log
			questLogCache[email].startTracking(email);

			// A restored local world has no NPC placement data to offer the first
			// quest. Seed the existing starter quest only when explicitly enabled
			// by the local compose configuration; hosted deployments remain driven
			// by their normal quest triggers.
			if (Platform.environment['LOCAL_SEED_QUESTS'] == 'true' &&
				questLogCache[email].inProgressQuests.isEmpty &&
				questLogCache[email].completedQuests.isEmpty) {
				await questLogCache[email].addInProgressQuest('Q1');
			}
		}
		if (map['acceptQuest'] != null) {
			try {
				messageBus.publish(new AcceptQuest(map['email'],map['id']));
			} catch (e, st) {
				Log.error('Accepting quest <id=${map['id']}> for <email=${map['email']}>', e, st);
			}
		}
		if (map['rejectQuest'] != null) {
			try {
				messageBus.publish(new RejectQuest(map['email'],map['id']));
			} catch (e, st) {
				Log.error('Rejecting quest <id=${map['id']}> for <email=${map['email']}>', e, st);
			}
		}
	}

	@app.Route('/requirementTypes')
	Map<String, List<String>> requirementTypes() {
		List<String> types = [];
		List<String> events = [];

		quests.values.forEach((Quest quest) {
			quest.requirements.cast<Requirement>().forEach((Requirement requirement) {
				if (!types.contains(requirement.type)) {
					types.add(requirement.type);
				}

				if (!events.contains(requirement.eventType)) {
					events.add(requirement.eventType);
				}
			});
		});

		return {
			'types': types,
			'events': events
		};
	}
}
