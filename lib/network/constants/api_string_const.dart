class APIStringConst {
  APIStringConst._();

  // Base Url
  static const String apAPIBaseURL =
      "https://proxypos-backend.vercel.app/api/v1/";

  // Optional API prefix (e.g., '/api' or '/api/v1')
  static const String apAPIPrefix = "api/v1";

  // Exception Messages
  static const String apUnAuthorizedMsg =
      "You are not authorized to make this request";
  static const String apBadRequestMsg =
      "Invalid request, please check your input";
  static const String apNoInternetMsg = "No or Bad Internet Connection";
  static const String apInternalServerErrorMsg = "Internal Server Error";
}
