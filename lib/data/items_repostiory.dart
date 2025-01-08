import 'package:async/async.dart';
import 'package:cross_file/cross_file.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/core/entity/owner.dart';
import 'package:things_map/data/app_datasource.dart';
import 'package:things_map/data/items_datasource.dart';

abstract class ItemsRepository {
  /// Get all [Item]s from the database
  Future<Result<List<Item>>> getAllItems();

  /// Save a [NewItem] and return the saved [Item]'s id
  Future<Result<int>> saveOrModifyItem({
    required NewItem newItem,
    List<String>? imagePaths,
  });
  Future<Result<List<String>>> getImagesForItem({
    required int itemId,
  });
  Future<Result<void>> saveImages({
    required int itemId,
    required List<XFile> images,
  });

  /// Get a list of [Item]s with similar name or descriptions
  Future<Result<List<Item>>> getSearchResult({
    required String searchString,
  });

  Future<Result<void>> deleteItem({required int itemId});
  Future<Result<List<Owner>>> getAllOwners();
  Future<Result<void>> saveOwner({required Owner owner});
}

class ItemsRepositoryImpl implements ItemsRepository {
  final ItemsDatasource itemsDatasource;
  final AppDataSource appDataSource;
  ItemsRepositoryImpl({
    required this.itemsDatasource,
    required this.appDataSource,
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
    List<String>? imagePaths,
  }) async {
    try {
      final id = await itemsDatasource.saveOrModifyItem(
        newItem: newItem,
      );
      return Result.value(id);
    } catch (error, stackTrace) {
      return Result.error(error, stackTrace);
    }
  }

  @override
  Future<Result<void>> deleteItem({required int itemId}) async {
    try {
      final id = await itemsDatasource.deleteItem(itemId: itemId);
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
  Future<Result<void>> saveOwner({required Owner owner}) async {
    try {
      await itemsDatasource.saveNewOwner(owner: owner);
      return Result.value(null);
    } catch (error, stackTrace) {
      return Result.error(error, stackTrace);
    }
  }

  @override
  Future<Result<List<String>>> getImagesForItem({
    required int itemId,
  }) async {
    try {
      final imagePaths = await itemsDatasource.getImagePathsForItem(
        itemId: itemId,
      );
      return Result.value(imagePaths);
    } catch (error, stackTrace) {
      return Result.error(error, stackTrace);
    }
  }

  @override
  Future<Result<void>> saveImages({
    required int itemId,
    required List<XFile> images,
  }) async {
    try {
      final paths = await appDataSource.saveImage(
        itemId: itemId,
        images: images,
      );
      await itemsDatasource.saveImagePathsForItem(
        itemId: itemId,
        imagePaths: paths,
      );
      return Result.value(null);
    } catch (error, stackTrace) {
      return Result.error(error, stackTrace);
    }
  }

  @override
  Future<Result<List<Item>>> getSearchResult({
    required String searchString,
  }) async {
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
