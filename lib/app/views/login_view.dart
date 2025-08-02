import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import 'chat_view.dart';


class LoginView extends StatelessWidget {

  final ChatController chatController = Get.put(ChatController());

  // Hardcoded list of users since we do not have currently a database or a server
  // to fetch users from.
  final users = ["user1", "user2", "user3"];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: Text("Login")),

      body: ListView.builder(

        itemCount: users.length,
        itemBuilder: (_, index) {

          return ListTile(

            title: Text(users[index]),
            onTap: () {

              chatController.login(users[index]);
              Get.to(() => ChatView());

            },

          );

        },

      ),

    );

  }

}
