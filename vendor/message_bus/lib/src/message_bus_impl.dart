library message_bus_impl;

import 'package:message_bus/message_bus.dart';

class MessageBusImpl implements MessageBus {
	static MessageBusImpl _instance;
	Map<Type, List<Deliverer>> _channels = {};

	MessageBusImpl._();

	factory MessageBusImpl() {
		if (MessageBusImpl._instance == null) {
			MessageBusImpl._instance = new MessageBusImpl._();
		}

		return MessageBusImpl._instance;
	}

	Function _undeliverableHandler = (dynamic event) {
		print('Unable to deliver event to any subscribers: $event');
	};

	@override
	void set undeliverableHandler(dynamic handler) {
		_undeliverableHandler = handler;
	}

	@override
	void subscribe(Type type, EventHandler handler, {whereFunc, enrichFunc}) {
		if (!_channels.containsKey(type)) {
			_channels[type] = [];
		}

		Deliverer deliverer = new Deliverer()
			..eventHandler = handler;

		if (whereFunc != null) {
			deliverer.where = whereFunc;
		}

		if (enrichFunc != null) {
			deliverer.enrich = enrichFunc;
		}

		_channels[type].add(deliverer);
	}

	@override
	void unsubscribe(Type T, EventHandler handler) {
		_channels[T]?.removeWhere((Deliverer d) => d.eventHandler == handler);
	}

	@override
	void unsubscribeAll({Type type}) {
		if (type != null) {
			_channels.remove(type);
		} else {
			_channels.clear();
		}
	}

	bool subscribersExist(dynamic event) {
		if (!_channels.containsKey(event.runtimeType) ||
			_channels[event.runtimeType].length == 0) {
			_undeliverableHandler(event);
			return false;
		}

		return true;
	}

	@override
	void publish(event) {
		if (subscribersExist(event)) {
			for (Deliverer deliverer in _channels[event.runtimeType]) {
				if (!deliverer.deliver(event)) {
					_undeliverableHandler(event);
				}
			}
		}
	}
}

class Deliverer<T> {
	EventHandler<T> eventHandler;
	whereFunc where = (dynamic event) => true;
	enrichFunc enrich = (){};

	bool deliver(event) {
		if (!where(event)) {
			return false;
		}

		enrich();
		eventHandler.handleEvent(event);

		return true;
	}
}
