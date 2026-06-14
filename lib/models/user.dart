class UserModel {
  final String fullName;

  UserModel({required this.fullName});

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      fullName: map['fullName'] ?? '',
    );
  }
}
