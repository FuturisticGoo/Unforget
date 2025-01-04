import 'package:async/async.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:things_map/core/constants.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:equatable/equatable.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/data/items_repostiory.dart';
import 'package:path/path.dart' as p;
part 'items_view_state.dart';

class ItemsViewCubit extends Cubit<ItemsViewState> {
  final ItemsRepository thingsRepository;
  ItemsViewCubit({
    required this.thingsRepository,
  }) : super(ItemsViewInitial()) {
    _loadThings();
  }

  Future<void> _loadThings() async {
    emit(ItemsViewLoading());
    final result = await thingsRepository.getAllItems();

    switch (result) {
      case ErrorResult(:final error, :final stackTrace):
        emit(
          ItemsViewError(
            error: error,
            stackTrace: stackTrace,
          ),
        );
      case ValueResult(value: final allItems):
        emit(
          ItemsViewTopLevel(
            allItems: allItems,
            childrenIdNameMap: _getChildrenIdNameMap(
              allItems: allItems,
              currentId: rootId,
            ),
          ),
        );
    }
  }

  Map<int, String> _getChildrenIdNameMap({
    required List<Item> allItems,
    required int currentId,
  }) {
    return Map.fromEntries(
      allItems
          .whereType<NonRoot>()
          .where(
            (item) => item.parentId == currentId,
          )
          .map(
            (item) => MapEntry(item.id, item.name),
          ),
    );
  }

  String? _getNicePathToId({
    required List<Item> allItems,
    required int id,
  }) {
    final currentItem = binarySearchItemWithId(items: allItems, id: id);
    switch (currentItem) {
      case null:
      case Root():
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
        ):
        emit(ItemsViewLoading());
        if (id == rootId) {
          emit(
            ItemsViewTopLevel(
              allItems: allItems,
              childrenIdNameMap: _getChildrenIdNameMap(
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
        switch (foundItem) {
          case null:
            emit(ItemsViewError(error: "Cant find item"));
          case Root(id: final foundId):
            emit(
              ItemsViewTopLevel(
                allItems: allItems,
                childrenIdNameMap: _getChildrenIdNameMap(
                  allItems: allItems,
                  currentId: foundId,
                ),
              ),
            );
          case InternalItem(
              id: final foundId,
            ):
            emit(
              ItemsViewInternalLevel(
                allItems: allItems,
                currentItem: foundItem,
                childrenIdNameMap: _getChildrenIdNameMap(
                  allItems: allItems,
                  currentId: foundId,
                ),
                niceParentPath: _getNicePathToId(
                      allItems: allItems,
                      id: foundItem.parentId,
                    ) ??
                    "null",
                currentItemImagePaths: [
                  "/home/fgoo/Downloads/4.1.06.png",
                  "/home/fgoo/Downloads/control",
                  "/home/fgoo/Downloads/Other Stuff/always_gotta_stop_when_I_see_this.webp",
                  "/home/fgoo/Downloads/Other Stuff/trolled.webp",
                ],
                isEditMode: straightToEditMode,
              ),
            );
          case LeafItem():
            emit(
              ItemsViewLeafLevel(
                allItems: allItems,
                currentItem: foundItem,
                niceParentPath: _getNicePathToId(
                      allItems: allItems,
                      id: foundItem.parentId,
                    ) ??
                    "null",
                currentItemImagePaths: [
                  "/home/fgoo/Downloads/4.1.06.png",
                  "/home/fgoo/Downloads/control",
                  "/home/fgoo/Downloads/Other Stuff/always_gotta_stop_when_I_see_this.webp",
                  "/home/fgoo/Downloads/Other Stuff/trolled.webp",
                ],
                isEditMode: straightToEditMode,
              ),
            );
        }
      default:
        break;
    }
  }

  Future<void> saveItem({required NewItem newItem}) async {
    // switch (state) {
    //   case ItemsViewLoaded(:final currentItem, isEditMode: true):
    //     final parentPath = currentItem.parentPathId;
    //     final saveResult = await thingsRepository.saveNewItem(newItem: newItem);
    //     switch (saveResult) {
    //       case ErrorResult(:final error):
    //         emit(ItemsViewError(error: error));
    //       case ValueResult(:final value):
    //         await _loadThings();

    //         // emit(ItemsViewLoaded(rootItem: rootItem, currentItem: currentItem, niceParentPath: niceParentPath, currentItemImagePaths: currentItemImagePaths, isEditMode: isEditMode))
    //         final newItemPath = p.join(
    //           parentPath,
    //           value.toString(),
    //         );
    //         print("Path: $newItemPath");
    //         if (state case ItemsViewLoaded(rootItem: final newRootItem)) {
    //           final addedItemAndPath = await _getItemAndNicePathWithId(
    //             root: newRootItem,
    //             requiredId: newItemPath,
    //           );
    //           if (addedItemAndPath != null) {
    //             await goToItem(
    //               item: addedItemAndPath.$1,
    //               straightToEditMode: false,
    //             );
    //           } else {
    //             emit(
    //               ItemsViewError(
    //                 error: UnimplementedError(
    //                   "Unable to find item",
    //                 ),
    //               ),
    //             );
    //           }
    //         }
    //     }
    //   default:
    //     break;
    // }
  }

  Future<void> showAddItem() async {
    //   switch (state) {
    //     case ItemsViewLoaded(
    //           :final rootItem,
    //           :final currentItem,
    //           :final niceParentPath,
    //         )
    //         when currentItem is InternalItem:
    //       // final currentGreatestChildItemBaseId = currentItem.items.fold(
    //       //   0,
    //       //   (previousValue, element) {
    //       //     return (previousValue < element.baseId)
    //       //         ? element.baseId
    //       //         : previousValue;
    //       //   },
    //       // );
    //       final newItem = InternalItem(
    //         pathId: p.join(currentItem.pathId, "0"),
    //         // pathId: p.join(
    //         //   currentItem.pathId,
    //         //   (currentGreatestChildItemBaseId + 1).toString(),
    //         // ),
    //         name: "",
    //         items: [],
    //         owners: [],
    //         lastUpdated: DateTime.now(),
    //       );
    //       emit(
    //         ItemsViewLoaded(
    //           rootItem: rootItem,
    //           currentItem: newItem,
    //           niceParentPath: _getNiceParentPath(
    //             currentNiceParentPath: niceParentPath,
    //             currentItem: currentItem,
    //           ),
    //           currentItemImagePaths: [],
    //           isEditMode: true,
    //         ),
    //       );
    //     default:
    //       break;
    //   }
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
