import 'dart:io' as io;
import 'package:flutter/material.dart';

class ImageTile extends StatelessWidget {
  final bool isReadOnly;
  final List<String> imagePaths;
  final void Function(int index) onImageTap;
  final void Function(bool useCamera) onAddImageTap;
  const ImageTile({
    super.key,
    required this.isReadOnly,
    required this.imagePaths,
    required this.onImageTap,
    required this.onAddImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return CarouselView(
      itemExtent: double.infinity,
      onTap: (value) {
        if (value == imagePaths.length + 1) {
          onAddImageTap(false);
        } else if (value == imagePaths.length) {
          onAddImageTap(true);
        } else {
          onImageTap(value);
        }
      },
      children: [
        ...imagePaths.map(
          (path) {
            return Image.file(io.File(path));
          },
        ),
        ...(isReadOnly)
            ? []
            : [
                Center(
                  child: Text("Capture image"),
                ),
                Center(
                  child: Text("Pick image"),
                ),
              ]
      ],
    );
  }
}
