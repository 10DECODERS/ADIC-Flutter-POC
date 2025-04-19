import 'dart:async';
import 'package:adic_poc/models/staff.dart';
import 'package:adic_poc/services/api_service.dart';
import 'package:adic_poc/services/database_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _dbService = DatabaseService();
  final ApiService _apiService = ApiService();
  
  bool _isSyncing = false;
  late StreamSubscription<bool> _connectivitySubscription;

  void init() {
    // Listen for connectivity changes
    _connectivitySubscription = _dbService.connectivityStream.listen((isOnline) {
      if (isOnline) {
        syncData();
      }
    });
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }

  Future<void> syncData() async {
    if (_isSyncing || !_dbService.isOnline) return;
    
    _isSyncing = true;
    
    try {
      // First, handle any unsynced changes
      await _syncLocalChanges();
      
      // Then, fetch and store remote data
      await _fetchRemoteData();
      
      // Finally, clean up any deleted records
      await _dbService.cleanupDeletedRecords();
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncLocalChanges() async {
    final unsyncedRecords = await _dbService.getUnsyncedStaff();
    
    for (var staff in unsyncedRecords) {
      try {
        switch (staff.syncStatus) {
          case SyncStatus.created:
            final createdStaff = await _apiService.createStaff(staff);
            staff.serverId = createdStaff.serverId;
            staff.syncStatus = SyncStatus.synced;
            await _dbService.updateStaff(staff);
            break;
            
          case SyncStatus.updated:
            await _apiService.updateStaff(staff);
            staff.syncStatus = SyncStatus.synced;
            await _dbService.updateStaff(staff);
            break;
            
          case SyncStatus.deleted:
            if (staff.serverId != null) {
              await _apiService.deleteStaff(staff.serverId!);
            }
            // The record will be cleaned up by cleanupDeletedRecords
            break;
            
          case SyncStatus.synced:
            // Nothing to do
            break;
        }
      } catch (e) {
        print('Error syncing record ${staff.id}: $e');
        // Keep the record marked as unsynced for the next sync attempt
      }
    }
  }

  Future<void> _fetchRemoteData() async {
    try {
      final remoteStaff = await _apiService.fetchAllStaff();
      
      for (var staff in remoteStaff) {
        final localStaff = await _dbService.getStaffByServerId(staff.serverId!);
        
        if (localStaff == null) {
          // New record from the server
          await _dbService.saveStaff(staff);
        } else if (localStaff.syncStatus == SyncStatus.synced) {
          // Update local record with server data, but only if it hasn't been modified locally
          localStaff.name = staff.name;
          localStaff.position = staff.position;
          localStaff.department = staff.department;
          localStaff.email = staff.email;
          localStaff.phone = staff.phone;
          localStaff.joinDate = staff.joinDate;
          await _dbService.updateStaff(localStaff);
        }
        // If record has been modified locally, prioritize local changes
      }
    } catch (e) {
      print('Error fetching remote data: $e');
    }
  }
} 