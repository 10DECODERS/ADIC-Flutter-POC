import 'package:flutter/material.dart';
import 'package:adic_poc/models/staff.dart';
import 'package:adic_poc/services/database_service.dart';
import 'package:adic_poc/services/sync_service.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({Key? key}) : super(key: key);

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();
  List<Staff> _staffList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _syncService.syncData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: Icon(
              _dbService.isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _dbService.isOnline ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (_dbService.isOnline) {
                _syncService.syncData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Syncing data with server...')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You are currently offline. Changes will be synced when online.')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStaff,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staffList.isEmpty
              ? const Center(child: Text('No staff records found'))
              : ListView.builder(
                  itemCount: _staffList.length,
                  itemBuilder: (context, index) {
                    final staff = _staffList[index];
                    return ListTile(
                      title: Text(staff.name),
                      subtitle: Text('${staff.position} - ${staff.department}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _getSyncStatusIcon(staff.syncStatus),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showStaffForm(staff: staff),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteStaff(staff),
                          ),
                        ],
                      ),
                      onTap: () => _showStaffDetails(staff),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showStaffForm(),
      ),
    );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(staff.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Position', staff.position),
              _detailRow('Department', staff.department),
              _detailRow('Email', staff.email),
              _detailRow('Phone', staff.phone),
              _detailRow('Join Date', '${staff.joinDate.day}/${staff.joinDate.month}/${staff.joinDate.year}'),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Sync Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  _getSyncStatusIcon(staff.syncStatus),
                  const SizedBox(width: 5),
                  Text(_getSyncStatusText(staff.syncStatus)),
                ],
              ),
            ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
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

  Future<void> _showStaffForm({Staff? staff}) async {
    final nameController = TextEditingController(text: staff?.name ?? '');
    final positionController = TextEditingController(text: staff?.position ?? '');
    final departmentController = TextEditingController(text: staff?.department ?? '');
    final emailController = TextEditingController(text: staff?.email ?? '');
    final phoneController = TextEditingController(text: staff?.phone ?? '');
    
    final dateController = TextEditingController(
      text: staff != null
          ? '${staff.joinDate.day}/${staff.joinDate.month}/${staff.joinDate.year}'
          : '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(staff == null ? 'Add Staff' : 'Edit Staff'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                TextFormField(
                  controller: positionController,
                  decoration: const InputDecoration(labelText: 'Position'),
                ),
                TextFormField(
                  controller: departmentController,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final joinDate = DateTime.now();

                if (staff == null) {
                  // Create new staff
                  final newStaff = Staff(
                    name: nameController.text,
                    position: positionController.text,
                    department: departmentController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                    joinDate: joinDate,
                  );
                  await _dbService.saveStaff(newStaff);
                } else {
                  // Update existing staff
                  staff.name = nameController.text;
                  staff.position = positionController.text;
                  staff.department = departmentController.text;
                  staff.email = emailController.text;
                  staff.phone = phoneController.text;
                  staff.joinDate = staff.joinDate; // Maintain existing join date
                  await _dbService.updateStaff(staff);
                }

                if (_dbService.isOnline) {
                  _syncService.syncData();
                }

                Navigator.pop(context);
                _loadStaff();
              }
            },
            child: Text(staff == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaff(Staff staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${staff.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _dbService.deleteStaff(staff.id);
      
      if (_dbService.isOnline) {
        _syncService.syncData();
      }
      
      _loadStaff();
    }
  }
} 