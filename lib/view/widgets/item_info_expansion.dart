import 'package:flutter/material.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/owner.dart';
import 'package:things_map/cubit/items_view_cubit.dart';
import 'package:things_map/view/widgets/image_tile.dart';
import 'package:things_map/view/widgets/item_info_text_field.dart';
import 'package:things_map/view/widgets/owners_chip.dart';

class ItemInfoExpansion extends StatefulWidget {
  final ItemsViewState state;
  final NonRoot? item;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController quantityController;
  final TextEditingController notesController;
  final void Function(bool canContainItems) onItemTypeChange;
  final void Function(Owner owner, bool selected) onSelectOwner;
  final void Function(Owner owner) onDeleteOwner;
  final void Function(Owner owner) onNewOwner;
  final void Function(bool useCamera) onAddImageTap;
  final Map<Owner, bool> ownerSelection;
  final GlobalKey<FormState> formKey;
  final bool isReadOnly;
  final bool canContainItems;
  const ItemInfoExpansion({
    super.key,
    required this.isReadOnly,
    required this.item,
    required this.state,
    required this.nameController,
    required this.priceController,
    required this.quantityController,
    required this.notesController,
    required this.onItemTypeChange,
    required this.formKey,
    required this.onSelectOwner,
    required this.onDeleteOwner,
    required this.onNewOwner,
    required this.ownerSelection,
    required this.canContainItems,
    required this.onAddImageTap,
  });

  @override
  State<ItemInfoExpansion> createState() => _ItemInfoExpansionState();
}

class _ItemInfoExpansionState extends State<ItemInfoExpansion> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      // childrenPadding: EdgeInsets.zero,
      key: Key("Item:${widget.item?.id ?? -1}${widget.state.runtimeType}"),
      shape: Border(),
      title: Text(
        widget.item?.name ?? "New Item",
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
      initiallyExpanded: widget.state is ItemsViewEdit,
      children: [
        Visibility(
          visible: switch (widget.state) {
            ItemsViewNonTopLevel(:final currentItemImagePaths) =>
              currentItemImagePaths.isNotEmpty,
            _ => true,
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.9,
              maxHeight: 200,
            ),
            child: ImageTile(
              isReadOnly: widget.isReadOnly,
              imagePaths: switch (widget.state) {
                ItemsViewNonTopLevel(:final currentItemImagePaths) ||
                ItemsViewEdit(:final currentItemImagePaths) =>
                  currentItemImagePaths,
                _ => []
              },
              onImageTap: (index) {},
              onAddImageTap: widget.onAddImageTap,
            ),
          ),
        ),
        ItemInfoTextFormField(
          readOnly: widget.isReadOnly,
          label: "Name",
          initialValue: widget.item?.name ?? "",
          controller: widget.nameController,
          validator: (string) {
            if (string == null || string.isEmpty) {
              return "Enter a valid name";
            } else {
              return null;
            }
          },
        ),
        ItemInfoTextFormField(
          readOnly: widget.isReadOnly,
          label: "Price",
          initialValue: widget.item?.price?.toString() ??
              ((widget.state is ItemsViewEdit) ? "" : "Unknown"),
          controller: widget.priceController,
          validator: (string) {
            if (string == null || string.isEmpty) {
              return null;
            } else {
              final price = BigInt.tryParse(string);
              return (price == null) ? "Invalid price" : null;
            }
          },
        ),
        ItemInfoTextFormField(
          readOnly: widget.isReadOnly,
          label: "Quantity",
          initialValue: switch (widget.item?.quantity) {
            null => "1",
            double() => widget.item!.quantity.toStringAsFixed(
                (widget.item!.quantity.toInt() == widget.item!.quantity)
                    ? 0
                    : 2,
              ),
          },
          controller: widget.quantityController,
          validator: (string) {
            final quantity = double.tryParse(string ?? "");
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
          readOnly: widget.isReadOnly,
          label: "Owners",
          ownerSelectionMap: widget.ownerSelection,
          onSelected: widget.onSelectOwner,
          onDeleted: widget.onDeleteOwner,
          onNew: widget.onNewOwner,
        ),
        ItemInfoTextFormField(
          readOnly: widget.isReadOnly,
          label: "Notes",
          initialValue: widget.item?.extraNotes?.toString() ??
              ((widget.state is ItemsViewEdit) ? "" : "<Blank>"),
          controller: widget.notesController,
        ),
        SizedBox(
          height: 8,
        ),
        Visibility(
          visible: widget.state is ItemsViewEdit,
          child: ListTile(
            title: Text("Can contain items"),
            trailing: Switch(
              value: widget.canContainItems,
              onChanged: widget.onItemTypeChange,
            ),
          ),
        ),
      ],
    );
  }
}
