import 'package:inventory_app_pos/network/exceptions/api_exceptions.dart';
import '../constants/api_string_const.dart';

class UnauthorizedException extends ApiExceptions {
  UnauthorizedException({super.message = APIStringConst.apUnAuthorizedMsg});
}