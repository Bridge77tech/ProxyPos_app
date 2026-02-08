import 'package:inventory_app_pos/network/models/api_endpoint.dart';

class APIEndpointConst {
  APIEndpointConst._();

  static const APIEndpoint apLoginEndpoint = APIEndpoint(route: 'auth/login');
  static const APIEndpoint apTopProductEndpoint = APIEndpoint(route: 'pos/products/top-products');

  static const List<APIEndpoint> privateAPIEndpoint = [
    apLoginEndpoint,
    apTopProductEndpoint,
  ];

  static const String apLogin = "auth/login";
  static const String apTopProduct = "pos/products/top-products";
}
