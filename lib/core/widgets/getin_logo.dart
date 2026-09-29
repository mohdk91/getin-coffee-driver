import 'package:flutter/material.dart';

class GetinLogoMark extends StatelessWidget {
  final double size;

  const GetinLogoMark({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/getin_logo_mark.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
