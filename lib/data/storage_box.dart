enum StorageBox {
  auth(name: "auth_v1", isEncrypted: true);

  final String name;
  final bool isEncrypted;

  const StorageBox({required this.name, required this.isEncrypted});
}