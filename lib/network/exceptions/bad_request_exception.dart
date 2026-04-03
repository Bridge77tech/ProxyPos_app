import 'package:inventory_app_pos/network/exceptions/api_exceptions.dart';

import '../constants/api_string_const.dart';

class BadRequestException extends APIExceptions {
  BadRequestException({
    super.message = APIStringConst.apBadRequestMsg,
    super.statusCode,
  });
}