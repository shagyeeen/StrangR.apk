import 'package:flutter/material.dart';
import 'package:strangr_app/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:strangr_app/core/socket_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:ui';

class SearchHubScreen extends StatefulWidget {
  const SearchHubScreen({super.key});

  @override
  State<SearchHubScreen> createState() => _SearchHubScreenState();
}

class _SearchHubScreenState extends State<SearchHubScreen> with TickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  bool _isSearching = false;
  late String _userId;

  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_${Random().nextInt(10000)}';
    
    _radarController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 3),
    );
    _radarAnimation = CurvedAnimation(parent: _radarController, curve: Curves.easeOut);

    // Initialize Realtime Socket with Firebase Token
    _connectSocket();

    _socketService.onMatchFound = (Map<String, dynamic> data) {
      if (mounted) {
        setState(() { _isSearching = false; });
        _radarController.stop();
        
        // Navigate directly to chat without showing a popup
        Navigator.pushReplacementNamed(context, '/chat', arguments: {
          'roomId': data['roomId'],
          'strangerId': data['uid'],
          'strangRCode': data['strangRCode'] ?? 'Stranger',
        });
      }
    };
  }

  Future<void> _connectSocket() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final idToken = await user.getIdToken();
      await _socketService.initSocket(user.uid, idToken!);
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    if (!_socketService.connected) {
      _connectSocket();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connecting to realtime server...'))
      );
      return;
    }

    setState(() {
      _isSearching = !_isSearching;
    });

    if (_isSearching) {
      _radarController.repeat();
      _socketService.startSearching();
    } else {
      _radarController.stop();
      _socketService.stopSearching();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D020D),
      body: Stack(
        children: [
          // Radial Glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Color(0xFF1A121A),
                    Color(0xFF0D020D),
                  ],
                ),
              ),
            ),
          ),
          
          // Pattern Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'public/images/chat_wallpaper.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(flex: 1),
                _buildCentralLogo(),
                const SizedBox(height: 48),
                _buildHeroText(),
                const SizedBox(height: 40),
                _buildMainActionButton(),
                const Spacer(flex: 2),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              const Icon(Icons.link, color: StrangRTheme.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                'STRANGR',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
          
          // Action Buttons
          Row(
            children: [
              IconButton(icon: const Icon(Icons.people_outline, size: 22), onPressed: () => Navigator.pushNamed(context, '/friends')),
              IconButton(icon: const Icon(Icons.person_outline, size: 22), onPressed: () => Navigator.pushNamed(context, '/settings')),
              IconButton(icon: const Icon(Icons.settings_outlined, size: 22), onPressed: () {}),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium, size: 14, color: StrangRTheme.primary),
                    const SizedBox(width: 4),
                    Text('UPGRADE', style: StrangRTheme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCentralLogo() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric Rings
          for (int i = 1; i <= 3; i++)
            Container(
              width: 100 + (i * 40.0),
              height: 100 + (i * 40.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.05 * (4 - i)),
                  width: 1.0,
                ),
              ),
            ),
          
          // Outer Glow Pulse (if searching)
          if (_isSearching)
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Container(
                  width: 140 + (40 * _radarAnimation.value),
                  height: 140 + (40 * _radarAnimation.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: StrangRTheme.primary.withOpacity(1 - _radarAnimation.value),
                      width: 2.0,
                    ),
                  ),
                );
              },
            ),

          // Central Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: StrangRTheme.primary.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Icon(
              _isSearching ? Icons.motion_photos_on : Icons.search,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          Text(
            'DISCOVER STRANGR',
            style: StrangRTheme.textTheme.labelSmall?.copyWith(
              color: StrangRTheme.primary,
              letterSpacing: 4.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isSearching ? 'FINDING STRANGR' : 'START SEARCHING',
            textAlign: TextAlign.center,
            style: StrangRTheme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 20),
          Text(
            _isSearching 
              ? 'Navigating the unknown for your perfect match. Connection established through soul, not profile.'
              : 'Connect with a true StrangR through pure communication—beyond names, faces, and identities.',
            textAlign: TextAlign.center,
            style: StrangRTheme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton() {
    return GestureDetector(
      onTap: _toggleSearch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.black,
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
          boxShadow: [
            if (_isSearching)
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 20,
              )
            else
              BoxShadow(
                color: StrangRTheme.primary.withOpacity(0.1),
                blurRadius: 20,
              )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isSearching ? 'STOP SEARCHING' : 'START SEARCHING',
              style: StrangRTheme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: _isSearching ? Colors.redAccent : Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              _isSearching ? Icons.close : Icons.auto_awesome,
              color: _isSearching ? Colors.redAccent : StrangRTheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

}
