// Copyright (c) 2016, Robert McDermot. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:message_bus/message_bus.dart';
import 'dart:async';

MessageBus mBus;

main() async {
	mBus = new MessageBus();
	ClientA aClient = new ClientA();
	ClientB bClient = new ClientB();
	await bClient.publish();
	mBus.unsubscribe(String, aClient);
	bClient = new ClientB();
	await bClient.publish();
}

class ClientA implements EventHandler<String> {
	ClientA() {
		mBus.subscribe(String, this);
	}

	@override
	Future handleEvent(String event) async {
		print('I got me a string event: $event');
	}
}

class ClientB {
	Future publish() async {
		await mBus.publish('ClientB being created - message 1');
		await mBus.publish('ClientB being created - message 2');
		await mBus.publish(1);
	}
}