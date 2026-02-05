import 'package:inventory_app_pos/network/exceptions/api_exceptions.dart';

import '../constants/api_string_const.dart';

class NetworkException extends APIExceptions {
  NetworkException({
    super.message = APIStringConst.apNoInternetMsg,
    super.statusCode,
  });
}