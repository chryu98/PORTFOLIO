// lib/ui/toss_nav_bar.dart
import 'package:flutter/material.dart';

const kNavTrack = Color(0xFFF4F6FA);
const kNavBorder = Color(0xFFE6E8EE);

class TossNavItem {
  final IconData icon;
  final String label;
  const TossNavItem(this.icon, this.label);
}

class TossNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<TossNavItem> items;
  final Color activeColor;
  final Color inactiveColor;

  /// 부드러움 조절용
  final Duration duration;
  final Curve curve;

  const TossNavBar({
    super.key,
    required this.index,
    required this.onTap,
    required this.items,
    this.activeColor = const Color(0xffB91111),
    this.inactiveColor = const Color(0xFF23272F),
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeInOutCubicEmphasized, // ✅ 여기
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SizedBox(
          height: 58,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final n = items.length;
              final w = constraints.maxWidth;
              final itemW = w / n;

              return Stack(
                children: [
                  // 트랙
                  Container(
                    decoration: BoxDecoration(
                      color: kNavTrack,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kNavBorder),
                    ),
                  ),

                  // 슬라이딩 썸
                  AnimatedPositioned(
                    duration: duration,
                    curve: curve,
                    left: index * itemW + 3,
                    width: itemW - 6,
                    top: 3,
                    bottom: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 아이템
                  Row(
                    children: List.generate(n, (i) {
                      final sel = i == index;
                      final it = items[i];

                      return Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => onTap(i),
                          child: TweenAnimationBuilder<double>(
                            duration: duration,
                            curve: curve,
                            tween: Tween(begin: 0, end: sel ? 1 : 0),
                            builder: (context, t, _) {
                              // t: 0(비선택) → 1(선택)
                              final color = Color.lerp(inactiveColor, activeColor, t)!;
                              final y = -4 * t; // 살짝 위로
                              final labelOpacity = 0.6 + 0.4 * t;

                              return AnimatedDefaultTextStyle(
                                duration: duration,
                                curve: curve,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                                  color: color,
                                ),
                                child: Transform.translate(
                                  offset: Offset(0, y),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(it.icon, size: 20, color: color),
                                      const SizedBox(height: 4),
                                      Opacity(
                                        opacity: labelOpacity,
                                        child: Text(
                                          it.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
