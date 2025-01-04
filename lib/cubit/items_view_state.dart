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
  Map<int, String> get childrenIdNameMap;
}

class ItemsViewTopLevel extends ItemsViewLoaded with ItemsViewWithChildren {
  @override
  final Map<int, String> childrenIdNameMap;
  const ItemsViewTopLevel({
    required super.allItems,
    required this.childrenIdNameMap,
  });
  @override
  List<Object?> get props => [
        ...super.props,
        childrenIdNameMap,
      ];
}

sealed class ItemsViewNonTopLevel extends ItemsViewLoaded {
  final String niceParentPath;
  final NonRoot currentItem;
  final List<String> currentItemImagePaths;
  final bool isEditMode;
  const ItemsViewNonTopLevel({
    required super.allItems,
    required this.currentItem,
    required this.niceParentPath,
    required this.currentItemImagePaths,
    required this.isEditMode,
  });
  @override
  List<Object?> get props => [
        ...super.props,
        currentItem,
        niceParentPath,
        currentItemImagePaths,
        isEditMode,
      ];
}

class ItemsViewInternalLevel extends ItemsViewNonTopLevel
    with ItemsViewWithChildren {
  @override
  final Map<int, String> childrenIdNameMap;
  const ItemsViewInternalLevel({
    required super.allItems,
    required super.currentItem,
    required this.childrenIdNameMap,
    required super.niceParentPath,
    required super.currentItemImagePaths,
    required super.isEditMode,
  });
  @override
  List<Object?> get props => [
        ...super.props,
        childrenIdNameMap,
      ];
}

class ItemsViewLeafLevel extends ItemsViewNonTopLevel {
  const ItemsViewLeafLevel({
    required super.allItems,
    required super.currentItem,
    required super.niceParentPath,
    required super.currentItemImagePaths,
    required super.isEditMode,
  });
}
