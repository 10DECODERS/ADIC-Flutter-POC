import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:adic_poc/models/staff.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late Isar _isar;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool _isOnline = true;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [StaffSchema],
      directory: dir.path,
    );
    
    // Initialize connectivity monitoring
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _updateConnectionStatus(await Connectivity().checkConnectivity());
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    bool previousStatus = _isOnline;
    
    if (result == ConnectivityResult.none) {
      _isOnline = false;
    } else {
      // Double-check with InternetConnectionChecker to verify actual internet connectivity
      _isOnline = await InternetConnectionChecker().hasConnection;
    }
    
    // Only notify listeners when the status actually changes
    if (previousStatus != _isOnline) {
      print('Connectivity status changed: $_isOnline');
      _connectivityController.add(_isOnline);
    }
  }

  // Add method to manually check connectivity status (can be called periodically)
  Future<bool> checkConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    await _updateConnectionStatus(result);
    return _isOnline;
  }

  bool get isOnline => _isOnline;

  // Staff CRUD operations
  Future<List<Staff>> getAllStaff() async {
    return await _isar.staffs.where().findAll();
  }

  Future<Staff?> getStaffById(int id) async {
    return await _isar.staffs.get(id);
  }

  Future<Staff?> getStaffByServerId(int serverId) async {
    return await _isar.staffs
        .where()
        .findAll()
        .then((staffs) => staffs.where((staff) => staff.serverId == serverId).firstOrNull);
  }

  Future<int> saveStaff(Staff staff) async {
    // Always mark new staff as needing sync, since APIs are not yet implemented
    staff.syncStatus = SyncStatus.created;
    return await _isar.writeTxn(() async {
      return await _isar.staffs.put(staff);
    });
  }

  Future<bool> updateStaff(Staff staff) async {
    // Always mark as updated since APIs are not implemented yet
    if (staff.syncStatus != SyncStatus.created) {
      staff.syncStatus = SyncStatus.updated;
    }
    return await _isar.writeTxn(() async {
      return await _isar.staffs.put(staff) > 0;
    });
  }

  Future<bool> deleteStaff(int id) async {
    if (!_isOnline) {
      // Mark for deletion instead of actually deleting
      final staff = await getStaffById(id);
      if (staff != null) {
        staff.syncStatus = SyncStatus.deleted;
        return await updateStaff(staff);
      }
      return false;
    }
    return await _isar.writeTxn(() async {
      return await _isar.staffs.delete(id);
    });
  }

  Future<List<Staff>> getUnsyncedStaff() async {
    return await _isar.staffs
        .where()
        .findAll()
        .then((staffs) => staffs.where((staff) => staff.syncStatus != SyncStatus.synced).toList());
  }

  Future<bool> markAsSynced(int id) async {
    return await _isar.writeTxn(() async {
      final staff = await _isar.staffs.get(id);
      if (staff != null) {
        staff.syncStatus = SyncStatus.synced;
        return await _isar.staffs.put(staff) > 0;
      }
      return false;
    });
  }

  Future<void> cleanupDeletedRecords() async {
    final deletedRecords = await _isar.staffs
        .where()
        .findAll()
        .then((staffs) => staffs.where((staff) => staff.syncStatus == SyncStatus.deleted).toList());
    
    await _isar.writeTxn(() async {
      for (var staff in deletedRecords) {
        await _isar.staffs.delete(staff.id);
      }
    });
  }
} 