class GetProductException {
  String? message;

  GetProductException(this.message);

  @override
  String toString() {
    return 'GetProductExpection: $message';
  }
}
