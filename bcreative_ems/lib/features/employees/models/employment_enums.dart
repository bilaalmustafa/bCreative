enum EmploymentStatus {
  active('active', 'Active'),
  inactive('inactive', 'Inactive'),
  onLeave('on_leave', 'On leave'),
  terminated('terminated', 'Terminated');

  const EmploymentStatus(this.value, this.label);
  final String value;
  final String label;

  static EmploymentStatus? fromValue(String? value) {
    if (value == null) return null;
    for (final e in EmploymentStatus.values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum EmploymentType {
  fullTime('full_time', 'Full time'),
  partTime('part_time', 'Part time'),
  contract('contract', 'Contract'),
  intern('intern', 'Intern');

  const EmploymentType(this.value, this.label);
  final String value;
  final String label;

  static EmploymentType? fromValue(String? value) {
    if (value == null) return null;
    for (final e in EmploymentType.values) {
      if (e.value == value) return e;
    }
    return null;
  }
}
