//Copyright (c) 2016, Robert McDermot. All rights reserved. Use of this source code
//is governed by a BSD-style license that can be found in the LICENSE file.

import 'message_bus_impl.dart';

typedef bool whereFunc(dynamic event);
typedef void enrichFunc();
typedef void handlerFunc(dynamic event);

///Offers an instance of a [MessageBus] through which you can subscribe to and publish events
abstract class MessageBus {
	factory MessageBus() {
		return new MessageBusImpl();
	}

	///The [handler] function will be called if there are no subscribers listening to a
	///published message. The default handler will print a message indicating that the
	///event could not be received by any subscribers
	void set undeliverableHandler(dynamic handler);

	///Publish an event to the message bus. It will be delivered to all subscribers
	///who are subscribed to the event's type
	void publish(dynamic event);

	///Subscribe to be notified when instances of an event of type T are generated.
	///When they are, [handleEvent] will be called with the instance of the event.
	///If [whereFunc] is set, events will only be delivered if the function returns true
	///If [enrichFunc] is defined it can be used to set the [EventHandler.headers] to
	///include arbitrary data for each event that is sent
	void subscribe(Type T, EventHandler handler, {whereFunc, enrichFunc});

	///Remove the class from listening to events of type T
	void unsubscribe(Type T, EventHandler handler);

	///Remove all listeners. If [type] is given, will only remove listeners of that type
	void unsubscribeAll({Type type});
}

abstract class EventHandler<T> {
	Map<String, dynamic> headers = {};
	void handleEvent(T event);
}
