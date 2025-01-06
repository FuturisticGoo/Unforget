import 'package:async/async.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/core/entity/owner.dart';
import 'package:things_map/data/items_datasource.dart';

abstract class ItemsRepository {
  /// Get all [Item]s from the database
  Future<Result<List<Item>>> getAllItems();

  /// Save a [NewItem] and return the saved [Item]'s id
  Future<Result<int>> saveOrModifyItem({
    required NewItem newItem,
    NonRoot? oldItem,
  });

  /// Get a list of [Item]s with similar name or descriptions
  Future<Result<List<Item>>> getSearchResult({
    required String searchString,
  });
  Future<Result<List<Owner>>> getAllOwners();
  Future<Result<void>> saveOrModifyOwner();
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
  Future<Result<int>> saveOrModifyItem({
    required NewItem newItem,
    NonRoot? oldItem,
  }) async {
    try {
      final id = await itemsDatasource.saveOrModifyItem(
        newItem: newItem,
        oldItem: oldItem,
      );
      return Result.value(id);
    } catch (error, stackTrace) {
      return Result.error(error, stackTrace);
    }
  }

  @override
  Future<Result<List<Owner>>> getAllOwners() async {
    try {
      final ownersResult = await itemsDatasource.getAllOwners();
      return Result.value(ownersResult);
    } catch (error, stackTrace) {
      return Result.error(error, stackTrace);
    }
  }

  @override
  Future<Result<void>> saveOrModifyOwner() {
    // TODO: implement saveOrModifyOwner
    throw UnimplementedError();
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
