import 'package:async/async.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:text_search/text_search.dart';
import 'package:things_map/core/constants.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:equatable/equatable.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/core/entity/owner.dart';
import 'package:things_map/data/items_repostiory.dart';
import 'package:path/path.dart' as p;
part 'items_view_state.dart';

class ItemsViewCubit extends Cubit<ItemsViewState> {
  final ItemsRepository itemsRepository;
  List<TextSearchItem<NonRoot>>? _searchItemsCache;
  ItemsViewCubit({
    required this.itemsRepository,
  }) : super(ItemsViewInitial()) {
    _loadThings();
  }

  Future<void> _loadThings() async {
    emit(ItemsViewLoading());
    final itemsResult = await itemsRepository.getAllItems();
    final ownersResult = await itemsRepository.getAllOwners();
    switch ((itemsResult, ownersResult)) {
      case (_, ErrorResult(:final error, :final stackTrace)):
      case (ErrorResult(:final error, :final stackTrace), _):
        emit(
          ItemsViewError(
            error: error,
            stackTrace: stackTrace,
          ),
        );
      case (
          ValueResult(value: final allItems),
          ValueResult(value: final allOwners)
        ):
        _searchItemsCache = allItems.map(
          (item) {
            return TextSearchItem.fromTerms(item, [item.name]);
          },
        ).toList();
        emit(
          ItemsViewTopLevel(
            allItems: allItems,
            allOwners: allOwners,
            children: _getChildrenOfItem(
              allItems: allItems,
              currentId: rootId,
            ),
          ),
        );
    }
  }

  List<NonRoot> _getChildrenOfItem({
    required List<Item> allItems,
    required int currentId,
  }) {
    return allItems
        .whereType<NonRoot>()
        .where(
          (item) => item.parentId == currentId,
        )
        .toList();
  }

  String? _getNicePathToId({
    required List<Item> allItems,
    required int id,
  }) {
    final currentItem = binarySearchItemWithId(items: allItems, id: id);
    switch (currentItem) {
      case null:
        // case Root():
        return "/";
      case NonRoot(:final parentId):
        final parentNicePath = _getNicePathToId(
          allItems: allItems,
          id: parentId,
        );
        if (parentNicePath != null) {
          return p.join(parentNicePath, currentItem.name);
        } else {
          return null;
        }
    }
  }

  Future<void> goToItemWithId({
    required int id,
    required bool straightToEditMode,
  }) async {
    switch (state) {
      case ItemsViewLoaded(
          :final allItems,
          :final allOwners,
        ):
        emit(ItemsViewLoading());
        if (id == rootId) {
          emit(
            ItemsViewTopLevel(
              allItems: allItems,
              allOwners: allOwners,
              children: _getChildrenOfItem(
                allItems: allItems,
                currentId: rootId,
              ),
            ),
          );
          return;
        }
        final foundItem = binarySearchItemWithId(
          items: allItems,
          id: id,
        );
        List<String> imagePaths = [];
        if (foundItem != null) {
          final imagesResult = await itemsRepository.getImagesForItem(
            itemId: foundItem.id,
          );
          if (imagesResult case ValueResult(:final value)) {
            imagePaths = value;
          }
        }
        switch (foundItem) {
          case null:
            emit(ItemsViewError(error: "Cant find item"));
          // case Root(id: final foundId):
          //   emit(
          //     ItemsViewTopLevel(
          //       allItems: allItems,
          //       allOwners: allOwners,
          //       children: _getChildrenOfItem(
          //         allItems: allItems,
          //         currentId: foundId,
          //       ),
          //     ),
          //   );
          case InternalItem(
              id: final foundId,
            ):
            final newState = ItemsViewInternalLevel(
              allItems: allItems,
              allOwners: allOwners,
              currentItem: foundItem,
              children: _getChildrenOfItem(
                allItems: allItems,
                currentId: foundId,
              ),
              nicePath: _getNicePathToId(
                    allItems: allItems,
                    id: foundId,
                  ) ??
                  "null",
              currentItemImagePaths: imagePaths,
            );

            emit((straightToEditMode) ? newState.editItem : newState);
          case LeafItem():
            final newState = ItemsViewLeafLevel(
              allItems: allItems,
              allOwners: allOwners,
              currentItem: foundItem,
              nicePath: _getNicePathToId(
                    allItems: allItems,
                    id: foundItem.id,
                  ) ??
                  "null",
              currentItemImagePaths: imagePaths,
            );
            emit(
              (straightToEditMode) ? newState.editItem : newState,
            );
        }
      default:
        break;
    }
  }

  Future<void> addImage({
    required List<XFile> imagesToAdd,
  }) async {
    switch (state) {
      case ItemsViewEdit(
          :final allItems,
          :final allOwners,
          :final parentId,
          :final nicePath,
          :final currentItemImagePaths,
          :final newImages,
          :final editingItem,
        ):
        emit(
          ItemsViewEdit(
            editingItem: editingItem,
            allItems: allItems,
            allOwners: allOwners,
            parentId: parentId,
            nicePath: nicePath,
            currentItemImagePaths: [
              ...currentItemImagePaths,
              ...imagesToAdd.map(
                (e) => e.path,
              )
            ],
            newImages: [
              ...newImages,
              ...imagesToAdd,
            ],
          ),
        );
      default:
        break;
    }
  }

  Future<void> saveItem({
    required NewItem newItem,
    List<XFile>? images,
  }) async {
    // switch (state) {
    // case ItemsViewEdit():
    final saveResult = await itemsRepository.saveOrModifyItem(newItem: newItem);
    switch (saveResult) {
      case ErrorResult(:final error):
        emit(ItemsViewError(error: error));
      case ValueResult(:final value):
        if (images != null) {
          final imageResult = await itemsRepository.saveImages(
            itemId: value,
            images: images,
          );
        }
        await _loadThings();
        await goToItemWithId(id: value, straightToEditMode: false);
    }
    //   default:
    //     break;
    // }
  }

  Future<void> addNewOwner({required Owner owner}) async {
    await itemsRepository.saveOwner(owner: owner);
  }

  Future<void> showAddOrEditItem({
    NonRoot? editingItem,
  }) async {
    switch (state) {
      case ItemsViewTopLevel(
          :final allItems,
          :final allOwners,
        ):
        emit(
          ItemsViewEdit(
            allItems: allItems,
            allOwners: allOwners,
            parentId: rootId,
            nicePath: "/",
            editingItem: editingItem,
            currentItemImagePaths: [],
          ),
        );
      case ItemsViewNonTopLevel(
          :final allItems,
          :final allOwners,
          :final currentItem,
          :final currentItemImagePaths,
        ):
        emit(
          ItemsViewEdit(
            allItems: allItems,
            allOwners: allOwners,
            parentId: editingItem?.parentId ?? currentItem.id,
            nicePath: _getNicePathToId(
                  allItems: allItems,
                  id: currentItem.id,
                ) ??
                "",
            editingItem: editingItem,
            currentItemImagePaths:
                editingItem == null ? [] : currentItemImagePaths,
          ),
        );
      default:
        break;
    }
  }

  Future<void> deleteItem({required NonRoot item}) async {
    final result = await itemsRepository.deleteItem(itemId: item.id);
    switch (result) {
      case ValueResult():
        await _loadThings();
        await goToItemWithId(
          id: item.parentId,
          straightToEditMode: false,
        );
      case ErrorResult(:final error, :final stackTrace):
        emit(
          ItemsViewError(
            error: error,
            stackTrace: stackTrace,
          ),
        );
    }
  }

  Future<void> searchForItem({required String searchTerm}) async {
    switch (state) {
      case ItemsViewLoaded(
          :final allItems,
          :final allOwners,
        ):
        emit(
          ItemsViewSearch(
            allItems: allItems,
            allOwners: allOwners,
            searchResults: searchTerm.isEmpty
                ? []
                : await _searchItemsForString(
                    allItems: allItems,
                    searchTerm: searchTerm,
                  ),
            lastItemId: switch (state) {
              ItemsViewNonTopLevel(:final currentItem) => currentItem.id,
              ItemsViewSearch(:final lastItemId) => lastItemId,
              _ => rootId,
            },
          ),
        );
      default:
        break;
    }
  }

  Future<List<NonRoot>> _searchItemsForString({
    required List<NonRoot> allItems,
    required String searchTerm,
  }) async {
    _searchItemsCache ??= _searchItemsCache = allItems.map(
      (item) {
        return TextSearchItem.fromTerms(item, [item.name]);
      },
    ).toList();

    final searcher = TextSearch(_searchItemsCache!);
    final result = searcher.fastSearch(searchTerm);
    return result;
  }
}

Item? binarySearchItemWithId({required List<Item> items, required int id}) {
  int low = 0;
  int high = items.length - 1;
  while (low <= high) {
    int mid = ((low + high) / 2).floor();
    if (items[mid].id == id) {
      return items[mid];
    } else if (items[mid].id > id) {
      high = mid - 1;
    } else {
      low = mid + 1;
    }
  }
  return null;
}
