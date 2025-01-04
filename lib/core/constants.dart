import 'dart:io';

const dbFileName = "things_map.sqlite";

const appVersion = "0.1.0";

final rootDir = Directory("/");

/// Contains the app settings stored as a JSON string.
/// It's a single row table.
class SettingsTable {
  static const tableName = "settings";

  /// INTEGER
  static const id = "id";

  /// VARCHAR, the JSON string
  static const jsonString = "settings_json";

  /// There is only one row of data in this table, which has [fixedSingleId] as
  /// its id
  static const fixedSingleId = 1;
}

/// Contains all the items data.
class ItemsTable {
  static const tableName = "items";

  /// INTEGER
  static const baseId = "id";

  /// VARCHAR
  static const name = "name";

  /// BOOL/INTEGER, indicates whether this item can contain items
  static const canContainItems = "can_contain_items";

  /// STRING?, price of this item, can be null
  static const price = "price";

  /// INTEGER, number of this item
  static const quantity = "quantity";

  /// VARCHAR?, some extra stuff
  static const extraNotes = "extra_notes";

  /// VARCHAR, ISO8601 timestamp of last update of this data
  static const lastUpdated = "last_updated";
}

/// Contains the list of owners.
class OwnersTable {
  static const tableName = "owners";

  /// INTEGER
  static const id = "id";

  /// VARCHAR
  static const name = "name";
}

/// [ItemsOwnedByTable.itemId] is owned by [ItemsOwnedByTable.ownerId].
/// There can be multiple owners.
class ItemsOwnedByTable {
  static const tableName = "item_owned_by";

  /// INTEGER
  static const itemId = "item_id";

  /// INTEGER
  static const ownerId = "owner_id";
}

/// [ItemPictures.itemId]'s pictures are with [ItemPictures.pictureFileName].
/// There can be many pictures.
class ItemPictures {
  static const tableName = "item_pictures";

  /// INTEGER
  static const itemId = "item_id";

  /// VARCHAR
  static const pictureFileName = "picture_file_name";
}

/// [ItemIsInsideTable.itemId] is inside [ItemIsInsideTable.containerId].
/// One container can contain many items, but one item can only be contained
/// by one container
class ItemIsInsideTable {
  static const tableName = "item_is_inside";

  /// INTEGER
  static const itemId = "item_id";

  /// INTEGER
  static const containerId = "container_id";
}

/// [RootLevelItemsTable.itemId] is a root level item, which should be the
/// shown as the top level item in the UI. There can be many root level items.
class RootLevelItemsTable {
  static const tableName = "root_level_items";

  /// INTEGER
  static const itemId = "item_id";
}
