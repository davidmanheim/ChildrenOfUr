part of couclient;

class ShrineWindow extends Modal {
	static ShrineWindow shrineWindow;
	String id = 'shrineWindow',
		giantName;
	int favor, maxFavor;
	String shrineId;
	Element buttonHolder, confirmButton, cancelButton, dropTarget, numSelectorContainer, helpText;
	ProgressElement favorProgress;
	Element favorLabel;
	Map<String, dynamic> item;
	NumberInputElement numBox;
	Element QtyContainer, plusBtn, minusBtn, maxBtn;

	factory ShrineWindow(String giantName, int favor, int maxFavor, String shrineId) {
		if (shrineWindow == null) {
			shrineWindow = new ShrineWindow._(giantName, favor, maxFavor, shrineId);
		} else {
			shrineWindow
				..giantName = giantName
				..favor = favor
				..maxFavor = maxFavor
				..shrineId = shrineId;
		}

		return shrineWindow;
	}

	@override
	close() {
		sendAction("close", shrineId, {});
		super.close();
	}

	@override
	open({bool ignoreKeys: false}) {
		resetShrineWindow();
		populateShrineWindow();
		makeDraggables();
		super.open(ignoreKeys: true);
	}

	void resetShrineWindow() {
		buttonHolder.style.visibility = 'hidden';
		dropTarget.style.backgroundImage = 'none';
		helpText.innerHtml = 'Drop an item here from your inventory to donate it to ' + giantName + ' for favor.';
		numSelectorContainer.hidden = true;
		item.clear();
	}

	void populateShrineWindow() {
		List<Element> insertGiantName = querySelectorAll(".insert-giantname").toList();
		insertGiantName.forEach((placeholder) => placeholder.text = giantName);

		int percent = 100 * favor ~/ maxFavor;
		_setFavorProgress(percent);
	}

	void populateQtySelector(String itemType) {
		numBox.attributes['max'] = _getNumItems(itemType).toString();
		numBox.valueAsNumber = 1;
	}

	void makeDraggables() {
		Dropzone dropzone = new Dropzone(dropTarget);
		dropzone.onDrop.listen((DropzoneEvent dropEvent) {
			//verify it is a valid item before acting on it
			if (dropEvent.draggableElement.attributes['itemMap'] == null) {
				return;
			}

			buttonHolder.style.visibility = 'visible';
			item = jsonDecode(dropEvent.draggableElement.attributes['itemMap']) as Map;
			dropTarget.style.backgroundImage = 'url(${item['iconUrl']})';
			helpText.innerHtml = 'Donate how many?';

			numSelectorContainer.hidden = false;
			populateQtySelector(item['itemType']);
		});
	}

	// Was: favorProgress..setAttribute('percent', ...)..setAttribute('status', ...)
	// against a `<ur-progress>` element -- a custom element that was never
	// actually implemented anywhere (no JS/Dart registration, no CSS), so
	// those attributes had no visual effect at all. Donating genuinely
	// updated favor server-side; nothing about it ever appeared on screen.
	// Drives the real <progress>/<label> pair now (see index.html).
	void _setFavorProgress(int percent) {
		favorProgress.value = percent;
		favorLabel.text = "$favor of $maxFavor favor towards an Emblem of $giantName";
	}

	ShrineWindow._(this.giantName, this.favor, this.maxFavor, this.shrineId) {
		prepare();

		QtyContainer = displayElement.querySelector("#shrine-window-qty");
		plusBtn = displayElement.querySelector(".plus");
		minusBtn = displayElement.querySelector(".minus");
		maxBtn = displayElement.querySelector(".max");
		numBox = displayElement.querySelector(".NumToDonate");
		buttonHolder = querySelector('#shrine-window-buttons');
		confirmButton = querySelector('#shrine-window-confirm');
		cancelButton = querySelector('#shrine-window-cancel');
		dropTarget = querySelector("#DonateDropTarget");
		favorProgress = querySelector("#shrine-window-favor");
		favorLabel = displayElement.querySelector("#shrine-window-bottom .progress label");
		numSelectorContainer = querySelector("#shrine-window-qty");
		helpText = querySelector("#DonateHelp");
		item = {};

		populateShrineWindow();

		new Service(['favorUpdate'], (favorMap) {
			favor = favorMap['favor'];
			maxFavor = favorMap['maxFavor'];
			int percent = 100 * favorMap['favor'] ~/ favorMap['maxFavor'];
			_setFavorProgress(percent);
		});

		confirmButton.onClick.listen((_) {
			Map<String, dynamic> actionMap = {
				"itemType": item['itemType'] as String,
				"qty": numBox.valueAsNumber.toInt()
			};
			sendAction("donate", shrineId, actionMap);
			resetShrineWindow();
		});

		cancelButton.onClick.listen((_) {
			resetShrineWindow();
		});

		plusBtn.onClick.listen((_) {
			if (numBox.valueAsNumber + 1 > num.parse(numBox.max)) {
				numBox.valueAsNumber = num.parse(numBox.max);
			} else {
				numBox.valueAsNumber = numBox.valueAsNumber + 1;
			}
		});

		minusBtn.onClick.listen((_) {
			if (numBox.valueAsNumber - 1 < num.parse(numBox.min)) {
				numBox.valueAsNumber = num.parse(numBox.min);
			} else {
				numBox.valueAsNumber = numBox.valueAsNumber - 1;
			}
		});

		maxBtn.onClick.listen((_) {
			numBox.valueAsNumber = num.parse(numBox.max);
		});
	}
}