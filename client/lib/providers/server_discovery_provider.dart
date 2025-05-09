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
  }

  // Getters
  List<GraphQLServerInfo> get discoveredServers => _networkScanner.discoveredServers;
  bool get isScanning => _isScanning;
  String? get error => _error;
  String? get selectedServerUrl => _networkScanner.selectedServerUrl;

  // Initialize with the previously selected server
  Future<void> _initializeSelectedServer() async {
    final selectedUrl = _networkScanner.selectedServerUrl;
    if (selectedUrl != null) {
      await _graphQLService.setServerUrl(selectedUrl);
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
      await _networkScanner.selectServer(serverUrl);
      await _graphQLService.setServerUrl(serverUrl);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
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

  @override
  void dispose() {
    _networkScanner.dispose();
    super.dispose();
  }
} 