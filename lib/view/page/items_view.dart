import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/core/init_setup.dart';
import 'package:things_map/cubit/items_view_cubit.dart';
import 'package:things_map/view/widgets/image_tile.dart';
import 'package:path/path.dart' as p;
import 'package:things_map/view/widgets/item_info_text_field.dart';
import 'package:things_map/view/widgets/list_heading.dart';

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
                        ...switch (state) {
                          ItemsViewTopLevel() => [
                              ListHeading("Top Level"),
                            ],
                          ItemsViewNonTopLevel(
                            :final currentItem,
                            :final niceParentPath,
                            :final isEditMode,
                            :final currentItemImagePaths,
                          ) =>
                            [
                              ListTile(
                                title: Text(
                                  niceParentPath,
                                ),
                                leading: Icon(Icons.arrow_back),
                                onTap: () {
                                  context.read<ItemsViewCubit>().goBack();
                                },
                              ),
                              Divider(),
                              ExpansionTile(
                                // childrenPadding: EdgeInsets.zero,
                                key: Key("Item:${currentItem.id}"),
                                shape: Border(),
                                title: Text(
                                  currentItem.name.isEmpty
                                      ? "New item"
                                      : currentItem.name,
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
                                initiallyExpanded: isEditMode,
                                children: [
                                  Visibility(
                                    visible: currentItemImagePaths.isNotEmpty,
                                    child:
                                        //  AspectRatio(
                                        //   aspectRatio: 1,
                                        //   child:
                                        SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: ImageTile(
                                        imagePaths: currentItemImagePaths,
                                      ),
                                    ),
                                    // ),
                                  ),
                                  ItemInfoTextFormField(
                                    readOnly: !isEditMode,
                                    label: "Name",
                                    initialValue: currentItem.name,
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
                                    readOnly: !isEditMode,
                                    label: "Price",
                                    initialValue:
                                        currentItem.price?.toString() ??
                                            ((isEditMode) ? "" : "Unknown"),
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
                                    readOnly: !isEditMode,
                                    label: "Quantity",
                                    initialValue:
                                        currentItem.quantity.toStringAsFixed(
                                      (currentItem.quantity.toInt() ==
                                              currentItem.quantity)
                                          ? 0
                                          : 2,
                                    ),
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
                                  ItemInfoTextFormField(
                                    readOnly: !isEditMode,
                                    label: "Notes",
                                    initialValue:
                                        currentItem.extraNotes?.toString() ??
                                            ((isEditMode) ? "" : "<Blank>"),
                                    controller: _notesController,
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  Visibility(
                                    visible: isEditMode,
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
                            childrenIdNameMap: final childrenNames,
                          ) =>
                            [
                              ListHeading("Contains"),
                              ...childrenNames.entries.map(
                                (entry) {
                                  return ListTile(
                                    title: Text(entry.value),
                                    trailing: Icon(Icons.arrow_forward),
                                    onTap: () {
                                      //TODO: do it
                                    },
                                  );
                                },
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
              case ItemsViewLeafLevel():
                return Container();
              case ItemsViewNonTopLevel(
                  :final isEditMode,
                  :final currentItem,
                ):
                return FloatingActionButton.extended(
                  onPressed: () async {
                    switch (isEditMode) {
                      case true:
                        if (_formKey.currentState!.validate()) {
                          final newItem = NewItem(
                            parentId: currentItem.parentId,
                            name: _nameController.text,
                            price: BigInt.tryParse(_priceController.text),
                            quantity: double.parse(_quantityController.text),
                            extraNotes: _notesController.text,
                            owners: [],
                            lastUpdated: DateTime.now(),
                            itemType: _canContainItems
                                ? ItemType.internal
                                : ItemType.leaf,
                          );
                          await context.read<ItemsViewCubit>().saveItem(
                                newItem: newItem,
                              );
                        }
                      case false:
                        await context.read<ItemsViewCubit>().showAddItem();
                    }
                  },
                  label: isEditMode ? Text("Save") : Text("Add item"),
                  icon: Icon(
                    isEditMode ? Icons.save : Icons.add,
                  ),
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
