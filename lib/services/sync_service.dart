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
      // 1. Fetch all staff from the remote server
      final remoteStaff = await _apiService.fetchAllStaff();
      final remoteServerIds = remoteStaff.map((s) => s.serverId).where((id) => id != null).cast<int>().toSet();
      print('[SyncService._fetchRemoteData] Received ${remoteStaff.length} records from API. Server IDs: ${remoteServerIds}');

      // 2. Get all local staff that are synced and have a server ID
      final localSyncedStaff = await _dbService.getSyncedStaffWithServerIds();
      print('[SyncService._fetchRemoteData] Found ${localSyncedStaff.length} synced local records with server IDs.');

      // 3. Identify and delete local records that are no longer on the server
      List<int> idsToDeleteLocally = [];
      for (final localStaff in localSyncedStaff) {
        if (localStaff.serverId != null && !remoteServerIds.contains(localStaff.serverId)) {
          print('[SyncService._fetchRemoteData] Local record (ID: ${localStaff.id}, ServerID: ${localStaff.serverId}) no longer exists on server. Marking for deletion.');
          idsToDeleteLocally.add(localStaff.id);
        }
      }
      
      // Perform deletions
      if (idsToDeleteLocally.isNotEmpty) {
        print('[SyncService._fetchRemoteData] Deleting ${idsToDeleteLocally.length} local records...');
        for (final idToDelete in idsToDeleteLocally) {
          // Use deleteStaff directly - it handles marking as deleted or actual deletion based on online status and serverId presence
          await _dbService.deleteStaff(idToDelete);
        }
        print('[SyncService._fetchRemoteData] Finished deleting local records.');
      }

      // 4. Process the remote staff list to add new or update existing local records
      for (var staff in remoteStaff) {
        print('[SyncService._fetchRemoteData] Processing remote staff: ID=${staff.serverId}, Name=${staff.name}');
        
        if (staff.serverId == null) {
          print('[SyncService._fetchRemoteData] Warning: Remote staff record has null serverId: ${staff.name}');
          continue;
        }
        
        final localStaff = await _dbService.getStaffByServerId(staff.serverId!);
        print('[SyncService._fetchRemoteData] Local staff found for serverId ${staff.serverId}: ${localStaff != null}');
        
        if (localStaff == null) {
          // New record from the server
          staff.syncStatus = SyncStatus.synced; // Mark as synced
          print('[SyncService._fetchRemoteData] Attempting to save new staff: ${staff.toJson()}');
          try {
            final savedId = await _dbService.saveStaff(staff);
            print('[SyncService._fetchRemoteData] Successfully saved new staff with local ID: $savedId');
          } catch (e) {
            print('[SyncService._fetchRemoteData] Error saving new staff (serverId: ${staff.serverId}): $e');
          }
        } else {
          // For any record that exists on server, update its local data
          // and mark as synced regardless of current sync status
          localStaff.name = staff.name;
          localStaff.position = staff.position;
          localStaff.department = staff.department;
          localStaff.email = staff.email;
          localStaff.phone = staff.phone;
          localStaff.joinDate = staff.joinDate;
          
          // First, persist the updated data fields
          await _dbService.updateStaff(localStaff); 
          
          // Then, explicitly mark the record as synced since the data came from the server
          await _dbService.markAsSynced(localStaff.id);
          
          print('Updated local record and marked as synced: ${staff.name}');
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