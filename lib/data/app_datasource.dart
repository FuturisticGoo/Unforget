import 'package:cross_file/cross_file.dart';
import 'package:things_map/core/init_setup.dart';
import 'package:path/path.dart' as p;

abstract class AppDataSource {
  Future<List<String>> saveImage({
    required int itemId,
    required List<XFile> images,
  });
}

class AppDataSourceImpl implements AppDataSource {
  final AppDicrectory appDirectory;
  AppDataSourceImpl({
    required this.appDirectory,
  });
  @override
  Future<List<String>> saveImage({
    required int itemId,
    required List<XFile> images,
  }) async {
    final savedImagesPaths = <String>[];
    for (final image in images) {
      final destPath = p.join(
        appDirectory,
        "${itemId}_${DateTime.now().microsecondsSinceEpoch}",
      );
      await image.saveTo(destPath);
      savedImagesPaths.add(destPath);
    }
    return savedImagesPaths;
  }
}
