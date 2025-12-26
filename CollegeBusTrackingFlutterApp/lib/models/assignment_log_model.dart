class AssignmentLogModel {
  final String id;
  final String busId;
  final String driverId;
  final String? routeId;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String status;
  final String? busNumber; // From populated data
  final String? driverName; // From populated data
  final String? routeName; // From populated data

  AssignmentLogModel({
    required this.id,
    required this.busId,
    required this.driverId,
    this.routeId,
    required this.assignedAt,
    this.acceptedAt,
    this.completedAt,
    required this.status,
    this.busNumber,
    this.driverName,
    this.routeName,
  });

  factory AssignmentLogModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.parse(value);
      return null;
    }

    // Handle populated fields
    String? bNum;
    if (map['busId'] is Map) bNum = map['busId']['busNumber'];

    String? dName;
    if (map['driverId'] is Map) dName = map['driverId']['fullName'];

    String? rName;
    if (map['routeId'] is Map) rName = map['routeId']['routeName'];

    return AssignmentLogModel(
      id: map['_id'] ?? '',
      busId: map['busId'] is Map ? map['busId']['_id'] : (map['busId'] ?? ''),
      driverId: map['driverId'] is Map
          ? map['driverId']['_id']
          : (map['driverId'] ?? ''),
      routeId: map['routeId'] is Map ? map['routeId']['_id'] : map['routeId'],
      assignedAt: parseDate(map['assignedAt']) ?? DateTime.now(),
      acceptedAt: parseDate(map['acceptedAt']),
      completedAt: parseDate(map['completedAt']),
      status: map['status'] ?? 'pending',
      busNumber: bNum,
      driverName: dName,
      routeName: rName,
    );
  }
}
