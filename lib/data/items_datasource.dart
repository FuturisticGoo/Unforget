import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:things_map/core/constants.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/core/entity/owner.dart';
import 'package:path/path.dart' as p;

abstract class ItemsDatasource {
  Future<Root> getItemsRoot();
  Future<int> saveNewItem({required NewItem newItem});
}

class ItemsDataSourceSQLite implements ItemsDatasource {
  final Database db;
  const ItemsDataSourceSQLite({required this.db});

  Future<void> _ensureTables() async {
    await db.execute("""
CREATE TABLE IF NOT EXISTS ${ItemsTable.tableName} (
  ${ItemsTable.baseId} INTEGER PRIMARY KEY,
  ${ItemsTable.name} TEXT NOT NULL,
  ${ItemsTable.canContainItems} INTEGER NOT NULL,
  ${ItemsTable.price} TEXT,
  ${ItemsTable.quantity} REAL NOT NULL,
  ${ItemsTable.extraNotes} TEXT,
  ${ItemsTable.lastUpdated} TEXT
)
    """);

    await db.execute("""
CREATE TABLE IF NOT EXISTS ${OwnersTable.tableName}(
  ${OwnersTable.id} INTEGER PRIMARY KEY,
  ${OwnersTable.name} TEXT NOT NULL
)
    """);

    await db.execute("""
CREATE TABLE IF NOT EXISTS ${ItemsOwnedByTable.tableName} (
  ${ItemsOwnedByTable.itemId} INTEGER REFERENCES ${ItemsTable.tableName}(${ItemsTable.baseId}),
  ${ItemsOwnedByTable.ownerId} INTEGER REFERENCES ${OwnersTable.tableName}(${OwnersTable.id})
)
    """);

    await db.execute("""
CREATE TABLE IF NOT EXISTS ${ItemPictures.tableName} (
  ${ItemPictures.itemId} INTEGER REFERENCES ${ItemsTable.tableName}(${ItemsTable.baseId}),
  ${ItemPictures.pictureFileName} TEXT NOT NULL
)
    """);

    await db.execute("""
CREATE TABLE IF NOT EXISTS ${ItemIsInsideTable.tableName} (
  ${ItemIsInsideTable.itemId} INTEGER REFERENCES ${ItemsTable.tableName}(${ItemsTable.baseId}),
  ${ItemIsInsideTable.containerId} INTEGER REFERENCES ${ItemsTable.tableName}(${ItemsTable.baseId})
)
    """);

    await db.execute("""
CREATE TABLE IF NOT EXISTS ${RootLevelItemsTable.tableName} (
  ${RootLevelItemsTable.itemId} INTEGER REFERENCES ${ItemsTable.tableName}(${ItemsTable.baseId})
)
    """);
  }

  Future<Item> _buildTreeFromNode({
    required int id,
    required String parentPath,
  }) async {
    final currentItemResult = await db.rawQuery(
      """
SELECT
  ${ItemsTable.baseId},
  ${ItemsTable.name},
  ${ItemsTable.canContainItems},
  ${ItemsTable.price},
  ${ItemsTable.quantity},
  ${ItemsTable.extraNotes},
  ${ItemsTable.lastUpdated}
FROM
  ${ItemsTable.tableName}
WHERE
  ${ItemsTable.baseId}=?
    """,
      [id],
    );
    final currentItemOwners = await db.rawQuery(
      """
SELECT 
  o.${OwnersTable.name}
FROM ${OwnersTable.tableName} o
  INNER JOIN ${ItemsOwnedByTable.tableName} iob
    ON o.${OwnersTable.id}=iob.${ItemsOwnedByTable.ownerId}
WHERE
  iob.${ItemsOwnedByTable.itemId}=?
    """,
      [id],
    );
    final owners = currentItemOwners.map(
      (row) {
        return Owner(name: row[OwnersTable.name].toString());
      },
    ).toList();
    final currentItemSingle = currentItemResult.single;
    final pathId = p.join(parentPath, id.toString());
    final priceString = currentItemSingle[ItemsTable.price]?.toString();
    final price = (priceString == null) ? null : BigInt.parse(priceString);
    final name = currentItemSingle[ItemsTable.name].toString();
    final quantity = currentItemSingle[ItemsTable.quantity] as double;
    final extraNotes = currentItemSingle[ItemsTable.extraNotes].toString();
    final lastUpdated = DateTime.parse(
      currentItemSingle[ItemsTable.lastUpdated].toString(),
    );

    switch (currentItemSingle[ItemsTable.canContainItems]) {
      case 1:
        List<Item> childrenItems = [];
        final childrenItemIdResult = await db.rawQuery(
          """
SELECT 
  ${ItemIsInsideTable.itemId}
FROM
  ${ItemIsInsideTable.tableName}
WHERE
  ${ItemIsInsideTable.containerId}=?
      """,
          [id],
        );
        for (final child in childrenItemIdResult) {
          childrenItems.add(
            await _buildTreeFromNode(
              id: child[ItemsOwnedByTable.itemId] as int,
              parentPath: pathId,
            ),
          );
        }
        return InternalItem(
          name: name,
          price: price,
          owners: owners,
          pathId: pathId,
          quantity: quantity,
          items: childrenItems,
          extraNotes: extraNotes,
          lastUpdated: lastUpdated,
        );
      case 0:
      default:
        return LeafItem(
          name: name,
          price: price,
          owners: owners,
          pathId: pathId,
          quantity: quantity,
          extraNotes: extraNotes,
          lastUpdated: lastUpdated,
        );
    }
  }

  @override
  Future<Root> getItemsRoot() async {
    await _ensureTables();

    List<Item> rootChildItems = [];
    final rootLevelItemsIdResult = await db.rawQuery("""
SELECT 
  ${RootLevelItemsTable.itemId}
FROM
  ${RootLevelItemsTable.tableName}
  """);
    for (final rootLevel in rootLevelItemsIdResult) {
      final item = await _buildTreeFromNode(
        id: rootLevel[RootLevelItemsTable.itemId] as int,
        parentPath: rootDir.path,
      );
      rootChildItems.add(item);
    }
    return Root(
      items: rootChildItems,
      lastUpdated: DateTime.now(), //TODO: get the latest updated time here
    );
  }

  @override
  Future<int> saveNewItem({required NewItem newItem}) async {
    await _ensureTables();
    // Inserting into [ItemsTable]
    final rowId = await db.rawInsert(
      """
INSERT INTO 
  ${ItemsTable.tableName}
  (
    ${ItemsTable.name},
    ${ItemsTable.canContainItems},
    ${ItemsTable.price},
    ${ItemsTable.quantity},
    ${ItemsTable.extraNotes},
    ${ItemsTable.lastUpdated}
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

    if (!newItem.isImmediateChildOfRoot) {
      // Inserting into [ItemIsInsideTable] if its not immediate
      // child of root
      await db.rawInsert(
        """
INSERT INTO 
  ${ItemIsInsideTable.tableName}
  (
    ${ItemIsInsideTable.itemId},
    ${ItemIsInsideTable.containerId}
  )
VALUES
  (?, ?)
    """,
        [
          rowId,
          newItem.parentBaseId,
        ],
      );
    }

    // Getting list of owner ids from owner name in [OwnersTable]
    final argQMarks = List.filled(newItem.owners.length, "?").join(",");
    final ownersResult = await db.rawQuery(
      """
SELECT 
  ${OwnersTable.id}
FROM
  ${OwnersTable.tableName}
WHERE
  ${OwnersTable.name} IN ($argQMarks)
    """,
      newItem.owners
          .map(
            (owner) => owner.name,
          )
          .toList(),
    );
    final ownerIds = ownersResult.map(
      (e) {
        return e[OwnersTable.id] as int;
      },
    ).toList();

    // Inserting into [ItemsOwnedByTable]
    final ownersStmt = """
INSERT INTO 
  ${ItemsOwnedByTable.tableName}
  (
    ${ItemsOwnedByTable.itemId},
    ${ItemsOwnedByTable.ownerId}
  )
VALUES
  (?, ?)
    """;
    for (final ownerId in ownerIds) {
      await db.rawInsert(
        ownersStmt,
        [rowId, ownerId],
      );
    }

    // If the item is an immediate child of root, then add it to
    // the [RootLevelItemsTable]
    if (newItem.isImmediateChildOfRoot) {
      await db.rawInsert(
        """
INSERT INTO 
  ${RootLevelItemsTable.tableName}
  (
    ${RootLevelItemsTable.itemId}
  )
VALUES
  (?)
      """,
        [rowId],
      );
    }
    return rowId;
  }

  Future<List<Item>> getItemSearchMatches({
    required String searchString,
  }) async {
    throw UnimplementedError();
  }
}
