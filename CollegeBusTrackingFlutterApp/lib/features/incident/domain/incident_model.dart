class IncidentModel {
  final String? id;
  final String collegeId;
  final String? busId;
  final String? driverId;
  final String reporterId;
  final String type; // accident, breakdown, delay, behavior, other
  final String description;
  final String severity; // low, medium, high, critical
  final String status; // open, investigating, resolved
  final Map<String, dynamic>? location; // {lat: double, lng: double}
  final DateTime? createdAt;

  IncidentModel({
    this.id,
    required this.collegeId,
    this.busId,
    this.driverId,
    required this.reporterId,
    required this.type,
    required this.description,
    this.severity = 'medium',
    this.status = 'open',
    this.location,
    this.createdAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['_id'],
      collegeId: json['collegeId'],
      busId: json['busId'] is Map ? json['busId']['_id'] : json['busId'],
      driverId: json['driverId'] is Map
          ? json['driverId']['_id']
          : json['driverId'],
      reporterId: json['reporterId'] is Map
          ? json['reporterId']['_id']
          : json['reporterId'],
      type: json['type'],
      description: json['description'],
      severity: json['severity'],
      status: json['status'],
      location: json['location'] != null
          ? Map<String, dynamic>.from(json['location'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collegeId': collegeId,
      if (busId != null) 'busId': busId,
      if (driverId != null) 'driverId': driverId,
      'reporterId': reporterId,
      'type': type,
      'description': description,
      'severity': severity,
      'status': status,
      if (location != null) 'location': location,
    };
  }
}
