import 'dart:io' as io;
import 'package:flutter/material.dart';

class ImageTile extends StatelessWidget {
  final List<String> imagePaths;
  const ImageTile({
    super.key,
    required this.imagePaths,
  });

  @override
  Widget build(BuildContext context) {
    switch (imagePaths.length) {
      case 0:
        return Container();
      default:
        return CarouselView(
          itemExtent: double.infinity,
          children: imagePaths.map(
            (path) {
              return Image.file(io.File(path));
            },
          ).toList(),
        );
    }
  }
}
