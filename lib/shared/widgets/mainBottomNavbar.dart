import 'dart:ui' show lerpDouble, MaskFilter, BlurStyle, ImageFilter;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'package:flearn_app/core/constants/colors.dart';

// =======================================================================
// 1. WIDGET CHÍNH BAO BỌC SCAFFOLD VÀ THANH ĐIỀU HƯỚNG
// =======================================================================
class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white, // Nền trắng
      body: Obx(() => IndexedStack(
        index: controller.selectedIndex.value,
        children: controller.screens,
      )),
      bottomNavigationBar: Obx(
            () => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: CustomBottomNavBar(
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) =>
            controller.selectedIndex.value = index,
          ),
        ),
      ),
    );
  }
}

// =======================================================================
// 2. WIDGET THANH ĐIỀU HƯỚNG TÙY CHỈNH (STATEFUL)
// =======================================================================
class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  int _fromIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.selectedIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _fromIndex = oldWidget.selectedIndex;
      _animationController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _centerXForIndex(int idx, double totalWidth) {
    final double slotWidth = totalWidth / 5;
    return (idx + 0.5) * slotWidth;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Tăng blur
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double fromX = _centerXForIndex(_fromIndex, totalWidth);
              final double toX =
              _centerXForIndex(widget.selectedIndex, totalWidth);

              const double baseBubbleW = 70.0;
              const double baseBubbleH = 60.0;
              const double topPadding = 2.5;

              return Stack(
                children: [
                  SizedBox.expand(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, _) {
                        final double t = _animationController.value;
                        final double progress =
                        Curves.easeInOutCubicEmphasized.transform(t);
                        final double currentX =
                        (t == 0.0) ? toX : lerpDouble(fromX, toX, progress)!;

                        return CustomPaint(
                          painter: _GlassBubblePainter(
                            currentX: currentX,
                            progress: t,
                            baseWidth: baseBubbleW,
                            baseHeight: baseBubbleH,
                            topPadding: topPadding,
                            borderColors: [
                              Colors.blue.shade400.withOpacity(0.02),     // ← ĐỔI ĐÂY: Màu viền trên
                              Colors.blue.shade300.withOpacity(0.02),     // ← ĐỔI ĐÂY: Màu viền giữa
                              Colors.blue.shade500.withOpacity(0.02),
                            ],

                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: _buildNavItem(Icons.home, Icons.home_outlined,
                              0, "Trang chủ")),
                      Expanded(
                          child: _buildNavItem(
                              Icons.speaker_notes, Icons.speaker_notes_outlined, 1, "Nhập vai")),
                      Expanded(
                          child: _buildNavItem(Icons.book,
                              Icons.book_outlined, 2, "Khoá học")),
                      Expanded(
                          child: _buildNavItem(Icons.school,
                              Icons.school_outlined, 3, "Lớp học")),
                      Expanded(
                          child: _buildNavItem(Icons.person,
                              Icons.person_outline, 4, "Tài khoản")),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData selectedIcon, IconData unselectedIcon, int index, String label) {
    final isSelected = widget.selectedIndex == index;
    final color = isSelected ? Colors.blue.shade600 : Colors.grey.shade600; // Màu phù hợp với nền trắng

    return GestureDetector(
      onTap: () => widget.onDestinationSelected(index),
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? selectedIcon : unselectedIcon,
              color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// 3. PAINTER ĐỂ VẼ BONG BÓNG HIỆU ỨNG THỦY TINH
// =======================================================================
class _GlassBubblePainter extends CustomPainter {
  final double currentX;
  final double progress;
  final double baseWidth;
  final double baseHeight;
  final double topPadding;
  final List<Color> borderColors;

  _GlassBubblePainter({
    required this.currentX,
    required this.progress,
    required this.baseWidth,
    required this.baseHeight,
    required this.topPadding,
    this.borderColors = const [Colors.white, Colors.white24],
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBubble(canvas, size, 1.0);
  }

  void _drawBubble(Canvas canvas, Size size, double opacity) {
    final double centerY = topPadding + baseHeight / 2;
    final double gooeyProgress = (progress * (1 - progress)) * 4;
    final double stretch = lerpDouble(0, 15, gooeyProgress)!.clamp(0, 15);
    final double bubbleW = baseWidth + stretch;
    final double bubbleH = baseHeight - lerpDouble(0, 5, gooeyProgress)!;
    final RRect bubbleRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(currentX, centerY), width: bubbleW, height: bubbleH),
      Radius.circular(30 - (stretch * 0.5)),
    );

    // Bong bóng xanh dương nổi bật trên nền trắng
    final Paint glassPaint = Paint()
      ..color = Colors.blue.shade500.withOpacity(0.35 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawRRect(bubbleRRect, glassPaint);

    final Paint borderPaint = Paint()
      ..shader = LinearGradient(
        colors:
        borderColors.map((c) => c.withOpacity(c.opacity * opacity)).toList(),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bubbleRRect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(bubbleRRect, borderPaint);

    final Path path = Path()..addRRect(bubbleRRect);
    canvas.drawShadow(
        path,   Colors.black.withOpacity(0.3 * opacity), 6.0, true);
  }

  @override
  bool shouldRepaint(covariant _GlassBubblePainter oldDelegate) {
    return currentX != oldDelegate.currentX || progress != oldDelegate.progress;
  }
}