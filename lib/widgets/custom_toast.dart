import 'package:flutter/material.dart';
import 'dart:async';

enum ToastType { success, error, info }

class ToastService {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) =>
          _ToastWidget(message: message, type: type, onDismiss: () {}),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  static void showSuccess(BuildContext context, String message) =>
      show(context, message, type: ToastType.success);

  static void showError(BuildContext context, String message) =>
      show(context, message, type: ToastType.error);

  static void showInfo(BuildContext context, String message) =>
      show(context, message, type: ToastType.info);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _offset = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBgColor(bool isDark) {
    // Modern glass/card look
    // Or distinct colors
    return isDark ? const Color(0xFF333333) : Colors.white;
  }

  Color _getIconColor() {
    switch (widget.type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return Colors.red;
      case ToastType.info:
        return Colors.blue;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _offset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getBgColor(isDark),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Row(
                children: [
                  Icon(_getIcon(), color: _getIconColor(), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
