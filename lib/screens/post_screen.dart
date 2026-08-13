import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  File? _selectedImage;
  bool _isUploading = false;
  final TextEditingController _tagsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // ── Outfit items (product name + link) ──
  final List<Map<String, String>> _outfitItems = [];
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemLinkController = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _addOutfitItem() {
    final name = _itemNameController.text.trim();
    final link = _itemLinkController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _outfitItems.add({'name': name, 'url': link});
      _itemNameController.clear();
      _itemLinkController.clear();
    });
  }

  void _removeOutfitItem(int index) {
    setState(() => _outfitItems.removeAt(index));
  }

  Future<void> _submitPost() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'dev-user-001';
      final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('fits/$fileName');

      await storageRef.putFile(_selectedImage!);
      final imageUrl = await storageRef.getDownloadURL();

      final user = FirebaseAuth.instance.currentUser;
      String uniqueUsername = '@devuser';
      if (user != null) {
        if (user.email != null && user.email!.isNotEmpty) {
          uniqueUsername =
              '@${user.email!.split('@')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';
        } else {
          uniqueUsername =
              '@${user.displayName?.replaceAll(' ', '').toLowerCase() ?? 'user'}${user.uid.substring(0, 4)}';
        }
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': uid,
        'username': uniqueUsername,
        'imageUrl': imageUrl,
        'tags': _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'outfitItems': _outfitItems,
        'totalScore': 0,
        'avgScore': 0.0,
        'ratingCount': 0,
        'saveCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _tagsController.dispose();
    _itemNameController.dispose();
    _itemLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post a Fit',
          style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ──── Step 1: Upload ────
                const _StepHeader(stepNum: '01', title: 'Upload your Fit'),

                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 380,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111116),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _selectedImage != null
                            ? Colors.transparent
                            : AppColors.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (_selectedImage == null)
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.04),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.border.withOpacity(0.5),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.photo_library_outlined,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Change Photo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 30,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tap to choose fit image',
                                style: TextStyle(
                                  fontFamily: 'Syne',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'PNG, JPG or WEBP high-res',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // ──── Step 2: Tags ────
                const _StepHeader(stepNum: '02', title: 'Vibe Tags'),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _tagsController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tags (comma separated)',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      hintText: 'y2k, streetwear, minimal, grunge',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.tag_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceCard,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ──── Step 3: Breakdown ────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: _StepHeader(
                        stepNum: '03',
                        title: 'Outfit Breakdown',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: const Text(
                          'OPTIONAL',
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Detail the pieces in your fit so others can search for it.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Outfit Items List ──
                if (_outfitItems.isNotEmpty) ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: _outfitItems.length,
                    itemBuilder: (context, index) {
                      final item = _outfitItems[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if ((item['url'] ?? '').isNotEmpty)
                                    Text(
                                      item['url']!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              color: Colors.redAccent.withOpacity(0.8),
                              onPressed: () => _removeOutfitItem(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                // ── Breakdown creation panel ──
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.7),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _itemNameController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Product name (e.g. Nike Dunks)',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF13131A),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _itemLinkController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          hintText: 'Product link (optional)',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF13131A),
                          prefixIcon: const Icon(
                            Icons.link_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addOutfitItem,
                          icon: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Colors.black,
                          ),
                          label: const Text('Add Piece'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontFamily: 'Syne',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Drop the Fit Floating Bottom Button ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.9),
                    Colors.black,
                  ],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27),
                    boxShadow: [
                      if (_selectedImage != null)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _selectedImage == null ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedImage == null
                          ? AppColors.surfaceCard
                          : AppColors.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppColors.surfaceCard
                          .withOpacity(0.6),
                      disabledForegroundColor: AppColors.textMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Drop the Fit',
                                style: TextStyle(
                                  fontFamily: 'Syne',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: _selectedImage == null
                                      ? AppColors.textMuted
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.flash_on_rounded,
                                size: 16,
                                color: _selectedImage == null
                                    ? AppColors.textMuted
                                    : Colors.black,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          // ── Glass Loading Overlay when Uploading ──
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.7),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3.5,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Dropping your fit...',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String stepNum;
  final String title;

  const _StepHeader({required this.stepNum, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              stepNum,
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
