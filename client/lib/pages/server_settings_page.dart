import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/server_discovery_provider.dart';
import '../services/network_scanner_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/graphql_service.dart';
import '../l10n/app_localizations.dart';

class ServerSettingsPage extends StatefulWidget {
  const ServerSettingsPage({super.key});

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '8080');
  final TextEditingController _serverNameController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;
  List<String> _recentIPs = [];
  bool _loadingRecentIPs = true;

  @override
  void initState() {
    super.initState();
    _loadRecentIPs();
  }
  
  Future<void> _loadRecentIPs() async {
    setState(() {
      _loadingRecentIPs = true;
    });
    
    try {
      final ips = await context.read<ServerDiscoveryProvider>().getRecentServerIPs();
      if (mounted) {
        setState(() {
          _recentIPs = ips;
          _loadingRecentIPs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRecentIPs = false;
        });
      }
    }
  }

  // Test connection to server
  Future<void> _testConnection(String url) async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    bool httpSuccess = false;
    bool graphqlSuccess = false;
    String httpResult = '';
    String graphqlResult = '';

    try {
      // Try a simple HTTP request to the server
      try {
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
          onTimeout: () => http.Response('Timeout', 408),
        );
        
        httpSuccess = response.statusCode == 200;
        httpResult = 'HTTP GET ${httpSuccess ? 'successful' : 'failed'}: ${response.statusCode}';
      } catch (e) {
        httpResult = 'HTTP GET failed: $e';
      }
      
      // Try a simple GraphQL introspection query
      try {
        final graphQLResponse = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': '{__typename}',
          }),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => http.Response('Timeout', 408),
        );
        
        if (graphQLResponse.statusCode == 200) {
          final responseBody = jsonDecode(graphQLResponse.body);
          graphqlSuccess = responseBody.containsKey('data');
          graphqlResult = 'GraphQL query successful: ${responseBody.toString()}';
        } else {
          graphqlResult = 'GraphQL query failed: HTTP ${graphQLResponse.statusCode}';
        }
      } catch (e) {
        graphqlResult = 'GraphQL query error: $e';
      }
      
      // Set final result - consider it a success if GraphQL works, even if HTTP GET fails
      setState(() {
        if (graphqlSuccess) {
          // If GraphQL works, the server is functional for our app's needs
          _testResult = 'CONNECTION SUCCESSFUL ?\n\n' +
                      (httpSuccess ? '? ' : '?? ') + httpResult + '\n' +
                      '? ' + graphqlResult;
        } else {
          // If GraphQL fails, the connection test failed
          _testResult = 'CONNECTION FAILED ?\n\n' +
                      (httpSuccess ? '? ' : '? ') + httpResult + '\n' +
                      '? ' + graphqlResult;
        }
      });
    } catch (e) {
      setState(() {
        _testResult = 'Connection error: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _serverNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.serverSettings),
      ),
      body: Consumer<ServerDiscoveryProvider>(
        builder: (context, provider, child) {
          final discoveredServers = provider.discoveredServers;
          final selectedUrl = provider.selectedServerUrl;
          
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              localizations.serverSettings,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: provider.isScanning
                                ? null
                                : () => provider.scanNetwork(),
                            icon: const Icon(Icons.search),
                            label: Text(localizations.search),
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
                      
                      // Test connection section
                      if (selectedUrl != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${localizations.connectedTo} $selectedUrl',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isTesting
                                  ? null
                                  : () => _testConnection(selectedUrl),
                              icon: const Icon(Icons.network_check),
                              label: Text(localizations.tryAgain),
                            ),
                          ],
                        ),
                        if (_isTesting)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        if (_testResult != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              color: _testResult!.contains('CONNECTION SUCCESSFUL')
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              child: Text(
                                _testResult!,
                                style: TextStyle(
                                  color: _testResult!.contains('CONNECTION SUCCESSFUL')
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ),
                      ],
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
                          localizations.serverConfigManual,
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
                        
                        // Recent IPs section
                        if (_recentIPs.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Recent Servers',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _recentIPs.map((ip) {
                              return ActionChip(
                                avatar: const Icon(Icons.history, size: 16),
                                label: Text(ip),
                                onPressed: () {
                                  _ipController.text = ip;
                                  // Also try to add the server immediately with default port
                                  final port = int.tryParse(_portController.text) ?? 8080;
                                  provider.addManualServer(ip, port).then((success) {
                                    if (success && mounted) {
                                      // If successful, also select this server
                                      final serverUrl = 'http://$ip:$port/query';
                                      provider.selectServer(serverUrl);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(localizations.usingConfiguredServer),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ] else if (_loadingRecentIPs) ...[
                          const SizedBox(height: 16),
                          const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_ipController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(localizations.pleaseEnterTitle),
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
                                // Also select this server automatically
                                final serverUrl = 'http://${_ipController.text}:$port/query';
                                await provider.selectServer(serverUrl);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(localizations.usingConfiguredServer),
                                  ),
                                );
                                _ipController.clear();
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(localizations.cannotConnectToServer),
                                  ),
                                );
                              }
                            },
                            child: Text(localizations.save),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // List of servers
                provider.isScanning
                    ? const Center(child: CircularProgressIndicator())
                    : discoveredServers.isEmpty
                        ? _buildNoServersFound(context, provider)
                        : _buildServerList(context, discoveredServers, selectedUrl),
              ],
            ),
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
    final localizations = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check),
                title: Text(localizations.usingConfiguredServer),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<ServerDiscoveryProvider>().selectServer(server.url);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(localizations.edit),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(context, server);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(localizations.delete),
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
    final localizations = AppLocalizations.of(context);
    _serverNameController.text = server.name ?? '';
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(localizations.edit),
          content: TextField(
            controller: _serverNameController,
            decoration: InputDecoration(
              labelText: localizations.title,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text(localizations.cancel),
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
              child: Text(localizations.save),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, GraphQLServerInfo server) {
    final localizations = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(localizations.delete),
          content: Text(localizations.deleteConfirm.replaceAll('{name}', server.name ?? server.url)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () {
                context.read<ServerDiscoveryProvider>().removeServer(server.url);
                Navigator.pop(ctx);
              },
              child: Text(localizations.delete),
            ),
          ],
        );
      },
    );
  }

  // Extract the "No servers found" widget to a separate method for better organization
  Widget _buildNoServersFound(BuildContext context, ServerDiscoveryProvider provider) {
    final localizations = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.public_off,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.noResults,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            localizations.serverConfigInfo,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => provider.scanNetwork(),
            icon: const Icon(Icons.search),
            label: Text(localizations.search),
          ),
        ],
      ),
    );
  }
  
  // Extract the server list to a separate method for better organization
  Widget _buildServerList(BuildContext context, List<GraphQLServerInfo> discoveredServers, String? selectedUrl) {
    final localizations = AppLocalizations.of(context);
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling as parent is scrollable
      padding: EdgeInsets.zero, // Remove padding to avoid unexpected spacing
      itemCount: discoveredServers.length,
      itemBuilder: (context, index) {
        final server = discoveredServers[index];
        final isSelected = server.url == selectedUrl;
        final isDefaultUrl = server.url.contains('10.0.2.2') || 
                           server.url.contains('localhost');
        
        return ListTile(
          leading: Icon(
            isDefaultUrl
                ? Icons.phonelink_setup
                : server.isVerified
                    ? Icons.verified
                    : Icons.warning,
            color: isDefaultUrl
                ? Colors.orange
                : server.isVerified
                    ? Colors.green
                    : Colors.orange,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(server.name ?? localizations.appTitle),
              ),
              if (isDefaultUrl)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    localizations.usingDefaultConnection,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
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
              print('ℹ️ ServerSettings: User selected server: ${server.url}');
              
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.attemptingReconnect),
                  duration: Duration(seconds: 1),
                ),
              );
              
              // First, get the current GraphQLService and check its URL
              final graphQLService = Provider.of<GraphQLService>(context, listen: false);
              print('ℹ️ ServerSettings: Current GraphQLService URL: ${graphQLService.serverUrl}');
              
              // Select the server
              Provider.of<ServerDiscoveryProvider>(context, listen: false).selectServer(server.url).then((_) {
                // Double-check both the provider and service have the correct URL
                final updatedProvider = Provider.of<ServerDiscoveryProvider>(context, listen: false);
                print('ℹ️ ServerSettings: After selection - Provider URL: ${updatedProvider.selectedServerUrl}');
                print('ℹ️ ServerSettings: After selection - GraphQLService URL: ${graphQLService.serverUrl}');
                
                // Verify server selection was successful in both places
                if (updatedProvider.selectedServerUrl == server.url && 
                    graphQLService.serverUrl == server.url) {
                  print('ℹ️ ServerSettings: URL successfully set in both places');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.connectedTo + ' ' + (server.name ?? server.url)),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  print('ℹ️ ServerSettings: URL MISMATCH DETECTED!');
                  print('ℹ️ ServerSettings: Provider URL: ${updatedProvider.selectedServerUrl}');
                  print('ℹ️ ServerSettings: GraphQLService URL: ${graphQLService.serverUrl}');
                  
                  // Try to force the GraphQLService to use the correct URL
                  graphQLService.setServerUrl(server.url).then((_) {
                    // Check if the fix worked
                    print('ℹ️ ServerSettings: After fix - GraphQLService URL: ${graphQLService.serverUrl}');
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(graphQLService.serverUrl == server.url 
                          ? localizations.usingConfiguredServer 
                          : localizations.cannotConnectToServer),
                        backgroundColor: graphQLService.serverUrl == server.url 
                          ? Colors.green 
                          : Colors.red,
                      ),
                    );
                  });
                }
              });
            }
          },
        );
      },
    );
  }
} 