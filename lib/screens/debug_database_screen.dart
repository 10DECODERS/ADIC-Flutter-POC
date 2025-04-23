import 'package:flutter/material.dart';
import 'package:adic_poc/models/staff.dart';
import 'package:adic_poc/services/database_service.dart';
import 'package:adic_poc/services/sync_service.dart';

class DebugDatabaseScreen extends StatefulWidget {
  const DebugDatabaseScreen({super.key});

  @override
  State<DebugDatabaseScreen> createState() => _DebugDatabaseScreenState();
}

class _DebugDatabaseScreenState extends State<DebugDatabaseScreen> {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();
  List<Staff> _allStaff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllRecords();
  }

  Future<void> _loadAllRecords() async {
    setState(() {
      _isLoading = true;
    });

    final allStaff = await _dbService.getAllStaff();
    
    setState(() {
      _allStaff = allStaff;
      _isLoading = false;
    });
  }

  Future<void> _deleteAllRecords() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Records'),
        content: const Text('Are you sure you want to delete ALL local database records? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Use the efficient database method to clear all records
        await _dbService.deleteAllStaff();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All database records deleted'),
            backgroundColor: Colors.green,
          ),
        );

        _loadAllRecords();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting records: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRecord(Staff staff) async {
    try {
      await _dbService.deleteStaff(staff.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted: ${staff.name}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAllRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadAllRecords,
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Export as JSON',
            onPressed: _exportDatabaseAsJson,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete All Records',
            onPressed: _deleteAllRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allStaff.isEmpty
              ? const Center(
                  child: Text('No records in database'),
                )
              : ListView.builder(
                  itemCount: _allStaff.length,
                  itemBuilder: (context, index) {
                    final staff = _allStaff[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ExpansionTile(
                        title: Text('${staff.name} (ID: ${staff.id})'),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _getSyncStatusColor(staff.syncStatus),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getSyncStatusText(staff.syncStatus),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            Text('Server ID: ${staff.serverId ?? "None"}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRecord(staff),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailRow('Name', staff.name),
                                _detailRow('Position', staff.position),
                                _detailRow('Department', staff.department),
                                _detailRow('Email', staff.email),
                                _detailRow('Phone', staff.phone),
                                _detailRow('Join Date', staff.joinDate.toString()),
                                _detailRow('Local ID', staff.id.toString()),
                                _detailRow('Server ID', staff.serverId?.toString() ?? 'None'),
                                _detailRow('Sync Status', _getSyncStatusText(staff.syncStatus)),
                                const SizedBox(height: 16),
                                if (staff.syncStatus != SyncStatus.synced && _dbService.isOnline)
                                  ElevatedButton.icon(
                                    onPressed: () => _forceSyncRecord(staff),
                                    icon: const Icon(Icons.sync),
                                    label: const Text('Force Sync This Record'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Records: ${_allStaff.length}'),
              ElevatedButton(
                onPressed: _dbService.isOnline ? _forceSyncAll : null,
                child: const Text('Force Sync All'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _forceSyncAll() async {
    if (!_dbService.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sync while offline'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _syncService.syncData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Force sync completed'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadAllRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error syncing: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.created:
        return Colors.blue;
      case SyncStatus.updated:
        return Colors.orange;
      case SyncStatus.deleted:
        return Colors.red;
    }
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return 'SYNCED';
      case SyncStatus.created:
        return 'CREATED';
      case SyncStatus.updated:
        return 'UPDATED';
      case SyncStatus.deleted:
        return 'DELETED';
    }
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  Future<void> _exportDatabaseAsJson() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allStaff = await _dbService.getAllStaff();
      final jsonData = allStaff.map((staff) => {
        'id': staff.id,
        'serverId': staff.serverId,
        'name': staff.name,
        'position': staff.position,
        'department': staff.department,
        'email': staff.email,
        'phone': staff.phone,
        'joinDate': staff.joinDate.toString(),
        'syncStatus': _getSyncStatusText(staff.syncStatus),
      }).toList();

      // Display the JSON in a dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Database as JSON'),
            content: SingleChildScrollView(
              child: SelectableText(
                jsonData.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceSyncRecord(Staff staff) async {
    if (!_dbService.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sync while offline'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the specific force sync for a single record
      final success = await _syncService.forceSyncRecord(staff);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully synced ${staff.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync ${staff.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      _loadAllRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error syncing: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
} 