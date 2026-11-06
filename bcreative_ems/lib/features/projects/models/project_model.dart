import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectStatus {
  notStarted('not_started', 'Not Started'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed'),
  onHold('on_hold', 'On Hold'),
  cancelled('cancelled', 'Cancelled');

  const ProjectStatus(this.value, this.label);

  final String value;
  final String label;

  static ProjectStatus fromValue(String? value) =>
      ProjectStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => ProjectStatus.notStarted,
      );
}

enum ProjectPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  urgent('urgent', 'Urgent');

  const ProjectPriority(this.value, this.label);

  final String value;
  final String label;

  static ProjectPriority fromValue(String? value) =>
      ProjectPriority.values.firstWhere(
        (priority) => priority.value == value,
        orElse: () => ProjectPriority.medium,
      );
}

/// A small safe employee projection stored with a project. This lets an
/// assigned employee see their project team without being granted access to
/// the private `/employees` collection.
class ProjectTeamMember {
  const ProjectTeamMember({
    required this.employeeId,
    required this.name,
    this.jobTitle,
    this.department,
    this.profilePhotoUrl,
  });

  final String employeeId;
  final String name;
  final String? jobTitle;
  final String? department;
  final String? profilePhotoUrl;

  factory ProjectTeamMember.fromJson(Map<String, dynamic> json) =>
      ProjectTeamMember(
        employeeId: json['employeeId'] as String? ?? '',
        name: json['name'] as String? ?? 'Employee',
        jobTitle: json['jobTitle'] as String?,
        department: json['department'] as String?,
        profilePhotoUrl: json['profilePhotoUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'name': name.trim(),
    'jobTitle': _trimOrNull(jobTitle),
    'department': _trimOrNull(department),
    'profilePhotoUrl': _trimOrNull(profilePhotoUrl),
  };
}

class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    required this.client,
    required this.description,
    required this.department,
    required this.category,
    required this.priority,
    required this.status,
    required this.employeeIds,
    required this.teamMembers,
    this.startDate,
    this.endDate,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String client;
  final String description;
  final String department;
  final String category;
  final ProjectPriority priority;
  final ProjectStatus status;
  final List<String> employeeIds;
  final List<ProjectTeamMember> teamMembers;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get nameLower => name.trim().toLowerCase();

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    client: json['client'] as String? ?? '',
    description: json['description'] as String? ?? '',
    department: json['department'] as String? ?? '',
    category: json['category'] as String? ?? '',
    priority: ProjectPriority.fromValue(json['priority'] as String?),
    status: ProjectStatus.fromValue(json['status'] as String?),
    employeeIds: _stringList(json['employeeIds']),
    teamMembers: _teamList(json['teamMembers']),
    startDate: _readDate(json['startDate']),
    endDate: _readDate(json['endDate']),
    createdBy: json['createdBy'] as String?,
    createdAt: _readDate(json['createdAt']),
    updatedAt: _readDate(json['updatedAt']),
  );

  factory ProjectModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) => ProjectModel.fromJson({...?document.data(), 'id': document.id});

  Map<String, dynamic> toJson({bool includeCreatedAt = false}) => {
    'name': name.trim(),
    'nameLower': nameLower,
    'client': client.trim(),
    'description': description.trim(),
    'department': department.trim(),
    'category': category.trim(),
    'priority': priority.value,
    'status': status.value,
    'employeeIds': employeeIds,
    'teamMembers': teamMembers.map((member) => member.toJson()).toList(),
    'startDate': startDate == null ? null : Timestamp.fromDate(startDate!),
    'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
    'createdBy': createdBy,
    if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  ProjectModel copyWith({
    String? id,
    String? name,
    String? client,
    String? description,
    String? department,
    String? category,
    ProjectPriority? priority,
    ProjectStatus? status,
    List<String>? employeeIds,
    List<ProjectTeamMember>? teamMembers,
    DateTime? startDate,
    DateTime? endDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProjectModel(
    id: id ?? this.id,
    name: name ?? this.name,
    client: client ?? this.client,
    description: description ?? this.description,
    department: department ?? this.department,
    category: category ?? this.category,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    employeeIds: employeeIds ?? this.employeeIds,
    teamMembers: teamMembers ?? this.teamMembers,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().where((id) => id.isNotEmpty).toList();
  }

  static List<ProjectTeamMember> _teamList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => ProjectTeamMember.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((member) => member.employeeId.isNotEmpty)
        .toList();
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

String? _trimOrNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
