import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum Vibe { drip, clean, mid, notIt }

class VibeCard {
  final Vibe vibe;
  final String emoji;
  final String label;
  final Color color;
  final int score; // weighted score out of 100

  const VibeCard({
    required this.vibe,
    required this.emoji,
    required this.label,
    required this.color,
    required this.score,
  });
}

const vibeCards = [
  VibeCard(
    vibe: Vibe.drip,
    emoji: '',
    label: 'Drip',
    color: AppColors.drip,
    score: 100,
  ),
  VibeCard(
    vibe: Vibe.clean,
    emoji: '',
    label: 'Clean',
    color: AppColors.clean,
    score: 75,
  ),
  VibeCard(
    vibe: Vibe.mid,
    emoji: '',
    label: 'Mid',
    color: AppColors.mid,
    score: 40,
  ),
  VibeCard(
    vibe: Vibe.notIt,
    emoji: '',
    label: 'Not it',
    color: AppColors.notIt,
    score: 10,
  ),
];

class VibeCardButton extends StatefulWidget {
  final VibeCard card;
  final bool selected;
  final VoidCallback onTap;

  const VibeCardButton({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  State<VibeCardButton> createState() => _VibeCardButtonState();
}

class _VibeCardButtonState extends State<VibeCardButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.85,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward(from: 0).then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final card = widget.card;

    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? card.color.withOpacity(0.15)
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? card.color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: card.color.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(card.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                card.label,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? card.color : AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
