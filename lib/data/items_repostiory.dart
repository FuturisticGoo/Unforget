import 'package:async/async.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/data/items_datasource.dart';

abstract class ItemsRepository {
  /// Get all [Item]s from the database
  Future<Result<List<Item>>> getAllItems();

  /// Save a [NewItem] and return the saved [Item]'s id
  Future<Result<int>> saveNewItem({
    required NewItem newItem,
  });

  /// Get a list of [Item]s with similar name or descriptions
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
  Future<Result<List<Item>>> getAllItems() async {
    try {
      final result = await itemsDatasource.getAllItems();
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
