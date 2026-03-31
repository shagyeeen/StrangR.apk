import 'package:flutter/material.dart';
import 'package:strangr_app/core/theme.dart';
import 'package:strangr_app/core/socket_service.dart';
import 'package:strangr_app/core/friends_manager.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

enum BondStatus { initial, pending, requested, bonded }

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String strangerId;
  final String strangRCode;
  
  const ChatScreen({
    super.key, 
    required this.roomId,
    required this.strangerId,
    this.strangRCode = 'Stranger',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SocketService _socketService = SocketService();
  final FriendsManager _friendsManager = FriendsManager();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _strangerTyping = false;
  BondStatus _bondStatus = BondStatus.initial;
  String? _connectionId; // Needed to accept the bond
  String? _friendshipId; // ID for the permanent friendship room

  @override
  void initState() {
    super.initState();
    
    // Initialize bonded state if coming from Friends List
    if (widget.roomId.startsWith('bond_')) {
      _bondStatus = BondStatus.bonded;
      _friendshipId = widget.roomId;
    }
    
    _socketService.onMessageReceived = (data) {
      if (mounted) {
        setState(() {
          // data is { text, senderId, ... }
          _messages.add({
            'text': data['text'],
            'sender': data['senderId'] == FirebaseAuth.instance.currentUser?.uid ? 'me' : 'stranger',
            'timestamp': data['timestamp']
          });
          _strangerTyping = false;
        });
        _scrollToBottom();
      }
    };
    
    _socketService.onTypingStatus = (data) {
       if (mounted && data['senderId'] == widget.strangerId) {
          setState(() {
             _strangerTyping = data['isTyping'];
          });
       }
    };

    _socketService.onStrangerDisconnected = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Stranger disconnected or skipped.'))
        );
        Navigator.pushReplacementNamed(context, '/search_hub');
      }
    };

    _socketService.onBondRequested = (data) {
       if (mounted) {
          setState(() {
             // We don't change _bondStatus to requested visually for P2
             // but we keep track of the connectionId in case we need it
             _connectionId = data['connectionId'];
          });
       }
    };

    _socketService.onBondAccepted = (data) async {
       if (mounted) {
           setState(() {
              _bondStatus = BondStatus.bonded;
              _friendshipId = data['friendshipId'];
           });
          
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId != null) {
            await _friendsManager.addFriend(
               currentUserId, 
               Friend(
                  id: widget.strangerId, 
                  name: widget.strangRCode, 
                  status: 'online', 
                  roomId: data['friendshipId'] ?? widget.roomId
               )
            );
          }
          
          // Close "Proposed" dialog if it's open
          if (Navigator.of(context).canPop()) {
             Navigator.of(context).pop(); 
          }
          _showCompleteDialog();
       }
    };

    _socketService.onBondDeclined = (data) {
       if (mounted) {
          setState(() {
             _bondStatus = BondStatus.initial;
          });
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Bond request declined.'))
          );
       }
    };
  }
  
  void _scrollToBottom() {
     WidgetsBinding.instance.addPostFrameCallback((_) {
         if (_scrollController.hasClients) {
            _scrollController.animateTo(
               _scrollController.position.maxScrollExtent + 100,
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeOut,
            );
         }
     });
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    final currentRoomId = _friendshipId ?? widget.roomId;
    if (text.isNotEmpty) {
      _socketService.sendMessage(text, widget.strangerId, roomId: currentRoomId);
      
      setState(() {
        _messages.add({
          'text': text,
          'sender': 'me',
          'timestamp': DateTime.now().toIso8601String()
        });
      });
      _msgController.clear();
      _socketService.sendTypingStatus(false, widget.strangerId, roomId: currentRoomId);
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
        backgroundColor: const Color(0xFF0D020D),
        appBar: AppBar(
           backgroundColor: Colors.black,
           elevation: 0,
           leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () {
                 if (_bondStatus != BondStatus.bonded) {
                    _socketService.skipStranger(widget.strangerId);
                 }
                 Navigator.pushReplacementNamed(context, '/search_hub');
              },
           ),
           titleSpacing: 0,
           title: Row(
              children: [
                 Stack(
                    children: [
                       CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.purple.withOpacity(0.2),
                          child: const Icon(Icons.person, color: Colors.purple, size: 20),
                       ),
                       Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                             width: 10, height: 10,
                             decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2),
                             ),
                          ),
                       )
                    ],
                 ),
                 const SizedBox(width: 12),
                 Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                          widget.strangRCode.toUpperCase(), 
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)
                       ),
                       Text(
                          _strangerTyping ? 'TYPING...' : 'ACTIVE NOW', 
                          style: GoogleFonts.inter(
                             fontSize: 10, 
                             fontWeight: FontWeight.w700,
                             color: _strangerTyping ? StrangRTheme.tertiary : Colors.grey.shade600,
                             letterSpacing: 0.5
                          )
                       ),
                    ],
                 ),
              ],
           ),
           actions: [
              Row(
                children: [
                   if (_bondStatus == BondStatus.initial)
                      IconButton(
                         icon: const Icon(Icons.link, color: Colors.white, size: 20),
                         onPressed: () {
                            _socketService.requestBond(widget.strangerId);
                            setState(() {
                               _bondStatus = BondStatus.pending;
                            });
                            _showProposedDialog();
                         },
                      ),
                   if (_bondStatus == BondStatus.pending)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple)),
                      ),
                   if (_bondStatus == BondStatus.bonded)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.verified, color: Colors.greenAccent, size: 20),
                      ),
                   Icon(Icons.shield_outlined, size: 14, color: Colors.white.withOpacity(0.3)),
                   const SizedBox(width: 4),
                   Text('P2P SECURE', style: GoogleFonts.inter(fontSize: 8, color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.bold)),
                   const SizedBox(width: 16),
                ],
              )
           ],
        ),
        body: Stack(
           children: [
              // Doodle Background Pattern
              Positioned.fill(
                 child: Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                       'public/images/chat_wallpaper.png',
                       fit: BoxFit.cover,
                    ),
                 ),
              ),
              Column(
                 children: [
              Expanded(
                 child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                       final msg = _messages[index];
                       final isMe = msg['sender'] == 'me';
                       return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                             margin: const EdgeInsets.only(bottom: 12),
                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                             constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                             decoration: BoxDecoration(
                                color: isMe ? const Color(0xFFE8C8FA) : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(24).copyWith(
                                   bottomRight: Radius.circular(isMe ? 4 : 24),
                                   bottomLeft: Radius.circular(isMe ? 24 : 4),
                                ),
                             ),
                             child: Text(
                                msg['text'] ?? '',
                                style: GoogleFonts.inter(
                                   color: isMe ? Colors.black : Colors.white,
                                   fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
                                   fontSize: 15,
                                ),
                             ),
                          ),
                       );
                    },
                 ),
              ),
              
              // Input Field
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                 color: Colors.transparent,
                 child: SafeArea(
                    child: Container(
                       padding: const EdgeInsets.all(4),
                       decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                       ),
                       child: Row(
                          children: [
                             const SizedBox(width: 16),
                             Expanded(
                                child: TextField(
                                   controller: _msgController,
                                    onChanged: (val) {
                                       final currentRoomId = _friendshipId ?? widget.roomId;
                                       _socketService.sendTypingStatus(val.isNotEmpty, widget.strangerId, roomId: currentRoomId);
                                    },
                                   style: const TextStyle(color: Colors.white, fontSize: 14),
                                   decoration: InputDecoration(
                                      hintText: 'Message ${widget.strangRCode}...',
                                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                   ),
                                ),
                             ),
                             GestureDetector(
                                onTap: _sendMessage,
                                child: Container(
                                   height: 42, width: 42,
                                   decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.1),
                                   ),
                                   child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                                ),
                             ),
                             const SizedBox(width: 4),
                          ],
                       ),
                    ),
                 ),
              )
                 ],
              ),
           ],
        ),
     );
  }

  void _showProposedDialog() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF131313),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.white.withOpacity(0.3), size: 20),
                    ),
                  ),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.purple.withOpacity(0.5), width: 1),
                    ),
                    child: const Center(child: Icon(Icons.person_outline, color: Colors.purple, size: 40)),
                  ),
                  const SizedBox(height: 24),
                  Text('Connection Request\nProposed', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2)),
                  const SizedBox(height: 8),
                  Text('Hoping for a connection...', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: () {
                      // Logic to cancel proposal if available in socket
                      setState(() { _bondStatus = BondStatus.initial; });
                      Navigator.pop(context);
                    },
                    child: Text('CANCEL PROPOSAL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFFF9B8F9), letterSpacing: 1.5)),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCompleteDialog() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF131313),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8C8FA),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0xFFE8C8FA), blurRadius: 40, spreadRadius: -10)],
                    ),
                    child: const Center(child: Icon(Icons.favorite, color: Color(0xFF4C1D51), size: 48)),
                  ),
                  const SizedBox(height: 32),
                  Text('✨ Bond Complete ✨', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.6), height: 1.5),
                      children: [
                        TextSpan(text: widget.strangRCode, style: const TextStyle(color: Color(0xFFF9B8F9), fontWeight: FontWeight.bold)),
                        const TextSpan(text: ' has accepted the bond.\n\nYou can now find them in your Friends list and decide if you\'d like to share your real identity.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('CONTINUE DIALOGUE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
