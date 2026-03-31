import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String id;
  final String name;
  final String status;
  final String roomId;

  Friend({
    required this.id,
    required this.name,
    required this.status,
    required this.roomId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'roomId': roomId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Bonded Stranger',
      status: map['status'] ?? 'offline',
      roomId: map['roomId'] ?? '',
    );
  }
}

class FriendsManager {
  static final FriendsManager _instance = FriendsManager._internal();
  factory FriendsManager() => _instance;
  FriendsManager._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Friend>> getFriendsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Friend.fromMap(doc.data())).toList();
    });
  }

  Future<void> addFriend(String myUserId, Friend friend) async {
    try {
      await _db
          .collection('users')
          .doc(myUserId)
          .collection('friends')
          .doc(friend.id)
          .set(friend.toMap());
    } catch (e) {
      print('Error adding friend to Firestore: $e');
    }
  }

  Future<void> updateStatus(String myUserId, String friendId, String status) async {
     try {
       await _db
          .collection('users')
          .doc(myUserId)
          .collection('friends')
          .doc(friendId)
          .update({'status': status});
     } catch (e) {
       print('Error updating status in Firestore: $e');
     }
  }
}
