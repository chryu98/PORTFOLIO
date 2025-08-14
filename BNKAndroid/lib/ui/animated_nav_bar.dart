import 'package:flutter/material.dart';

class AttachNavItem {
  final IconData icon;
  final String label;
  const AttachNavItem(this.icon, this.label);
}

class AnimatedAttachNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<AttachNavItem> items;

  // 애니메이션 조절
  final Duration indicatorDuration;
  final Curve indicatorCurve;
  final Duration highlightDuration;
  final Curve highlightCurve;

  // ✅ BNK 레드 캡슐 색 (바꾸고 싶으면 주입)
  final Color indicatorColor;

  const AnimatedAttachNavBar({
    super.key,
    required this.index,
    required this.onTap,
    required this.items,
    this.indicatorDuration = const Duration(milliseconds: 700),
    this.indicatorCurve = Curves.easeInOutCubic,
    this.highlightDuration = const Duration(milliseconds: 220),
    this.highlightCurve = Curves.easeOut,
    this.indicatorColor = const Color(0xFFB91111), // BNK Red
  }) : assert(items.length >= 2);

  @override
  Widget build(BuildContext context) {
    const barHeight = 72.0;             // 바 자체 높이 ↑ (캡슐이 글+아이콘을 다 감싸도록)
    const indicatorHeight = 50.0;       // ✅ 캡슐 높이 (아이콘+라벨 전체 커버)
    const indicatorRadius = 18.0;

    return SafeArea(
      top: false,
      child: Container(
        height: barHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0x11111827))),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / items.length;
            final indicatorWidth = tabWidth * 0.78; // 폭도 넉넉하게
            final left = index * tabWidth + (tabWidth - indicatorWidth) / 2.0;

            return Stack(
              children: [
                // ✅ 캡슐(인디케이터) — 먼저 그려서 뒤에 깔림
                AnimatedPositioned(
                  duration: indicatorDuration,
                  curve: indicatorCurve,
                  left: left,
                  top: (barHeight - indicatorHeight) / 2,
                  width: indicatorWidth,
                  height: indicatorHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: indicatorColor, // BNK Red
                      borderRadius: BorderRadius.circular(indicatorRadius),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                  ),
                ),

                // 아이콘/라벨
                Row(
                  children: List.generate(items.length, (i) {
                    final it = items[i];
                    final selected = i == index;

                    // 선택이면 흰색(캡슐 위), 아니면 회색
                    final iconColor = selected ? Colors.white : const Color(0xFF98A2B3);
                    final textColor = selected ? Colors.white : const Color(0xFF98A2B3);

                    return Expanded(
                      child: InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () => onTap(i),
                        child: AnimatedDefaultTextStyle(
                          duration: highlightDuration,
                          curve: highlightCurve,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: textColor,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                duration: highlightDuration,
                                curve: highlightCurve,
                                scale: selected ? 1.06 : 1.0,
                                child: AnimatedOpacity(
                                  duration: highlightDuration,
                                  curve: highlightCurve,
                                  opacity: selected ? 1 : 0.9,
                                  child: Icon(it.icon, size: 24, color: iconColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(it.label),
                            ],
                          ),
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
    );
  }
}
