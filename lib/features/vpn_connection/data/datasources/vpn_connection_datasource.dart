import 'dart:async';
import 'dart:io';

import 'package:flutter_vpn/flutter_vpn.dart';
import 'package:injectable/injectable.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart' as openvpn;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../vpn_config/domain/entities/vpn_config.dart';
import '../models/vpn_connection_status_model.dart';
import 'vpn_config_validator.dart';

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
  bool _isInitializing = false;
  bool _isInitialized = false;
  Completer<void>? _initializationCompleter;
  final StreamController<VpnConnectionStatusModel> _statusController =
      StreamController<VpnConnectionStatusModel>.broadcast();

  VpnConnectionStatusModel _currentStatus = const VpnConnectionStatusModel(
    status: 'disconnected',
  );

  Timer? _connectionTimeout;
  Timer? _statusMonitor;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  VpnConnectionDataSourceImpl() {
    _initializeOpenVPN();
    _initializeConnectivityMonitoring();
  }

  Future<void> _initializeOpenVPN() async {
    // If already initializing, return the completer to avoid duplicate initialization
    if (_isInitializing) {
      if (_initializationCompleter != null) {
        print('🔵 OpenVPN already initializing, waiting for completion...');
        await _initializationCompleter!.future;
      }
      return;
    }

    // If already initialized, no need to reinitialize
    if (_isInitialized) {
      print('🔵 OpenVPN already initialized');
      return;
    }

    // Mark as initializing
    _isInitializing = true;
    _initializationCompleter = Completer<void>();
    
    try {
      print('🔵 Starting OpenVPN initialization...');
      
      _openVPN = openvpn.OpenVPN(
        onVpnStatusChanged: (data) {
          print('🔵 OpenVPN onVpnStatusChanged callback triggered');
          _handleOpenVpnStatusChange(data);
        },
        onVpnStageChanged: (stage, message) {
          print('🔵 OpenVPN stage change: $stage - $message');
          _handleOpenVpnStageChange(stage.toString(), message);
        },
      );
      print('🟢 OpenVPN instance created successfully');

      // Initialize the OpenVPN engine (this is crucial for Android)
      if (Platform.isAndroid) {
        try {
          await _openVPN?.initialize(
            groupIdentifier: "group.com.softether.vpn.softether_vpn_client",
            providerBundleIdentifier: "com.softether.vpn.softether_vpn_client.NetworkExtension",
            localizedDescription: "SoftEther VPN Client",
          );
          print('🟢 OpenVPN Android engine initialized');
        } catch (e) {
          print('🟡 OpenVPN initialize method not available, trying alternative approach: $e');
          // Some versions of the plugin don't have initialize method
          // The plugin should work without it on newer versions
        }
      }

      _isInitialized = true;
      _initializationCompleter?.complete();
      print('🟢 OpenVPN setup completed');
    } catch (e) {
      print('🔴 OpenVPN initialization failed: $e');
      _initializationCompleter?.completeError(e);
    } finally {
      _isInitializing = false;
    }
  }

  void _initializeConnectivityMonitoring() {
    print('🔵 Initializing connectivity monitoring');
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    print('🔵 Connectivity changed: $results');

    final hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);

    if (!hasConnection && _currentStatus.status == 'connected') {
      print('🟡 Network lost while VPN connected - monitoring for recovery');
      _updateStatus(VpnConnectionStatusModel(
        status: 'connecting',
        configId: _currentConfig?.id,
        configName: _currentConfig?.name,
        errorMessage: 'Network connection lost - attempting to reconnect...',
      ));
    } else if (hasConnection && _currentStatus.status == 'connecting' &&
               _currentStatus.errorMessage?.contains('Network connection lost') == true) {
      print('🟢 Network recovered - VPN should reconnect automatically');
      _updateStatus(VpnConnectionStatusModel(
        status: 'connecting',
        configId: _currentConfig?.id,
        configName: _currentConfig?.name,
      ));
    }
  }

  void _handleOpenVpnStageChange(String stage, String message) {
    print('🔵 OpenVPN stage: $stage, message: $message');

    // Update status based on stage information
    String status = 'connecting';

    // Handle the stage string, which might be in the format "VPNStage.disconnected"
    final stageValue = stage.contains('.') ? stage.split('.').last : stage;

    switch (stageValue.toLowerCase()) {
      case 'connecting':
      case 'wait':
      case 'auth':
      case 'get_config':
      case 'assign_ip':
        status = 'connecting';
        break;
      case 'connected':
        status = 'connected';
        break;
      case 'disconnected':
      case 'reconnecting':
        status = 'disconnected';
        break;
      case 'error':
        status = 'error';
        break;
      default:
        print('🟡 Unknown OpenVPN stage: $stage (parsed as: $stageValue)');
        // Don't default to 'connecting' for unknown stages at startup
        // Keep the current status if we're not in a connection process
        if (_currentConfig == null) {
          // Not in a connection process, keep as disconnected
          status = 'disconnected';
        } else {
          // In a connection process, default to connecting
          status = 'connecting';
        }
        break;
    }

    _updateStatus(VpnConnectionStatusModel(
      status: status,
      configId: _currentConfig?.id,
      configName: _currentConfig?.name,
      connectedAt: status == 'connected' ? DateTime.now() : null,
      errorMessage: status == 'error' ? message : null,
    ));
  }

  @override
  Future<void> connect(VpnConfig config) async {
    try {
      print('🔵 VpnConnectionDataSource: Starting connection process');
      print('🔵 Config: ${config.name} (${config.protocol.displayName})');
      print('🔵 Server: ${config.serverAddress}:${config.serverPort}');

      _currentConfig = config;
      _updateStatus(const VpnConnectionStatusModel(status: 'connecting'));

      switch (config.protocol) {
        case VpnProtocol.l2tpIpsec:
          print('🔵 Using L2TP/IPSec protocol');
          await _connectL2TP(config);
          break;
        case VpnProtocol.openVpn:
          print('🔵 Using OpenVPN protocol');
          print('🔵 OpenVPN config length: ${config.ovpnConfig?.length ?? 0} characters');
          await _connectOpenVPN(config);
          break;
        case VpnProtocol.sslVpn:
          print('🔴 SSL-VPN not implemented');
          throw VpnConnectionException('SSL-VPN not yet implemented');
      }

      print('🔵 Connection initiation completed');
    } catch (e) {
      print('🔴 Connection failed: $e');
      print('🔴 Error type: ${e.runtimeType}');

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
    if (!Platform.isAndroid) {
      print('🔵 Non-Android platform, permission granted by default');
      return true;
    }

    try {
      print('🔵 Checking VPN permission on Android...');
      // Try to prepare VPN, if it fails, permission is not granted
      await FlutterVpn.prepare();
      print('🟢 VPN permission check successful');
      return true;
    } catch (e) {
      print('🔴 VPN permission check failed: $e');
      // If prepare fails, assume no permission
      return false;
    }
  }

  @override
  Future<bool> requestVpnPermission() async {
    if (!Platform.isAndroid) {
      print('🔵 Non-Android platform, permission granted by default');
      return true;
    }

    try {
      print('🔵 Requesting VPN permission...');
      // Prepare VPN connection (this will request permission if needed)
      await FlutterVpn.prepare();
      print('🟢 VPN permission request successful');
      return true;
    } catch (e) {
      print('🔴 VPN permission request failed: $e');
      throw PermissionException('Failed to request VPN permission: $e');
    }
  }

  Future<void> _connectL2TP(VpnConfig config) async {
    if (!Platform.isAndroid) {
      print('🔴 L2TP/IPSec only supported on Android');
      throw VpnConnectionException('L2TP/IPSec only supported on Android');
    }

    try {
      // Validate L2TP configuration
      final validationError = VpnConfigValidator.getL2TPValidationError(
        config.serverAddress,
        config.username,
        config.password,
      );
      if (validationError != null) {
        print('🔴 L2TP config validation failed: $validationError');
        throw VpnConnectionException('Invalid L2TP config: $validationError');
      }

      print('🔵 Starting L2TP/IPSec connection...');
      print('🔵 Server: ${config.serverAddress}');
      print('🔵 Username: ${config.username}');

      // First check and request permissions
      if (!await checkVpnPermission()) {
        print('🔵 VPN permission not granted, requesting...');
        final hasPermission = await requestVpnPermission();
        if (!hasPermission) {
          print('🔴 VPN permission denied by user');
          throw VpnConnectionException('VPN permission denied');
        }
      }

      print('🔵 Initiating L2TP/IPSec connection via FlutterVpn...');
      await FlutterVpn.connectIkev2EAP(
        server: config.serverAddress,
        username: config.username,
        password: config.password,
      );

      print('🟢 L2TP/IPSec connection initiated successfully');

      // Set connection timeout
      _startConnectionTimeout();

      // Connection initiated successfully, status will be updated via platform channels
      _updateStatus(VpnConnectionStatusModel(
        status: 'connecting',
        configId: config.id,
        configName: config.name,
      ));
    } catch (e) {
      print('🔴 L2TP connection failed: $e');
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

  Future<void> _ensureOpenVPNInitialized() async {
    // If not initialized or initializing, start initialization
    if (!_isInitialized && !_isInitializing) {
      print('🔵 OpenVPN not initialized, starting initialization...');
      await _initializeOpenVPN();
      return;
    }

    // If currently initializing, wait for it to complete
    if (_isInitializing && _initializationCompleter != null) {
      print('🔵 Waiting for OpenVPN initialization to complete...');
      await _initializationCompleter!.future;
      return;
    }

    // If already initialized, nothing to do
    if (_isInitialized) {
      print('🔵 OpenVPN already initialized');
      return;
    }
  }

  Future<void> _connectOpenVPN(VpnConfig config) async {
    // Validate OpenVPN configuration
    final validationError = VpnConfigValidator.getOpenVPNValidationError(config.ovpnConfig);
    if (validationError != null) {
      print('🔴 OpenVPN config validation failed: $validationError');
      throw VpnConnectionException('Invalid OpenVPN config: $validationError');
    }

    try {
      print('🔵 Starting OpenVPN connection...');
      print('🔵 Server: ${config.serverAddress}');
      print('🔵 Config preview: ${config.ovpnConfig!.substring(0, config.ovpnConfig!.length.clamp(0, 200))}...');

      // First check and request permissions
      if (Platform.isAndroid) {
        if (!await checkVpnPermission()) {
          print('🔵 VPN permission not granted, requesting...');
          final hasPermission = await requestVpnPermission();
          if (!hasPermission) {
            print('🔴 VPN permission denied by user');
            throw VpnConnectionException('VPN permission denied');
          }
        }
      }

      // Ensure OpenVPN is properly initialized before connecting
      try {
        await _ensureOpenVPNInitialized();
      } catch (initError) {
        print('🔴 OpenVPN initialization failed: $initError');
        // Reset initialization state to allow retry
        _resetInitializationState();
        throw VpnConnectionException('OpenVPN initialization failed: $initError');
      }

      if (_openVPN == null) {
        print('🔴 OpenVPN instance is null');
        throw VpnConnectionException('OpenVPN not initialized');
      }

      print('🔵 Initiating OpenVPN connection...');
      try {
        await _openVPN!.connect(
          config.ovpnConfig!,
          config.name,
          username: config.username,
          password: config.password,
          certIsRequired: false,
        );
      } catch (e) {
        // If the error says "need to be initialized", try to reinitialize
        if (e.toString().contains('need to be initialized')) {
          print('🔵 OpenVPN needs reinitialization, attempting to reinitialize...');
          // Reset initialization state and reinitialize
          _resetInitializationState();
          await _initializeOpenVPN();
          
          // Try connection again after reinitializing
          await _openVPN!.connect(
            config.ovpnConfig!,
            config.name,
            username: config.username,
            password: config.password,
            certIsRequired: false,
          );
        } else {
          rethrow;
        }
      }

      print('🟢 OpenVPN connection initiated successfully');

      // Set connection timeout
      _startConnectionTimeout();

      // OpenVPN status updates will be handled by the callback
    } catch (e) {
      print('🔴 OpenVPN connection failed: $e');
      print('🔴 Error type: ${e.runtimeType}');
      throw VpnConnectionException('OpenVPN connection failed: $e');
    }
  }

  Future<void> _disconnectOpenVPN() async {
    _openVPN?.disconnect();
    // Status update will be handled by the callback
  }

  void _handleOpenVpnStatusChange(openvpn.VpnStatus? data) {
    if (data == null) {
      print('🔴 OpenVPN status change callback received null data');
      return;
    }

    print('🔵 OpenVPN status change: ${data.toString()}');

    String status = 'disconnected'; // Default to disconnected instead of connecting
    DateTime? connectedAt;

    // Map OpenVPN status to our internal status
    final statusString = data.toString().toLowerCase();
    print('🔵 Status string: $statusString');

    switch (statusString) {
      case 'vpn_status_connected':
      case 'connected':
        print('🟢 OpenVPN status: CONNECTED');
        status = 'connected';
        connectedAt = DateTime.now();
        _clearConnectionTimeout(); // Clear timeout on successful connection
        break;
      case 'vpn_status_connecting':
      case 'connecting':
        print('🔵 OpenVPN status: CONNECTING');
        status = 'connecting';
        break;
      case 'vpn_status_disconnected':
      case 'disconnected':
        print('🔴 OpenVPN status: DISCONNECTED');
        status = 'disconnected';
        _currentConfig = null;
        _clearConnectionTimeout();
        break;
      case 'vpn_status_denied':
      case 'vpn_status_error':
      case 'error':
        print('🔴 OpenVPN status: ERROR/DENIED');
        status = 'error';
        _clearConnectionTimeout();
        break;
      default:
        print('🟡 OpenVPN status: UNKNOWN ($statusString)');
        // Don't default to 'connecting' for unknown statuses at startup
        // Keep the current status if we're not in a connection process
        if (_currentConfig == null) {
          // Not in a connection process, keep as disconnected
          status = 'disconnected';
        } else {
          // In a connection process, default to connecting
          status = 'connecting';
        }
        break;
    }

    print('🔵 Updating internal status to: $status');
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

  void _startConnectionTimeout() {
    _clearConnectionTimeout(); // Clear any existing timeout

    print('🔵 Starting 60-second connection timeout');
    _connectionTimeout = Timer(const Duration(seconds: 60), () {
      print('🔴 Connection timeout reached!');
      _updateStatus(VpnConnectionStatusModel(
        status: 'error',
        configId: _currentConfig?.id,
        configName: _currentConfig?.name,
        errorMessage: 'Connection timeout - server may be unreachable',
      ));
    });
  }

  void _clearConnectionTimeout() {
    if (_connectionTimeout != null) {
      print('🔵 Clearing connection timeout');
      _connectionTimeout?.cancel();
      _connectionTimeout = null;
    }
  }

  void _resetInitializationState() {
    _isInitializing = false;
    _isInitialized = false;
    _initializationCompleter = null;
  }

  void _updateStatus(VpnConnectionStatusModel newStatus) {
    print('🔵 Status update: ${newStatus.status} (${newStatus.configName ?? 'No config'})');
    if (newStatus.errorMessage != null) {
      print('🔴 Error message: ${newStatus.errorMessage}');
    }

    _currentStatus = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    print('🔵 Disposing VPN connection data source');
    _clearConnectionTimeout();
    _statusMonitor?.cancel();
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}