import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(createFactory: false, createToJson: false)
abstract class APIResponse<T> {
  APIResponse({
    this.message,
    this.statusCode,
    this.token,
    });

  @JsonKey(name: 'message', includeFromJson: true)
  String? message;

  @JsonKey(name: 'statusCode', includeFromJson: true)
  String? statusCode;

  String? token;

  T fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson();
}
