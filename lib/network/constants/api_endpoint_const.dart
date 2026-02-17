import 'package:inventory_app_pos/network/models/api_endpoint.dart';

class APIEndpointConst {
  APIEndpointConst._();

  static const APIEndpoint apLoginEndpoint = APIEndpoint(route: 'auth/login');
  static const APIEndpoint apTopProductEndpoint = APIEndpoint(route: 'pos/products/top-products');
  static const APIEndpoint apAllProductEndpoint = APIEndpoint(route: 'pos/products');
  static const APIEndpoint apCreateNewSaleEndPoint = APIEndpoint(route: 'pos/sales');

  static const List<APIEndpoint> privateAPIEndpoint = [
    apLoginEndpoint,
    apTopProductEndpoint,
    apAllProductEndpoint,
    apCreateNewSaleEndPoint,
  ];

  static const String apLogin = "auth/login";
  static const String apTopProduct = "pos/products/top-products";
  static const String apAllProduct = "pos/products";
  static const String apCreateNewSale = "pos/sales";
}
