import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:things_map/core/constants.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/cubit/items_view_cubit.dart';

class ChildItem extends StatelessWidget {
  final NonRoot item;
  const ChildItem({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: ListTile(
        title: Text(item.name),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          context.read<ItemsViewCubit>().goToItemWithId(
                id: item.id,
                straightToEditMode: false,
              );
        },

        // ),
      ),
      onLongPressStart: (details) {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx + 40,
            details.globalPosition.dy + 15,
          ),
          items: [
            PopupMenuItem(
              onTap: () {
                final snack = SnackBar(
                  content: Row(
                    children: [
                      Text("Copying ${item.name}"),
                      Spacer(),
                      IconButton(
                        onPressed: () async {
                          final latestState =
                              context.read<ItemsViewCubit>().state;
                          switch (latestState) {
                            case ItemsViewNonTopLevel(:final currentItem)
                                when currentItem.id != item.id:
                              await context.read<ItemsViewCubit>().saveItem(
                                    newItem: NewItem.fromNonRoot(
                                      item: item,
                                      parentId: currentItem.id,
                                    ),
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).clearSnackBars();
                              }

                            case ItemsViewTopLevel():
                              await context.read<ItemsViewCubit>().saveItem(
                                    newItem: NewItem.fromNonRoot(
                                      item: item,
                                      parentId: rootId,
                                    ),
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).clearSnackBars();
                              }
                            default:
                              break;
                          }
                        },
                        icon: Icon(
                          Icons.paste,
                          color: Theme.of(context)
                              .buttonTheme
                              .colorScheme
                              ?.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  duration: Duration(days: 365),
                );
                ScaffoldMessenger.of(context).showSnackBar(snack);
              },
              child: Row(
                children: [
                  Icon(Icons.cut),
                  SizedBox(
                    width: 5,
                  ),
                  Text("Cut"),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () async {
                await context.read<ItemsViewCubit>().deleteItem(
                      item: item,
                    );
              },
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(
                    width: 5,
                  ),
                  Text("Delete"),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
