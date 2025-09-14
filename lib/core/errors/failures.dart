import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

class VpnConnectionFailure extends Failure {
  const VpnConnectionFailure([super.message]);
}

class ConfigurationFailure extends Failure {
  const ConfigurationFailure([super.message]);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message]);
}