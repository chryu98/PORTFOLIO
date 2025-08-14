import 'package:flutter/material.dart';
import 'bnk_theme.dart';

/// 화면 컨테이너 (공통 패딩 + Section 카드 간격)
class BNKPage extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  const BNKPage({super.key, required this.child, this.appBar, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor ?? BNKColors.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    );
  }
}

/// 섹션 카드 (라운드+미세 그림자 느낌)
class BNKSection extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  const BNKSection({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin  = const EdgeInsets.only(top: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BNKColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000), offset: Offset(0, 6), blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 설정/리스트형 행 (우측 화살표)
class BNKSettingRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leading;
  final VoidCallback? onTap;
  const BNKSettingRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(leading, color: BNKColors.text, size: 22),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: BNKColors.text,
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: TextStyle(color: BNKColors.textSub)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: BNKColors.textSub),
          ],
        ),
      ),
    );
  }
}

/// 토스풍 셀렉션 바텀시트 (흰배경, 전체폭, 체크 표시)
Future<T?> showSelectSheet<T>({
  required BuildContext context,
  required List<T> options,
  required String Function(T) labelOf,
  T? selected,
}) async {
  final media = MediaQuery.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withOpacity(0.2),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final maxH = media.size.height * 0.7;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44, height: 4,
              decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final opt = options[i];
                  final isSel = opt == selected;
                  return ListTile(
                    title: Text(labelOf(opt),
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                        )),
                    trailing: isSel ? const Icon(Icons.check, color: BNKColors.primary) : null,
                    onTap: () => Navigator.pop(ctx, opt),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 입력칸: 눌렀을 때 위 바텀시트 열리는 셀렉터
class BNKSelectField<T> extends FormField<T> {
  BNKSelectField({
    Key? key,
    required T? value,
    required String hintText,
    required List<T> options,
    required String Function(T) labelOf,
    FormFieldValidator<T>? validator,
    ValueChanged<T?>? onChanged,
    InputDecoration? decoration,
  }) : super(
    key: key,
    initialValue: value,
    validator: validator,
    builder: (state) {
      final selected = state.value;
      Future<void> open() async {
        final res = await showSelectSheet<T>(
          context: state.context,
          options: options,
          labelOf: labelOf,
          selected: selected,
        );
        if (res != null) {
          state.didChange(res);
          onChanged?.call(res);
        }
      }

      return InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          isFocused: false,
          isEmpty: selected == null,
          decoration: (decoration ?? const InputDecoration())
              .copyWith(hintText: hintText, errorText: state.errorText),
          child: Text(
            selected == null ? hintText : labelOf(selected),
            style: TextStyle(
              color: selected == null ? Colors.grey.shade400 : BNKColors.text,
              fontWeight: selected == null ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ),
      );
    },
  );
}
