import 'package:isar/isar.dart';

part 'staff.g.dart';

@collection
class Staff {
  Id id = Isar.autoIncrement;
  
  @Index()
  int? serverId;
  
  String name;
  String position;
  String department;
  
  @Index(unique: true)
  String email;
  
  String phone;
  DateTime joinDate;
  
  @enumerated
  SyncStatus syncStatus;
  
  Staff({
    this.serverId,
    required this.name,
    required this.position,
    required this.department,
    required this.email,
    required this.phone,
    required this.joinDate,
    this.syncStatus = SyncStatus.synced,
  });
  
  factory Staff.fromJson(Map<String, dynamic> json) {
    DateTime joinDate;
    try {
      joinDate = json['joinDate'] != null 
        ? DateTime.parse(json['joinDate']) 
        : DateTime.now();
    } catch (e) {
      joinDate = DateTime.now();
    }

    return Staff(
      serverId: json['id'],
      name: json['name'],
      position: json['position'] ?? '',
      department: json['department'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      joinDate: joinDate,
      syncStatus: SyncStatus.synced,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': serverId,
      'name': name,
      'position': position,
      'department': department,
      'email': email,
      'phone': phone,
      'joinDate': joinDate.toIso8601String(),
    };
  }
}

@enumerated
enum SyncStatus {
  synced,
  created,
  updated,
  deleted
} 