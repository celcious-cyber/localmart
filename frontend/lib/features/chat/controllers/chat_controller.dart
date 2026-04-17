import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/app_alert.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/models/store_models.dart';

class ChatController extends GetxController {
  WebSocketChannel? _channel;
  final RxList<dynamic> messages = <dynamic>[].obs;
  final RxBool isConnected = false.obs;
  final RxBool isLoading = false.obs;
  
  int? currentConversationId;
  int? currentReceiverId;
  String? senderType; // 'user' or 'merchant'

  final Rxn<StoreModel> recipient = Rxn<StoreModel>();
  final RxString fallbackName = 'User'.obs;
  final RxString fallbackAvatar = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      if (Get.arguments is StoreModel) {
        recipient.value = Get.arguments as StoreModel;
        debugPrint('Chatting with: ${recipient.value?.name}');
      } else if (Get.arguments is Map<String, dynamic>) {
        final args = Get.arguments as Map<String, dynamic>;
        if (args.containsKey('store')) {
          recipient.value = args['store'];
        }
        if (args.containsKey('convId')) {
          currentConversationId = args['convId'];
        }
        if (args.containsKey('receiverId')) {
          currentReceiverId = args['receiverId'];
        }
        if (args.containsKey('receiverName')) {
          fallbackName.value = args['receiverName'];
        }
        if (args.containsKey('receiverAvatar')) {
          fallbackAvatar.value = args['receiverAvatar'];
        }
      }
    }
  }

  @override
  void onClose() {
    _channel?.sink.close();
    super.onClose();
  }

  Future<void> fetchMessages(int conversationId) async {
    isLoading.value = true;
    messages.clear();
    try {
      debugPrint('Fetching messages for ID: $conversationId');
      final response = await ApiService().getMessages(conversationId);
      messages.assignAll(response);
    } catch (e) {
      debugPrint("Error fetching messages: $e");
    } finally {
      isLoading.value = false;
    }
  }

  String get _wsUrl {
    if (kIsWeb) {
      return 'ws://localhost:8080/api/v1/ws';
    }
    if (GetPlatform.isAndroid) {
      return 'ws://10.0.2.2:8080/api/v1/ws';
    }
    return 'ws://localhost:8080/api/v1/ws';
  }

  void connect() async {
    if (isConnected.value) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    
    if (token == null) {
      debugPrint("Cannot connect: Token is null");
      return;
    }

    final urlWithToken = '$_wsUrl?token=$token';
    
    try {
      debugPrint("Mencoba koneksi ke: $urlWithToken");
      _channel = WebSocketChannel.connect(Uri.parse(urlWithToken));
      
      _channel!.stream.listen(
        (message) {
          isConnected.value = true;
          debugPrint('WebSocket Received: $message'); // Debug log for incoming messages
          final data = jsonDecode(message);
          if (data['type'] == 'chat' && data['conversation_id'] == currentConversationId) {
            messages.insert(0, data);
          }
        },
        onDone: () {
          isConnected.value = false;
          _reconnect();
        },
        onError: (error) {
          isConnected.value = false;
          debugPrint("WS Error: $error");
          _reconnect();
        },
      );
    } catch (e) {
      isConnected.value = false;
      debugPrint("WS Connection Error: $e");
      AppAlert.error('Koneksi Gagal', 'Tidak dapat terhubung ke chat server. Mencoba kembali...');
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!isConnected.value) {
        connect();
      }
    });
  }

  void sendMessage(String content) {
    if (content.trim().isEmpty || _channel == null) return;

    // Haptic Feedback for premium feel
    HapticFeedback.lightImpact();

    final payload = {
      "type": "chat",
      "conversation_id": currentConversationId,
      "receiver_id": currentReceiverId,
      "content": content,
      "sender_type": senderType ?? 'user',
      "created_at": DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(jsonEncode(payload));
  }
}
