class UnauthrizedException implements Exception {
  final String message;
  final dynamic requiredPermission;

  UnauthrizedException({
    this.message = 'You do not have permiision to perform this action.',
    this.requiredPermission,
  });

  @override
  String toString() => 'UnauthorizedException: $message';
}
