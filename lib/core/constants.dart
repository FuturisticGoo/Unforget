const appDataFolderName = "unforget_data";
const dbFileName = "unforget.sqlite";

const appVersion = "0.1.0";

final rootId = 0;

/// Contains the app settings stored as a JSON string.
/// It's a single row table.
class SettingsTable {
  static const tableName = "settings";

  /// INTEGER
  static const id = "$tableName.id";

  /// VARCHAR, the JSON string
  static const jsonString = "$tableName.settings_json";

  /// There is only one row of data in this table, which has [fixedSingleId] as
  /// its id
  static const fixedSingleId = 1;
}

/// Contains all the items data.
class ItemsTable {
  static const tableName = "items";

  /// INTEGER
  static const id = "$tableName.id";

  /// VARCHAR
  static const name = "$tableName.name";

  /// BOOL/INTEGER, indicates whether this item can contain items
  static const canContainItems = "$tableName.can_contain_items";

  /// STRING?, price of this item, can be null
  static const price = "$tableName.price";

  /// INTEGER, number of this item
  static const quantity = "$tableName.quantity";

  /// VARCHAR?, some extra stuff
  static const extraNotes = "$tableName.extra_notes";

  /// VARCHAR, ISO8601 timestamp of last update of this data
  static const lastUpdated = "$tableName.last_updated";
}

/// Contains the list of owners.
class OwnersTable {
  static const tableName = "owners";

  /// INTEGER
  static const id = "$tableName.id";

  /// VARCHAR
  static const name = "$tableName.name";
}

/// [ItemsOwnedByTable.itemId] is owned by [ItemsOwnedByTable.ownerId].
/// There can be multiple owners.
class ItemsOwnedByTable {
  static const tableName = "item_owned_by";

  /// INTEGER
  static const itemId = "$tableName.item_id";

  /// INTEGER
  static const ownerId = "$tableName.owner_id";
}

/// [ItemPictures.itemId]'s pictures are with [ItemPictures.pictureFileName].
/// There can be many pictures.
class ItemPictures {
  static const tableName = "item_pictures";

  /// INTEGER
  static const itemId = "$tableName.item_id";

  /// VARCHAR
  static const pictureFileName = "$tableName.picture_file_name";
}

/// [ItemIsInsideTable.itemId] is inside [ItemIsInsideTable.containerId].
/// One container can contain many items, but one item can only be contained
/// by one container
class ItemIsInsideTable {
  static const tableName = "item_is_inside";

  /// INTEGER
  static const itemId = "$tableName.item_id";

  /// INTEGER
  static const containerId = "$tableName.container_id";
}

/// [TopLevelItemsTable.itemId]  should be shown as the top level items in the
/// UI. There can be many top level items.
class TopLevelItemsTable {
  static const tableName = "top_level_items";

  /// INTEGER
  static const itemId = "$tableName.item_id";
}
