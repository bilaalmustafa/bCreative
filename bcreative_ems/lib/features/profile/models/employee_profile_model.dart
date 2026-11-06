import 'package:bcreative_ems/features/employees/models/employment_enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// The employee-safe data projection stored in `employee_profiles`.
///
/// Employee accounts never read the private `employees` documents; the Super
/// Admin repository keeps this projection synchronised when a record changes.
class EmployeeProfileModel {
  const EmployeeProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.employeeCode,
    this.jobTitle,
    this.department,
    this.contactNumber,
    this.profilePhotoUrl,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.cnicPassport,
    this.residentialAddress,
    this.managerName,
    this.workLocation,
    this.employmentStatus,
    this.isActive = true,
    this.joiningDate,
    this.employmentType,
    this.bankName,
    this.accountNumber,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String? employeeCode;
  final String? jobTitle;
  final String? department;
  final String? contactNumber;
  final String? profilePhotoUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? nationality;
  final String? cnicPassport;
  final String? residentialAddress;
  final String? managerName;
  final String? workLocation;
  final String? employmentStatus;
  final bool isActive;
  final DateTime? joiningDate;
  final EmploymentType? employmentType;
  final String? bankName;
  final String? accountNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCurrentlyActive =>
      isActive && employmentStatus?.trim().toLowerCase() == 'active';

  String get employmentStatusLabel => _titleCase(employmentStatus);

  /// Mirrors the exact Firebase download URL stored by the admin record.
  String? get displayPhotoUrl => _downloadUrl(profilePhotoUrl);

  /// Employee-safe payload retained for the self-service model contract.
  /// Admin-controlled employment fields are deliberately excluded.
  Map<String, dynamic> toSelfServiceJson() => {
    'contactNumber': _trimOrNull(contactNumber),
    'nationality': _trimOrNull(nationality),
    'residentialAddress': _trimOrNull(residentialAddress),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory EmployeeProfileModel.fromJson(Map<String, dynamic> json) {
    return EmployeeProfileModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      employeeCode: json['employeeCode'] as String?,
      jobTitle: json['jobTitle'] as String?,
      department: json['department'] as String?,
      contactNumber: json['contactNumber'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      dateOfBirth: _readDate(json['dateOfBirth']),
      gender: json['gender'] as String?,
      nationality: json['nationality'] as String?,
      cnicPassport: json['cnicPassport'] as String?,
      residentialAddress: json['residentialAddress'] as String?,
      managerName: json['managerName'] as String?,
      workLocation: json['workLocation'] as String?,
      employmentStatus: json['employmentStatus'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      joiningDate: _readDate(json['joiningDate']),
      employmentType: EmploymentType.fromValue(
        json['employmentType'] as String?,
      ),
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  factory EmployeeProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return EmployeeProfileModel.fromJson({
      ...?document.data(),
      'id': document.id,
    });
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _titleCase(String? value) {
    final parts = value
        ?.trim()
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts == null || parts.isEmpty) return 'Not set';
    return parts
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? _downloadUrl(String? value) {
    final url = _trimOrNull(value);
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.queryParameters.containsKey('v')) return url;
    final query = Map<String, String>.from(uri.queryParameters)..remove('v');
    return uri.replace(queryParameters: query).toString();
  }
}
