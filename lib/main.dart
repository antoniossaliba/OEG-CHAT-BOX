import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String currentUser = "User1"; // Change to User2 or User3 per emulator

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Private Chat App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Color(0xFFF1F5FB),
      ),
      home: ChatScreen(currentUser: currentUser),
    );
  }
}

class ChatController extends GetxController {
  late IO.Socket socket;
  final String currentUser;

  var selected = ''.obs; // The user you're chatting with
  var chats = <String, RxList<Message>>{}.obs; // chatId -> messages list

  ChatController(this.currentUser);

  @override
  void onInit() {
    super.onInit();
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();

    socket.onConnect((_) {
      print('Connected');
      socket.emit('join', currentUser);
    });

    socket.on('private_message', (data) {
      final msg = Message(
        sender: data['sender'],
        receiver: data['receiver'],
        text: data['message'],
      );
      final chatId = getChatId(msg.sender, msg.receiver);
      chats.putIfAbsent(chatId, () => <Message>[].obs).add(msg);
    });

    socket.onDisconnect((_) => print('Disconnected'));
  }

  void send(String text) {
    if (text.trim().isEmpty || selected.value.isEmpty) return;
    final msg = Message(
      sender: currentUser,
      receiver: selected.value,
      text: text,
    );
    final chatId = getChatId(currentUser, selected.value);
    chats.putIfAbsent(chatId, () => <Message>[].obs).add(msg);
    socket.emit('private_message', {
      'sender': currentUser,
      'receiver': selected.value,
      'message': text,
    });
  }

  String getChatId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}

class Message {
  final String sender;
  final String receiver;
  final String text;

  Message({required this.sender, required this.receiver, required this.text});
}

class ChatScreen extends StatelessWidget {
  final String currentUser;
  ChatScreen({required this.currentUser});

  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final ChatController c = Get.put(ChatController(currentUser));
    final users = ['User1', 'User2', 'User3'].where((u) => u != currentUser).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        centerTitle: true,
        backgroundColor: Colors.indigo,
        title: Obx(() => Text(
          c.selected.value.isEmpty
              ? 'Select a User'
              : 'Chat with ${c.selected.value}',
          style: TextStyle(fontWeight: FontWeight.w500),
        )),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: users.map((u) => Obx(() => ChoiceChip(
                label: Text(u),
                selected: c.selected.value == u,
                onSelected: (_) => c.selected.value = u,
                selectedColor: Colors.indigo,
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: c.selected.value == u ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ))).toList(),
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: Obx(() {
              final chatId = c.getChatId(currentUser, c.selected.value);
              final messages = c.chats[chatId] ?? <Message>[].obs;
              return ListView.builder(
                reverse: true,
                padding: EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[messages.length - 1 - index];
                  final isMe = msg.sender == currentUser;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      padding: EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.indigo[400] : Colors.grey[300],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(isMe ? 12 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              msg.sender,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          SizedBox(height: 4),
                          Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 16,
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) {
                        c.send(textController.text);
                        textController.clear();
                      },
                    ),
                  ),
                ),
                SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      c.send(textController.text);
                      textController.clear();
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}