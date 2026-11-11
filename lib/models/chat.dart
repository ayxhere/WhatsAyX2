/// A chat thread shown in the Chats list.
class ChatThread {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isGroup;
  final int avatarColor;

  const ChatThread({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.isGroup = false,
    this.avatarColor = 0xFF4DD0C4,
  });
}

/// A single message inside a chat.
class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final String time;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
  });
}

/// A status update shown on the Status tab.
class StatusItem {
  final String id;
  final String name;
  final String time;
  final bool viewed;
  final int avatarColor;

  const StatusItem({
    required this.id,
    required this.name,
    required this.time,
    this.viewed = false,
    this.avatarColor = 0xFF4DD0C4,
  });
}

/// Demo data used when the gateway is not connected.
/// The real data comes from the Node gateway (Baileys) via ApiService.
class DemoData {
  static const List<ChatThread> chats = [
    ChatThread(
      id: '1',
      name: 'Raju',
      lastMessage: 'Bhai, naya logo dekh liya? Box 09 final hai.',
      time: '02:31',
      unread: 2,
      avatarColor: 0xFF4DD0C4,
    ),
    ChatThread(
      id: '2',
      name: 'ElePay Support',
      lastMessage: 'Withdrawal done. Check your balance.',
      time: '01:58',
      unread: 0,
      isGroup: true,
      avatarColor: 0xFF82AAFF,
    ),
    ChatThread(
      id: '3',
      name: 'AyX Team',
      lastMessage: 'v2 build is ready. Flutter + Node.',
      time: 'Yesterday',
      unread: 0,
      avatarColor: 0xFF25D366,
    ),
    ChatThread(
      id: '4',
      name: 'Imayx',
      lastMessage: 'Site is live on imayx.in',
      time: 'Yesterday',
      unread: 1,
      avatarColor: 0xFFFFB020,
    ),
  ];

  static const List<ChatMessage> messages = [
    ChatMessage(
      id: 'm1',
      text: 'Hi, WhatsAyX v2 kaisa lag raha hai?',
      isMe: false,
      time: '02:28',
    ),
    ChatMessage(
      id: 'm2',
      text: 'Clean hai bhai, WZH style. Smooth bhi hai.',
      isMe: true,
      time: '02:29',
    ),
    ChatMessage(
      id: 'm3',
      text: 'Logo original wala hi hai, box bada kar diya.',
      isMe: false,
      time: '02:30',
    ),
    ChatMessage(
      id: 'm4',
      text: 'Perfect. Ab chats yahin se chalenge.',
      isMe: true,
      time: '02:31',
    ),
  ];

  static const List<StatusItem> statuses = [
    StatusItem(
      id: 's1',
      name: 'Raju',
      time: '10 min ago',
      avatarColor: 0xFF4DD0C4,
    ),
    StatusItem(
      id: 's2',
      name: 'AyX Team',
      time: '1 hr ago',
      avatarColor: 0xFF82AAFF,
    ),
    StatusItem(
      id: 's3',
      name: 'Imayx',
      time: '3 hrs ago',
      viewed: true,
      avatarColor: 0xFF25D366,
    ),
  ];
}
