import 'package:flutter/material.dart';

/// Helper class for optimized navigation
class NavigationHelper {
  /// Fast navigation with optimized page route
  static Future<T?> pushFast<T extends Object?>(
    BuildContext context,
    Widget page, {
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fast fade transition
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200), // Fast transition
        reverseTransitionDuration: const Duration(milliseconds: 150),
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  /// Replace current route quickly
  static Future<T?> pushReplacementFast<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      ),
      result: result,
    );
  }

  /// Push and remove all previous routes quickly
  static Future<T?> pushAndRemoveUntilFast<T extends Object?>(
    BuildContext context,
    Widget page,
    RoutePredicate predicate,
  ) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      ),
      predicate,
    );
  }
}

