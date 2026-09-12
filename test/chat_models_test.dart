import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/features/chat/data/chat_models.dart';

void main() {
  test('chat conversation parses backend payload into in-app message model', () {
    final conversation = ChatConversation.fromJson({
      'id': 7,
      'booking_id': 15,
      'driver_trip_id': 22,
      'driver': {'id': 4, 'name': 'Ahsan'},
      'passenger': {'id': 1, 'name': 'Nadia'},
      'messages': [
        {
          'id': 101,
          'sender_id': 1,
          'message': 'On my way.',
          'read_at': null,
          'created_at': '2026-09-11T09:30:00Z',
          'is_from_me': true,
        },
      ],
      'unread_count': 0,
    });

    expect(conversation.id, 7);
    expect(conversation.messages.length, 1);
    expect(conversation.messages.first.text, 'On my way.');
    expect(conversation.messages.first.isFromMe, isTrue);
    expect(conversation.driverName, 'Ahsan');
  });
}
