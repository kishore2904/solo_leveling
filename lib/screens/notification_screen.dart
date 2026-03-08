import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import 'dart:math' as math;
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

// Floating particle model
class FloatingParticle {
  late double x;
  late double y;
  late double size;
  late double speedX;
  late double speedY;
  late Color color;

  FloatingParticle() {
    x = math.Random().nextDouble() * 400;
    y = math.Random().nextDouble() * 800;
    size = math.Random().nextDouble() * 3 + 1;
    speedX = (math.Random().nextDouble() - 0.5) * 2;
    speedY = (math.Random().nextDouble() - 0.5) * 2;
    
    final colors = [AppColors.neonBlue, AppColors.neonCyan, AppColors.neonLightBlue];
    color = colors[math.Random().nextInt(colors.length)];
  }

  void update(Size screenSize) {
    x += speedX;
    y += speedY;

    // Wrap around screen
    if (x < 0) x = screenSize.width;
    if (x > screenSize.width) x = 0;
    if (y < 0) y = screenSize.height;
    if (y > screenSize.height) y = 0;
  }
}

// Typewriter text widget
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const TypewriterText({
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 50),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  late String displayText;

  @override
  void initState() {
    super.initState();
    displayText = '';
    _typeText();
  }

  void _typeText() async {
    for (int i = 0; i <= widget.text.length; i++) {
      await Future.delayed(widget.duration);
      if (mounted) {
        setState(() {
          displayText = widget.text.substring(0, i);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      displayText,
      style: widget.style,
    );
  }
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shakeAnimation;
  
  late List<FloatingParticle> particles;

  @override
  void initState() {
    super.initState();

    // Initialize particles
    particles = List.generate(20, (index) => FloatingParticle());

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Glow animation (continuous)
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Particle animation (continuous)
    _particleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    // Shake animation (for button press)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticInOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = (math.sin(_shakeAnimation.value * math.pi * 4) * 5);
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
        children: [
          // Floating particles background
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Update particles position
                  for (var particle in particles) {
                    particle.update(constraints.biggest);
                  }

                  return CustomPaint(
                    painter: FloatingParticlesPainter(particles),
                    size: constraints.biggest,
                  );
                },
              );
            },
          ),
          // Main content
          Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Glow Background
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonBlue.withOpacity(_glowAnimation.value),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: AppColors.neonCyan.withOpacity(_glowAnimation.value * 0.6),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        border: Border.all(
                          color: AppColors.neonBlue,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Notification Header with Animation
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, -0.3),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _fadeController,
                                curve: const Interval(0.2, 0.8),
                              )),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Info Icon with Pulse
                                  ScaleTransition(
                                    scale: Tween<double>(begin: 0, end: 1).animate(
                                      CurvedAnimation(
                                        parent: _scaleController,
                                        curve: const Interval(0.4, 1),
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.red,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: const Icon(
                                        Icons.info,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Notification Text
                                  Text(
                                    AppStrings.notification,
                                    style: const TextStyle(
                                      color: AppColors.neonBlue,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Main Text with Typewriter Effect
                            FadeTransition(
                              opacity: Tween<double>(begin: 0, end: 1).animate(
                                CurvedAnimation(
                                  parent: _fadeController,
                                  curve: const Interval(0.3, 1),
                                ),
                              ),
                              child: TypewriterText(
                                text: '${AppStrings.playerQualifications}\nto be a ${AppStrings.playerTitle}. ${AppStrings.playerQuestion}',
                                style: const TextStyle(
                                  color: AppColors.neonBlue,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                duration: const Duration(milliseconds: 30),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Action Buttons with Animation
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _fadeController,
                                curve: const Interval(0.4, 1),
                              )),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Accept Button
                                  _buildAnimatedButton(
                                    label: AppStrings.accept,
                                    onTap: () {
                                      _triggerShake();
                                      HapticFeedback.mediumImpact();
                                      Future.delayed(const Duration(milliseconds: 200), () {
                                        _showAcceptDialog(context);
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 20),
                                  // Decline Button
                                  _buildAnimatedButton(
                                    label: AppStrings.decline,
                                    isDanger: true,
                                    onTap: () {
                                      _triggerShake();
                                      HapticFeedback.lightImpact();
                                      Future.delayed(const Duration(milliseconds: 200), () {
                                        _showDeclineDialog(context);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ])
    ));
  }

  void _triggerShake() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
  }

  Widget _buildAnimatedButton({
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return MouseRegion(
      onEnter: (_) => setState(() {}),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.black,
            border: Border.all(
              color: isDanger ? Colors.red : AppColors.neonBlue,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: (isDanger ? Colors.red : AppColors.neonBlue).withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: (isDanger ? Colors.red : AppColors.neonBlue).withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDanger ? Colors.red : AppColors.neonBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAcceptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.neonBlue, width: 2),
        ),
        title: const Text(
          'Success',
          style: TextStyle(
            color: AppColors.neonBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'You have accepted to become a Player!',
          style: TextStyle(color: AppColors.neonBlue),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.neonBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeclineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: const Text(
          'Declined',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'You have declined the Player qualification.',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for floating particles
class FloatingParticlesPainter extends CustomPainter {
  final List<FloatingParticle> particles;

  FloatingParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      // Draw glowing dot
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );

      // Draw outer glow
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * 3,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(FloatingParticlesPainter oldDelegate) => true;
}
