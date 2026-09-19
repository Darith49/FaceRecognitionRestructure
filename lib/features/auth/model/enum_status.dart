enum UserStatus { active, inactive }

//Get From Firestore  : String -> Enum
UserStatus stringToUserStatus(String? value) {
  switch (value) {
    case 'active':
      return UserStatus.active;
    case 'inactive':
      return UserStatus.inactive;
    default:
      return UserStatus.active;
  }
}

//Send to Firestore : Enum-->String , because firestore store String
String userStatusToString(UserStatus status) {
  switch (status) {
    case UserStatus.active:
      return 'active';
    case UserStatus.inactive:
      return 'inactive';
  }
}
