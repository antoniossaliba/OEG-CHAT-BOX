import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';


class ChatView extends StatelessWidget {

  final ChatController chatController = Get.find();

  final TextEditingController messageController = TextEditingController();
  final RxString selectedUser = ''.obs;

  @override
  Widget build(BuildContext context) {

    selectedUser.value = chatController.otherUsers.first;

    return Scaffold(

      appBar: AppBar(

        title: Obx(() => Text("Chatting as ${chatController.userId.value}")),

      ),

      body: Column(

        children: [

          Obx(() => DropdownButton<String>(

              value: selectedUser.value,
              items: chatController.otherUsers.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) {

                if (value != null) selectedUser.value = value;

              }

          )),

          Expanded(

            child: Obx(() => ListView.builder(

              itemCount: chatController.messages.length,
              itemBuilder: (_, index) {

                final msg = chatController.messages[index];
                return ListTile(

                  title: Text("${msg['from']}: ${msg['message']}"),

                );

              },

            )),

          ),

          Padding(

            padding: const EdgeInsets.all(8.0),
            child: Row (

              children: [

                Expanded(

                  child: TextField(controller: messageController),

                ),

                IconButton(

                  icon: Icon(Icons.send),
                  onPressed: () {

                    final msg = messageController.text;

                    if (msg.isNotEmpty) {

                      chatController.sendMesssage(selectedUser.value, msg);
                      messageController.clear();

                    }

                  },

                )

              ],

            ),

          )

        ],

      ),

    );

  }

}
