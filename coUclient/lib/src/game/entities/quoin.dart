part of couclient;

class Quoin {
	static Map<String, bool> notified = new Map();

	String typeString;
	Animation animation;
	bool ready = false;
	bool firstRender = true;
	bool collected = false; // Whether the quoin is waiting to respawn
	bool checking = false; // Whether the client is waiting for the server to verify/award the quoin
	bool hit = false; // Whether the client is sending the intersection to the server
	CanvasElement canvas;
	DivElement circle, parent;
	Rectangle quoinRect;
	num left, top;
	String id;

	Quoin(Map<String, dynamic> map) {
		init(map);
	}

	Future<Null> init(Map<String, dynamic> map) async {
		typeString = map['type'];

		// Don't show Quarazy Quoins more than once for a street
		if (typeString == "quarazy") {
			if (!metabolics.load.isCompleted) {
				await metabolics.load.future;
			}

			if (
				metabolics.location_history.contains(currentStreet.tsid_g)
				|| metabolics.location_history.contains(currentStreet.tsid)
			) {
				return;
			}
		}

		id = map["id"];
		// The original 8x24 remote quoin sprite sheet has been retired.  The
		// local fallback (and each real converted per-type token, which is
		// not square -- see content/sprites/quoin/) is one static frame,
		// sized below from the loaded image's own pixel dimensions rather
		// than a fixed constant, matching how NPC entities size their canvas
		// (see npc.dart's updateAnimation).
		animation = new Animation(map['url'], typeString.toLowerCase(), 1, 1, [0], fps: 1);
		try {
		await animation.load();
		} catch (e, st) {
			print("$e\n$st");
			return;
		}

		canvas = new CanvasElement();
		// The real converted per-type art (~24-41px) reads as noticeably
		// small in-world at its native pixel size -- per direct user
		// feedback, scaled up here rather than left at 1:1. drawImageToRect()
		// (see render() below) already scales the source image to whatever
		// destRect/canvas size is set, so this is just a display multiplier,
		// not a re-export of the art at a different resolution.
		const num displayScale = 1.75;
		canvas.width = (animation.width * displayScale).round();
		canvas.height = (animation.height * displayScale).round();
		canvas.id = id;
		canvas.className = map['type'] + " quoin";
		canvas.style.position = "absolute";
		canvas.style.left = map['x'].toString() + "px";
		canvas.style.top = map['y'].toString() + "px";
		canvas.style.transform = "translateZ(0)";
		canvas.attributes['collected'] = "false";

		left = map['x'];
		top = map['y'] - canvas.height;

		circle = new DivElement()
			..id = "q" + id
			..className = "circle"
			..style.position = "absolute"
			..style.left = map["x"].toString() + "px"
			..style.top = map["y"].toString() + "px";
		parent = new DivElement()
			..id = "qq" + id
			..className = "parent"
			..style.position = "absolute"
			..style.left = map["x"].toString() + "px"
			..style.top = map["y"].toString() + "px";
		DivElement inner = new DivElement();
		inner.className = "inner";
		DivElement content = new DivElement();
		content.className = "quoinString";
		parent.append(inner);
		inner.append(content);

		// Grey out quoins if their stats are maxed out
		if (statIsMaxed) {
			greyedOut = true;
		}

		view.playerHolder
			..append(canvas)
			..append(circle)
			..append(parent);

		ready = true;
		addingLocks[id] = false;
	}

	void update(double dt) {
		if (!ready) {
			return;
		}

		quoinRect = new Rectangle(left, top, canvas.width, canvas.height);

		//if a player collides with us, tell the server
		if (!hit && (_checkPlayerCollision() && _canCollect())) {
			// Intersecting and able to collect
			_sendToServer();

			// Don't check again
			hit = true;
		} else if (!collected) {
			hit = false;
		}

		if (intersect(camera.visibleRect, quoinRect)) {
			// In view
			animation.updateSourceRect(dt);
			greyedOut = statIsMaxed;
		}
	}

	/// Returns true if the quoin can be collected, false (and possibly toasts) if not
	bool _canCollect() {
		/// Notifies of the quoin message only one time per session
		bool _toastIfNotNotified(String message, [String key]) {
			/// Checks and updates notification history for this session
			bool _checkNotified(String key) {
				if (notified[key] != null && notified[key] == true) {
					// Already notified

					// Do not send it
					return true;
				} else {
					// First notification

					// Update status
					notified[key] = true;

					// Send it this time
					return false;
				}
			}

			// Not notified yet?
			if (!_checkNotified(key ?? typeString)) {
				// Send message
				new Toast(message);
			}

			// Allow single lines in the if bodies below
			return false;
		}

		if ((metabolics?.playerMetabolics?.quoinsCollected ?? 0) >= constants.quoinLimit) {
			return _toastIfNotNotified(
				"You've reached your daily limit of ${constants.quoinLimit} quoins",
				"daily_limit");
		} else if (typeString == 'mood' && (metabolics?.playerMetabolics?.mood ?? 0) >= (metabolics?.playerMetabolics?.maxMood ?? 1)) {
			return _toastIfNotNotified(
				"You tried to collect a mood quoin, but your mood was already full.",
				"full_mood");
		} else if (typeString == 'energy' && (metabolics?.playerMetabolics?.energy ?? 0) >= (metabolics?.playerMetabolics?.maxEnergy ?? 1)) {
			return _toastIfNotNotified(
				"You tried to collect an energy quoin, but your energy tank was already full.",
				"full_energy");
		} else {
			return true;
		}
	}

	bool _checkPlayerCollision() {
		if(collected || checking) {
			return false;
		}

		return intersect(CurrentPlayer.entityRect, quoinRect);
	}

	void _sendToServer() {
		//don't try to collect the same quoin again before we get a response
		checking = true;

		audio.playSound('quoinSound');

		circle.classes.add("circleExpand");
		parent.classes.add("circleExpand");
		new Timer(new Duration(seconds:2), () => _removeCircleExpand(parent));
		new Timer(new Duration(milliseconds:800), () => _removeCircleExpand(circle));
		canvas.style.display = "none"; //.remove() is very slow

		if(streetSocket != null && streetSocket.readyState == WebSocket.OPEN) {
			Map map = new Map();
			map["remove"] = id;
			map["type"] = "quoin";
			map['username'] = game.username;
			map["streetName"] = currentStreet.label;
			streetSocket.send(jsonEncode(map));
		}
	}

	void _removeCircleExpand(Element element) {
		if(element != null)
			element.classes.remove("circleExpand");
	}

	render() {
		if(ready && animation.dirty && canvas.attributes['collected'] == "false") {
			if(!firstRender) {
				//if the entity is not visible, don't render it
				if(!intersect(camera.visibleRect, quoinRect))
					return;
			}

			firstRender = false;

			//fastest way to clear a canvas (without using a solid color)
			//source: http://jsperf.com/ctx-clearrect-vs-canvas-width-canvas-width/6
			canvas.context2D.clearRect(0, 0, canvas.width, canvas.height);

			Rectangle destRect = new Rectangle(0, 0, canvas.width, canvas.height);
			canvas.context2D.drawImageToRect(animation.spritesheet, destRect, sourceRect: animation.sourceRect);
			animation.dirty = false;
		}
	}

	bool get statIsMaxed {
		if ((metabolics.playerMetabolics.quoinsCollected ?? 0) >= constants.quoinLimit) {
			return true;
		}

		switch (typeString) {
			case "mood":
				return metabolics.playerMetabolics.mood >= metabolics.playerMetabolics.maxMood;
			case "energy":
				return metabolics.playerMetabolics.energy >= metabolics.playerMetabolics.maxEnergy;
			default:
				return false;
		}
	}

	set greyedOut(bool newValue) {
		final String GREY_CLASS = "quoin-disabled";

		if (newValue) {
			canvas.classes.add(GREY_CLASS);
		} else {
			canvas.classes.remove(GREY_CLASS);
		}
	}
}
