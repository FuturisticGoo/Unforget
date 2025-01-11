import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/core/entity/owner.dart';
import 'package:things_map/core/init_setup.dart';
import 'package:things_map/cubit/items_view_cubit.dart';
import 'package:things_map/view/widgets/child_item.dart';
import 'package:things_map/view/widgets/item_info_expansion.dart';
import 'package:things_map/view/widgets/list_heading.dart';
import 'package:things_map/view/widgets/select_image.dart';

class ItemsView extends StatefulWidget {
  const ItemsView({super.key});

  @override
  State<ItemsView> createState() => _ItemsViewState();
}

class _ItemsViewState extends State<ItemsView> {
  final _searchTextController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  bool _canContainItems = true;
  final _formKey = GlobalKey<FormState>();
  Map<Owner, bool> _ownerSelection = {};

  @override
  void dispose() {
    _searchTextController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ItemsViewCubit(itemsRepository: sl()),
      child: Builder(builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              return;
            }
            final state = context.read<ItemsViewCubit>().state;
            switch (state) {
              case ItemsViewCanGoUpward(:final parentId):
                context.read<ItemsViewCubit>().goToItemWithId(
                      id: parentId,
                      straightToEditMode: false,
                    );
              default:
                SystemNavigator.pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text("Unforget"),
              actions: [
                BlocBuilder<ItemsViewCubit, ItemsViewState>(
                  builder: (context, state) {
                    switch (state) {
                      case ItemsViewLoaded():
                        return IconButton(
                          onPressed: () async {
                            if (state case ItemsViewSearch(:final lastItemId)) {
                              context.read<ItemsViewCubit>().goToItemWithId(
                                    id: lastItemId,
                                    straightToEditMode: false,
                                  );
                            } else {
                              await context
                                  .read<ItemsViewCubit>()
                                  .searchForItem(searchTerm: "");
                            }
                          },
                          icon: Icon(Icons.search),
                        );
                      default:
                        return Container();
                    }
                  },
                ),
              ],
            ),
            body: BlocConsumer<ItemsViewCubit, ItemsViewState>(
              listener: (context, state) {
                switch (state) {
                  case ItemsViewEdit(:final allOwners, :final editingItem):
                    final alreadySelected = editingItem?.owners ?? [];
                    setState(
                      () {
                        _ownerSelection = Map.fromEntries(
                          allOwners.map(
                            (e) {
                              return MapEntry(e, alreadySelected.contains(e));
                            },
                          ),
                        );
                      },
                    );
                  case ItemsViewNonTopLevel(:final currentItem):
                    _ownerSelection = Map.fromEntries(
                      currentItem.owners.map(
                        (owner) => MapEntry(owner, true),
                      ),
                    );
                  case ItemsViewError(:final error, :final stackTrace):
                    print(error);
                    print(stackTrace);
                  default:
                    break;
                }
              },
              builder: (context, state) {
                switch (state) {
                  case ItemsViewInitial():
                  case ItemsViewLoading():
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  case ItemsViewError(:final error, :final stackTrace):
                    return ErrorWidget.withDetails(
                      message: "$error\n$stackTrace",
                    );
                  case ItemsViewSearch(
                      :final searchResults,
                    ):
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            autofocus: true,
                            controller: _searchTextController,
                            decoration: InputDecoration(
                              label: Text("Search"),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  _searchTextController.clear();
                                  context
                                      .read<ItemsViewCubit>()
                                      .searchForItem(searchTerm: "");
                                },
                                icon: Icon(
                                  Icons.close,
                                ),
                              ),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) async {
                              context.read<ItemsViewCubit>().searchForItem(
                                    searchTerm: value,
                                  );
                            },
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(
                                    searchResults[index].name,
                                  ),
                                  onTap: () async {
                                    _searchTextController.clear();
                                    await context
                                        .read<ItemsViewCubit>()
                                        .goToItemWithId(
                                          id: searchResults[index].id,
                                          straightToEditMode: false,
                                        );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  case ItemsViewLoaded():
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          children: [
                            ListTile(
                              title: Text(
                                switch (state) {
                                  ItemsViewCanGoUpward(
                                    nicePath: final niceParentPath
                                  ) =>
                                    niceParentPath,
                                  _ => ""
                                },
                              ),
                              leading: Icon(Icons.arrow_back),
                              enabled: (state is ItemsViewCanGoUpward),
                              onTap: () {
                                switch (state) {
                                  case ItemsViewCanGoUpward(:final parentId):
                                    context
                                        .read<ItemsViewCubit>()
                                        .goToItemWithId(
                                          id: parentId,
                                          straightToEditMode: false,
                                        );
                                  default:
                                    break;
                                }
                              },
                            ),
                            Divider(),
                            ...switch (state) {
                              ItemsViewTopLevel() => [
                                  ListHeading("Top Level"),
                                ],
                              ItemsViewSearch() => [],
                              ItemsViewNonTopLevel(
                                currentItem: NonRoot? item
                              ) ||
                              ItemsViewEdit(editingItem: NonRoot? item) =>
                                [
                                  ItemInfoExpansion(
                                    item: item,
                                    state: state,
                                    formKey: _formKey,
                                    nameController: _nameController,
                                    priceController: _priceController,
                                    quantityController: _quantityController,
                                    notesController: _notesController,
                                    canContainItems: _canContainItems,
                                    ownerSelection: _ownerSelection,
                                    isReadOnly: state is! ItemsViewEdit,
                                    onItemTypeChange: (canContainItems) {
                                      setState(() {
                                        _canContainItems = canContainItems;
                                      });
                                    },
                                    onSelectOwner: (owner, selected) {
                                      setState(() {
                                        _ownerSelection[owner] = selected;
                                      });
                                    },
                                    onDeleteOwner: (owner) {
                                      setState(() {
                                        _ownerSelection.remove(owner);
                                      });
                                    },
                                    onNewOwner: (owner) {
                                      setState(() {
                                        _ownerSelection[owner] = true;
                                      });
                                      context
                                          .read<ItemsViewCubit>()
                                          .addNewOwner(owner: owner);
                                    },
                                    onAddImageTap: (useCamera) async {
                                      final images =
                                          await getImages(useCamera: useCamera);
                                      if (images != null && context.mounted) {
                                        await context
                                            .read<ItemsViewCubit>()
                                            .addImage(
                                              imagesToAdd: images,
                                            );
                                      }
                                    },
                                  ),
                                ],
                            },
                            Divider(),
                            ...switch (state) {
                              ItemsViewWithChildren(
                                :final children,
                              ) =>
                                [
                                  ListHeading("Contains"),
                                  ...children.map(
                                    (item) {
                                      return ChildItem(
                                        scaffoldContext: context,
                                        item: item,
                                      );
                                    },
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Center(
                                    child: OutlinedButton.icon(
                                      icon: Icon(Icons.add),
                                      onPressed: () async {
                                        await context
                                            .read<ItemsViewCubit>()
                                            .showAddOrEditItem();
                                      },
                                      label: Text("Add item"),
                                    ),
                                  )
                                ],
                              _ => [
                                  SizedBox(
                                    height: 300,
                                  )
                                ]
                            },
                          ],
                        ),
                      ),
                    );
                }
              },
            ),
            floatingActionButton: BlocBuilder<ItemsViewCubit, ItemsViewState>(
              builder: (context, state) {
                switch (state) {
                  case ItemsViewEdit(
                      :final parentId,
                      :final editingItem,
                      :final newImages,
                    ):
                    return FloatingActionButton.extended(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final newItem = NewItem(
                            editingItem: editingItem,
                            parentId: parentId,
                            name: _nameController.text,
                            price: BigInt.tryParse(_priceController.text),
                            quantity: double.parse(_quantityController.text),
                            extraNotes: _notesController.text,
                            owners: _ownerSelection.entries
                                .where(
                                  (o) => o.value,
                                )
                                .map(
                                  (e) => e.key,
                                )
                                .toList(),
                            lastUpdated: DateTime.now(),
                            itemType: _canContainItems
                                ? ItemType.internal
                                : ItemType.leaf,
                          );

                          if (context.mounted) {
                            await context.read<ItemsViewCubit>().saveItem(
                                  newItem: newItem,
                                  images: newImages,
                                );
                          }
                        }
                      },
                      icon: Icon(Icons.save),
                      label: Text("Save"),
                    );
                  case ItemsViewNonTopLevel(:final currentItem):
                    return FloatingActionButton.extended(
                      onPressed: () async {
                        await context.read<ItemsViewCubit>().showAddOrEditItem(
                              editingItem: currentItem,
                            );
                      },
                      icon: Icon(Icons.edit),
                      label: Text("Edit"),
                    );
                  default:
                    return Container();
                }
              },
            ),
          ),
        );
      }),
    );
  }
}
