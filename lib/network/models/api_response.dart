import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable(
  fieldRename: FieldRename.snake,
  genericArgumentFactories: true,
)
class ApiResponse<T> {
  ApiResponse({
    this.error,
    this.responseDesc,
    this.responseCode,
    this.data,
  });

  bool? error;
  @JsonKey(name: 'resp_dec')
  String? responseDesc;

  @JsonKey(name: 'resp_code')
  String? responseCode;

  T? data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Function(T value) toJsonT) => _$ApiResponseToJson(this, toJsonT);
}