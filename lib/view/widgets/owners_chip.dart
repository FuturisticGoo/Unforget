import 'package:flutter/material.dart';
import 'package:things_map/core/entity/owner.dart';

class OwnersChip extends StatefulWidget {
  final bool readOnly;
  final String label;
  final Map<Owner, bool> ownerSelectionMap;
  final void Function(Owner owner, bool selection) onSelected;
  final void Function(Owner owner) onDeleted;
  final void Function(Owner owner) onNew;
  const OwnersChip({
    super.key,
    required this.readOnly,
    required this.label,
    required this.ownerSelectionMap,
    required this.onSelected,
    required this.onDeleted,
    required this.onNew,
  });

  @override
  State<OwnersChip> createState() => _OwnersChipState();
}

class _OwnersChipState extends State<OwnersChip> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          widget.readOnly ? 4 : 16, 8, 16, widget.readOnly ? 0 : 8),
      child: TextField(
        readOnly: widget.readOnly,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          label: Text(widget.label),
          border: widget.readOnly
              ? OutlineInputBorder(borderSide: BorderSide.none)
              : OutlineInputBorder(),
          // border: OutlineInputBorder(),
          focusedBorder: widget.readOnly
              ? OutlineInputBorder(borderSide: BorderSide.none)
              : null,
          enabledBorder: widget.readOnly
              ? OutlineInputBorder(borderSide: BorderSide.none)
              : null,
          prefixIconConstraints:
              BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.9),
          prefixIcon: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: EdgeInsets.only(
                top: 12,
                bottom: widget.readOnly ? 0 : 12,
                left: 12,
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Wrap(
                  runSpacing: 4.0,
                  spacing: 4.0,
                  children: [
                    ...widget.ownerSelectionMap.keys.map(
                      (Owner owner) {
                        return FilterChip(
                          selected: widget.ownerSelectionMap[owner] ?? false,
                          label: Text(owner.name),
                          deleteIcon: Icon(Icons.close),
                          onDeleted: () {
                            if (!widget.readOnly) {
                              widget.onDeleted(owner);
                            }
                          },
                          onSelected: (selected) {
                            if (!widget.readOnly) {
                              widget.onSelected(owner, selected);
                            }
                          },
                        );
                      },
                    ),
                    Visibility(
                      visible: widget.ownerSelectionMap.keys.isEmpty &&
                          widget.readOnly,
                      child: FilterChip(
                        label: Text("None"),
                        onSelected: (_) {},
                      ),
                    ),
                    Visibility(
                      visible: !widget.readOnly,
                      child: FilterChip(
                        label: Text("+"),
                        onSelected: (selected) async {
                          final newOwner = await showNewOwnerAddDialog(
                            context,
                            titleText: "New owner name",
                            textLabel: "Name",
                          );
                          switch (newOwner) {
                            case null:
                              break;
                            case String():
                              widget.onNew(Owner(name: newOwner));
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> showNewOwnerAddDialog(
  BuildContext context, {
  required String titleText,
  required String textLabel,
  String positiveButtonText = "Add",
}) {
  return showAdaptiveDialog<String?>(
    context: context,
    builder: (context) {
      String newTagsText = "";
      return SimpleDialog(
        title: Text(titleText),
        contentPadding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            maxLines: 1,
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              label: Text(textLabel),
            ),
            onChanged: (value) {
              newTagsText = value;
            },
          ),
          const SizedBox(
            height: 20,
          ),
          Builder(
            builder: (context) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        newTagsText.trim().isEmpty ? null : newTagsText.trim(),
                      );
                    },
                    child: Text(positiveButtonText),
                  ),
                ],
              );
            },
          )
        ],
      );
    },
  );
}
