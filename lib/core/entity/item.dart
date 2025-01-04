import 'package:equatable/equatable.dart';
import 'package:things_map/core/entity/owner.dart';
import 'package:path/path.dart' as p;
import 'dart:io' as io;

sealed class Item extends Equatable {
  // In our implementation, we use file system-like structure. Each id is like a
  // path, where "/" is the root id and an id of "/a/b/c" means c is under b is
  // under a. This makes it easier to find things and get the parent, sibling
  // relation in (I think) O(logn) time.
  final String pathId;

  final String name;
  final BigInt? price;
  final double quantity;
  final String? extraNotes;
  final List<Owner> owners;
  final DateTime lastUpdated;
  const Item({
    required this.pathId,
    required this.name,
    this.price,
    this.quantity = 1,
    this.extraNotes,
    required this.owners,
    required this.lastUpdated,
  });
  @override
  List<Object?> get props => [
        pathId,
        name,
        price,
        owners,
        quantity,
        extraNotes,
        lastUpdated,
      ];
}

extension IDOps on Item {
  /// Get the actual ID of the item as integer, intead of the whole path
  int get baseId {
    return int.parse(p.basename(pathId));
  }

  String get parentPathId {
    return io.File(pathId).parent.path;
  }
}

/// An [Item] that cannot contain anything, ex: 5 Volt Battery
class LeafItem extends Item {
  const LeafItem({
    required super.pathId,
    required super.name,
    super.price,
    super.quantity,
    super.extraNotes,
    required super.owners,
    required super.lastUpdated,
  });
}

/// This is just like [LeafItem], except that it can contain other [Item]s
class InternalItem extends Item {
  final List<Item> items;
  const InternalItem({
    required super.pathId,
    required super.name,
    super.price,
    super.quantity,
    super.extraNotes,
    required this.items,
    required super.owners,
    required super.lastUpdated,
  });
  @override
  List<Object?> get props => [
        items,
        ...super.props,
      ];
}

class Root extends InternalItem {
  const Root({
    required super.items,
    required super.lastUpdated,
  }) : super(
          owners: const [],
          pathId: "/",
          name: "Root",
        );
}
