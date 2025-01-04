import 'package:equatable/equatable.dart';
import 'package:things_map/core/constants.dart';
import 'package:things_map/core/entity/owner.dart';

sealed class Item extends Equatable {
  // In this implementation, each item will have a unique integer as its id
  final int id;
  final DateTime lastUpdated;
  const Item({
    required this.id,
    required this.lastUpdated,
  });
  @override
  List<Object?> get props => [
        id,
        lastUpdated,
      ];
}

mixin ItemWithChildren {
  List<int> get children;
}

class Root extends Item with EquatableMixin, ItemWithChildren {
  @override
  final List<int> children;
  const Root({
    required this.children,
    required super.lastUpdated,
  }) : super(id: 0);
  @override
  List<Object?> get props => [
        ...super.props,
        children,
      ];
}

sealed class NonRoot extends Item with EquatableMixin {
  final int parentId;
  final String name;
  final BigInt? price;
  final double quantity;
  final String? extraNotes;
  final List<Owner> owners;
  const NonRoot({
    required super.id,
    required this.parentId,
    required this.name,
    this.price,
    this.quantity = 1,
    this.extraNotes,
    required this.owners,
    required super.lastUpdated,
  });
  @override
  List<Object?> get props => [
        ...super.props,
        parentId,
        name,
        price,
        quantity,
        extraNotes,
        owners,
      ];
}

extension IsTopLevelItem on NonRoot {
  bool get isTopLevelItem {
    return parentId == rootId;
  }
}

/// An [NonRoot] that cannot contain anything, ex: 5 Volt Battery
class LeafItem extends NonRoot {
  const LeafItem({
    required super.id,
    required super.parentId,
    required super.name,
    super.price,
    super.quantity,
    super.extraNotes,
    required super.owners,
    required super.lastUpdated,
  });
}

/// This is just like [LeafItem], except that it can contain other [NonRoot]s
class InternalItem extends NonRoot with ItemWithChildren {
  @override
  final List<int> children;
  const InternalItem({
    required super.id,
    required super.parentId,
    required super.name,
    super.price,
    super.quantity,
    super.extraNotes,
    required this.children,
    required super.owners,
    required super.lastUpdated,
  });
  @override
  List<Object?> get props => [
        ...super.props,
        children,
      ];
}
