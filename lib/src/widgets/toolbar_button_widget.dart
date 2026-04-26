import 'package:flutter/material.dart';

class ToolbarButtonWidget extends StatelessWidget {
  const ToolbarButtonWidget({
    super.key,
    required this.icon,
    required this.onTap,
    required this.isActive,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor.withValues(alpha: 0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : Colors.white70,
        ),
      ),
    );
  }
}
