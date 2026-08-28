part of couclient;
// Handles all the engine's audio needs.


class SoundManager {
	Map<String, Sound> gameSounds = {};
	Map<String, AudioChannel> audioChannels = {};
	bool useWebAudio = true, muted = false;
	String extension = 'ogg';

	// Stores all the loaded user interface sounds.
	Batch ui_sounds;

	SC sc = new SC(SC_TOKEN);
	Map<String, Scound> songs = {};
	Scound currentSong;
	AudioInstance currentAudioInstance, loadingSound;
	bool _soundCloudUnavailableLogged = false;
	bool _audioUnlocked = false;

	SoundManager() {
		logmessage('[SoundManager] Starting up...');
		init().then((_) {
			new Service(['playSong'], (event) {
				event = event.replaceAll(' ', '');
				if (songs[event] == null) {
					loadSong(event).then((_) => _playSong(event));
				} else _playSong(event);
			});

			new Service(['playSound'], (event) => this.playSound(event));

			logmessage('[SoundManager] Registered services');
		});
	}

	Future<void> init() async {
		try {
			num effectsVolume = 50, musicVolume = 50, weatherVolume = 50;
			if(localStorage.containsKey('effectsVolume')) effectsVolume = num.parse(localStorage['effectsVolume']);
			if(localStorage.containsKey('musicVolume')) musicVolume = num.parse(localStorage['musicVolume']);
			if(localStorage.containsKey('weatherVolume')) weatherVolume = num.parse(localStorage['weatherVolume']);

			audioChannels['soundEffects'] = new AudioChannel("soundEffects")
				..gain = effectsVolume / 100;
			audioChannels['music'] = new AudioChannel("music")
				..gain = musicVolume / 100;
			audioChannels['weather'] = new AudioChannel("weather")
				..gain = weatherVolume / 100;
		} catch(e) {
			logmessage("[SoundManager] Browser does not support web audio: $e");
			useWebAudio = false;
		} finally {
			setMute(view.slider.muted);
		}

		// Chrome suspends Web Audio contexts created during page load. Resume the
		// already-loaded local effects only after the first real user gesture.
		document.onClick.first.then((_) => _unlockAudio());
		document.onTouchStart.first.then((_) => _unlockAudio());
		document.onKeyDown.first.then((_) => _unlockAudio());

		if(useWebAudio) {
			//if canPlayType returns the empty string, that format is not compatible
			if(new AudioElement().canPlayType('audio/ogg') == "") {
				logmessage("[SoundManager] Ogg not supported, using mp3s instead");
				extension = "mp3";
			}

			try {
				if(!muted) {
					//load the loading music and play when ready
					gameSounds['loading'] = new Sound(channel: audioChannels['music']);
					await gameSounds['loading'].load("files/audio/loading.$extension");
					loadingSound = gameSounds['loading'].play(looping:true);
				}

				//load the sound effects

				gameSounds['quoinSound'] = new Sound(channel: audioChannels['soundEffects']);
				gameSounds['mention'] = new Sound(channel: audioChannels['soundEffects']);
				gameSounds['game_loaded'] = new Sound(channel: audioChannels['soundEffects']);
				gameSounds['tripleJump'] = new Sound(channel: audioChannels['soundEffects']);
				gameSounds['levelUp'] = new Sound(channel: audioChannels['soundEffects']);
				gameSounds['newDay'] = new Sound(channel: audioChannels['soundEffects']);
				gameSounds['purr'] = new Sound(channel: audioChannels['soundEffects']);

				await Future.wait([
					gameSounds['quoinSound'].load('files/audio/quoinSound.$extension'),
					gameSounds['mention'].load('files/audio/mention.$extension'),
					gameSounds['game_loaded'].load('files/audio/game_loaded.$extension'),
					gameSounds['tripleJump'].load('files/audio/tripleJump.$extension'),
					gameSounds['levelUp'].load('files/audio/levelUp.$extension'),
					gameSounds['newDay'].load('files/audio/newday_rooster.$extension'),
					gameSounds['purr'].load('files/audio/purr.$extension')
				]);

				Asset soundCloudSongs = new Asset('./files/json/music.json');
				await soundCloudSongs.load(statusElement: querySelector("#LoadStatus2"));
			} catch(e) {
				logmessage("[SoundManager] There was a problem: $e");
				useWebAudio = false;
				await loadNonWebAudio();
			}
		} else {
			await loadNonWebAudio();
		}
	}

	void _unlockAudio() {
		if (_audioUnlocked || !useWebAudio) {
			return;
		}
		_audioUnlocked = true;
		audioChannels.values.forEach((AudioChannel channel) {
			channel.resume().catchError((_) {});
		});
	}

	// Sound Effects ////////////////////////////////////////////////////////////////////////////////

	Future<void> loadNonWebAudio() async {
		logmessage("[SoundManager] Loading non-WebAudio");
		// Load all our user interface sounds.

		//iOS/safari/IE doesn't seem to like .ogg files
		//and dartium/Opera/older Firefox doesn't seem to like .mp3 files
		//here's a fix for dartium http://downloadsquad.switched.com/2010/06/24/play-embedded-mp3-audio-files-chromium/
		//also I updated the loadie library to attempt to find both a .mp3 file and a .ogg file at the specified location
		//this should help with browser compatibility
		try {
			ui_sounds = new Batch([
				new Asset('files/audio/mention.mp3'),
				new Asset('files/audio/quoinSound.mp3'),
				new Asset('files/audio/game_loaded.mp3'),
				new Asset('files/audio/tripleJump.mp3'),
				new Asset('files/audio/levelUp.mp3'),
				new Asset('files/audio/newday_rooster.mp3')
			]);
			await ui_sounds.load();
			// Load the names and track id's of the music.json file but save actually loading the media file
			// until it is requested (whether by street load or by setsong command)
			Asset soundCloudSongs = new Asset('files/json/music.json');
			await soundCloudSongs.load(statusElement: querySelector("#LoadStatus2"));
		} catch(e) {
			logmessage("[SoundManager] Error while loading sounds: $e");
		}
	}

	Future<dynamic> playSound(String name, {bool asset: true, bool looping: false,
		bool fadeIn: false, Duration fadeInDuration, Element parentElement: null}) async {

		try {
			if(useWebAudio) {
				if(asset) {
					AudioInstance audio = gameSounds[name].play(looping: looping);
					if(fadeIn) {
						audio.gain = 0.0;
						if(fadeInDuration == null) {
							fadeInDuration = new Duration(seconds:5);
						}
						double currentPercentOfFade = 0.0;
						//for some reason if(audio.gain >= 1.0) threw errors about int
						//not being a subtype of double. So this steps method instead
						int steps = fadeInDuration.inMilliseconds~/100;
						new Timer.periodic(new Duration(milliseconds:100), (Timer t) {
							currentPercentOfFade += 100 / fadeInDuration.inMilliseconds;
							audio.gain = currentPercentOfFade;
							steps--;
							if(steps <= 0) {
								t.cancel();
							}
						});
					}
					return audio;
				} else {
					//if we say it's not an asset then load a new sound and play it as music
					Sound music = new Sound(channel: audioChannels['music']);
					await music.load(currentSong.streamingUrl);
					currentAudioInstance = music.play(looping: looping);
				}
			} else {
				AudioElement loading = ASSET[name].get();
				loading.loop = looping;
				if(asset) {
					loading.volume = int.parse(localStorage['effectsVolume']) / 100;
				} else {
					loading.volume = int.parse(localStorage['musicVolume']) / 100;
				}

				if(parentElement != null) {
					parentElement.append(loading);
				}

				loading.play();
				return loading;
			}
		} catch(err) {
			logmessage('[SoundManager] Error playing sound: $err');
		}
	}

	void stopSound(soundObjectToStop, {bool fadeOut:false, Duration fadeOutDuration}) {
		try {
			if(useWebAudio) {
				assert (soundObjectToStop is AudioInstance);
				AudioInstance audio = soundObjectToStop as AudioInstance;
				if(fadeOut) {
					if(fadeOutDuration == null) {
						fadeOutDuration = new Duration(seconds:5);
					}
					double currentPercentOfFade = 0.0;
					//for some reason if(audio.gain <=) threw errors about int
					//not being a subtype of double. So this steps method instead
					int steps = fadeOutDuration.inMilliseconds~/100;
					new Timer.periodic(new Duration(milliseconds:100), (Timer t) {
						currentPercentOfFade += 100 / fadeOutDuration.inMilliseconds;
						audio.gain = 1.0 - currentPercentOfFade;
						steps--;
						if(steps <= 0) {
							audio.stop();
							t.cancel();
						}
					});
				} else {
					audio.stop();
				}
			} else {
				AudioElement audio = soundObjectToStop as AudioElement;
				audio.pause();
				audio.remove();
			}
		} catch(err) {
			logmessage('[SoundManager] Error stopping sound: $err');
		}
	}

	void setMute(bool mute) {
		muted = mute;
		audioChannels.forEach((String channelName, AudioChannel channel) {
			channel.mute = mute;
		});
		for(AudioElement audio in querySelectorAll('audio')) {
			audio.muted = mute;
		}
	}

	// Track keys for which a locally recovered/converted ambient track is bundled
	// at files/sounds/music/<key>.$extension, so per-region ambient music can play
	// without a SoundCloud API token. Source/provenance for each key is recorded in
	// content/music-manifest.json. Keys not listed here (e.g. one-off event tracks
	// like 'crowns', 'rainbow', 'rube', or the still-unmatched 'forest_slow' region)
	// fall through to the SoundCloud path below, same as before this change.
	static final Set<String> localMusicTracks = new Set<String>.from(<String>[
		'ancestral', 'cave', 'enchanted', 'firebog', 'forest', 'hell',
		'highlands', 'ilmenskie', 'ix', 'jal', 'kajuu', 'kloroandhaoma',
		'nottis', 'uralia2', 'urwok',
	]);

	Future<void> loadSong(String name) async {
		if (localMusicTracks.contains(name)) {
			try {
				String path = 'files/sounds/music/$name.$extension';
				// Mirrors SC.load()'s construction of a Scound (see vendor/scproxy):
				// an <audio> element attached to the document plus lightweight meta,
				// just pointed at a bundled local file instead of a SoundCloud stream.
				AudioElement localAudio = document.body.append(new AudioElement(path));
				localAudio.load();
				songs[name] = new Scound(localAudio, {
					'title': name,
					'user': {'username': 'Children of Ur (recovered soundtrack)'},
					'permalink_url': path,
				});
				return;
			} catch(e) {
				logmessage('[SoundManager] Failed to load local music "$name", falling back to SoundCloud: $e');
				// fall through to the SoundCloud path below
			}
		}

		if (SC_TOKEN == null || SC_TOKEN.trim().isEmpty) {
			if (!_soundCloudUnavailableLogged) {
				logmessage('[SoundManager] Background music is disabled locally: no SoundCloud API token is configured.');
				_soundCloudUnavailableLogged = true;
			}
			return;
		}
		try{
			if(ASSET['music'].get()[name] == null) {
				logmessage('Song "$name" does not exist.');
			} else {
				Scound s = await sc.load(ASSET['music'].get()[name]['scid']);
				songs[name] = s;
			}
		} catch(e) {
			logmessage('[SoundManager] $e');
		}
	}

	// Music ////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * Sets the SoundCloud widget's song to [value].  Must be one of the available songs.
	 * If [value] is already playing, this method has no effect.
	 */
	Future<void> setSong(String value) async {
		if(currentSong != null && songs[value] != null &&
			songs[value].meta['title'] == currentSong.meta['title']) {
			return;
		}

		value = value.replaceAll(' ', '');
		if(songs[value] == null) {
			await loadSong(value);
			_playSong(value);
		} else {
			_playSong(value);
		}
	}

	Future<Null> _playSong(String name) {
		if (songs[name] == null) {
			return null;
		}
		/*
		 * canPlayType should return:
		 * probably: if the specified type appears to be playable.
		 * maybe: if it's impossible to tell whether the type is playable without playing it.
		 * The empty string: if the specified type definitely cannot be played.
		 *
		 * Checked against `extension` (ogg, or mp3 fallback) rather than a
		 * hardcoded mp3 so this also covers the local bundled tracks, which are
		 * shipped as ogg (see loadSong's localMusicTracks path).
		 */
		String testResult = new AudioElement().canPlayType('audio/$extension');
		if(testResult == '') {
			logmessage('[SoundManager] Your browser doesnt like .$extension files :(');
			return null;
		} else if(testResult == 'maybe') {
			//give warning message but proceed anyway
			logmessage('[SoundManager] Your browser may or may not fully support .$extension files');
		}

		// Stop the old song
		if(currentSong != null) {
			currentSong.remove();
			currentSong = null;
		}

		//play a new song
		currentSong = songs[name];
		if(useWebAudio) {
			if (currentAudioInstance != null) {
				stopSound(currentAudioInstance,
					fadeOut: true,
					fadeOutDuration: new Duration(seconds: 5));
			}
			playSound(currentSong.streamingUrl,
				asset: false,
				looping: true,
				fadeIn: true,
				fadeInDuration: new Duration(seconds: 5));
		} else {
			currentSong.play();
			currentSong.loop(true);
		}

		// Change the ui
		view.soundcloud.SCsong = currentSong.meta['title'];
		view.soundcloud.SCartist = currentSong.meta['user']['username'];
		view.soundcloud.SClink = currentSong.meta['permalink_url'];
		return null;
	}
}
