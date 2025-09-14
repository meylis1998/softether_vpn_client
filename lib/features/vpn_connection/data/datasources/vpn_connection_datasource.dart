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
      // Try to prepare VPN, if it fails, permission is not granted
      await FlutterVpn.prepare();
      return true;
    } catch (e) {
      // If prepare fails, assume no permission
      return false;
    }
  }

  @override
  Future<bool> requestVpnPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // Prepare VPN connection (this will request permission if needed)
      await FlutterVpn.prepare();
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
      // First check and request permissions
      if (!await checkVpnPermission()) {
        final hasPermission = await requestVpnPermission();
        if (!hasPermission) {
          throw VpnConnectionException('VPN permission denied');
        }
      }

      await FlutterVpn.connectIkev2EAP(
        server: config.serverAddress,
        username: config.username,
        password: config.password,
      );

      // Connection initiated successfully, status will be updated via platform channels
      _updateStatus(VpnConnectionStatusModel(
        status: 'connecting',
        configId: config.id,
        configName: config.name,
      ));
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

    try {
      // First check and request permissions
      if (Platform.isAndroid) {
        if (!await checkVpnPermission()) {
          final hasPermission = await requestVpnPermission();
          if (!hasPermission) {
            throw VpnConnectionException('VPN permission denied');
          }
        }
      }

      _openVPN?.connect(
        config.ovpnConfig!,
        config.name,
        username: config.username,
        password: config.password,
        certIsRequired: false,
      );

      // OpenVPN status updates will be handled by the callback
    } catch (e) {
      throw VpnConnectionException('OpenVPN connection failed: $e');
    }
  }

  Future<void> _disconnectOpenVPN() async {
    _openVPN?.disconnect();
    // Status update will be handled by the callback
  }

  void _handleOpenVpnStatusChange(openvpn.VpnStatus? data) {
    if (data == null) return;

    String status = 'connecting';
    DateTime? connectedAt;

    // Map OpenVPN status to our internal status
    switch (data.toString().toLowerCase()) {
      case 'vpn_status_connected':
      case 'connected':
        status = 'connected';
        connectedAt = DateTime.now();
        break;
      case 'vpn_status_connecting':
      case 'connecting':
        status = 'connecting';
        break;
      case 'vpn_status_disconnected':
      case 'disconnected':
        status = 'disconnected';
        _currentConfig = null;
        break;
      case 'vpn_status_denied':
      case 'vpn_status_error':
      case 'error':
        status = 'error';
        break;
      default:
        status = 'connecting';
    }

    _updateStatus(VpnConnectionStatusModel(
      status: status,
      configId: _currentConfig?.id,
      configName: _currentConfig?.name,
      connectedAt: connectedAt,
      bytesReceived: null,
      bytesSent: null,
      durationSeconds: null,
    ));
  }

  void _updateStatus(VpnConnectionStatusModel newStatus) {
    _currentStatus = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    _statusController.close();
  }
}