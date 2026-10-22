import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';
import 'package:humming_bird/services/group_system_message_service.dart';

Messages _system(Map<String, dynamic> payload, {String? raw}) {
  final rawText = raw ?? jsonEncode(payload);
  return Messages.fromJson({
    'm_id': '11',
    'm_room_id': '2',
    'm_message_type': '7',
    'm_message': rawText,
    'm_sender_id': '10',
  });
}

Messages _encryptedSystem(Map<String, dynamic> payload) {
  return _system(payload,
      raw: EncryptionHelper().encryptMessage(jsonEncode(payload)));
}

final _members = [
  User()
    ..userId = '10'
    ..userFirstName = 'Benu'
    ..userLastName = 'Sharma',
  User()
    ..userId = '20'
    ..userFirstName = 'Ria'
    ..userLastName = '',
  User()
    ..userId = '30'
    ..userMobileNum = '9876543210',
];

void main() {
  group('GroupSystemMessageService', () {
    test('isSystem only matches type 7', () {
      expect(GroupSystemMessageService.isSystem(_system({'event': 'x'})), true);
      final normal = Messages.fromJson({
        'm_id': '1',
        'm_message_type': '0',
        'm_message': 'hello',
      });
      expect(GroupSystemMessageService.isSystem(normal), false);
    });

    test('decodePayload parses plaintext and encrypted payloads', () {
      final payload = {'event': 'member_added', 'actorId': '10', 'targetIds': ['20']};
      final plain = GroupSystemMessageService.decodePayload(_system(payload));
      expect(plain, isNotNull);
      expect(plain!['event'], 'member_added');

      final enc = GroupSystemMessageService.decodePayload(
          _encryptedSystem(payload));
      expect(enc, isNotNull);
      expect(enc!['event'], 'member_added');
    });

    test('decodePayload returns null for junk text', () {
      expect(
          GroupSystemMessageService.decodePayload(
              Messages.fromJson({
                'm_id': '1',
                'm_message_type': '7',
                'm_message': 'not json at all',
              })),
          isNull);
    });

    test('group_created shows actor', () {
      final msg = _system({'event': 'group_created', 'actorId': '10'});
      expect(GroupSystemMessageService.format(msg,
              members: _members, myUserId: '10'),
          'You created this group');
    });

    test('name change quotes the new name', () {
      final msg = _system({
        'event': 'group_name_changed',
        'actorId': '10',
        'newName': 'Tech Team',
      });
      expect(GroupSystemMessageService.format(msg,
              members: _members, myUserId: '10'),
          'You changed the group name to "Tech Team"');
    });

    test('single target becomes "and"-free single name', () {
      final msg = _system({'event': 'member_added', 'actorId': '10', 'targetIds': ['20']});
      expect(GroupSystemMessageService.format(msg,
              members: _members, myUserId: '10'),
          'You added Ria');
    });

    test('two targets join with "and"', () {
      final msg =
          _system({'event': 'member_added', 'actorId': '10', 'targetIds': ['20', '30']});
      expect(GroupSystemMessageService.format(msg,
              members: _members, myUserId: '10'),
          'You added Ria and 9876543210');
    });

    test('three or more targets collapse to a count', () {
      final msg = _system({
        'event': 'member_added',
        'actorId': '10',
        'targetIds': ['20', '30', '40', '50']
      });
      expect(GroupSystemMessageService.format(msg,
              members: _members, myUserId: '10'),
          'You added 4 members');
    });

    test('removed/promoted/demoted/left sentences', () {
      expect(
          GroupSystemMessageService.format(
              _system({'event': 'member_removed', 'actorId': '10', 'targetIds': ['30']}),
              members: _members,
              myUserId: '10'),
          'You removed 9876543210');
      expect(
          GroupSystemMessageService.format(
              _system({'event': 'member_promoted', 'actorId': '10', 'targetIds': ['20']}),
              members: _members,
              myUserId: '10'),
          'You made Ria an admin');
      expect(
          GroupSystemMessageService.format(
              _system({'event': 'member_demoted', 'actorId': '10', 'targetIds': ['20']}),
              members: _members,
              myUserId: '10'),
          'You stopped Ria from being an admin');
      expect(
          GroupSystemMessageService.format(
              _system({'event': 'member_left', 'actorId': '20'}),
              members: _members,
              myUserId: '10'),
          'Ria left this group');
    });

    test('falls back to phone, then Member, for unknown ids', () {
      expect(
          GroupSystemMessageService.format(
              _system({'event': 'member_added', 'actorId': '10', 'targetIds': ['999']}),
              members: _members,
              myUserId: '10'),
          'You added Member');
    });

    test('unknown event yields empty preview (never spoofed)', () {
      expect(
          GroupSystemMessageService.format(
              _system({'event': 'mystery', 'actorId': '10'}),
              members: _members,
              myUserId: '10'),
          '');
    });

    test('preview includes no "sender:" prefix for system rows', () {
      final text = GroupSystemMessageService.preview(
          _encryptedSystem({'event': 'member_left', 'actorId': '10'}));
      expect(text.contains('Benu'), false);
      expect(text.contains(':'), false);
    });
  });
}