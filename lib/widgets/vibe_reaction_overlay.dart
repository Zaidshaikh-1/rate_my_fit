import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vibe_card_button.dart';
import '../theme/app_theme.dart';

/// Visual config for each vibe's reaction animation
class _VibeReactionConfig {
  final IconData icon;
  final String label;
  final Color glowColor;
  final Color accentColor;

  const _VibeReactionConfig({
    required this.icon,
    required this.label,
    required this.glowColor,
    required this.accentColor,
  });
}

final _reactionConfigs = {
  Vibe.drip: _VibeReactionConfig(
    icon: Icons.local_fire_department_rounded,
    label: 'DRIP',
    glowColor: AppColors.drip,
    accentColor: const Color(0xFFFF8A50),
  ),
  Vibe.clean: _VibeReactionConfig(
    icon: Icons.auto_awesome_rounded,
    label: 'CLEAN',
    glowColor: AppColors.clean,
    accentColor: const Color(0xFF80FFD4),
  ),
  Vibe.mid: _VibeReactionConfig(
    icon: Icons.sentiment_neutral_rounded,
    label: 'MID',
    glowColor: AppColors.mid,
    accentColor: const Color(0xFFFFCC44),
  ),
  Vibe.notIt: _VibeReactionConfig(
    icon: Icons.heart_broken_rounded,
    label: 'NOT IT',
    glowColor: AppColors.notIt,
    accentColor: const Color(0xFF9E9E9E),
  ),
};

// ──────────────────────────────────────────────────────────────────────
//  PARTICLE — a geometric shape that bursts outward
// ──────────────────────────────────────────────────────────────────────

enum _ParticleShape { circle, diamond, ring, dot }

class _Particle {
  final _ParticleShape shape;
  final double angle;
  final double distance;
  final double delay; // 0.0 – 0.25 stagger
  final double size;
  final double opacity;

  _Particle({
    required this.shape,
    required this.angle,
    required this.distance,
    required this.delay,
    required this.size,
    required this.opacity,
  });
}

// ──────────────────────────────────────────────────────────────────────
//  VIBE REACTION OVERLAY
// ──────────────────────────────────────────────────────────────────────

class VibeReactionOverlay extends StatefulWidget {
  const VibeReactionOverlay({super.key});

  @override
  VibeReactionOverlayState createState() => VibeReactionOverlayState();
}

class VibeReactionOverlayState extends State<VibeReactionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _labelCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _ringCtrl;

  late Animation<double> _mainScale;
  late Animation<double> _mainOpacity;
  late Animation<double> _particleProgress;
  late Animation<double> _labelSlide;
  late Animation<double> _labelOpacity;
  late Animation<double> _glowOpacity;
  late Animation<double> _ringExpand;
  late Animation<double> _ringOpacity;

  Vibe? _activeVibe;
  List<_Particle> _particles = [];
  final _random = Random();
  final _shapes = _ParticleShape.values;

  @override
  void initState() {
    super.initState();

    // Main icon — scale up, bounce, fade out
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _mainScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.4,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_mainCtrl);

    _mainOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_mainCtrl);

    // Particles — burst outward
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _particleProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _particleCtrl, curve: Curves.easeOut));

    // Label — slide up and fade
    _labelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _labelSlide = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 20.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 30),
    ]).animate(_labelCtrl);
    _labelOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_labelCtrl);

    // Glow radial background
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut));

    // Expanding ring
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ringExpand = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _ringOpacity = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _particleCtrl.dispose();
    _labelCtrl.dispose();
    _glowCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  List<_Particle> _generateParticles() {
    final particles = <_Particle>[];
    final count = 10 + _random.nextInt(5); // 10-14 particles

    for (int i = 0; i < count; i++) {
      particles.add(
        _Particle(
          shape: _shapes[_random.nextInt(_shapes.length)],
          angle: (2 * pi * i / count) + (_random.nextDouble() * 0.4 - 0.2),
          distance: 70 + _random.nextDouble() * 70,
          delay: _random.nextDouble() * 0.2,
          size: 3 + _random.nextDouble() * 6,
          opacity: 0.6 + _random.nextDouble() * 0.4,
        ),
      );
    }
    return particles;
  }

  /// Play the reaction animation for the given vibe
  void playReaction(Vibe vibe) {
    final config = _reactionConfigs[vibe];
    if (config == null) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _activeVibe = vibe;
      _particles = _generateParticles();
    });

    _mainCtrl.reset();
    _particleCtrl.reset();
    _labelCtrl.reset();
    _glowCtrl.reset();
    _ringCtrl.reset();

    _glowCtrl.forward();
    _mainCtrl.forward();
    _ringCtrl.forward();

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _particleCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _labelCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 280), () {
      HapticFeedback.lightImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeVibe == null) return const SizedBox.shrink();

    final config = _reactionConfigs[_activeVibe]!;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainCtrl,
        _particleCtrl,
        _labelCtrl,
        _glowCtrl,
        _ringCtrl,
      ]),
      builder: (context, child) {
        final isPlaying =
            _mainCtrl.isAnimating ||
            _particleCtrl.isAnimating ||
            _labelCtrl.isAnimating ||
            _glowCtrl.isAnimating ||
            _ringCtrl.isAnimating;
        final isVisible =
            _mainCtrl.value > 0 ||
            _particleCtrl.value > 0 ||
            _labelCtrl.value > 0 ||
            _glowCtrl.value > 0 ||
            _ringCtrl.value > 0;

        if (!isPlaying && !isVisible) return const SizedBox.shrink();

        return IgnorePointer(
          child: SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Radial glow ──
                if (_glowOpacity.value > 0)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GlowPainter(
                        color: config.glowColor,
                        opacity: _glowOpacity.value,
                      ),
                    ),
                  ),

                // ── Expanding ring ──
                if (_ringOpacity.value > 0)
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _RingPainter(
                      color: config.glowColor,
                      progress: _ringExpand.value,
                      opacity: _ringOpacity.value,
                    ),
                  ),

                // ── Particle burst ──
                CustomPaint(
                  size: const Size(300, 300),
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleProgress.value,
                    color: config.glowColor,
                    accentColor: config.accentColor,
                  ),
                ),

                // ── Main icon ──
                Opacity(
                  opacity: _mainOpacity.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _mainScale.value,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: config.glowColor.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: config.glowColor.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        config.icon,
                        size: 38,
                        color: config.glowColor,
                      ),
                    ),
                  ),
                ),

                // ── Label ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Align(
                    alignment: const Alignment(0, 0.35),
                    child: Transform.translate(
                      offset: Offset(0, _labelSlide.value),
                      child: Opacity(
                        opacity: _labelOpacity.value.clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: config.glowColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: config.glowColor.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: config.glowColor.withValues(alpha: 0.25),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            config.label,
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: config.glowColor,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  CUSTOM PAINTERS
// ──────────────────────────────────────────────────────────────────────

/// Paints a soft radial glow in the center
class _GlowPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _GlowPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.opacity != opacity || old.color != color;
}

/// Paints an expanding ring that fades out
class _RingPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double opacity;

  _RingPainter({
    required this.color,
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final radius = maxRadius * progress;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * (1.0 - progress); // thins out as it expands

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.opacity != opacity;
}

/// Paints geometric particles bursting outward
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;
  final Color accentColor;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final t = (progress - p.delay).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final x = center.dx + cos(p.angle) * p.distance * t;
      final y = center.dy + sin(p.angle) * p.distance * t;
      final fadeOut = (1.0 - t).clamp(0.0, 1.0) * p.opacity;
      final particleColor = i.isEven ? color : accentColor;

      final paint = Paint()
        ..color = particleColor.withValues(alpha: fadeOut)
        ..style = PaintingStyle.fill;

      switch (p.shape) {
        case _ParticleShape.circle:
          canvas.drawCircle(Offset(x, y), p.size, paint);
          break;

        case _ParticleShape.diamond:
          final path = Path()
            ..moveTo(x, y - p.size)
            ..lineTo(x + p.size * 0.7, y)
            ..lineTo(x, y + p.size)
            ..lineTo(x - p.size * 0.7, y)
            ..close();
          canvas.drawPath(path, paint);
          break;

        case _ParticleShape.ring:
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawCircle(Offset(x, y), p.size, paint);
          break;

        case _ParticleShape.dot:
          canvas.drawCircle(Offset(x, y), p.size * 0.5, paint);
          // add a tiny glow around the dot
          final glowPaint = Paint()
            ..color = particleColor.withValues(alpha: fadeOut * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(Offset(x, y), p.size, glowPaint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
