import 'package:things_map/core/constants.dart';
import 'package:things_map/core/entity/owner.dart';
import 'package:path/path.dart' as p;

enum ItemType {
  internal,
  leaf,
}

class NewItem {
  final String parentPathId;
  final String name;
  final BigInt? price;
  final double quantity;
  final String? extraNotes;
  final List<Owner> owners;
  final DateTime lastUpdated;
  final ItemType itemType;
  const NewItem({
    required this.parentPathId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.extraNotes,
    required this.owners,
    required this.lastUpdated,
    required this.itemType,
  });
  bool get isImmediateChildOfRoot {
    return parentPathId == rootDir.path;
  }

  int get parentBaseId {
    return int.parse(p.basename(parentPathId));
  }
}
