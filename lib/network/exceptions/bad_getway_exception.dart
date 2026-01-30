import 'package:inventory_app_pos/network/exceptions/api_exceptions.dart';

import '../constants/api_string_const.dart';

class BadGatewayException extends ApiExceptions {
  BadGatewayException({
   super.message = APIStringConst.apInternalServerErrorMsg,
    super.statusCode = 502,
  });
}