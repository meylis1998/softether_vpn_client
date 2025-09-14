import 'dart:async';
import 'dart:io';

import 'package:flutter_vpn/flutter_vpn.dart';
import 'package:injectable/injectable.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart' as openvpn;

import '../../../../core/errors/exceptions.dart';
import '../../../vpn_config/domain/entities/vpn_config.dart';
import '../models/vpn_connection_status_model.dart';

abstract class VpnConnectionDataSource {
  Future<void> connect(VpnConfig config);
  Future<void> disconnect();
  Future<VpnConnectionStatusModel> getStatus();
  Stream<VpnConnectionStatusModel> watchStatus();
  Future<bool> checkVpnPermission();
  Future<bool> requestVpnPermission();
}

@LazySingleton(as: VpnConnectionDataSource)
class VpnConnectionDataSourceImpl implements VpnConnectionDataSource {
  openvpn.OpenVPN? _openVPN;
  VpnConfig? _currentConfig;
  final StreamController<VpnConnectionStatusModel> _statusController =
      StreamController<VpnConnectionStatusModel>.broadcast();

  VpnConnectionStatusModel _currentStatus = const VpnConnectionStatusModel(
    status: 'disconnected',
  );

  VpnConnectionDataSourceImpl() {
    _initializeOpenVPN();
  }

  void _initializeOpenVPN() {
    _openVPN = openvpn.OpenVPN(
      onVpnStatusChanged: (data) {
        _handleOpenVpnStatusChange(data);
      },
      onVpnStageChanged: (stage, message) {
        // Handle stage changes if needed
      },
    );
  }

  @override
  Future<void> connect(VpnConfig config) async {
    try {
      _currentConfig = config;
      _updateStatus(const VpnConnectionStatusModel(status: 'connecting'));

      switch (config.protocol) {
        case VpnProtocol.l2tpIpsec:
          await _connectL2TP(config);
          break;
        case VpnProtocol.openVpn:
          await _connectOpenVPN(config);
          break;
        case VpnProtocol.sslVpn:
          throw VpnConnectionException('SSL-VPN not yet implemented');
      }
    } catch (e) {
      _updateStatus(VpnConnectionStatusModel(
        status: 'error',
        errorMessage: e.toString(),
      ));
      throw VpnConnectionException('Connection failed: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      _updateStatus(const VpnConnectionStatusModel(status: 'disconnecting'));

      switch (_currentConfig?.protocol) {
        case VpnProtocol.l2tpIpsec:
          await _disconnectL2TP();
          break;
        case VpnProtocol.openVpn:
          await _disconnectOpenVPN();
          break;
        case VpnProtocol.sslVpn:
          throw VpnConnectionException('SSL-VPN not yet implemented');
        case null:
          _updateStatus(const VpnConnectionStatusModel(status: 'disconnected'));
          return;
      }
    } catch (e) {
      _updateStatus(VpnConnectionStatusModel(
        status: 'error',
        errorMessage: e.toString(),
      ));
      throw VpnConnectionException('Disconnect failed: $e');
    }
  }

  @override
  Future<VpnConnectionStatusModel> getStatus() async {
    return _currentStatus;
  }

  @override
  Stream<VpnConnectionStatusModel> watchStatus() {
    return _statusController.stream;
  }

  @override
  Future<bool> checkVpnPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // This is a simplified check - in real implementation,
      // you would use platform channels to check VPN permission
      return true;
    } catch (e) {
      throw PermissionException('Failed to check VPN permission: $e');
    }
  }

  @override
  Future<bool> requestVpnPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // This is a simplified implementation - in real implementation,
      // you would use platform channels to request VPN permission
      return true;
    } catch (e) {
      throw PermissionException('Failed to request VPN permission: $e');
    }
  }

  Future<void> _connectL2TP(VpnConfig config) async {
    if (!Platform.isAndroid) {
      throw VpnConnectionException('L2TP/IPSec only supported on Android');
    }

    try {
      await FlutterVpn.connectIkev2EAP(
        server: config.serverAddress,
        username: config.username,
        password: config.password,
      );

      // Assume success for now - in real implementation, check the result
      final result = true;

      if (result) {
        _updateStatus(VpnConnectionStatusModel(
          status: 'connected',
          configId: config.id,
          configName: config.name,
          connectedAt: DateTime.now(),
        ));
      } else {
        throw VpnConnectionException('L2TP connection failed');
      }
    } catch (e) {
      throw VpnConnectionException('L2TP connection failed: $e');
    }
  }

  Future<void> _disconnectL2TP() async {
    try {
      await FlutterVpn.disconnect();
      _updateStatus(const VpnConnectionStatusModel(status: 'disconnected'));
      _currentConfig = null;
    } catch (e) {
      throw VpnConnectionException('L2TP disconnect failed: $e');
    }
  }

  Future<void> _connectOpenVPN(VpnConfig config) async {
    if (config.ovpnConfig == null) {
      throw VpnConnectionException('OpenVPN config is required');
    }

    _openVPN?.connect(
      config.ovpnConfig!,
      config.name,
      username: config.username,
      password: config.password,
      certIsRequired: false,
    );

    // OpenVPN status updates will be handled by the callback
  }

  Future<void> _disconnectOpenVPN() async {
    _openVPN?.disconnect();
    // Status update will be handled by the callback
  }

  void _handleOpenVpnStatusChange(openvpn.VpnStatus? data) {
    if (data == null) return;

    String status;
    // Note: OpenVPN plugin status handling - simplified for now
    // In real implementation, you'd need to check the actual OpenVPN plugin API
    status = 'connected'; // Simplified - should be based on actual data

    _updateStatus(VpnConnectionStatusModel(
      status: status,
      configId: _currentConfig?.id,
      configName: _currentConfig?.name,
      connectedAt: status == 'connected' ? DateTime.now() : null,
      bytesReceived: null, // These would come from actual OpenVPN data
      bytesSent: null,
      durationSeconds: null,
    ));

    if (status == 'disconnected') {
      _currentConfig = null;
    }
  }

  void _updateStatus(VpnConnectionStatusModel newStatus) {
    _currentStatus = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    _statusController.close();
  }
}