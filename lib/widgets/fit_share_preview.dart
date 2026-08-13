import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';

class FitSharePreviewSheet extends StatefulWidget {
  final String username;
  final String? imageUrl;
  final double avgScore;
  final int ratingCount;
  final List<String> tags;

  const FitSharePreviewSheet({
    super.key,
    required this.username,
    required this.avgScore,
    required this.ratingCount,
    required this.tags,
    this.imageUrl,
  });

  @override
  State<FitSharePreviewSheet> createState() => _FitSharePreviewSheetState();
}

class _FitSharePreviewSheetState extends State<FitSharePreviewSheet> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareImage(String shareText) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      // Find boundary render object
      final RenderRepaintBoundary? boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('RepaintBoundary context not ready.');
      }

      // Check if image is still loading or if rendering tree needs to lay out
      if (boundary.debugNeedsLayout) {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // Capture widget image at high resolution (3.0 ratio = crisp on retina/high-res screens)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to encode image data.');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Write bytes to a temporary directory file
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/rate_my_fit_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = await File(filePath).create();
      await file.writeAsBytes(pngBytes);

      // Launch share sheet (which natively links to Instagram Stories, DMs, feed, etc.)
      await Share.shareXFiles([XFile(file.path)], text: shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share to Instagram: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          alignmentIndicator(),

          // Title header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share fit status',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Scaling viewport for preview card (constrained size to preview on device screen)
          Center(
            child: Container(
              width: 250,
              height: 444, // 9:16 aspect ratio scaled preview
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: buildShareCardContent(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Options / Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Share to stories button
                _ShareActionButton(
                  icon: Icons.auto_awesome_motion_rounded,
                  label: 'Share to Instagram Stories',
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF833AB4), // Instagram gradient colors
                      Color(0xFFFD1D1D),
                      Color(0xFFF56040),
                      Color(0xFFFCAF45),
                    ],
                  ),
                  isLoading: _isSharing,
                  onTap: () => _shareImage(
                    'Rate my fit! Average score: ${widget.ratingCount > 0 ? widget.avgScore.toStringAsFixed(1) : "—"}/10! ⚡',
                  ),
                ),

                const SizedBox(height: 12),

                // Share to DM/Others button
                _ShareActionButton(
                  icon: Icons.send_rounded,
                  label: 'Send in Messages / DMs',
                  backgroundColor: AppColors.surfaceCard,
                  borderColor: AppColors.border,
                  iconColor: AppColors.primary,
                  isLoading: _isSharing,
                  onTap: () => _shareImage(
                    'Check my fit score! Vibe check status is ${widget.ratingCount > 0 ? widget.avgScore.toStringAsFixed(1) : "—"}/10! 🔥',
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
          SafeArea(child: Container()),
        ],
      ),
    );
  }

  Widget alignmentIndicator() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // Renders the high quality 9:16 layout representing the Instagram Story sticker
  Widget buildShareCardContent() {
    return Container(
      width: 360,
      height: 640,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF09090E), // deep midnight black
            Color(0xFF13131A), // elevated dark transition
            Color(0xFF1A1A2E), // deep space dark blue/purple
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background ambient blurs/glows
          Positioned(
            top: 60,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),

          // Main vertical content layout
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Rate My Fit Logo (Top Left Corner) ──
                Row(
                  children: [
                    const Icon(
                      Icons.checkroom_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'RATE',
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'MYFIT.',
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 3),

                // Center Page: Preview Image Card
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 4 / 5,
                        child: widget.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.imageUrl!,
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(
                                  milliseconds: 100,
                                ),
                                placeholder: (_, __) => Container(
                                  color: AppColors.surfaceCard,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surfaceCard,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: AppColors.textMuted,
                                    size: 40,
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.surfaceCard,
                                child: const Icon(
                                  Icons.photo_size_select_actual_outlined,
                                  color: AppColors.textMuted,
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Stats Overlay Footer Info Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      // User detail
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outfit by ${widget.username}',
                              style: const TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.how_to_vote_outlined,
                                  size: 11,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.ratingCount} reviews',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (widget.tags.isNotEmpty)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: widget.tags.take(3).map((tag) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#$tag',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Vibe metric badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.ratingCount > 0
                                  ? widget.avgScore.toStringAsFixed(1)
                                  : '—',
                              style: const TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'AVG VIBE',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.black.withOpacity(0.6),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Joining detail text
                const Center(
                  child: Text(
                    'JOIN THE VIBE CHECK • DOWNLOAD RATE MY FIT',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMuted,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final bool isLoading;

  const _ShareActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradient != null;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Material(
        color: hasGradient
            ? Colors.transparent
            : (backgroundColor ?? Colors.black),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: hasGradient
                            ? Colors.white
                            : (iconColor ?? AppColors.textPrimary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: hasGradient
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Utility function to call this share dialog from anywhere
void showFitShareSheet(
  BuildContext context, {
  required String username,
  required double avgScore,
  required int ratingCount,
  required List<String> tags,
  String? imageUrl,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) {
      return FitSharePreviewSheet(
        username: username,
        imageUrl: imageUrl,
        avgScore: avgScore,
        ratingCount: ratingCount,
        tags: tags,
      );
    },
  );
}
