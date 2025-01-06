import 'package:flutter/material.dart';
import 'package:things_map/core/entity/owner.dart';

class OwnersChip extends StatefulWidget {
  final Map<Owner, bool> ownersSelectionMap;
  final void Function(Owner owner, bool selected) onSelect;
  final bool readOnly;
  const OwnersChip({
    super.key,
    required this.ownersSelectionMap,
    required this.onSelect,
    required this.readOnly,
  });

  @override
  State<OwnersChip> createState() => _OwnersChipState();
}

class _OwnersChipState extends State<OwnersChip> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: EdgeInsets.all((widget.readOnly) ? 0 : 8),
            decoration: BoxDecoration(
              border: (widget.readOnly)
                  ? Border.all(color: Colors.transparent)
                  : Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Owners: "),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width -
                        60, // MAGIC VALUE OOoo
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 5.0,
                        runSpacing: 5.0,
                        children: widget.ownersSelectionMap.entries
                            .where(
                              (ownerEntry) =>
                                  (widget.readOnly && ownerEntry.value) ||
                                  !widget.readOnly,
                            )
                            .map(
                              (ownerEntry) => FilterChip(
                                label: Text(ownerEntry.key.name),
                                selected: ownerEntry.value,
                                onSelected: (selected) =>
                                    widget.onSelect(ownerEntry.key, selected),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
