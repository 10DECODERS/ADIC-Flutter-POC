import 'package:flutter/material.dart';
import 'package:adic_poc/models/staff.dart';
import 'package:adic_poc/services/database_service.dart';
import 'package:adic_poc/services/sync_service.dart';
import 'dart:async';
import 'package:adic_poc/screens/staff_form_screen.dart';
import 'package:adic_poc/screens/staff_ai_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();
  final TextEditingController _searchController = TextEditingController();
  List<Staff> _staffList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showAIFeature = true;
  late StreamSubscription<bool> _connectivitySubscription;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _loadSettings();
    _syncService.syncData();
    
    // Subscribe to connectivity changes
    _connectivitySubscription = _dbService.connectivityStream.listen((isOnline) {
      // Update UI when connectivity status changes
      if (mounted) {
        setState(() {});
        
        // Try to sync data when coming back online
        if (isOnline) {
          _syncService.syncData();
        }
      }
    });
    
    // Set up periodic connectivity check every 10 seconds to catch any missed connectivity changes
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (mounted) {
        await _dbService.checkConnectivity();
      }
    });
  }

  @override
  void dispose() {
    // Cancel subscription and timer to avoid memory leaks
    _connectivitySubscription.cancel();
    _connectivityTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
    });
    
    final staffList = await _dbService.getAllStaff();
    
    setState(() {
      _staffList = staffList;
      _isLoading = false;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showAIFeature = prefs.getBool('showAIFeature') ?? true;
      });
    }
  }

  List<Staff> get _filteredStaffList {
    if (_searchQuery.isEmpty) {
      return _staffList;
    }
    
    final query = _searchQuery.toLowerCase();
    return _staffList.where((staff) {
      return staff.name.toLowerCase().contains(query) ||
             staff.position.toLowerCase().contains(query) ||
             staff.department.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        title: const Text(
          'Staff Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _dbService.isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _dbService.isOnline ? Colors.white : Colors.red.shade100,
            ),
            onPressed: () async {
              // Check connectivity status when icon is pressed
              bool isOnline = await _dbService.checkConnectivity();
              
              if (isOnline) {
                _syncService.syncData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.sync, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text('Syncing data with server...'),
                      ],
                    ),
                    backgroundColor: Colors.blue.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.signal_wifi_off, color: Colors.white),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('You are currently offline. Changes will be synced when online.'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.orange.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStaff,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue.shade700,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search staff...',
                      hintStyle: TextStyle(color: Colors.blue.shade100),
                      prefixIcon: Icon(Icons.search, color: Colors.blue.shade100),
                      filled: true,
                      fillColor: Colors.blue.shade600,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                if (_showAIFeature) ...[
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StaffAIChatScreen(),
                          ),
                        ).then((_) => _loadSettings());
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.smart_toy_outlined,
                              color: Colors.blue.shade100,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ask AI',
                              style: TextStyle(
                                color: Colors.blue.shade100,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    ),
                  )
                : _filteredStaffList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No staff records found'
                                  : 'No staff matching "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear search'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredStaffList.length,
                        padding: const EdgeInsets.only(top: 8),
                        itemBuilder: (context, index) {
                          final staff = _filteredStaffList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                staff.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    staff.position.isNotEmpty ? staff.position : 'No position',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    staff.department.isNotEmpty ? staff.department : 'No department',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _getSyncStatusIcon(staff.syncStatus),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getSyncStatusText(staff.syncStatus),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: Colors.blue.shade700,
                                    ),
                                    onPressed: () => _navigateToEditStaff(staff),
                                  ),
                                ],
                              ),
                              onTap: () => _showStaffDetails(staff),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _navigateToAddStaff(),
      ),
    );
  }

  Future<void> _navigateToAddStaff() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStaffScreen()),
    );
    
    if (result == true) {
      _loadStaff();
    }
  }

  Future<void> _navigateToEditStaff(Staff staff) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditStaffScreen(staff: staff)),
    );
    
    if (result == true) {
      _loadStaff();
    }
  }

  Widget _getSyncStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      case SyncStatus.created:
        return const Icon(Icons.add_circle, color: Colors.orange, size: 16);
      case SyncStatus.updated:
        return const Icon(Icons.update, color: Colors.orange, size: 16);
      case SyncStatus.deleted:
        return const Icon(Icons.highlight_off, color: Colors.red, size: 16);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _showStaffDetails(Staff staff) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile header
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.blue,
                  child: Text(
                    staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        staff.position.isNotEmpty ? staff.position : 'No position',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Staff Information section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Staff Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Information cards
            _infoCard('Department', staff.department, Icons.business),
            const SizedBox(height: 8),
            _infoCardWithAction(
              'Email', 
              staff.email, 
              Icons.email,
              onTap: () {
                // Launch email
              },
            ),
            const SizedBox(height: 8),
            _infoCardWithAction(
              'Phone', 
              staff.phone, 
              Icons.phone,
              onTap: () {
                // Launch phone call
              },
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToEditStaff(staff);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 14),
            
            // Bottom handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Safe area at bottom
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : 'Not specified',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _infoCardWithAction(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : 'Not specified',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                label == 'Email' ? Icons.email : Icons.phone,
                color: Colors.blue,
                size: 20,
              ),
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.created:
        return 'Created (not synced)';
      case SyncStatus.updated:
        return 'Updated (not synced)';
      case SyncStatus.deleted:
        return 'Deleted (not synced)';
      default:
        return '';
    }
  }
} 