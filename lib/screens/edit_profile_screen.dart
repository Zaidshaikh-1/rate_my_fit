import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() {
        _usernameController.text =
            doc.data()?['username']?.replaceAll('@', '') ?? '';
        _currentAvatarUrl = doc.data()?['avatarUrl'];
      });
    } else {
      // fallback to google data
      setState(() {
        _usernameController.text =
            FirebaseAuth.instance.currentUser?.displayName
                ?.replaceAll(' ', '')
                .toLowerCase() ??
            '';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final baseUsername = _usernameController.text.trim();
    if (baseUsername.isEmpty) return;

    final newUsername = '@$baseUsername';
    setState(() => _isLoading = true);

    try {
      String? avatarUrl = _currentAvatarUrl;

      // 1. Upload new image if chosen
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance.ref().child('avatars/$uid.jpg');
        await ref.putFile(
          _selectedImage!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        avatarUrl = await ref.getDownloadURL();
      }

      // 2. Check username uniqueness
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: newUsername)
          .get();

      bool isUnique = true;
      for (var d in query.docs) {
        if (d.id != uid) isUnique = false;
      }

      if (!isUnique) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username is already taken!')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 3. Update user document
      await userDocRef.set({
        'username': newUsername,
        'avatarUrl': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4. Batch update all of their existing posts so the feed updates instantly
      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in postsQuery.docs) {
        batch.update(doc.reference, {
          'username': newUsername,
          'avatarUrl': avatarUrl,
        });
      }
      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.surfaceCard,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_currentAvatarUrl != null
                                  ? NetworkImage(_currentAvatarUrl!)
                                  : null)
                              as ImageProvider?,
                    child: _selectedImage == null && _currentAvatarUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.textMuted,
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                prefixStyle: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Profile',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
