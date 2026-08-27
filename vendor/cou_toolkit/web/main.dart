import 'dart:html';

void main() {
	sliderBars();
	print("main OK");
}

void sliderBars() {
	RangeInputElement range = querySelector("#inputRange");

	ProgressElement progress1 = querySelector("#outputProgress");
	LabelElement progress1Label = querySelector("label[for='outputProgress']");

	ProgressElement progress2 = querySelector("#outputNotProgress");
	LabelElement progress2Label = querySelector("label[for='outputNotProgress']");

	range.onInput.listen((event) {
		num value = num.parse(range.value);

		progress1.value = value;
		progress1Label.text = "${(value * 100).toStringAsFixed(0)}% loaded";

		progress2.value = 1 - value;
		progress2Label.text = "${((1 - value) * 100).toStringAsFixed(0)}% unloaded";
	});
}
