import 'package:async/async.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:equatable/equatable.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/data/items_repostiory.dart';
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
      case ValueResult(:final value):
        emit(
          ItemsViewTopLevel(
            allItems: value,
            childrenIdNameMap: Map.fromEntries(
              value
                  .whereType<NonRoot>()
                  .where(
                    (item) => item.isTopLevelItem,
                  )
                  .map(
                    (item) => MapEntry(item.id, item.name),
                  ),
            ),
          ),
        );
    }
  }

  // Future<(Item, String)?> _getItemAndNicePathWithId({
  //   required Root root,
  //   required String requiredId,
  // }) async {
  //   final currentItemPath = io.Directory(requiredId);
  //   if (currentItemPath.path == rootDir.path) {
  //     return (root, rootDir.path);
  //   } else {
  //     final parent = currentItemPath.parent;
  //     final parentData = await _getItemAndNicePathWithId(
  //       root: root,
  //       requiredId: parent.path,
  //     );
  //     switch (parentData) {
  //       case (
  //           InternalItem(
  //             :final items,
  //           ),
  //           String()
  //         ):
  //         final item = items
  //             .where(
  //               (element) => element.pathId == requiredId,
  //             )
  //             .singleOrNull;
  //         if (item != null) {
  //           final nicePath = p.join(parentData.$2, item.name);
  //           return (item, nicePath);
  //         } else {
  //           return null;
  //         }
  //       default:
  //         return null;
  //     }
  //   }
  // }

  Future<void> goBack() async {
    // switch (state) {
    //   case ItemsViewLoaded(
    //       :final rootItem,
    //       :final currentItem,
    //     ):
    //     final parentId = io.Directory(currentItem.pathId).parent.path;
    //     final parentData = await _getItemAndNicePathWithId(
    //       root: rootItem,
    //       requiredId: parentId,
    //     );
    //     if (parentData != null) {
    //       emit(
    //         ItemsViewLoaded(
    //           rootItem: rootItem,
    //           currentItem: parentData.$1,
    //           niceParentPath: io.Directory(parentData.$2).parent.path,
    //           currentItemImagePaths: [],
    //           isEditMode: false,
    //         ),
    //       );
    //     }
    //   default:
    //     break;
    // }
  }

  // String _getNiceParentPath({
  //   required String currentNiceParentPath,
  //   required Item currentItem,
  // }) {
  //   return p.join(
  //     currentNiceParentPath,
  //     (currentItem is Root) ? rootDir.path : currentItem.name,
  //   );
  // }

  Future<void> goToItem({
    required Item item,
    required bool straightToEditMode,
  }) async {
    // switch (state) {
    //   case ItemsViewLoaded(
    //       :final rootItem,
    //       :final currentItem,
    //       :final niceParentPath,
    //     ):
    //     print("Going to: ${item.pathId}");
    //     emit(
    //       ItemsViewLoaded(
    //         rootItem: rootItem,
    //         currentItem: item,
    //         niceParentPath: _getNiceParentPath(
    //           currentNiceParentPath: niceParentPath,
    //           currentItem: currentItem,
    //         ),
    //         // TODO: actual picture
    //         currentItemImagePaths: [
    //           "/home/fgoo/Downloads/4.1.06.png",
    //           "/home/fgoo/Downloads/control",
    //           "/home/fgoo/Downloads/Other Stuff/always_gotta_stop_when_I_see_this.webp",
    //           "/home/fgoo/Downloads/Other Stuff/trolled.webp",
    //         ],
    //         isEditMode: straightToEditMode,
    //       ),
    //     );
    //   default:
    //     break;
    // }
  }

  // Future<void> _addItemToTree({
  //   required Root rootItem,
  //   required Item newItem,
  // }) async {}
  //

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
  int low = items.first.id;
  int high = items.last.id;
  if (id < low || id < high) {
    return null;
  } else {
    while (low < high) {
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
}
