// Copyright (c) 2016, Robert McDermot. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:message_bus/message_bus.dart';
import 'package:test/test.dart';

class StringSubscriber extends EventHandler<String> {
	int testkey;
	@override
	void handleEvent(String event) {
		print('I got a String event: $event with headers $headers');
		if (headers.containsKey('testkey')) {
			testkey = headers['testkey'];
		}
	}
}

class UnwantedMessageListener {
	int expect = 0, got = 0;
	void acceptMessage(dynamic event) {
		print('this is unwanted: $event');
		got++;
	}

	void reset() {
		expect = got = 0;
	}
}

void main() {
	group('MessageBus tests', () {
		MessageBus mBus = new MessageBus();
		UnwantedMessageListener unwantedListener = new UnwantedMessageListener();

		setUp(() {
			mBus.undeliverableHandler = unwantedListener.acceptMessage;
		});

		tearDown(() {
			mBus.unsubscribeAll();
			unwantedListener.reset();
		});

		test('subscribe, no miss', () {
			unwantedListener.expect = 0;
			StringSubscriber stringSub = new StringSubscriber();
			mBus.subscribe(String, stringSub);
			mBus.publish('The stringSub has been created for test1');

			expect(unwantedListener.got, equals(unwantedListener.expect));
		});

		test('subscribe string, miss others', () {
			unwantedListener.expect = 2;
			StringSubscriber stringSub = new StringSubscriber();
			mBus.subscribe(String, stringSub);
			mBus.publish('The stringSub has been created for test2');
			mBus.publish(1);
			mBus.publish({});

			expect(unwantedListener.got, equals(unwantedListener.expect));
		});

		test('subscribeWhere', () {
			unwantedListener.expect = 1;
			StringSubscriber stringSub = new StringSubscriber();
			mBus.subscribe(String, stringSub, whereFunc: (String event) => event.contains('pattern'));
			mBus.publish('Not in this one');
			mBus.publish('This one contains the pattern');

			expect(unwantedListener.got, equals(unwantedListener.expect));
		});

		test('unsubscribe', () {
			unwantedListener.expect = 1;
			StringSubscriber stringSub = new StringSubscriber();
			mBus.subscribe(String, stringSub);
			mBus.publish('The stringSub has been created for test4');
			mBus.unsubscribe(String, stringSub);
			mBus.publish('The stringSub has been unsubscribed');

			expect(unwantedListener.got, equals(unwantedListener.expect));
		});

		test('enrich', () {
			StringSubscriber stringSub = new StringSubscriber();
			int i;
			mBus.subscribe(String, stringSub, enrichFunc: () {
				stringSub.headers['testkey'] = i;
			});

			for (i=0; i<10; i++) {
				mBus.publish('event string');
			}

			expect(stringSub.testkey, equals(9));
		});
	});
}
