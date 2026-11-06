import 'package:cloud_firestore/cloud_firestore.dart';

enum EmployeeTaskStatus {
  assigned('assigned', 'Pending'),
  inProgress('in_progress', 'In progress'),
  completed('completed', 'Completed');

  const EmployeeTaskStatus(this.value, this.label);

  final String value;
  final String label;

  static EmployeeTaskStatus fromValue(String? value) =>
      EmployeeTaskStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => EmployeeTaskStatus.assigned,
      );
}

enum TaskPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  urgent('urgent', 'Urgent');

  const TaskPriority(this.value, this.label);

  final String value;
  final String label;

  static TaskPriority fromValue(String? value) =>
      TaskPriority.values.firstWhere(
        (priority) => priority.value == value,
        orElse: () => TaskPriority.medium,
      );
}

class EmployeeTaskModel {
  const EmployeeTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.employeeId,
    required this.assignedBy,
    required this.status,
    this.projectId,
    this.priority = TaskPriority.medium,
    this.progress = 0,
    this.taskType,
    this.labels = const [],
    this.estimatedHours,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String employeeId;
  final String assignedBy;
  final EmployeeTaskStatus status;
  final String? projectId;
  final TaskPriority priority;
  final int progress;
  final String? taskType;
  final List<String> labels;
  final num? estimatedHours;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EmployeeTaskModel.fromJson(Map<String, dynamic> data) {
    return EmployeeTaskModel(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      assignedBy: data['assignedBy'] as String? ?? '',
      status: EmployeeTaskStatus.fromValue(data['status'] as String?),
      projectId: data['projectId'] as String?,
      priority: TaskPriority.fromValue(data['priority'] as String?),
      progress: _progressFor(data['progress'], data['status'] as String?),
      taskType: data['taskType'] as String?,
      labels: _readStringList(data['labels']),
      estimatedHours: data['estimatedHours'] as num?,
      dueDate: _readDate(data['dueDate']),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  factory EmployeeTaskModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) => EmployeeTaskModel.fromJson({...?document.data(), 'id': document.id});

  Map<String, dynamic> toJson({bool includeCreatedAt = false}) => {
    'title': title.trim(),
    'description': description.trim(),
    'employeeId': employeeId,
    'assignedBy': assignedBy,
    'status': status.value,
    'projectId': projectId,
    'priority': priority.value,
    'progress': progress.clamp(0, 100),
    'taskType': _trimOrNull(taskType),
    'labels': labels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(),
    'estimatedHours': estimatedHours,
    'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
    if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  EmployeeTaskModel copyWith({
    String? title,
    String? description,
    String? employeeId,
    String? projectId,
    EmployeeTaskStatus? status,
    TaskPriority? priority,
    int? progress,
    String? taskType,
    List<String>? labels,
    num? estimatedHours,
    DateTime? dueDate,
  }) => EmployeeTaskModel(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    employeeId: employeeId ?? this.employeeId,
    assignedBy: assignedBy,
    status: status ?? this.status,
    projectId: projectId ?? this.projectId,
    priority: priority ?? this.priority,
    progress: progress ?? this.progress,
    taskType: taskType ?? this.taskType,
    labels: labels ?? this.labels,
    estimatedHours: estimatedHours ?? this.estimatedHours,
    dueDate: dueDate ?? this.dueDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int _progressFor(dynamic value, String? status) {
    if (value is num) return value.toInt().clamp(0, 100);
    return switch (EmployeeTaskStatus.fromValue(status)) {
      EmployeeTaskStatus.assigned => 0,
      EmployeeTaskStatus.inProgress => 50,
      EmployeeTaskStatus.completed => 100,
    };
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .where((label) => label.trim().isNotEmpty)
        .toList();
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class TaskUpdateModel {
  const TaskUpdateModel({
    required this.id,
    required this.taskId,
    required this.employeeId,
    required this.text,
    this.fileName,
    this.storagePath,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String taskId;
  final String employeeId;
  final String text;
  final String? fileName;
  final String? storagePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasFile => storagePath != null && storagePath!.isNotEmpty;

  factory TaskUpdateModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return TaskUpdateModel(
      id: document.id,
      taskId: data['taskId'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      fileName: data['fileName'] as String?,
      storagePath: data['storagePath'] as String?,
      createdAt: EmployeeTaskModel._readDate(data['createdAt']),
      updatedAt: EmployeeTaskModel._readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson({bool includeCreatedAt = false}) => {
    'taskId': taskId,
    'employeeId': employeeId,
    'text': text.trim(),
    'fileName': fileName,
    'storagePath': storagePath,
    if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
