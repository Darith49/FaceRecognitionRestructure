abstract class AppRoutes {
  static const String login = "/login";
  static const String forgotpassword = "/forgotpassword";
  static const String navigation = "/navigation";
  static const String attendance = "/attendance";
  // Clock, Request Information, Permission
  static const String clock = "/clock";
  static const String request = "/request";
  static const String requestInformation = "/request-information";
  static const String requestUnauthorized = "/request-unauthorized";
  static const String requestAuthorized = "/request-authorized";
  static const String requestDetail = "/request-detail";
  static const String permission = "/permission";
  static const String requestPermission = "/request-permission";
  static const String permissionSessions = "/permission-sessions";
  
  // Leave
  static const String leave = "/leave";
  static const String requestLeave = "/request-leave";
  static const String leaveDetail = "/leave-detail";

  // Overtime
  static const String overtime = "/overtime";
  static const String requestOvertime = "/request-overtime";
  static const String overtimeDetail = "/overtime-detail";

  // Suggestion
  static const String suggestion = "/suggestion";
  static const String suggestionStatus = "/suggestion-status";
  static const String suggestionDetail = "/suggestion-detail";

  // Schedule
  static const String schedule = "/schedule";

  // Settings
  static const String settings = "/settings";

  // Branch Management
  static const String branchList = "/branch-list";
  static const String createBranch = "/create-branch";

  // Department Management
  static const String departmentList = "/department-list";
  static const String createDepartment = "/create-department";

  // Employee Directory & Management
  static const String employeeList = "/employee-list";
  static const String createEmployee = "/create-employee";

  // Face Biometrics & Camera
  static const String faceCapture = "/face-capture";

  // Notifications
  static const String notifications = "/notifications";
}
