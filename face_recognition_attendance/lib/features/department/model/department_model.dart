class DepartmentModel {
  final int id;
  final String name;
  final int branchId;
  final String branchName;
  final String createdBy;
  final DateTime? createdAt;
  final int employeeCount;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.branchId,
    this.branchName = '',
    this.createdBy = '',
    this.createdAt,
    this.employeeCount = 0,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      branchId: json['branch'] is int
          ? json['branch']
          : int.tryParse(json['branch'].toString()) ?? 0,
      branchName: json['branch_name'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      employeeCount: json['employee_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'branch': branchId,
      'created_by': createdBy,
    };
  }
}
