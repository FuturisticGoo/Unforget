import 'package:async/async.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:things_map/core/constants.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:equatable/equatable.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/core/entity/owner.dart';
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
    final itemsResult = await thingsRepository.getAllItems();
    final ownersResult = await thingsRepository.getAllOwners();
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
        switch (foundItem) {
          case null:
            emit(ItemsViewError(error: "Cant find item"));
          case Root(id: final foundId):
            emit(
              ItemsViewTopLevel(
                allItems: allItems,
                allOwners: allOwners,
                children: _getChildrenOfItem(
                  allItems: allItems,
                  currentId: foundId,
                ),
              ),
            );
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
                    id: foundItem.id,
                  ) ??
                  "null",
              currentItemImagePaths: [
                "/home/fgoo/Downloads/4.1.06.png",
                "/home/fgoo/Downloads/control",
                "/home/fgoo/Downloads/Other Stuff/always_gotta_stop_when_I_see_this.webp",
                "/home/fgoo/Downloads/Other Stuff/trolled.webp",
              ],
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
              currentItemImagePaths: [
                "/home/fgoo/Downloads/4.1.06.png",
                "/home/fgoo/Downloads/control",
                "/home/fgoo/Downloads/Other Stuff/always_gotta_stop_when_I_see_this.webp",
                "/home/fgoo/Downloads/Other Stuff/trolled.webp",
              ],
            );
            emit(
              (straightToEditMode) ? newState.editItem : newState,
            );
        }
      default:
        break;
    }
  }

  Future<void> saveItem({
    required NewItem newItem,
    NonRoot? oldItem,
  }) async {
    switch (state) {
      case ItemsViewEdit():
        final saveResult = await thingsRepository.saveOrModifyItem(
          newItem: newItem,
          oldItem: oldItem,
        );
        switch (saveResult) {
          case ErrorResult(:final error):
            emit(ItemsViewError(error: error));
          case ValueResult(:final value):
            await _loadThings();
            await goToItemWithId(id: value, straightToEditMode: false);
        }
      default:
        break;
    }
  }

  Future<void> addNewOwner({required Owner owner}) async {
    await thingsRepository.saveOwner(owner: owner);
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
          ),
        );
      case ItemsViewNonTopLevel(
          :final allItems,
          :final allOwners,
          :final currentItem,
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
          ),
        );
      default:
        break;
    }
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
