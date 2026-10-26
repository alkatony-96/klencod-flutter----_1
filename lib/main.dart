import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'attendance_screen.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const TeacherAttendanceApp());
}

class TeacherAttendanceApp extends StatefulWidget {
  const TeacherAttendanceApp({super.key});

  @override
  State<TeacherAttendanceApp> createState() => _TeacherAttendanceAppState();
}

class _TeacherAttendanceAppState extends State<TeacherAttendanceApp> {
  bool isDarkMode = true;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: WelcomeScreen(
        isDarkMode: isDarkMode,
        onToggleTheme: toggleTheme,
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const WelcomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutBack,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> lightGradient = [
      const Color(0xFF0F2027),
      const Color(0xFF203A43),
      const Color(0xFF2C5364),
    ];

    final List<Color> darkGradient = [
      const Color(0xFF050B14),
      const Color(0xFF0A1128),
      const Color(0xFF101F42),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // 1. الخلفية المتدرجة
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isDarkMode ? darkGradient : lightGradient,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),

          // 2. الدوائر خلفية
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -40,
                    left: -40,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E676).withOpacity(0.12),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    right: -50,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF29B6F6).withOpacity(0.15),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. زر المظهر أعلى اليمين
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, right: 20.0),
                child: _buildGlassWidget(
                  borderRadius: 16,
                  child: IconButton(
                    onPressed: widget.onToggleTheme,
                    icon: Icon(
                      widget.isDarkMode
                          ? Icons.wb_sunny_rounded
                          : Icons.nightlight_round,
                      color: widget.isDarkMode ? Colors.amber : Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. محتوى الشاشة
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGlassWidget(
                        borderRadius: 30,
                        padding: const EdgeInsets.symmetric(
                            vertical: 36, horizontal: 24),
                        child: Column(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.30),
                                    Colors.white.withOpacity(0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF29B6F6)
                                        .withOpacity(0.25),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(
                                    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                      Icons.account_balance_rounded,
                                      size: 55,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "إعدادية البعاج للبنين",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "نظام الحضور والانصراف الذكي للكادر التعليمي",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 45),

                      // 5. زر السحب (بدون شريط SnackBar سفلي وبنهاية متناسقة تماماً)
                      GlassSwipeButton(
                        onSwipeComplete: () {
                          // تم حذف الـ SnackBar السفلي تماماً كما طلبت
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildGlassWidget({
    required Widget child,
    double borderRadius = 20,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// تصميم زر السحب مع ضبط انحناء نهاية الشريط 100%
class GlassSwipeButton extends StatefulWidget {
  final VoidCallback onSwipeComplete;

  const GlassSwipeButton({super.key, required this.onSwipeComplete});

  @override
  State<GlassSwipeButton> createState() => _GlassSwipeButtonState();
}

class _GlassSwipeButtonState extends State<GlassSwipeButton> {
  double _dragPosition = 0.0;
  bool _isDragging = false;
  final double _buttonSize = 52.0;
  final double _padding = 6.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        final double innerWidth = trackWidth - (_padding * 2);
        final double maxDrag = innerWidth - _buttonSize;
        final double progress =
            maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 64,
              width: double.infinity,
              padding: EdgeInsets.all(_padding),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  children: [
                    // 1. الشريط الأخضر المحوي داخلياً بالكامل بانحناء 26 للزوايا
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: _dragPosition + _buttonSize,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00C853)
                                  .withOpacity(0.85 * progress + 0.12),
                              const Color(0xFF00E676)
                                  .withOpacity(0.95 * progress + 0.18),
                            ],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),

                    // 2. النص التوضيحي
                    Center(
                      child: Opacity(
                        opacity: (1.0 - progress * 1.8).clamp(0.0, 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "اسحب لتسجيل الدخول",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_double_arrow_left_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. زر الإبهام المتحرك
                    Positioned(
                      right: _dragPosition,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onHorizontalDragStart: (_) =>
                            setState(() => _isDragging = true),
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dragPosition -= details.delta.dx;
                            if (_dragPosition < 0) _dragPosition = 0;
                            if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                          });
                        },
                        onHorizontalDragEnd: (details) {
  setState(() => _isDragging = false);
  if (_dragPosition >= maxDrag * 0.75) {
    setState(() => _dragPosition = maxDrag);
    widget.onSwipeComplete();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherAttendanceScreen(),
      ),
    );
  } else {
    setState(() => _dragPosition = 0);
  }
},
                        {},
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: _buttonSize,
                          height: _buttonSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color.lerp(
                                  Colors.black.withOpacity(0.25),
                                  const Color(0xFF00E676).withOpacity(0.8),
                                  progress,
                                )!,
                                blurRadius: _isDragging ? 16 : 10,
                                spreadRadius: _isDragging ? 2 : 1,
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: progress > 0.85
                                ? const Icon(
                                    Icons.check_rounded,
                                    key: ValueKey('check_icon'),
                                    color: Color(0xFF1B5E20),
                                    size: 28,
                                  )
                                : const Icon(
                                    Icons.arrow_back_rounded,
                                    key: ValueKey('arrow_icon'),
                                    color: Color(0xFF0F2027),
                                    size: 26,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}