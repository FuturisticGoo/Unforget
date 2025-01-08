import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:things_map/core/constants.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/core/entity/owner.dart';

extension _SQLOnlyColumnName on String {
  String get colName {
    return split(".").last;
  }
}

abstract class ItemsDatasource {
  Future<List<Item>> getAllItems();
  Future<int> saveOrModifyItem({
    required NewItem newItem,
  });
  Future<void> deleteItem({required int itemId});
  Future<List<Owner>> getAllOwners();
  Future<void> saveNewOwner({
    required Owner owner,
  });
  Future<List<String>> getImagePathsForItem({
    required int itemId,
  });
  Future<void> saveImagePathsForItem({
    required int itemId,
    required List<String> imagePaths,
  });
}

class ItemsDataSourceSQLite implements ItemsDatasource {
  final Database db;
  const ItemsDataSourceSQLite({required this.db});

  Future<void> _ensureTables() async {
    await db.execute("""
CREATE TABLE IF NOT EXISTS ${ItemsTable.tableName} (
  ${ItemsTable.id.colName} INTEGER PRIMARY KEY,
  ${ItemsTable.name.colName} TEXT NOT NULL,
  ${ItemsTable.canContainItems.colName} INTEGER NOT NULL,
  ${ItemsTable.price.colName} TEXT,
  ${ItemsTable.quantity.colName} REAL NOT NULL,
  ${ItemsTable.extraNotes.colName} TEXT,
  ${ItemsTable.lastUpdated.colName} TEXT
)
    """);

    await db.execute("""
CREATE TABLE IF NOT EXISTS 
  ${OwnersTable.tableName} (
    ${OwnersTable.id.colName} INTEGER PRIMARY KEY,
    ${OwnersTable.name.colName} TEXT NOT NULL
  )
    """);

    await db.execute("""
CREATE TABLE IF NOT EXISTS 
  ${ItemsOwnedByTable.tableName} (
    ${ItemsOwnedByTable.itemId.colName} INTEGER 
      REFERENCES ${ItemsTable.tableName}(${ItemsTable.id.colName}),
    ${ItemsOwnedByTable.ownerId.colName} INTEGER 
      REFERENCES ${OwnersTable.tableName}(${OwnersTable.id.colName})
  )
    """);

    await db.execute("""
CREATE TABLE IF NOT EXISTS 
  ${ItemPictures.tableName} (
    ${ItemPictures.itemId.colName} INTEGER 
      REFERENCES ${ItemsTable.tableName}(${ItemsTable.id.colName}),
    ${ItemPictures.pictureFileName.colName} TEXT 
      NOT NULL
  )
    """);

    await db.execute("""
CREATE TABLE IF NOT EXISTS 
  ${ItemIsInsideTable.tableName} (
    ${ItemIsInsideTable.itemId.colName} INTEGER 
      REFERENCES ${ItemsTable.tableName}(${ItemsTable.id.colName}),
    ${ItemIsInsideTable.containerId.colName} INTEGER 
      REFERENCES ${ItemsTable.tableName}(${ItemsTable.id.colName})
  )
    """);

    await db.execute("""
CREATE TABLE IF NOT EXISTS 
  ${TopLevelItemsTable.tableName} (
    ${TopLevelItemsTable.itemId.colName} INTEGER 
      REFERENCES ${ItemsTable.tableName}(${ItemsTable.id.colName})
  )
    """);
  }

  Future<List<Owner>> _getOwnersOfItem({required int itemId}) async {
    final ownersFinderResult = await db.rawQuery(
      """
SELECT 
  ${OwnersTable.name}
FROM 
  ${OwnersTable.tableName}
    INNER JOIN 
      ${ItemsOwnedByTable.tableName}
        ON 
          ${OwnersTable.id}=${ItemsOwnedByTable.ownerId}
WHERE
  ${ItemsOwnedByTable.itemId}=?
    """,
      [itemId],
    );
    List<Owner> owners = ownersFinderResult.map(
      (ownerRow) {
        return Owner(name: ownerRow[OwnersTable.name.colName].toString());
      },
    ).toList();
    return owners;
  }

  Future<List<int>> _getChildrenIdsOfItem({required int itemId}) async {
    final childrenFinderResult = await db.rawQuery(
      """
SELECT 
  ${ItemIsInsideTable.itemId}
FROM 
  ${ItemIsInsideTable.tableName}
WHERE
  ${ItemIsInsideTable.containerId}=?
    """,
      [itemId],
    );
    List<int> children = childrenFinderResult.map(
      (childRow) {
        return childRow[ItemIsInsideTable.itemId.colName] as int;
      },
    ).toList();
    return children;
  }

  @override
  Future<List<Item>> getAllItems() async {
    await _ensureTables();

    List<Item> allItems = [];
    final parentIdCol = "parent_id";
    final isTopLevelCol = "is_top_level";
    final allItemsResult = await db.rawQuery("""
SELECT 
	${ItemsTable.id}, 
	${ItemsTable.name}, 
	${ItemsTable.price}, 
	${ItemsTable.quantity}, 
	${ItemsTable.extraNotes}, 
	${ItemsTable.lastUpdated},
  ${ItemsTable.canContainItems},
  ${ItemIsInsideTable.containerId} as $parentIdCol,
  ${TopLevelItemsTable.itemId} as $isTopLevelCol
FROM 
	${ItemsTable.tableName} 
	LEFT JOIN 
		${ItemIsInsideTable.tableName}
			ON 
        ${ItemsTable.id}=${ItemIsInsideTable.itemId}
  LEFT JOIN
    ${TopLevelItemsTable.tableName}
      ON
        ${ItemsTable.id}=${TopLevelItemsTable.itemId};
    """);

    int id;
    int? parentId;
    bool isTopLevel, canContainItems;
    String name;
    BigInt? price;
    double quantity;
    DateTime lastUpdated;
    String? priceString, extraNotes;

    for (final row in allItemsResult) {
      id = row[ItemsTable.id.colName] as int;
      parentId = (row[parentIdCol] != null) ? row[parentIdCol] as int : null;
      isTopLevel = (row[isTopLevelCol] != null) ? true : false;
      canContainItems = (row[ItemsTable.canContainItems.colName] as int) == 1;
      priceString = row[ItemsTable.price.colName]?.toString();
      price = (priceString == null) ? null : BigInt.tryParse(priceString);
      name = row[ItemsTable.name.colName].toString();
      quantity = row[ItemsTable.quantity.colName] as double;
      extraNotes = row[ItemsTable.extraNotes.colName].toString();
      lastUpdated = DateTime.parse(
        row[ItemsTable.lastUpdated.colName].toString(),
      );
      final owners = await _getOwnersOfItem(itemId: id);
      final children = await _getChildrenIdsOfItem(itemId: id);
      if (canContainItems) {
        allItems.add(
          InternalItem(
            id: id,
            parentId: isTopLevel ? rootId : parentId!,
            name: name,
            children: children,
            owners: owners,
            lastUpdated: lastUpdated,
            price: price,
            quantity: quantity,
            extraNotes: extraNotes,
          ),
        );
      } else {
        allItems.add(
          LeafItem(
            id: id,
            parentId: isTopLevel ? rootId : parentId!,
            name: name,
            owners: owners,
            lastUpdated: lastUpdated,
            price: price,
            quantity: quantity,
            extraNotes: extraNotes,
          ),
        );
      }
    }
    return allItems;
  }

  @override
  Future<void> deleteItem({required int itemId}) async {
    await _deleteItemFromTopLevel(itemId: itemId); // NOOP if not in top level
    await _deleteOwnerRelationOfItem(itemId: itemId);
    final children = await _getChildrenIdsOfItem(itemId: itemId);
    for (final childId in children) {
      await deleteItem(itemId: childId);
    }
    await _deleteParentRelation(itemId: itemId);
    await db.rawDelete(
      """
DELETE FROM 
  ${ItemsTable.tableName}
WHERE
  ${ItemsTable.id.colName}=?
    """,
      [itemId],
    );
  }

  Future<void> _updateExisting({
    required NewItem newItem,
  }) async {
    await db.rawUpdate(
      """
UPDATE 
  ${ItemsTable.tableName}
SET
  ${ItemsTable.name.colName}=?,
  ${ItemsTable.canContainItems.colName}=?,
  ${ItemsTable.price.colName}=?,
  ${ItemsTable.quantity.colName}=?,
  ${ItemsTable.extraNotes.colName}=?,
  ${ItemsTable.lastUpdated.colName}=?
WHERE
  ${ItemsTable.id}=?
      """,
      [
        newItem.name,
        newItem.itemType == ItemType.internal ? 1 : 0,
        newItem.price?.toString() ?? newItem.editingItem?.price.toString(),
        newItem.quantity,
        newItem.extraNotes ?? newItem.editingItem?.extraNotes,
        newItem.lastUpdated.toIso8601String(),
        newItem.editingItem?.id ?? newItem.editingItem?.id,
      ],
    );
  }

  Future<int> _insertNewItem({
    required NewItem newItem,
  }) async {
    return await db.rawInsert(
      """
INSERT INTO
  ${ItemsTable.tableName}
  (
    ${ItemsTable.name.colName},
    ${ItemsTable.canContainItems.colName},
    ${ItemsTable.price.colName},
    ${ItemsTable.quantity.colName},
    ${ItemsTable.extraNotes.colName},
    ${ItemsTable.lastUpdated.colName}
  )
VALUES
  (?, ?, ?, ?, ?, ?)
    """,
      [
        newItem.name,
        newItem.itemType == ItemType.internal ? 1 : 0,
        newItem.price?.toString(),
        newItem.quantity,
        newItem.extraNotes,
        newItem.lastUpdated.toIso8601String(),
      ],
    );
  }

  /// Deletes [NonRoot] with [itemId] from the relation, so that it no longer
  /// has a parent relation
  Future<void> _deleteParentRelation({
    required int itemId,
  }) async {
    await db.rawDelete(
      """
DELETE FROM
  ${ItemIsInsideTable.tableName}
WHERE
  ${ItemIsInsideTable.itemId.colName}=?
    """,
      [
        itemId,
      ],
    );
  }

  Future<void> _addParentRelation({
    required int itemId,
    required int parentId,
  }) async {
    await db.rawInsert(
      """
INSERT INTO
  ${ItemIsInsideTable.tableName}
  (
    ${ItemIsInsideTable.itemId.colName},
    ${ItemIsInsideTable.containerId.colName}
  )
VALUES
  (?, ?)
    """,
      [
        itemId,
        parentId,
      ],
    );
  }

  Future<List<int>> _getOwnerIdsFromNames({required List<String> names}) async {
    // Getting list of owner ids from owner name in [OwnersTable]
    final argQMarks = List.filled(
      names.length,
      "?",
    ).join(
      ",",
    );
    final ownersResult = await db.rawQuery(
      """
SELECT
  ${OwnersTable.id}
FROM
  ${OwnersTable.tableName}
WHERE
  ${OwnersTable.name} IN ($argQMarks)
    """,
      names,
    );
    return ownersResult.map(
      (e) {
        return e[OwnersTable.id.colName] as int;
      },
    ).toList();
  }

  /// Removes any ownership relations of this [Item]
  Future<void> _deleteOwnerRelationOfItem({required int itemId}) async {
    await db.rawDelete(
      """
DELETE FROM
  ${ItemsOwnedByTable.tableName}
WHERE
  ${ItemsOwnedByTable.itemId.colName}=?
    """,
      [
        itemId,
      ],
    );
  }

  Future<void> _addOwnerRelationForItem({
    required int itemId,
    required int ownerId,
  }) async {
    await db.rawInsert(
      """
INSERT INTO
  ${ItemsOwnedByTable.tableName}
  (
    ${ItemsOwnedByTable.itemId.colName},
    ${ItemsOwnedByTable.ownerId.colName}
  )
VALUES
  (?, ?)
    """,
      [itemId, ownerId],
    );
  }

  /// Removes this [Item] from the top level table, NOOP if not in the table
  Future<void> _deleteItemFromTopLevel({required int itemId}) async {
    await db.rawDelete(
      """
DELETE FROM
  ${TopLevelItemsTable.tableName}
WHERE
  ${TopLevelItemsTable.itemId.colName}=?
    """,
      [itemId],
    );
  }

  Future<void> _addItemToTopLevel({required int itemId}) async {
    await db.rawInsert(
      """
INSERT INTO
  ${TopLevelItemsTable.tableName}
  (
    ${TopLevelItemsTable.itemId.colName}
  )
VALUES
  (?)
      """,
      [itemId],
    );
  }

  @override
  Future<int> saveOrModifyItem({
    required NewItem newItem,
  }) async {
    await _ensureTables();

    final int itemId;
    if (newItem.editingItem != null) {
      // If existing item, only update
      itemId = newItem.editingItem!.id;
      await _updateExisting(newItem: newItem);
    } else {
      // Else insert into [ItemsTable]
      itemId = await _insertNewItem(newItem: newItem);
    }

    if (newItem.editingItem?.isTopLevelItem == false) {
      // Deleting existing parent relation, because it's easier
      await _deleteParentRelation(itemId: itemId);
    }

    if (!newItem.isTopLevelItem) {
      // Inserting into [ItemIsInsideTable] if its not top level item
      await _addParentRelation(itemId: itemId, parentId: newItem.parentId);
    }

    final ownerIds = await _getOwnerIdsFromNames(
      names: newItem.owners
          .map(
            (owner) => owner.name,
          )
          .toList(),
    );
    // Inserting into [ItemsOwnedByTable]
    // First deleting existing because easier
    await _deleteOwnerRelationOfItem(itemId: itemId);
    for (final ownerId in ownerIds) {
      await _addOwnerRelationForItem(itemId: itemId, ownerId: ownerId);
    }

    await _deleteItemFromTopLevel(itemId: itemId);
    // If the item is an immediate child of root, then add it to
    // the [RootLevelItemsTable]
    if (newItem.isTopLevelItem) {
      await _addItemToTopLevel(itemId: itemId);
    }
    return itemId;
  }

  Future<bool> _isOwnerInTable({required Owner owner}) async {
    final resultSet = await db.rawQuery(
      """
SELECT
  ${OwnersTable.id.colName}
FROM
  ${OwnersTable.tableName}
WHERE 
  ${OwnersTable.name.colName}=?
    """,
      [
        owner.name,
      ],
    );
    return resultSet.isNotEmpty;
  }

  Future<void> _addNewOwner({required Owner owner}) async {
    await db.rawInsert(
      """
INSERT INTO
  ${OwnersTable.tableName}
    (
      ${OwnersTable.name.colName}
    )
VALUES
  (?)
    """,
      [owner.name],
    );
  }

  @override
  Future<void> saveNewOwner({required Owner owner}) async {
    if (!(await _isOwnerInTable(owner: owner))) {
      await _addNewOwner(owner: owner);
    }
  }

  @override
  Future<List<Owner>> getAllOwners() async {
    final ownersResult = await db.rawQuery(
      """
SELECT
  ${OwnersTable.name.colName}
FROM
  ${OwnersTable.tableName}
    """,
    );
    return ownersResult.map(
      (entry) {
        return Owner(name: entry[OwnersTable.name.colName].toString());
      },
    ).toList();
  }

  @override
  Future<List<String>> getImagePathsForItem({
    required int itemId,
  }) async {
    final pathsResult = await db.rawQuery(
      """
SELECT
  ${ItemPictures.pictureFileName.colName}
FROM
  ${ItemPictures.tableName}
WHERE
  ${ItemPictures.itemId.colName}=?
    """,
      [itemId],
    );
    return pathsResult.map(
      (row) {
        return row[ItemPictures.pictureFileName.colName] as String;
      },
    ).toList();
  }

  @override
  Future<void> saveImagePathsForItem({
    required int itemId,
    required List<String> imagePaths,
  }) async {
    for (final path in imagePaths) {
      await db.rawInsert(
        """
INSERT INTO 
  ${ItemPictures.tableName}
  (
    ${ItemPictures.itemId.colName},
    ${ItemPictures.pictureFileName.colName}
  )
VALUES
  (?, ?)
    """,
        [itemId, path],
      );
    }
  }

  Future<List<Item>> getItemSearchMatches({
    required String searchString,
  }) async {
    throw UnimplementedError();
  }
}
