import 'package:file_selector/file_selector.dart';

Future<List<XFile>?> getImages() async {
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
  final List<XFile> files = await openFiles(
    acceptedTypeGroups: <XTypeGroup>[
      jpgsTypeGroup,
      pngTypeGroup,
      webpTypeGroup,
    ],
  );
  return files;
}
