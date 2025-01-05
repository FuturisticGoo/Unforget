part of 'items_view_cubit.dart';

sealed class ItemsViewState {
  const ItemsViewState();
}

class ItemsViewInitial extends ItemsViewState {
  const ItemsViewInitial();
}

class ItemsViewLoading extends ItemsViewState {
  const ItemsViewLoading();
}

class ItemsViewError extends ItemsViewState {
  final Object error;
  final StackTrace? stackTrace;
  const ItemsViewError({required this.error, this.stackTrace});
}

sealed class ItemsViewLoaded extends ItemsViewState with EquatableMixin {
  final List<Item> allItems;
  const ItemsViewLoaded({
    required this.allItems,
  });
  @override
  List<Object?> get props => [
        allItems,
      ];
}

mixin ItemsViewWithChildren {
  List<NonRoot> get children;
}
mixin ItemsViewCanGoUpward {
  int get parentId;
  String get nicePath;
}

class ItemsViewEdit extends ItemsViewLoaded with ItemsViewCanGoUpward {
  @override
  final int parentId;
  @override
  final String nicePath;

  /// If this [editingItem] is null, then it means adding a new item
  final NonRoot? editingItem;
  const ItemsViewEdit({
    required super.allItems,
    required this.parentId,
    required this.nicePath,
    this.editingItem,
  });
  @override
  List<Object?> get props => [
        ...super.props,
        parentId,
        nicePath,
        editingItem,
      ];
}

class ItemsViewTopLevel extends ItemsViewLoaded with ItemsViewWithChildren {
  @override
  final List<NonRoot> children;
  const ItemsViewTopLevel({
    required super.allItems,
    required this.children,
  });
  @override
  List<Object?> get props => [
        ...super.props,
        children,
      ];
}

sealed class ItemsViewNonTopLevel extends ItemsViewLoaded
    with ItemsViewCanGoUpward {
  @override
  int get parentId => currentItem.parentId;

  @override
  final String nicePath;
  final NonRoot currentItem;
  final List<String> currentItemImagePaths;
  const ItemsViewNonTopLevel({
    required super.allItems,
    required this.currentItem,
    required this.nicePath,
    required this.currentItemImagePaths,
  });
  @override
  List<Object?> get props => [
        ...super.props,
        currentItem,
        nicePath,
        currentItemImagePaths,
      ];
}

class ItemsViewInternalLevel extends ItemsViewNonTopLevel
    with ItemsViewWithChildren {
  @override
  final List<NonRoot> children;
  const ItemsViewInternalLevel({
    required super.allItems,
    required super.currentItem,
    required this.children,
    required super.nicePath,
    required super.currentItemImagePaths,
  });
  @override
  List<Object?> get props => [
        ...super.props,
        children,
      ];
}

class ItemsViewLeafLevel extends ItemsViewNonTopLevel {
  const ItemsViewLeafLevel({
    required super.allItems,
    required super.currentItem,
    required super.nicePath,
    required super.currentItemImagePaths,
  });
}

extension _EditItem on ItemsViewNonTopLevel {
  ItemsViewEdit get editItem {
    return ItemsViewEdit(
      editingItem: currentItem,
      allItems: allItems,
      parentId: parentId,
      nicePath: nicePath,
    );
  }
}
