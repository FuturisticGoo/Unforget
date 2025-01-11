import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';

Future<List<XFile>?> getImages({
  required bool useCamera,
}) async {
  const XTypeGroup jpgsTypeGroup = XTypeGroup(
    label: 'JPEGs',
    extensions: <String>['jpg', 'jpeg'],
  );
  const XTypeGroup pngTypeGroup = XTypeGroup(
    label: 'PNGs',
    extensions: <String>['png'],
  );
  const XTypeGroup webpTypeGroup = XTypeGroup(
    label: 'WEBPs',
    extensions: <String>['webp'],
  );
  final List<XFile> files;
  if (useCamera) {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    files = image == null ? [] : [image];
  } else {
    files = await openFiles(
      acceptedTypeGroups: <XTypeGroup>[
        jpgsTypeGroup,
        pngTypeGroup,
        webpTypeGroup,
      ],
    );
  }
  return files;
}
