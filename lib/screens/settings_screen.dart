import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:strangr_app/core/theme.dart';
import 'package:strangr_app/core/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final TextEditingController nameController = TextEditingController(text: user?.displayName ?? 'New Stranger');
    final TextEditingController bioController = TextEditingController();
    
    return Scaffold(
      backgroundColor: StrangRTheme.background,
      appBar: AppBar(
        title: Text('Profile Settings', style: StrangRTheme.textTheme.titleLarge),
        backgroundColor: StrangRTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: StrangRTheme.onSurface),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            nameController.text = data['alias'] ?? user?.displayName ?? 'New Stranger';
            bioController.text = data['bio'] ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: StrangRTheme.surfaceHighlight,
                        child: Icon(Icons.person, size: 50, color: Colors.grey.shade400),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: StrangRTheme.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, size: 20, color: Colors.black),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text('ALIAS (DISPLAY NAME)', style: StrangRTheme.textTheme.labelSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: StrangRTheme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: StrangRTheme.surfaceHighlight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                Text('YOUR BIO', style: StrangRTheme.textTheme.labelSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  style: StrangRTheme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: StrangRTheme.surfaceHighlight,
                    hintText: 'Tell the world who you are...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StrangRTheme.primaryContainer,
                      foregroundColor: StrangRTheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (user != null) {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'alias': nameController.text,
                          'bio': bioController.text,
                          'lastUpdated': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated successfully!')),
                        );
                      }
                    },
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.grey),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text('Log Out', style: StrangRTheme.textTheme.bodyLarge?.copyWith(color: Colors.redAccent)),
                  onTap: () async {
                    await AuthService().signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                ),
              ],
            ),
          );
        }
      )
    );
  }
}
