import 'package:inventory_app_pos/network/models/api_endpoint.dart';

class APIEndpointConst {
  APIEndpointConst._();

  static const APIEndpoint apLoginEndpoint = APIEndpoint(route: 'auth/login', requiredAuth: false);
  static const APIEndpoint apTopProductEndpoint = APIEndpoint(route: 'pos/products/top-products', requiredAuth: true);
  static const APIEndpoint apAllProductEndpoint = APIEndpoint(route: 'pos/products', requiredAuth: true);
  static const APIEndpoint apCreateNewSaleEndPoint = APIEndpoint(route: 'pos/sales', requiredAuth: true);

  /// Public endpoints that DO NOT require authentication
  static const List<APIEndpoint> publicAPIEndpoint = [
    apLoginEndpoint,
  ];

  /// Private endpoints that REQUIRE authentication
  static const List<APIEndpoint> privateAPIEndpoint = [
    apTopProductEndpoint,
    apAllProductEndpoint,
    apCreateNewSaleEndPoint,
  ];

  static const String apLogin = "auth/login";
  static const String apTopProduct = "pos/products/top-products";
  static const String apAllProduct = "pos/products";
  static const String apCreateNewSale = "pos/sales";
  static const String apSalesHistory = "pos/sales";
}
