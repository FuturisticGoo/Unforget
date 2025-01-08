import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:things_map/core/constants.dart';
import 'package:things_map/data/app_datasource.dart';
import 'package:things_map/data/items_datasource.dart';
import 'package:things_map/data/items_repostiory.dart';
import 'dart:io' as io;

typedef AppDicrectory = String;

GetIt sl = GetIt.I;
Future<void> initSetup() async {
  final AppDicrectory appDirectory = p.join(
    (await getApplicationDocumentsDirectory()).path,
    appDataFolderName,
  );
  await io.Directory(appDirectory).create();
  final dbPath = p.join(
    appDirectory,
    dbFileName,
  );
  databaseFactory = databaseFactoryFfi;
  sqfliteFfiInit();
  final db = await openDatabase(dbPath);
  sl.registerSingleton<Database>(db);
  sl.registerSingleton<ItemsDatasource>(
    ItemsDataSourceSQLite(db: db),
  );
  sl.registerSingleton<AppDataSource>(
    AppDataSourceImpl(
      appDirectory: appDirectory,
    ),
  );
  sl.registerSingleton<ItemsRepository>(
    ItemsRepositoryImpl(
      itemsDatasource: sl(),
      appDataSource: sl(),
    ),
  );
}
