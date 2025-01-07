import 'dart:io';

import 'package:flutter/material.dart';

class FullscreenImage extends StatelessWidget {
  final File imageFile;
  const FullscreenImage({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.file(
          imageFile,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}