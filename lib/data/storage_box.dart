enum StorageBox {
  auth(name: "auth_v1", isEncrypted: true),
  topProducts(name: "top_products_v1", isEncrypted: false);

  final String name;
  final bool isEncrypted;

  const StorageBox({required this.name, required this.isEncrypted});
}
