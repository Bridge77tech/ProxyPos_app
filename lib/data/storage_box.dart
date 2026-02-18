enum StorageBox {
  auth(name: "auth_v1", isEncrypted: true),
  topProducts(name: "top_products_v1", isEncrypted: false),
  allProducts(name: "all_products_v1", isEncrypted: false),
  userProfile(name: "user_profile_v1", isEncrypted: true),
  createNewSale(name: "create_new_sale_v1", isEncrypted: true);

  final String name;
  final bool isEncrypted;

  const StorageBox({required this.name, required this.isEncrypted});
}
