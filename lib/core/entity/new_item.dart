import 'package:things_map/core/constants.dart';
import 'package:things_map/core/entity/owner.dart';

enum ItemType {
  internal,
  leaf,
}

class NewItem {
  final int? editingId;
  final int parentId;
  final String name;
  final BigInt? price;
  final double quantity;
  final String? extraNotes;
  final List<Owner> owners;
  final DateTime lastUpdated;
  final ItemType itemType;
  const NewItem({
    this.editingId,
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

  bool get isEditingExisting => editingId != null;
}
