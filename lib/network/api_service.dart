import 'package:dio/dio.dart';

class APIService {
  late Dio dio;

  Dio get dioInstance => dio;

  // static APIService _instance = APIService._internal(
  //   authSeasionStorage:
  // );


  // factory APIService() => _instance;
  // APIService._internal({required this.authSeasionStorage});

}