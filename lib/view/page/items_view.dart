import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/core/entity/owner.dart';
import 'package:things_map/core/init_setup.dart';
import 'package:things_map/cubit/items_view_cubit.dart';
import 'package:things_map/view/widgets/image_tile.dart';
import 'package:things_map/view/widgets/item_info_text_field.dart';
import 'package:things_map/view/widgets/list_heading.dart';
import 'package:things_map/view/widgets/owners_chip.dart';

class ItemsView extends StatefulWidget {
  const ItemsView({super.key});

  @override
  State<ItemsView> createState() => _ItemsViewState();
}

class _ItemsViewState extends State<ItemsView> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  bool _canContainItems = true;
  final _formKey = GlobalKey<FormState>();
  Map<Owner, bool> _ownerSelection = {};
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ItemsViewCubit(thingsRepository: sl()),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Thing Map"),
        ),
        body: BlocConsumer<ItemsViewCubit, ItemsViewState>(
          listener: (context, state) {
            if (state case ItemsViewError(:final error, :final stackTrace)) {
              print(error);
              print(stackTrace);
            }

            if (state
                case ItemsViewEdit(:final allOwners, :final editingItem)) {
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
                                context.read<ItemsViewCubit>().goToItemWithId(
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
                          ItemsViewNonTopLevel(currentItem: NonRoot? item) ||
                          ItemsViewEdit(editingItem: NonRoot? item) =>
                            [
                              ExpansionTile(
                                // childrenPadding: EdgeInsets.zero,
                                key: Key(
                                    "Item:${item?.id ?? -1}${state.runtimeType}"),
                                shape: Border(),
                                title: Text(
                                  item?.name ?? "New Item",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                initiallyExpanded: state is ItemsViewEdit,
                                children: [
                                  Visibility(
                                    visible: (state
                                            is ItemsViewInternalLevel) &&
                                        state.currentItemImagePaths.isNotEmpty,
                                    child:
                                        //  AspectRatio(
                                        //   aspectRatio: 1,
                                        //   child:
                                        SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: ImageTile(
                                        imagePaths:
                                            (state is ItemsViewInternalLevel)
                                                ? state.currentItemImagePaths
                                                : [],
                                      ),
                                    ),
                                    // ),
                                  ),
                                  ItemInfoTextFormField(
                                    readOnly: state is! ItemsViewEdit,
                                    label: "Name",
                                    initialValue: item?.name ?? "",
                                    controller: _nameController,
                                    validator: (string) {
                                      if (string == null || string.isEmpty) {
                                        return "Enter a valid name";
                                      } else {
                                        return null;
                                      }
                                    },
                                  ),
                                  ItemInfoTextFormField(
                                    readOnly: state is! ItemsViewEdit,
                                    label: "Price",
                                    initialValue: item?.price?.toString() ??
                                        ((state is ItemsViewEdit)
                                            ? ""
                                            : "Unknown"),
                                    controller: _priceController,
                                    validator: (string) {
                                      if (string == null || string.isEmpty) {
                                        return null;
                                      } else {
                                        final price = BigInt.tryParse(string);
                                        return (price == null)
                                            ? "Invalid price"
                                            : null;
                                      }
                                    },
                                  ),
                                  ItemInfoTextFormField(
                                    readOnly: state is! ItemsViewEdit,
                                    label: "Quantity",
                                    initialValue: switch (item?.quantity) {
                                      null => "1",
                                      double() =>
                                        item!.quantity.toStringAsFixed(
                                          (item.quantity.toInt() ==
                                                  item.quantity)
                                              ? 0
                                              : 2,
                                        ),
                                    },
                                    controller: _quantityController,
                                    validator: (string) {
                                      final quantity =
                                          double.tryParse(string ?? "");
                                      if (string == null ||
                                          string.isEmpty ||
                                          quantity == null ||
                                          quantity <= 0) {
                                        return "Enter a valid quantity";
                                      } else {
                                        return null;
                                      }
                                    },
                                  ),
                                  OwnersChip(
                                    readOnly: state is! ItemsViewEdit,
                                    ownersSelectionMap: switch (state) {
                                      ItemsViewNonTopLevel(
                                        :final currentItem
                                      ) =>
                                        Map.fromEntries(
                                          currentItem.owners.map(
                                            (e) {
                                              return MapEntry(e, true);
                                            },
                                          ),
                                        ),
                                      ItemsViewEdit() => _ownerSelection,
                                      _ => {},
                                    },
                                    onSelect: (owner, selected) {
                                      setState(() {
                                        _ownerSelection[owner] = selected;
                                      });
                                    },
                                  ),
                                  ItemInfoTextFormField(
                                    readOnly: state is! ItemsViewEdit,
                                    label: "Notes",
                                    initialValue:
                                        item?.extraNotes?.toString() ??
                                            ((state is ItemsViewEdit)
                                                ? ""
                                                : "<Blank>"),
                                    controller: _notesController,
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  Visibility(
                                    visible: state is ItemsViewEdit,
                                    child: ListTile(
                                      title: Text("Can contain items"),
                                      trailing: Switch(
                                        value: _canContainItems,
                                        onChanged: (value) {
                                          setState(() {
                                            _canContainItems = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
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
                                  return ListTile(
                                    title: Text(item.name),
                                    trailing: Icon(Icons.arrow_forward),
                                    onTap: () {
                                      context
                                          .read<ItemsViewCubit>()
                                          .goToItemWithId(
                                            id: item.id,
                                            straightToEditMode: false,
                                          );
                                    },
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
                          _ => []
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
                ):
                return FloatingActionButton.extended(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final newItem = NewItem(
                        editingId: editingItem?.id,
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
                      await context.read<ItemsViewCubit>().saveItem(
                            newItem: newItem,
                            oldItem: editingItem,
                          );
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
  }
}
