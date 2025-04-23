import 'package:flutter/material.dart';
import 'package:adic_poc/models/staff.dart';
import 'package:adic_poc/services/database_service.dart';
import 'package:adic_poc/services/sync_service.dart';

// Add Staff Screen
class AddStaffScreen extends StatefulWidget {
  final Map<String, dynamic>? prefillData;
  
  const AddStaffScreen({super.key, this.prefillData});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Set prefilled data if available from AI
    if (widget.prefillData != null) {
      if (widget.prefillData!['name'] != null) {
        _nameController.text = widget.prefillData!['name'];
      }
      if (widget.prefillData!['position'] != null) {
        _positionController.text = widget.prefillData!['position'];
      }
      if (widget.prefillData!['department'] != null) {
        _departmentController.text = widget.prefillData!['department'];
      }
      if (widget.prefillData!['email'] != null) {
        _emailController.text = widget.prefillData!['email'];
      }
      if (widget.prefillData!['phone'] != null) {
        _phoneController.text = widget.prefillData!['phone'];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Add New Staff',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isSaving ? null : _saveStaff,
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFormField(
                  controller: _nameController,
                  label: 'Name',
                  icon: Icons.person,
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _positionController,
                  label: 'Position',
                  icon: Icons.work,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _departmentController,
                  label: 'Department',
                  icon: Icons.business,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _phoneController,
                  label: 'Phone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      ),
    );
  }

  Future<void> _saveStaff() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Check if a staff with this email already exists
        final existingStaff = await _dbService.getStaffByEmail(_emailController.text);
        if (existingStaff != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('A staff member with this email already exists'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }
        
        final staff = Staff(
          name: _nameController.text,
          position: _positionController.text,
          department: _departmentController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          joinDate: DateTime.now(),
        );
        
        // Save locally first
        final id = await _dbService.saveStaff(staff);
        
        // Show appropriate message based on connectivity
        if (_dbService.isOnline) {
          // Trigger sync in background
          _syncService.syncData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Staff member added and syncing to server'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Staff member added locally. Will sync when online.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

// Edit Staff Screen
class EditStaffScreen extends StatefulWidget {
  final Staff staff;
  
  const EditStaffScreen({super.key, required this.staff});

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();
  
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _positionController;
  late final TextEditingController _departmentController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff.name);
    _positionController = TextEditingController(text: widget.staff.position);
    _departmentController = TextEditingController(text: widget.staff.department);
    _emailController = TextEditingController(text: widget.staff.email);
    _phoneController = TextEditingController(text: widget.staff.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Edit Staff',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isSaving ? null : _updateStaff,
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFormField(
                  controller: _nameController,
                  label: 'Name',
                  icon: Icons.person,
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _positionController,
                  label: 'Position',
                  icon: Icons.work,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _departmentController,
                  label: 'Department',
                  icon: Icons.business,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _phoneController,
                  label: 'Phone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: Icon(Icons.delete, color: Colors.red.shade400),
                  label: Text(
                    'Delete Staff Member', 
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _deleteStaff,
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      ),
    );
  }

  Future<void> _updateStaff() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Check if a staff with this email already exists (and it's not the current staff)
        if (_emailController.text != widget.staff.email) {
          final existingStaff = await _dbService.getStaffByEmail(_emailController.text);
          if (existingStaff != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('A staff member with this email already exists'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isSaving = false;
            });
            return;
          }
        }
        
        final updatedStaff = Staff(
          serverId: widget.staff.serverId,
          name: _nameController.text,
          position: _positionController.text,
          department: _departmentController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          joinDate: widget.staff.joinDate,
          syncStatus: widget.staff.syncStatus,
        );
        
        // Set the ID to maintain the same record
        updatedStaff.id = widget.staff.id;
        
        await _dbService.updateStaff(updatedStaff);
        
        // Show appropriate message based on connectivity
        if (_dbService.isOnline) {
          // Trigger sync in background
          _syncService.syncData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Staff member updated and syncing to server'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Staff member updated locally. Will sync when online.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  Future<void> _deleteStaff() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${widget.staff.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
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
        _isSaving = true;
      });
      
      try {
        await _dbService.deleteStaff(widget.staff.id);
        
        // Show appropriate message based on connectivity
        if (_dbService.isOnline) {
          // Trigger sync in background
          _syncService.syncData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Staff member deleted and syncing to server'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Staff member marked for deletion. Will sync when online.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        // Return true to indicate success
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
} 