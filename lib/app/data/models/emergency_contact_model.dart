class EmergencyContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String relation;
  final bool isPrimary;
  final DateTime createdAt;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relation,
    this.isPrimary = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // From JSON
  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      relation: json['relation'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relation': relation,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // CopyWith
  EmergencyContactModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relation,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relation: relation ?? this.relation,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Validate phone number
  bool get isValidPhoneNumber {
    final regex = RegExp(r'^(\+62|62|0)[0-9]{9,12}$');
    return regex.hasMatch(phoneNumber.replaceAll(RegExp(r'[\s-]'), ''));
  }

  // Format phone number
  String get formattedPhoneNumber {
    String phone = phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    if (phone.startsWith('0')) {
      return '+62${phone.substring(1)}';
    } else if (phone.startsWith('62')) {
      return '+$phone';
    }
    return phone;
  }

  @override
  String toString() {
    return 'EmergencyContactModel(name: $name, phone: $phoneNumber, relation: $relation)';
  }
}
