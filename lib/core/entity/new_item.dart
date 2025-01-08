import 'package:things_map/core/constants.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/owner.dart';

enum ItemType {
  internal,
  leaf,
}

class NewItem {
  final NonRoot? editingItem;
  final int parentId;
  final String name;
  final BigInt? price;
  final double quantity;
  final String? extraNotes;
  final List<Owner> owners;
  final DateTime lastUpdated;
  final ItemType itemType;
  const NewItem({
    this.editingItem,
    required this.parentId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.extraNotes,
    required this.owners,
    required this.lastUpdated,
    required this.itemType,
  });
  bool get isTopLevelItem {
    return parentId == rootId;
  }

  bool get isEditingExisting => editingItem != null;
  factory NewItem.fromNonRoot({
    required NonRoot item,
    int? parentId,
    String? name,
    BigInt? price,
    double? quantity,
    String? extraNotes,
    List<Owner>? owners,
    DateTime? lastUpdated,
  }) {
    return NewItem(
      editingItem: item,
      parentId: parentId ?? item.parentId,
      name: name ?? item.name,
      price: price ?? item.price,
      quantity: quantity ?? item.quantity,
      extraNotes: extraNotes ?? item.extraNotes,
      owners: owners ?? item.owners,
      lastUpdated: lastUpdated ?? item.lastUpdated,
      itemType: item is InternalItem ? ItemType.internal : ItemType.leaf,
    );
  }
}
