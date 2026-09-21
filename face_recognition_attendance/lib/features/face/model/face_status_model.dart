class FaceStatusModel {
  final bool registered;
  final int? employeeId;
  final String employeeName;

  FaceStatusModel({
    required this.registered,
    this.employeeId,
    this.employeeName = '',
  });

  factory FaceStatusModel.fromJson(Map<String, dynamic> json) {
    return FaceStatusModel(
      registered: json['registered'] ?? false,
      employeeId: json['employee_id'] is int ? json['employee_id'] : int.tryParse(json['employee_id']?.toString() ?? ''),
      employeeName: json['employee_name'] ?? '',
    );
  }
}
