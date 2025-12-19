import 'package:flutter/material.dart';

class NavButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const NavButton({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IconButton(
        icon: Icon(icon),
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.secondaryContainer
              : Colors.transparent,
        ),
      ),
    );
  }
}
