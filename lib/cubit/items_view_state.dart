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

class ItemsViewLoaded extends ItemsViewState with EquatableMixin {
  final Root rootItem;
  final Item currentItem;
  final String niceParentPath;
  final List<String> currentItemImagePaths;
  final bool isEditMode;
  const ItemsViewLoaded({
    required this.rootItem,
    required this.currentItem,
    required this.niceParentPath,
    required this.currentItemImagePaths,
    required this.isEditMode,
  });
  @override
  List<Object?> get props => [
        rootItem,
        currentItem,
        niceParentPath,
        currentItemImagePaths,
        isEditMode,
      ];
}
