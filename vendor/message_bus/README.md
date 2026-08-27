# message_bus

A simple message_bus library for Dart

## Usage

A simple usage example:

    import 'package:message_bus/message_bus.dart';
    
    MessageBus mBus = new MessageBus();
    
    class Subscriber() extends EventHandler<String> {
        @override
        handleEvent(String event) {
            print('I got an event: $event');
        }
    }

    main() {
        Subscriber subscriber = new Subscriber();
        mBus.subscribe(String, subscriber);
        mBus.publish('Subscriber will get this');
    }

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/RobertMcDermot/dart_message_bus/issues
