enum StorageBox {
  auth(name: "auth_v1", isEncrypted: true),
  topProducts(name: "top_products_v1", isEncrypted: false),
  allProducts(name: "all_products_v1", isEncrypted: false),
  userProfile(name: "user_profile_v1", isEncrypted: true),
  createNewSale(name: "create_new_sale_v1", isEncrypted: true),
  // Which update the owner has already said "Later" to. Unencrypted: it holds a
  // version string and nothing else, and it must stay readable even if the
  // encryption key is ever rotated — losing it would only re-ask, never strand.
  appUpdate(name: "app_update_v1", isEncrypted: false);

  final String name;
  final bool isEncrypted;

  const StorageBox({required this.name, required this.isEncrypted});
}
