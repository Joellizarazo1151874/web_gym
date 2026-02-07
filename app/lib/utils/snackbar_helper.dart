import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

enum SnackBarType { success, error, warning, info }

class SnackBarHelper {
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.success,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colorScheme = _getColorScheme(type);
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: duration,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.02,
          left: 16,
          right: 16,
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.color.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  colorScheme.icon,
                  color: colorScheme.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: GoogleFonts.catamaran(
                          color: AppColors.richBlack,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    Text(
                      message,
                      style: GoogleFonts.rubik(
                        color: title != null ? AppColors.sonicSilver : AppColors.richBlack,
                        fontWeight: title != null ? FontWeight.w400 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                icon: Icon(
                  Icons.close,
                  color: AppColors.sonicSilver.withOpacity(0.5),
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void success(BuildContext context, String message, {String? title}) {
    show(context: context, message: message, title: title, type: SnackBarType.success);
  }

  static void error(BuildContext context, String message, {String? title}) {
    show(context: context, message: message, title: title, type: SnackBarType.error);
  }

  static void warning(BuildContext context, String message, {String? title}) {
    show(context: context, message: message, title: title, type: SnackBarType.warning);
  }

  static void info(BuildContext context, String message, {String? title}) {
    show(context: context, message: message, title: title, type: SnackBarType.info);
  }

  static _SnackBarColorScheme _getColorScheme(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarColorScheme(
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      case SnackBarType.error:
        return _SnackBarColorScheme(
          color: AppColors.error,
          icon: Icons.error_rounded,
        );
      case SnackBarType.warning:
        return _SnackBarColorScheme(
          color: Colors.orange,
          icon: Icons.warning_rounded,
        );
      case SnackBarType.info:
        return _SnackBarColorScheme(
          color: AppColors.primary,
          icon: Icons.info_rounded,
        );
    }
  }
}

class _SnackBarColorScheme {
  final Color color;
  final IconData icon;

  _SnackBarColorScheme({required this.color, required this.icon});
}

