import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color backgroundColor;
  final VoidCallback? onBackPressed;

  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = true,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor = Colors.transparent,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title:
          titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                )
              : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: onBackPressed ?? () => Navigator.maybePop(context),
            )
          : null,
      actions: actions != null ? [...actions!, const SizedBox(width: 8)] : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
