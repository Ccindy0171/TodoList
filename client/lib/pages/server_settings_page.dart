import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/server_discovery_provider.dart';
import '../services/network_scanner_service.dart';

class ServerSettingsPage extends StatefulWidget {
  const ServerSettingsPage({super.key});

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '8080');
  final TextEditingController _serverNameController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _serverNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GraphQL Server Settings'),
      ),
      body: Consumer<ServerDiscoveryProvider>(
        builder: (context, provider, child) {
          final discoveredServers = provider.discoveredServers;
          final selectedUrl = provider.selectedServerUrl;
          
          return Column(
            children: [
              // Header with action buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'GraphQL Servers',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: provider.isScanning
                              ? null
                              : () => provider.scanNetwork(),
                          icon: const Icon(Icons.search),
                          label: const Text('Scan Network'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discovered ${discoveredServers.length} server(s)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (provider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          provider.error!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Manual server entry
              Card(
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Server Manually',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // IP Address
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _ipController,
                              decoration: const InputDecoration(
                                labelText: 'IP Address',
                                hintText: '192.168.1.100',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Port
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _portController,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                                hintText: '8080',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_ipController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter an IP address'),
                                ),
                              );
                              return;
                            }
                            
                            final port = int.tryParse(_portController.text) ?? 8080;
                            final success = await provider.addManualServer(
                              _ipController.text, 
                              port,
                            );
                            
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Server added successfully'),
                                ),
                              );
                              _ipController.clear();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to add server. Verify it is a valid GraphQL server.'),
                                ),
                              );
                            }
                          },
                          child: const Text('Add Server'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // List of servers
              Expanded(
                child: provider.isScanning
                    ? const Center(child: CircularProgressIndicator())
                    : discoveredServers.isEmpty
                        ? Center(
                            child: Text(
                              'No servers found. Tap "Scan Network" to discover GraphQL servers.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: discoveredServers.length,
                            itemBuilder: (context, index) {
                              final server = discoveredServers[index];
                              final isSelected = server.url == selectedUrl;
                              
                              return ListTile(
                                leading: Icon(
                                  server.isVerified
                                      ? Icons.verified
                                      : Icons.warning,
                                  color: server.isVerified
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                title: Text(server.name ?? 'Unnamed Server'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(server.url),
                                    Text(
                                      'Last seen: ${_formatDate(server.lastSeen)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.more_vert),
                                        onPressed: () {
                                          _showServerOptions(context, server);
                                        },
                                      ),
                                selected: isSelected,
                                onTap: () {
                                  if (!isSelected) {
                                    provider.selectServer(server.url);
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  void _showServerOptions(BuildContext context, GraphQLServerInfo server) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Use this server'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<ServerDiscoveryProvider>().selectServer(server.url);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(context, server);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(context, server);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, GraphQLServerInfo server) {
    _serverNameController.text = server.name ?? '';
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Rename Server'),
          content: TextField(
            controller: _serverNameController,
            decoration: const InputDecoration(
              labelText: 'Server Name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_serverNameController.text.isNotEmpty) {
                  context.read<ServerDiscoveryProvider>().renameServer(
                    server.url,
                    _serverNameController.text,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, GraphQLServerInfo server) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Remove Server'),
          content: Text('Are you sure you want to remove "${server.name ?? server.url}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<ServerDiscoveryProvider>().removeServer(server.url);
                Navigator.pop(ctx);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
} 