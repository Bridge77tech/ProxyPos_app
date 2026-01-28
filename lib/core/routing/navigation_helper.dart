import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'inv_navigator_keys.dart';

/// Navigation helper class for programmatic navigation with GoRouter
/// Core cross-cutting concern used across the application.
/// Provides methods to navigate in different contexts using navigator keys.
class NavigationHelper {
  /// Navigate within shell route to a route using the navigator key
  static void goShellNamed(
      String name, {
        Object? data,
        Map<String, dynamic> queryParams = const <String, dynamic>{},
      }) {
    return APNavigatorKeys.shellNavigatorKey.currentContext?.goNamed(
      name,
      extra: data,
      queryParameters: queryParams,
    );
  }

  /// Navigate outside shell route to a route using the navigator key
  static void goNamed(
      String name, {
        Object? data,
        Map<String, dynamic> queryParams = const <String, dynamic>{},
      }) {
    return APNavigatorKeys.rootNavigatorKey.currentContext?.goNamed(
      name,
      extra: data,
      queryParameters: queryParams,
    );
  }

  /// Push a route to the top of the route stack outside shell route.
  static Future<T?> pushNamed<T>(
      String name, {
        Object? data,
        Map<String, dynamic> queryParams = const <String, dynamic>{},
      }) async {
    return await APNavigatorKeys.rootNavigatorKey.currentContext?.pushNamed<T>(
      name,
      extra: data,
      queryParameters: queryParams,
    );
  }

  /// Push a route to the top of the route stack inside shell route.
  static Future<T?> pushShellNamed<T>(
      String name, {
        Object? data,
        Map<String, dynamic> queryParams = const <String, dynamic>{},
      }) async {
    return await APNavigatorKeys.shellNavigatorKey.currentContext?.pushNamed<T>(
      name,
      extra: data,
      queryParameters: queryParams,
    );
  }

  /// Pop routes until predicate returns true
  /// Useful for removing multiple routes from the route stack
  /// Example: popUntil((route) => route.name == 'home')
  static void popUntil(bool Function(Route<dynamic>) predicate) {
    if (APNavigatorKeys.rootNavigatorKey.currentContext != null) {
      APNavigatorKeys.rootNavigatorKey.currentState!.popUntil(predicate);
    }
  }

  /// Pop all routes from shell route until predicate returns true
  static void popShellUntil(bool Function(Route<dynamic>) predicate) {
    if (APNavigatorKeys.rootNavigatorKey.currentContext != null) {
      APNavigatorKeys.rootNavigatorKey.currentState!.popUntil(predicate);
    }
  }

  /// Pop route from shell navigator.
  static void popShell<T>([T? result]) {
    if (canPopShell()) {
      APNavigatorKeys.shellNavigatorKey.currentContext?.pop(result);
    }
  }

  /// route from current screen.
  static void pop<T>([T? result]) {
    if (canPop()) {
      APNavigatorKeys.rootNavigatorKey.currentContext?.pop(result);
    }
  }

  /// Check if navigator can pop
  static bool canPop() {
    return APNavigatorKeys.rootNavigatorKey.currentContext?.canPop() ?? false;
  }

  /// Check if shell navigator can pop
  static bool canPopShell() {
    return APNavigatorKeys.shellNavigatorKey.currentContext?.canPop() ?? false;
  }

  /// Pop all routes and navigate to named route
  static void popAllAndPushNamed(
      String name, {
        Object? extra,
        Map<String, dynamic> queryParams = const <String, dynamic>{},
      }) {
    popUntil((route) => route.isFirst);
    goNamed(name, data: extra, queryParams: queryParams);
  }

  /// Pop all routes in shell route and navigate to named route
  static void popShellAllAndPushNamed<T>(
      String name, {
        Object? extra,
        Map<String, dynamic> queryParams = const <String, dynamic>{},
      }) {
    popUntil((route) => route.isFirst);
    goShellNamed(name, data: extra, queryParams: queryParams);
  }
}
