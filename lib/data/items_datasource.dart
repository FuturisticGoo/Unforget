import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:things_map/core/constants.dart';
import 'package:things_map/core/entity/item.dart';
import 'package:things_map/core/entity/new_item.dart';
import 'package:things_map/core/entity/owner.dart';
import 'package:path/path.dart' as p;

extension _SQLOnlyColumnName on String {
  String get colName {
    return split(".").last;
  }
}

abstract class ItemsDatasource {
  Future<List<Item>> getAllItems();
  Future<int> saveNewItem({required NewItem newItem});
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

//   Future<Item> _buildTreeFromNode({
//     required int id,
//     required String parentPath,
//   }) async {
//     final currentItemResult = await db.rawQuery(
//       """
// SELECT
//   ${ItemsTable.id},
//   ${ItemsTable.name},
//   ${ItemsTable.canContainItems},
//   ${ItemsTable.price},
//   ${ItemsTable.quantity},
//   ${ItemsTable.extraNotes},
//   ${ItemsTable.lastUpdated}
// FROM
//   ${ItemsTable.tableName}
// WHERE
//   ${ItemsTable.id}=?
//     """,
//       [id],
//     );
//     final currentItemOwners = await db.rawQuery(
//       """
// SELECT
//   o.${OwnersTable.name}
// FROM ${OwnersTable.tableName} o
//   INNER JOIN ${ItemsOwnedByTable.tableName} iob
//     ON o.${OwnersTable.id}=iob.${ItemsOwnedByTable.ownerId}
// WHERE
//   iob.${ItemsOwnedByTable.itemId}=?
//     """,
//       [id],
//     );
//     final owners = currentItemOwners.map(
//       (row) {
//         return Owner(name: row[OwnersTable.name].toString());
//       },
//     ).toList();
//     final currentItemSingle = currentItemResult.single;
//     final pathId = p.join(parentPath, id.toString());
//     final priceString = currentItemSingle[ItemsTable.price]?.toString();
//     final price = (priceString == null) ? null : BigInt.parse(priceString);
//     final name = currentItemSingle[ItemsTable.name].toString();
//     final quantity = currentItemSingle[ItemsTable.quantity] as double;
//     final extraNotes = currentItemSingle[ItemsTable.extraNotes].toString();
//     final lastUpdated = DateTime.parse(
//       currentItemSingle[ItemsTable.lastUpdated].toString(),
//     );

//     switch (currentItemSingle[ItemsTable.canContainItems]) {
//       case 1:
//         List<Item> childrenItems = [];
//         final childrenItemIdResult = await db.rawQuery(
//           """
// SELECT
//   ${ItemIsInsideTable.itemId}
// FROM
//   ${ItemIsInsideTable.tableName}
// WHERE
//   ${ItemIsInsideTable.containerId}=?
//       """,
//           [id],
//         );
//         for (final child in childrenItemIdResult) {
//           childrenItems.add(
//             await _buildTreeFromNode(
//               id: child[ItemsOwnedByTable.itemId] as int,
//               parentPath: pathId,
//             ),
//           );
//         }
//         return InternalItem(
//           name: name,
//           price: price,
//           owners: owners,
//           pathId: pathId,
//           quantity: quantity,
//           items: childrenItems,
//           extraNotes: extraNotes,
//           lastUpdated: lastUpdated,
//         );
//       case 0:
//       default:
//         return LeafItem(
//           name: name,
//           price: price,
//           owners: owners,
//           pathId: pathId,
//           quantity: quantity,
//           extraNotes: extraNotes,
//           lastUpdated: lastUpdated,
//         );
//     }
//   }

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
      price = (priceString == null) ? null : BigInt.parse(priceString);
      name = row[ItemsTable.name.colName].toString();
      quantity = row[ItemsTable.quantity.colName] as double;
      extraNotes = row[ItemsTable.extraNotes.colName].toString();
      lastUpdated = DateTime.parse(
        row[ItemsTable.lastUpdated.colName].toString(),
      );
      final ownersFinderResult = await db.rawQuery(
        _ownerFinderStmt,
        [id],
      );
      List<Owner> owners = ownersFinderResult.map(
        (ownerRow) {
          return Owner(name: ownerRow[OwnersTable.name.colName].toString());
        },
      ).toList();

      final childrenFinderResult = await db.rawQuery(
        _childrenFinderStmt,
        [id],
      );
      List<int> children = childrenFinderResult.map(
        (childRow) {
          return childRow[ItemIsInsideTable.itemId.colName] as int;
        },
      ).toList();

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
            parentId: parentId!,
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

//     final nonTopItemsResult = await db.rawQuery("""
// SELECT
// 	${ItemsTable.id},
// 	${ItemsTable.name},
// 	${ItemsTable.canContainItems},
// 	${ItemsTable.price},
// 	${ItemsTable.quantity},
// 	${ItemsTable.extraNotes},
// 	${ItemsTable.lastUpdated},
// 	${ItemIsInsideTable.containerId}
// FROM
// 	${ItemsTable.tableName}
// 	INNER JOIN
// 		${ItemIsInsideTable.tableName}
// 			ON
//         ${ItemsTable.tableName}.${ItemsTable.id}=
//         ${ItemIsInsideTable.tableName}.${ItemIsInsideTable.itemId};
//     """);
  // }

  @override
  Future<int> saveNewItem({required NewItem newItem}) async {
    throw UnimplementedError();
//     await _ensureTables();
//     // Inserting into [ItemsTable]
//     final rowId = await db.rawInsert(
//       """
// INSERT INTO
//   ${ItemsTable.tableName}
//   (
//     ${ItemsTable.name},
//     ${ItemsTable.canContainItems},
//     ${ItemsTable.price},
//     ${ItemsTable.quantity},
//     ${ItemsTable.extraNotes},
//     ${ItemsTable.lastUpdated}
//   )
// VALUES
//   (?, ?, ?, ?, ?, ?)
//     """,
//       [
//         newItem.name,
//         newItem.itemType == ItemType.internal ? 1 : 0,
//         newItem.price?.toString(),
//         newItem.quantity,
//         newItem.extraNotes,
//         newItem.lastUpdated.toIso8601String(),
//       ],
//     );

//     if (!newItem.isImmediateChildOfRoot) {
//       // Inserting into [ItemIsInsideTable] if its not immediate
//       // child of root
//       await db.rawInsert(
//         """
// INSERT INTO
//   ${ItemIsInsideTable.tableName}
//   (
//     ${ItemIsInsideTable.itemId},
//     ${ItemIsInsideTable.containerId}
//   )
// VALUES
//   (?, ?)
//     """,
//         [
//           rowId,
//           newItem.parentBaseId,
//         ],
//       );
//     }

//     // Getting list of owner ids from owner name in [OwnersTable]
//     final argQMarks = List.filled(newItem.owners.length, "?").join(",");
//     final ownersResult = await db.rawQuery(
//       """
// SELECT
//   ${OwnersTable.id}
// FROM
//   ${OwnersTable.tableName}
// WHERE
//   ${OwnersTable.name} IN ($argQMarks)
//     """,
//       newItem.owners
//           .map(
//             (owner) => owner.name,
//           )
//           .toList(),
//     );
//     final ownerIds = ownersResult.map(
//       (e) {
//         return e[OwnersTable.id] as int;
//       },
//     ).toList();

//     // Inserting into [ItemsOwnedByTable]
//     final ownersStmt = """
// INSERT INTO
//   ${ItemsOwnedByTable.tableName}
//   (
//     ${ItemsOwnedByTable.itemId},
//     ${ItemsOwnedByTable.ownerId}
//   )
// VALUES
//   (?, ?)
//     """;
//     for (final ownerId in ownerIds) {
//       await db.rawInsert(
//         ownersStmt,
//         [rowId, ownerId],
//       );
//     }

//     // If the item is an immediate child of root, then add it to
//     // the [RootLevelItemsTable]
//     if (newItem.isImmediateChildOfRoot) {
//       await db.rawInsert(
//         """
// INSERT INTO
//   ${TopLevelItemsTable.tableName}
//   (
//     ${TopLevelItemsTable.itemId}
//   )
// VALUES
//   (?)
//       """,
//         [rowId],
//       );
//     }
//     return rowId;
  }

  Future<List<Item>> getItemSearchMatches({
    required String searchString,
  }) async {
    throw UnimplementedError();
  }
}

String _ownerFinderStmt = """
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
    """;

String _childrenFinderStmt = """
SELECT 
  ${ItemIsInsideTable.itemId}
FROM 
  ${ItemIsInsideTable.tableName}
WHERE
  ${ItemIsInsideTable.itemId}=?
    """;
