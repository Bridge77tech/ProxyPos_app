import 'package:inventory_app_pos/network/models/api_endpoint.dart';

class APIEndpointConst {
  APIEndpointConst._();

  static const APIEndpoint apLoginEndpoint = APIEndpoint(route: 'auth/login');

  static const List<APIEndpoint> privateAPIEndpoint = [
    apLoginEndpoint,
  ];

  static const String apLogin = "auth/login";
}
