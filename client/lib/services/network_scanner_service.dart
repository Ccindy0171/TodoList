import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GraphQLServerInfo {
  final String address;
  final String url;
  final bool isVerified;
  final String? name;
  final DateTime lastSeen;

  GraphQLServerInfo({
    required this.address,
    required this.url,
    required this.isVerified,
    this.name,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  factory GraphQLServerInfo.fromJson(Map<String, dynamic> json) {
    return GraphQLServerInfo(
      address: json['address'] as String,
      url: json['url'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      name: json['name'] as String?,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'url': url,
      'isVerified': isVerified,
      'name': name,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }
}

class NetworkScannerService {
  // Store found servers
  final List<GraphQLServerInfo> _discoveredServers = [];
  String? _selectedServerUrl;
  final StreamController<List<GraphQLServerInfo>> _serversStreamController = 
      StreamController<List<GraphQLServerInfo>>.broadcast();

  Stream<List<GraphQLServerInfo>> get serversStream => _serversStreamController.stream;
  List<GraphQLServerInfo> get discoveredServers => List.unmodifiable(_discoveredServers);
  String? get selectedServerUrl => _selectedServerUrl;

  // Common GraphQL ports to scan
  static const List<int> _portsToScan = [8080, 4000, 3000, 5000, 9000, 8000];
  
  // GraphQL introspection query to verify server capabilities
  static const String _introspectionQuery = '''
  query {
    __schema {
      queryType {
        name
        fields {
          name
        }
      }
      mutationType {
        name
        fields {
          name
        }
      }
    }
  }
  ''';

  NetworkScannerService() {
    _loadSavedServers();
  }

  // Load previously discovered servers from SharedPreferences
  Future<void> _loadSavedServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedServers = prefs.getStringList('discovered_servers') ?? [];
      final selectedServer = prefs.getString('selected_server');

      _discoveredServers.clear();
      for (final serverJson in savedServers) {
        try {
          final Map<String, dynamic> serverMap = 
              jsonDecode(serverJson) as Map<String, dynamic>;
          
          final server = GraphQLServerInfo.fromJson(serverMap);
          _discoveredServers.add(server);
        } catch (e) {
          print('Error loading saved server: $e');
        }
      }

      _selectedServerUrl = selectedServer;
      
      // Notify listeners
      _serversStreamController.add(_discoveredServers);
    } catch (e) {
      print('Error loading saved servers: $e');
    }
  }

  // Save discovered servers to SharedPreferences
  Future<void> _saveServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final serversToSave = _discoveredServers.map((server) {
        return jsonEncode(server.toJson());
      }).toList();
      
      await prefs.setStringList('discovered_servers', serversToSave);
      
      if (_selectedServerUrl != null) {
        await prefs.setString('selected_server', _selectedServerUrl!);
        
        // Also save the selected server's IP to recent IPs if it's not a default URL
        if (!_selectedServerUrl!.contains('10.0.2.2') && 
            !_selectedServerUrl!.contains('localhost') &&
            !_selectedServerUrl!.contains('127.0.0.1')) {
          try {
            // Extract IP from URL
            final uri = Uri.parse(_selectedServerUrl!);
            final host = uri.host;
            
            // Get existing IPs and add the selected one
            final existingIPs = prefs.getStringList('recent_server_ips') ?? [];
            if (!existingIPs.contains(host)) {
              existingIPs.add(host);
              await prefs.setStringList('recent_server_ips', existingIPs);
              print('? NetworkScanner: Saved selected server IP: $host to recent IPs');
            }
          } catch (e) {
            print('? NetworkScanner: Error extracting IP from URL: $e');
          }
        }
      }
      
      // Also save a list of recent server IPs for history
      final recentIps = _discoveredServers
          .where((s) => !s.url.contains('10.0.2.2') && !s.url.contains('localhost'))
          .map((s) => s.address)
          .toSet()
          .toList();
      
      // Merge with existing recent IPs
      final existingIPs = prefs.getStringList('recent_server_ips') ?? [];
      final combinedIPs = {...existingIPs, ...recentIps}.toList();
      
      await prefs.setStringList('recent_server_ips', combinedIPs);
      
      print('? NetworkScanner: Saved ${_discoveredServers.length} servers and ${combinedIPs.length} recent IPs');
    } catch (e) {
      print('? NetworkScanner: Error saving servers: $e');
    }
  }

  // Set the selected server
  Future<void> selectServer(String serverUrl) async {
    _selectedServerUrl = serverUrl;
    await _saveServers();
    
    // Notify that servers changed (to update UI with new selection)
    _serversStreamController.add(_discoveredServers);
  }

  // Manual entry of a server
  Future<bool> addManualServer(String ipAddress, int port) async {
    final url = 'http://$ipAddress:$port/query';
    
    try {
      final verified = await _verifyGraphQLServer(url);
      
      if (verified) {
        _addDiscoveredServer(ipAddress, port, verified);
        return true;
      } else {
        // Even if verification fails, still add the server but mark as unverified
        // This allows users to add servers that might be temporarily offline
        // or have non-standard GraphQL setups
        print('? NetworkScanner: Server verification failed, adding as unverified');
        _addDiscoveredServer(ipAddress, port, false);
        return true;
      }
    } catch (e) {
      print('? NetworkScanner: Error adding manual server: $e');
      // Still add the server even on connection error, just mark it as unverified
      _addDiscoveredServer(ipAddress, port, false);
      return true;
    }
  }

  // Get the local IP address
  Future<String?> _getLocalIpAddress() async {
    try {
      final info = NetworkInfo();
      return await info.getWifiIP();
    } catch (e) {
      print('Error getting local IP: $e');
      return null;
    }
  }

  // Check if a host is reachable
  Future<bool> _isHostReachable(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, 
          timeout: const Duration(milliseconds: 300))
          .catchError((e) => null);
      
      if (socket != null) {
        await socket.close();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Scan the network for GraphQL servers
  Future<List<GraphQLServerInfo>> scanNetwork() async {
    final localIp = await _getLocalIpAddress();
    if (localIp == null) {
      return _discoveredServers;
    }

    // Get the subnet base
    final subnet = localIp.substring(0, localIp.lastIndexOf('.'));
    print('Scanning subnet: $subnet.*');

    // For each potential host in the subnet
    for (int i = 1; i < 255; i++) {
      final host = '$subnet.$i';
      
      // Check each port
      for (final port in _portsToScan) {
        if (await _isHostReachable(host, port)) {
          print('Found device at $host:$port');
          
          // Verify if it's a GraphQL server
          final url = 'http://$host:$port/query';
          final isGraphQL = await _verifyGraphQLServer(url);
          
          if (isGraphQL) {
            _addDiscoveredServer(host, port, isGraphQL);
          }
        }
      }
    }

    // Save discovered servers
    await _saveServers();
    
    return _discoveredServers;
  }

  // Verify if the given URL is a GraphQL server with the required capabilities
  Future<bool> _verifyGraphQLServer(String url) async {
    try {
      // Attempt to make a GraphQL introspection query
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: '{"query": "${_introspectionQuery.replaceAll('\n', ' ').replaceAll('"', '\\"')}"}',
      ).timeout(const Duration(seconds: 5));

      // For GraphQL servers, we care more about the response structure
      // than the HTTP status code - some servers return 400 for GET
      // but still work fine with POST requests
      if (response.statusCode >= 200 && response.statusCode < 500) {
        try {
          // Check for expected GraphQL response structure
          final body = response.body;
          final jsonResponse = jsonDecode(body);
          
          // If we have data or a proper schema, consider it a success
          final hasData = jsonResponse.containsKey('data');
          
          if (hasData) {
            // Check if it contains the schema information
            final hasSchema = body.contains('"__schema"') && 
                              body.contains('"queryType"');
            
            // Check for specific queries we need
            final hasTodosQuery = body.contains('"todos"') || 
                                  body.contains('"name":"todos"');
            
            // Check for specific mutations we need
            final hasRequiredMutations = body.contains('"createTodo"') || 
                                         body.contains('"name":"createTodo"');
            
            return hasSchema || hasTodosQuery || hasRequiredMutations;
          }
        } catch (e) {
          print('? NetworkScanner: Error parsing GraphQL response: $e');
          return false;
        }
      }
      
      return false;
    } catch (e) {
      print('? NetworkScanner: Error verifying GraphQL server at $url: $e');
      return false;
    }
  }

  // Add or update a discovered server
  void _addDiscoveredServer(String host, int port, bool isVerified) {
    final url = 'http://$host:$port/query';
    
    // Check if we already found this server
    final existingIndex = _discoveredServers.indexWhere((s) => s.url == url);
    
    if (existingIndex >= 0) {
      // Update existing server info
      _discoveredServers[existingIndex] = GraphQLServerInfo(
        address: host,
        url: url,
        isVerified: isVerified,
        name: _discoveredServers[existingIndex].name,
        lastSeen: DateTime.now(),
      );
    } else {
      // Add new server
      _discoveredServers.add(GraphQLServerInfo(
        address: host,
        url: url,
        isVerified: isVerified,
        name: 'GraphQL Server ($host:$port)',
      ));
    }
    
    // Notify listeners
    _serversStreamController.add(_discoveredServers);
  }

  // Rename a server
  Future<void> renameServer(String url, String newName) async {
    final index = _discoveredServers.indexWhere((s) => s.url == url);
    if (index >= 0) {
      final server = _discoveredServers[index];
      _discoveredServers[index] = GraphQLServerInfo(
        address: server.address,
        url: server.url,
        isVerified: server.isVerified,
        name: newName,
        lastSeen: server.lastSeen,
      );
      
      // Save and notify
      await _saveServers();
      _serversStreamController.add(_discoveredServers);
    }
  }

  // Remove a server
  Future<void> removeServer(String url) async {
    _discoveredServers.removeWhere((s) => s.url == url);
    
    // If we removed the selected server, clear selection
    if (_selectedServerUrl == url) {
      _selectedServerUrl = null;
    }
    
    // Save and notify
    await _saveServers();
    _serversStreamController.add(_discoveredServers);
  }

  // Clean up resources
  void dispose() {
    _serversStreamController.close();
  }

  // Get list of recent server IPs
  Future<List<String>> getRecentServerIPs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentIps = prefs.getStringList('recent_server_ips') ?? [];
      
      // Filter to exclude localhost and emulator addresses
      return recentIps.where((ip) => 
        !ip.contains('10.0.2.2') && 
        !ip.contains('localhost') &&
        !ip.contains('127.0.0.1')
      ).toList();
    } catch (e) {
      print('? NetworkScanner: Error getting recent IPs: $e');
      return [];
    }
  }
}