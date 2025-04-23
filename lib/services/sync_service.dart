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
    
    // Check current connectivity status immediately
    Future.delayed(const Duration(seconds: 1), () async {
      await _dbService.checkConnectivity();
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
            try {
              final createdStaff = await _apiService.createStaff(staff);
              staff.serverId = createdStaff.serverId;
              staff.syncStatus = SyncStatus.synced;
              await _dbService.updateStaff(staff);
              print('Successfully created staff on server: ${staff.name}');
            } catch (e) {
              print('Error creating staff on server: $e');
              // Keep as unsynced for next attempt
            }
            break;
            
          case SyncStatus.updated:
            try {
              if (staff.serverId != null) {
                await _apiService.updateStaff(staff);
                staff.syncStatus = SyncStatus.synced;
                await _dbService.updateStaff(staff);
                print('Successfully updated staff on server: ${staff.name}');
              } else {
                // If somehow we have an updated record without server ID, 
                // treat it as a creation
                final createdStaff = await _apiService.createStaff(staff);
                staff.serverId = createdStaff.serverId;
                staff.syncStatus = SyncStatus.synced;
                await _dbService.updateStaff(staff);
                print('Created staff on server (was marked as update): ${staff.name}');
              }
            } catch (e) {
              print('Error updating staff on server: $e');
              // Keep as unsynced for next attempt
            }
            break;
            
          case SyncStatus.deleted:
            try {
              if (staff.serverId != null) {
                await _apiService.deleteStaff(staff.serverId!);
                // After successful deletion on server, remove from local DB
                await _dbService.cleanupDeletedRecords();
                print('Successfully deleted staff on server: ${staff.name}');
              } else {
                // If we don't have a server ID, we can just delete locally
                await _dbService.deleteStaff(staff.id);
                print('Deleted local-only staff record: ${staff.name}');
              }
            } catch (e) {
              print('Error deleting staff from server: $e');
              // Keep as unsynced for next attempt
            }
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
        if (staff.serverId == null) {
          print('Warning: Remote staff record has null serverId: ${staff.name}');
          continue;
        }
        
        final localStaff = await _dbService.getStaffByServerId(staff.serverId!);
        
        if (localStaff == null) {
          // New record from the server
          staff.syncStatus = SyncStatus.synced; // Mark as synced
          await _dbService.saveStaff(staff);
          print('Saved new staff from server: ${staff.name}');
        } else {
          // For any record that exists on server, update its local data
          // and mark as synced regardless of current sync status
          localStaff.name = staff.name;
          localStaff.position = staff.position;
          localStaff.department = staff.department;
          localStaff.email = staff.email;
          localStaff.phone = staff.phone;
          localStaff.joinDate = staff.joinDate;
          
          // Always mark as synced if it exists on the server
          localStaff.syncStatus = SyncStatus.synced;
          await _dbService.markAsSynced(localStaff.id);
          print('Updated and marked as synced: ${staff.name}');
        }
      }
    } catch (e) {
      print('Error fetching remote data: $e');
    }
  }

  // Force sync a specific staff record immediately
  Future<bool> forceSyncRecord(Staff staff) async {
    if (!_dbService.isOnline) return false;
    
    try {
      switch (staff.syncStatus) {
        case SyncStatus.created:
          try {
            final createdStaff = await _apiService.createStaff(staff);
            staff.serverId = createdStaff.serverId;
            staff.syncStatus = SyncStatus.synced;
            await _dbService.updateStaff(staff);
            print('Forced sync - created staff on server: ${staff.name}');
            return true;
          } catch (e) {
            print('Forced sync error - creating staff: $e');
            return false;
          }
          
        case SyncStatus.updated:
          try {
            if (staff.serverId != null) {
              await _apiService.updateStaff(staff);
              staff.syncStatus = SyncStatus.synced;
              await _dbService.markAsSynced(staff.id);
              print('Forced sync - updated staff on server: ${staff.name}');
              return true;
            } else {
              final createdStaff = await _apiService.createStaff(staff);
              staff.serverId = createdStaff.serverId;
              staff.syncStatus = SyncStatus.synced;
              await _dbService.updateStaff(staff);
              print('Forced sync - created staff (was marked updated): ${staff.name}');
              return true;
            }
          } catch (e) {
            print('Forced sync error - updating staff: $e');
            return false;
          }
          
        case SyncStatus.deleted:
          try {
            if (staff.serverId != null) {
              await _apiService.deleteStaff(staff.serverId!);
              await _dbService.deleteStaff(staff.id);
              print('Forced sync - deleted staff from server: ${staff.name}');
              return true;
            } else {
              await _dbService.deleteStaff(staff.id);
              print('Forced sync - deleted local-only staff: ${staff.name}');
              return true;
            }
          } catch (e) {
            print('Forced sync error - deleting staff: $e');
            return false;
          }
          
        case SyncStatus.synced:
          // Already synced, nothing to do
          return true;
      }
    } catch (e) {
      print('Force sync error: $e');
      return false;
    }
  }
} 