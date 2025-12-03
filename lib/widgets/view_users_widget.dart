import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:home_automation_tablet/widgets/user_card_row.dart';

class ViewUsersWidget extends StatefulWidget {
  const ViewUsersWidget({super.key});

  @override
  State<ViewUsersWidget> createState() => _ViewUsersWidgetState();
}

class _ViewUsersWidgetState extends State<ViewUsersWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> _getUsersStream() {
    try {
      return _firestore
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: 'no_of_users')
          .snapshots()
          .handleError((error) {
            print('Firestore stream error: $error');
            return Stream.empty();
          });
    } catch (e) {
      print('Error creating stream: $e');
      return Stream.empty();
    }
  }

  Uint8List? _decodeBase64Image(dynamic encodedImage) {
    if (encodedImage == null) return null;

    try {
      if (encodedImage is String) {
        if (encodedImage.isEmpty) {
          return null;
        }

        String base64String = encodedImage;
        if (encodedImage.contains(',')) {
          base64String = encodedImage.split(',').last;
        }

        return base64Decode(base64String);
      }

      if (encodedImage is Uint8List) {
        return encodedImage;
      }

      if (encodedImage is List) {
        return Uint8List.fromList(encodedImage.cast<int>());
      }

      if (encodedImage is Map) {
        if (encodedImage.containsKey('bytes')) {
          final bytes = encodedImage['bytes'];
          if (bytes is String) {
            return base64Decode(bytes);
          }
          if (bytes is List) {
            return Uint8List.fromList(bytes.cast<int>());
          }
        }

        if (encodedImage.containsKey('data')) {
          return _decodeBase64Image(encodedImage['data']);
        }
      }

      return null;
    } catch (e, stackTrace) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading users...'),
              ],
            ),
          );
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No users found', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              String name = data['name '] as String? ?? 'Unknown';
              final imageData = _decodeBase64Image(data['image']);
              return UserCardRow(name: name, imageData: imageData);
            },
          ),
        );
      },
    );
  }
}
