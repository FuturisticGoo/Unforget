import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:things_map/core/constants.dart';
import 'package:things_map/data/items_datasource.dart';
import 'package:things_map/data/items_repostiory.dart';

GetIt sl = GetIt.I;
Future<void> initSetup() async {
  final dbPath = p.join(
    (await getApplicationDocumentsDirectory()).path,
    dbFileName,
  );
  databaseFactory = databaseFactoryFfi;
  sqfliteFfiInit();
  // databaseFactory = databaseFactoryFfi;
  final db = await openDatabase(dbPath);
  sl.registerSingleton<Database>(db);
  sl.registerSingleton<ItemsDatasource>(
    ItemsDataSourceSQLite(db: db),
  );
  sl.registerSingleton<ItemsRepository>(
    ItemsRepositoryImpl(
      itemsDatasource: sl(),
    ),
  );
}
