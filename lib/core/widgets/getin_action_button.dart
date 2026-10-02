import 'package:flutter/material.dart';

class GetinActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;

  const GetinActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    final child = icon == null
        ? labelText
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Flexible(child: labelText),
            ],
          );

    final button = secondary
        ? OutlinedButton(
            onPressed: onPressed,
            child: child,
          )
        : FilledButton(
            onPressed: onPressed,
            child: child,
          );

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}
