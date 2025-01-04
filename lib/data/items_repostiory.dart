import 'package:async/async.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/data/items_datasource.dart';

abstract class ItemsRepository {
  Future<Result<Root>> getItemsTree();
  Future<Result<int>> saveNewItem({
    required NewItem newItem,
  });
  Future<Result<List<Item>>> getSearchResult({
    required String searchString,
  });
}

class ItemsRepositoryImpl implements ItemsRepository {
  final ItemsDatasource itemsDatasource;
  ItemsRepositoryImpl({
    required this.itemsDatasource,
  });

  @override
  Future<Result<Root>> getItemsTree() async {
    try {
      final result = await itemsDatasource.getItemsRoot();
      return Result.value(result);
    } catch (error, stackTrace) {
      return Result.error(error, stackTrace);
    }
  }

  @override
  Future<Result<int>> saveNewItem({required NewItem newItem}) async {
    try {
      final id = await itemsDatasource.saveNewItem(newItem: newItem);
      return Result.value(id);
    } catch (error, stackTrace) {
      return Result.error(error, stackTrace);
    }
  }

  @override
  Future<Result<List<Item>>> getSearchResult(
      {required String searchString}) async {
    if (itemsDatasource is ItemsDataSourceSQLite) {
      try {
        final result = await (itemsDatasource as ItemsDataSourceSQLite)
            .getItemSearchMatches(searchString: searchString);
        return Result.value(result);
      } catch (error, stackTrace) {
        return Result.error(error, stackTrace);
      }
    } else {
      return Result.error(
        UnimplementedError(
          "Search not implemented non-SQLite db storage",
        ),
      );
    }
  }
}
