import 'package:bcreative_ems/features/employees/models/employment_enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeBankDetails {
  const EmployeeBankDetails({
    this.bankName,
    this.accountTitle,
    this.accountNumber,
    this.iban,
  });

  final String? bankName;
  final String? accountTitle;
  final String? accountNumber;
  final String? iban;

  factory EmployeeBankDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EmployeeBankDetails();
    return EmployeeBankDetails(
      bankName: json['bankName'] as String?,
      accountTitle: json['accountTitle'] as String?,
      accountNumber: json['accountNumber'] as String?,
      iban: json['iban'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (_hasText(bankName)) 'bankName': bankName!.trim(),
    if (_hasText(accountTitle)) 'accountTitle': accountTitle!.trim(),
    if (_hasText(accountNumber)) 'accountNumber': accountNumber!.trim(),
    if (_hasText(iban)) 'iban': iban!.trim(),
  };

  static bool _hasText(String? value) => value?.trim().isNotEmpty ?? false;
}

class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.email,
    this.jobTitle,
    this.department,
    this.contactNumber,
    this.profilePhotoUrl,
    this.gender,
    this.managerName,
    this.workLocation,
    this.employmentStatus = EmploymentStatus.active,
    this.dateOfBirth,
    this.nationality,
    this.cnicPassport,
    this.residentialAddress,
    this.joiningDate,
    this.employmentType,
    this.salary,
    this.bankDetails = const EmployeeBankDetails(),
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String employeeCode;
  final String fullName;
  final String email;
  final String? jobTitle;
  final String? department;
  final String? contactNumber;
  final String? profilePhotoUrl;

  /// Optional profile fields are retained in the admin record and copied to
  /// the employee-safe profile projection. The current admin form does not
  /// require them, so older employee documents remain fully compatible.
  final String? gender;
  final String? managerName;
  final String? workLocation;
  final EmploymentStatus employmentStatus;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? cnicPassport;
  final String? residentialAddress;
  final DateTime? joiningDate;
  final EmploymentType? employmentType;
  final num? salary;
  final EmployeeBankDetails bankDetails;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get fullNameLower => fullName.trim().toLowerCase();

  /// Each replacement upload has its own Storage object path. Strip the
  /// temporary `v` query parameter written by earlier app builds so existing
  /// records also use Firebase Storage's exact download URL.
  String? get displayPhotoUrl => _downloadUrl(profilePhotoUrl);

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String? ?? '',
      employeeCode:
          json['employeeCode'] as String? ?? json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      jobTitle: json['jobTitle'] as String?,
      department: json['department'] as String?,
      contactNumber: json['contactNumber'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      gender: json['gender'] as String?,
      managerName: json['managerName'] as String?,
      workLocation: json['workLocation'] as String?,
      employmentStatus:
          EmploymentStatus.fromValue(json['employmentStatus'] as String?) ??
          EmploymentStatus.active,
      dateOfBirth: _readDate(json['dateOfBirth']),
      nationality: json['nationality'] as String?,
      cnicPassport: json['cnicPassport'] as String?,
      residentialAddress: json['residentialAddress'] as String?,
      joiningDate: _readDate(json['joiningDate']),
      employmentType: EmploymentType.fromValue(
        json['employmentType'] as String?,
      ),
      salary: json['salary'] as num?,
      bankDetails: EmployeeBankDetails.fromJson(_asMap(json['bankDetails'])),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  factory EmployeeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return EmployeeModel.fromJson({...?doc.data(), 'id': doc.id});
  }

  /// A Firestore-compatible representation. The document id remains the source
  /// of truth for [id], so it is deliberately not duplicated in the document.
  Map<String, dynamic> toJson({
    bool includeSensitive = true,
    bool includeCreatedAt = false,
    bool includeUpdatedAt = true,
  }) {
    return {
      'employeeCode': employeeCode.trim(),
      'fullName': fullName.trim(),
      'fullNameLower': fullNameLower,
      'email': email.trim().toLowerCase(),
      'jobTitle': _trimOrNull(jobTitle),
      'department': _trimOrNull(department),
      'contactNumber': _trimOrNull(contactNumber),
      'profilePhotoUrl': _trimOrNull(profilePhotoUrl),
      'gender': _trimOrNull(gender),
      'managerName': _trimOrNull(managerName),
      'workLocation': _trimOrNull(workLocation),
      'employmentStatus': employmentStatus.value,
      'dateOfBirth': dateOfBirth == null
          ? null
          : Timestamp.fromDate(dateOfBirth!),
      'nationality': _trimOrNull(nationality),
      'cnicPassport': _trimOrNull(cnicPassport),
      'residentialAddress': _trimOrNull(residentialAddress),
      'joiningDate': joiningDate == null
          ? null
          : Timestamp.fromDate(joiningDate!),
      'employmentType': employmentType?.value,
      if (includeSensitive) 'salary': salary,
      if (includeSensitive) 'bankDetails': bankDetails.toJson(),
      'isActive': isActive,
      if (includeCreatedAt)
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      if (includeUpdatedAt) 'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// The employee-safe projection duplicated in `employee_profiles`.
  Map<String, dynamic> toProfileJson({bool includeUpdatedAt = true}) {
    return {
      'employeeCode': employeeCode.trim(),
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'jobTitle': _trimOrNull(jobTitle),
      'department': _trimOrNull(department),
      'contactNumber': _trimOrNull(contactNumber),
      'profilePhotoUrl': _trimOrNull(profilePhotoUrl),
      'dateOfBirth': dateOfBirth == null
          ? null
          : Timestamp.fromDate(dateOfBirth!),
      'gender': _trimOrNull(gender),
      'nationality': _trimOrNull(nationality),
      'cnicPassport': _trimOrNull(cnicPassport),
      'residentialAddress': _trimOrNull(residentialAddress),
      'managerName': _trimOrNull(managerName),
      'workLocation': _trimOrNull(workLocation),
      'employmentStatus': employmentStatus.value,
      'isActive': isActive,
      'joiningDate': joiningDate == null
          ? null
          : Timestamp.fromDate(joiningDate!),
      'employmentType': employmentType?.value,
      'bankName': _trimOrNull(bankDetails.bankName),
      'accountNumber': _trimOrNull(bankDetails.accountNumber),
      if (includeUpdatedAt) 'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  EmployeeModel withFirestoreIdentity({
    required String id,
    required String employeeCode,
  }) {
    return EmployeeModel(
      id: id,
      employeeCode: employeeCode,
      fullName: fullName,
      email: email,
      jobTitle: jobTitle,
      department: department,
      contactNumber: contactNumber,
      profilePhotoUrl: profilePhotoUrl,
      gender: gender,
      managerName: managerName,
      workLocation: workLocation,
      employmentStatus: employmentStatus,
      dateOfBirth: dateOfBirth,
      nationality: nationality,
      cnicPassport: cnicPassport,
      residentialAddress: residentialAddress,
      joiningDate: joiningDate,
      employmentType: employmentType,
      salary: salary,
      bankDetails: bankDetails,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
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
