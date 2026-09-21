class BranchModel {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String createdBy;
  final DateTime? createdAt;
  final int employeeCount;
  final int departmentCount;

  BranchModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radius = 100.0,
    this.createdBy = '',
    this.createdAt,
    this.employeeCount = 0,
    this.departmentCount = 0,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radius: (json['radius'] as num?)?.toDouble() ?? 100.0,
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      employeeCount: json['employee_count'] ?? 0,
      departmentCount: json['department_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'created_by': createdBy,
    };
  }
}
