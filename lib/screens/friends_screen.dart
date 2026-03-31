import 'package:flutter/material.dart';
import 'package:strangr_app/core/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:strangr_app/core/friends_manager.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final friendsManager = FriendsManager();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: StrangRTheme.background,
      appBar: AppBar(
        backgroundColor: StrangRTheme.background,
        elevation: 0,
        title: Text('Connections', style: StrangRTheme.textTheme.titleLarge),
        iconTheme: const IconThemeData(color: StrangRTheme.onSurface),
      ),
      body: currentUserId == null 
        ? const Center(child: Text('Please log in to view connections.'))
        : StreamBuilder<List<Friend>>(
        stream: friendsManager.getFriendsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: StrangRTheme.primary));
          }
          
          if (snapshot.hasError) {
             return Center(child: Text('Error loading connections: ${snapshot.error}'));
          }

          final friends = snapshot.data ?? [];
          
          if (friends.isEmpty) {
            return Center(
               child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.people_outline, size: 64, color: Colors.grey.shade800),
                     const SizedBox(height: 16),
                     Text('No connections yet.', style: StrangRTheme.textTheme.bodyLarge),
                     Text('Find strangers in the Search Hub.', style: StrangRTheme.textTheme.labelSmall),
                  ],
               ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: friends.length,
            separatorBuilder: (_, __) => Divider(color: Colors.grey.shade900),
            itemBuilder: (context, index) {
              final friend = friends[index];
              final isOnline = friend.status == 'online';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: StrangRTheme.surfaceHighlight,
                      child: const Icon(Icons.person_outline, color: Colors.grey),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: StrangRTheme.tertiary,
                            shape: BoxShape.circle,
                            border: Border.all(color: StrangRTheme.background, width: 2),
                          ),
                        ),
                      )
                  ],
                ),
                title: Text(friend.name, style: StrangRTheme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text(isOnline ? 'Online now' : 'Last seen recently', style: StrangRTheme.textTheme.labelSmall),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  color: StrangRTheme.primaryContainer,
                  onPressed: () {
                    Navigator.pushNamed(
                      context, 
                      '/chat', 
                      arguments: {
                        'roomId': friend.roomId, 
                        'strangerId': friend.id,
                        'strangRCode': friend.name,
                      }
                    );
                  },
                ),
              );
            },
          );
        }
      ),
    );
  }
}
