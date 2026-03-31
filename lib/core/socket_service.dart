import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final String _serverUrl = 'https://strangr-app.onrender.com';
  
  // Callbacks
  Function(Map<String, dynamic>)? onMatchFound;
  Function()? onStrangerDisconnected;
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onTypingStatus;
  Function(Map<String, dynamic>)? onBondRequested;
  Function(Map<String, dynamic>)? onBondAccepted;
  Function(Map<String, dynamic>)? onBondDeclined;

  bool get connected => _socket?.connected ?? false;

  Future<void> initSocket(String userId, String token) async {
    if (_socket != null) {
      _socket!.disconnect();
    }

    _socket = IO.io(_serverUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .enableForceNew()
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('REALTIME: Connected to backend at $_serverUrl');
    });

    _socket!.onConnectError((err) {
      print('REALTIME ERROR: $err');
    });

    // --- Backend Event Mapping ---
    
    // Server emits 'new_match' when a partner is found
    _socket!.on('new_match', (data) {
      print('REALTIME: Match Found! $data');
      if (onMatchFound != null) onMatchFound!(data);
    });

    // Server emits 'match_skipped_you' or 'disconnect'
    _socket!.on('match_skipped_you', (_) {
      if (onStrangerDisconnected != null) onStrangerDisconnected!();
    });

    _socket!.on('receive_message', (data) {
      if (onMessageReceived != null) onMessageReceived!(data);
    });
    
    _socket!.on('user_typing', (data) {
       if (onTypingStatus != null) onTypingStatus!({'senderId': data['senderId'], 'isTyping': true});
    });

    _socket!.on('user_stopped_typing', (data) {
       if (onTypingStatus != null) onTypingStatus!({'senderId': data['senderId'], 'isTyping': false});
    });

    _socket!.on('connection_request_received', (data) {
       if (onBondRequested != null) onBondRequested!(data);
    });

    _socket!.on('connection_accepted', (data) {
       if (onBondAccepted != null) onBondAccepted!(data);
    });

    _socket!.on('connection_declined', (data) {
       if (onBondDeclined != null) onBondDeclined!(data);
    });

    _socket!.onDisconnect((_) {
      print('REALTIME: Disconnected');
    });
  }

  // --- Emitters matching backend handlers ---

  void startSearching() {
    if (connected) {
      print('REALTIME: Emitting start_matching');
      _socket!.emit('start_matching');
    }
  }

  void stopSearching() {
    if (connected) {
      _socket!.emit('stop_matching');
    }
  }

  void sendMessage(String text, String recipientId, {String? roomId}) {
    if (connected) {
      final payload = {
        'recipientId': recipientId,
        'text': text,
        'roomId': roomId,
        'friendshipId': roomId,
        'clientMsgId': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      _socket!.emit('send_message', payload);
    }
  }

  void sendTypingStatus(bool isTyping, String recipientId, {String? roomId}) {
    if (connected) {
      final event = isTyping ? 'typing' : 'stop_typing';
      _socket!.emit(event, {
        'recipientId': recipientId,
        'roomId': roomId,
        'friendshipId': roomId,
      });
    }
  }

  void skipStranger(String strangerId) {
    if (connected) {
      _socket!.emit('skip_stranger', {'strangerId': strangerId});
    }
  }

  void requestBond(String recipientId) {
    if (connected) {
      _socket!.emit('send_connection_request', {'recipientId': recipientId});
    }
  }

  void acceptBond(String connectionId, String requesterId) {
    if (connected) {
      _socket!.emit('accept_connection', {
        'connectionId': connectionId,
        'requesterId': requesterId,
      });
    }
  }

  void declineBond(String connectionId, String requesterId) {
    if (connected) {
      _socket!.emit('decline_connection', {
        'connectionId': connectionId,
        'requesterId': requesterId,
      });
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.clearListeners();
    _socket?.dispose();
    _socket = null;
  }
}
