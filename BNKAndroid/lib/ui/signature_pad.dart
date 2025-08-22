// lib/ui/signature_pad.dart
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePad extends StatefulWidget {
  final SignatureController controller;
  final double height;
  final double strokeWidth;
  final Color strokeColor;
  final Color backgroundColor;
  final String hint;        // 상단 안내 문구
  final bool showActions;   // 되돌리기/지우기 버튼 표시

  const SignaturePad({
    super.key,
    required this.controller,
    this.height = 260,
    this.strokeWidth = 3,
    this.strokeColor = const Color(0xFF222222),
    this.backgroundColor = Colors.white,
    this.hint = '박스 안에 서명해 주세요.',
    this.showActions = true,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  @override
  void initState() {
    super.initState();
  }

  void _undo() {
    if (widget.controller.points.isNotEmpty) {
      widget.controller.points.removeLast();
      setState(() {});
    }
  }

  void _clear() {
    if (widget.controller.isNotEmpty) {
      widget.controller.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.hint,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCED4DA)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Signature(
              controller: widget.controller,
              backgroundColor: widget.backgroundColor,
            ),
          ),
        ),
        if (widget.showActions) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: widget.controller.isEmpty ? null : _undo,
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('되돌리기'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: widget.controller.isEmpty ? null : _clear,
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('지우기'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
