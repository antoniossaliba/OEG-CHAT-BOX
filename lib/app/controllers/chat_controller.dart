import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;


class ChatController extends GetxController {

  late IO.Socket socket;

  final userId = ''.obs;

  final messages = <Map<String, String>>[].obs;

  void login(String id) {

    userId.value = id;

    socket = IO.io('http://localhost:3000', <String, dynamic> {

      'transports': ['websocket'],
      'autoConnect': false,

    });

    socket.connect();

    socket.onConnect((_) {

      print('Connected');
      socket.emit('register', id);

      socket.on('private_message', (data) {

        messages.add({

          'from': data['senderId'],
          'message': data['message']

        });

      });

    });

  }

  void sendMesssage(String to, String message) {

    socket.emit('private message', {

      'senderId': userId.value,
      'receiverId': to,
      'message': message

    });

  }

  List<String> get otherUsers => ['user1', 'user2', 'user3'].where((u) => u != userId.value).toList();

}
