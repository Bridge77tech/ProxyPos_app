class GenericResponse {
  String? message;
  int? userId;

  GenericResponse({this.message, this.userId});

  factory GenericResponse.fromJson(Map<String, dynamic> json) => GenericResponse(
    message: json["message"] as String?,
    userId: json["user_id"] as int?,
  );
}