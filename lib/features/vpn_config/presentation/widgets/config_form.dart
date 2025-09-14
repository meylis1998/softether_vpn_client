import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vpn_config.dart';
import '../bloc/vpn_config_bloc.dart';

class ConfigForm extends StatefulWidget {
  final Function(VpnConfig) onSave;
  final VpnConfig? initialConfig;

  const ConfigForm({
    super.key,
    required this.onSave,
    this.initialConfig,
  });

  @override
  State<ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends State<ConfigForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serverController = TextEditingController();
  final _portController = TextEditingController(text: '1194');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pskController = TextEditingController();
  final _hubController = TextEditingController();
  final _ovpnConfigController = TextEditingController();

  VpnProtocol _selectedProtocol = VpnProtocol.l2tpIpsec;

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      _populateForm(widget.initialConfig!);
    }
  }

  void _populateForm(VpnConfig config) {
    _nameController.text = config.name;
    _serverController.text = config.serverAddress;
    _portController.text = config.serverPort.toString();
    _usernameController.text = config.username;
    _passwordController.text = config.password;
    _pskController.text = config.presharedKey ?? '';
    _hubController.text = config.hubName ?? '';
    _ovpnConfigController.text = config.ovpnConfig ?? '';
    _selectedProtocol = config.protocol;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicFields(),
            const SizedBox(height: 20),
            _buildProtocolSelector(),
            const SizedBox(height: 20),
            _buildProtocolSpecificFields(),
            const SizedBox(height: 20),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Configuration Name',
                hintText: 'e.g., Office VPN',
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: 'Server Address',
                hintText: 'vpn.example.com or IP address',
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Server address is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'Port is required';
                final port = int.tryParse(value!);
                if (port == null || port < 1 || port > 65535) {
                  return 'Invalid port number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Username is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
              validator: (value) =>
                  value?.isEmpty == true ? 'Password is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VPN Protocol',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...VpnProtocol.values.map((protocol) {
              return RadioListTile<VpnProtocol>(
                title: Text(protocol.displayName),
                subtitle: Text(_getProtocolDescription(protocol)),
                value: protocol,
                groupValue: _selectedProtocol,
                onChanged: protocol == VpnProtocol.sslVpn
                    ? null // Disable SSL-VPN for now
                    : (value) {
                        setState(() {
                          _selectedProtocol = value!;
                        });
                      },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolSpecificFields() {
    switch (_selectedProtocol) {
      case VpnProtocol.l2tpIpsec:
        return _buildL2TPFields();
      case VpnProtocol.openVpn:
        return _buildOpenVPNFields();
      case VpnProtocol.sslVpn:
        return _buildSSLVPNFields();
    }
  }

  Widget _buildL2TPFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'L2TP/IPSec Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pskController,
              decoration: const InputDecoration(
                labelText: 'Pre-shared Key (PSK)',
                hintText: 'Leave empty if not required',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hubController,
              decoration: const InputDecoration(
                labelText: 'Hub Name (SoftEther)',
                hintText: 'For SoftEther VPN servers',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Android 4.0+ may have issues with PSK longer than 9 characters.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenVPNFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OpenVPN Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ovpnConfigController,
              decoration: const InputDecoration(
                labelText: 'OpenVPN Config (.ovpn)',
                hintText: 'Paste your .ovpn config here',
              ),
              maxLines: 8,
              validator: _selectedProtocol == VpnProtocol.openVpn
                  ? (value) => value?.isEmpty == true
                      ? 'OpenVPN config is required'
                      : null
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _loadOvpnFromFile,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Load from File'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _showOvpnInstructions,
                  child: const Text('Instructions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSSLVPNFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SSL-VPN Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'SSL-VPN support is coming in a future update.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return BlocBuilder<VpnConfigBloc, VpnConfigState>(
      builder: (context, state) {
        final isSaving = state is VpnConfigLoaded && state.isSaving;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : _saveConfig,
            child: isSaving
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Saving...'),
                    ],
                  )
                : const Text('Save Configuration'),
          ),
        );
      },
    );
  }

  String _getProtocolDescription(VpnProtocol protocol) {
    switch (protocol) {
      case VpnProtocol.l2tpIpsec:
        return 'Built into Android, works with SoftEther L2TP';
      case VpnProtocol.openVpn:
        return 'Uses OpenVPN protocol, requires .ovpn config';
      case VpnProtocol.sslVpn:
        return 'Native SoftEther SSL-VPN (coming soon)';
    }
  }

  void _saveConfig() {
    if (_formKey.currentState?.validate() == true) {
      final config = VpnConfig(
        id: widget.initialConfig?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        serverAddress: _serverController.text,
        serverPort: int.parse(_portController.text),
        protocol: _selectedProtocol,
        username: _usernameController.text,
        password: _passwordController.text,
        presharedKey: _pskController.text.isEmpty ? null : _pskController.text,
        hubName: _hubController.text.isEmpty ? null : _hubController.text,
        ovpnConfig: _ovpnConfigController.text.isEmpty
            ? null
            : _ovpnConfigController.text,
        createdAt: widget.initialConfig?.createdAt ?? DateTime.now(),
      );

      widget.onSave(config);
    }
  }

  void _loadOvpnFromFile() {
    // TODO: Implement file picker to load .ovpn files
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File picker not implemented yet. Please paste config manually.'),
      ),
    );
  }

  void _showOvpnInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OpenVPN Configuration'),
        content: const SingleChildScrollView(
          child: Text(
            '1. On your SoftEther VPN Server, enable OpenVPN Clone Function\n\n'
            '2. Generate and download the OpenVPN config files\n\n'
            '3. Open the .ovpn file in a text editor\n\n'
            '4. Copy the entire contents and paste it in the config field above\n\n'
            '5. Make sure the username and password fields match your VPN user account',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pskController.dispose();
    _hubController.dispose();
    _ovpnConfigController.dispose();
    super.dispose();
  }
}