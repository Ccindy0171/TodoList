import 'package:flutter/foundation.dart';
import '../services/network_scanner_service.dart';
import '../services/graphql_service.dart';

class ServerDiscoveryProvider with ChangeNotifier {
  final NetworkScannerService _networkScanner = NetworkScannerService();
  final GraphQLService _graphQLService;
  
  bool _isScanning = false;
  String? _error;

  // Constructor takes the GraphQLService
  ServerDiscoveryProvider(this._graphQLService) {
    // Initialize with any previously selected server
    _initializeSelectedServer();
    // Set up listener for server changes
    _networkScanner.serversStream.listen((_) {
      notifyListeners();
    });
  }

  // Getters
  List<GraphQLServerInfo> get discoveredServers => _networkScanner.discoveredServers;
  bool get isScanning => _isScanning;
  String? get error => _error;
  String? get selectedServerUrl => _networkScanner.selectedServerUrl;
  Stream<List<GraphQLServerInfo>> get serversStream => _networkScanner.serversStream;

  // Initialize with the previously selected server
  Future<void> _initializeSelectedServer() async {
    try {
      final selectedUrl = _networkScanner.selectedServerUrl;
      if (selectedUrl != null) {
        print('? ServerDiscoveryProvider: Initializing with previously selected server: $selectedUrl');
        
        // Ensure the GraphQLService uses this URL
        await _graphQLService.setServerUrl(selectedUrl);
        
        // Verify the URL was set correctly
        if (_graphQLService.serverUrl != selectedUrl) {
          print('? ServerDiscoveryProvider: ERROR - Failed to set server URL');
          print('?   Expected: $selectedUrl');
          print('?   Actual: ${_graphQLService.serverUrl}');
          
          // Try again with a different approach
          await _graphQLService.setServerUrl(selectedUrl);
        } else {
          print('? ServerDiscoveryProvider: Successfully set server URL');
        }
      } else {
        print('? ServerDiscoveryProvider: No previously selected server found');
      }
    } catch (e) {
      print('? ServerDiscoveryProvider: Error initializing selected server: $e');
    }
  }

  // Start network scanning
  Future<void> scanNetwork() async {
    if (_isScanning) return;
    
    _isScanning = true;
    _error = null;
    notifyListeners();

    try {
      await _networkScanner.scanNetwork();
    } catch (e) {
      _error = e.toString();
      print('Error scanning network: $_error');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  // Add a server manually
  Future<bool> addManualServer(String ipAddress, int port) async {
    _error = null;
    try {
      final success = await _networkScanner.addManualServer(ipAddress, port);
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Select a server
  Future<void> selectServer(String serverUrl) async {
    try {
      print('? ServerDiscoveryProvider: Selecting server: $serverUrl');
      
      // First update the network scanner's selection
      await _networkScanner.selectServer(serverUrl);
      
      // Then update the GraphQL service with the new URL
      // This is the critical step that was possibly failing
      await _graphQLService.setServerUrl(serverUrl);
      
      // When a server is explicitly selected, make sure we don't prompt for config
      // and don't use default URL (respect this explicit choice)
      if (_graphQLService.isUsingDefaultUrl) {
        // If it's the default URL, allow using it since it was explicitly selected
        await _graphQLService.setAllowDefaultUrl(true);
        print('? ServerDiscoveryProvider: Using default URL with explicit permission');
      } else {
        // For non-default URLs, make sure we don't show config screen
        // by setting allowDefaultUrl to false (meaning we have a configured server)
        await _graphQLService.setAllowDefaultUrl(false);
        print('? ServerDiscoveryProvider: Using non-default URL: $serverUrl');
      }
      
      // Verify the GraphQL service has the expected URL
      if (_graphQLService.serverUrl != serverUrl) {
        print('? ServerDiscoveryProvider: WARNING - GraphQLService URL mismatch!');
        print('?   Expected: $serverUrl');
        print('?   Actual: ${_graphQLService.serverUrl}');
        
        // Try setting it one more time
        await _graphQLService.setServerUrl(serverUrl);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('? ServerDiscoveryProvider: Error selecting server: $_error');
      notifyListeners();
    }
  }

  // Rename a server
  Future<void> renameServer(String url, String newName) async {
    try {
      await _networkScanner.renameServer(url, newName);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Remove a server
  Future<void> removeServer(String url) async {
    try {
      await _networkScanner.removeServer(url);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get recent server IPs
  Future<List<String>> getRecentServerIPs() async {
    return await _networkScanner.getRecentServerIPs();
  }

  @override
  void dispose() {
    _networkScanner.dispose();
    super.dispose();
  }
} 