class APIEndpoint {
  final String route;
  final bool requiredAuth;

  const APIEndpoint({
    required this.route,
    this.requiredAuth = false,
  });
}