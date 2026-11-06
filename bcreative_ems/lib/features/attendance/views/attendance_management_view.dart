import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/core/widgets/page_intro.dart';
import 'package:bcreative_ems/features/attendance/models/attendance_record_model.dart';
import 'package:bcreative_ems/features/attendance/viewmodels/attendance_controller.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/shell/views/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AttendanceManagementView extends GetView<AttendanceController> {
  const AttendanceManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Attendance',
      // Render the complete reference layout immediately. Firestore values
      // update the cards and table as their streams arrive; a slow/offline
      // connection must not leave the user looking at an otherwise blank page.
      body: _AttendanceContent(controller: controller),
    );
  }
}

class _AttendanceContent extends StatelessWidget {
  const _AttendanceContent({required this.controller});

  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final statColumns = width >= 1080
        ? 4
        : width >= 620
        ? 2
        : 1;
    return ListView(
      padding: EdgeInsets.all(isMobile(context) ? 16 : 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 2200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(controller: controller),
                const SizedBox(height: 18),
                Obx(
                  () => GridView.count(
                    crossAxisCount: statColumns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: statColumns == 1 ? 3.1 : 2.25,
                    children: [
                      _StatCard(
                        icon: Icons.groups_rounded,
                        label: 'Total Employees',
                        value: '${controller.totalEmployees}',
                        caption: 'All active employees',
                        color: const Color(0xFF2E6CF6),
                        background: const Color(0xFFE9F0FF),
                      ),
                      _StatCard(
                        icon: Icons.access_time_filled_rounded,
                        label: 'Present Today',
                        value: '${controller.presentToday}',
                        caption: _attendancePercent(
                          controller.presentToday,
                          controller.totalEmployees,
                        ),
                        color: const Color(0xFF10B979),
                        background: const Color(0xFFE1FAEE),
                      ),
                      _StatCard(
                        icon: Icons.person_off_rounded,
                        label: 'Absent Today',
                        value: '${controller.absentToday}',
                        caption: _attendancePercent(
                          controller.absentToday,
                          controller.totalEmployees,
                        ),
                        color: const Color(0xFFFF5964),
                        background: const Color(0xFFFFE7EB),
                      ),
                      _StatCard(
                        icon: Icons.schedule_rounded,
                        label: 'Late Today',
                        value: '${controller.lateToday}',
                        caption: _attendancePercent(
                          controller.lateToday,
                          controller.totalEmployees,
                        ),
                        color: const Color(0xFFFF8A18),
                        background: const Color(0xFFFFEEDC),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final records = _Surface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _FilterBar(controller: controller, embedded: true),
                          const Divider(height: 1, color: Color(0xFFE9EFF8)),
                          _AttendanceDirectory(
                            controller: controller,
                            embedded: true,
                          ),
                        ],
                      ),
                    );
                    final details = _AttendanceDetails(controller: controller);
                    if (constraints.maxWidth >= 920) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: records),
                          const SizedBox(width: 14),
                          SizedBox(width: 350, child: details),
                        ],
                      );
                    }
                    return Column(
                      children: [records, const SizedBox(height: 14), details],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    return const PageIntro(
      icon: Icons.calendar_month_rounded,
      description:
          'View attendance records, check-in/out times and working hours.',
      backgroundColor: Color(0xFFE8F0FF),
      iconSize: 29,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Row(
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF344A70),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7185A9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller, this.embedded = false});

  final AttendanceController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Obx(
      () => Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          _FieldShell(
            width: 228,
            label: 'Date Range',
            child: Row(
              children: [
                const Icon(
                  Icons.date_range_outlined,
                  size: 20,
                  color: Color(0xFF54709C),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${DateFormat('dd MMM yyyy').format(controller.rangeStart)} - ${DateFormat('dd MMM yyyy').format(controller.rangeEnd)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          _FilterDropdown<String>(
            label: 'Department',
            width: 186,
            value: controller.departmentFilter.value,
            allLabel: 'All Departments',
            values: controller.departments,
            onChanged: controller.setDepartmentFilter,
          ),
          _FilterDropdown<String>(
            label: 'Employee',
            width: 192,
            value: controller.employeeFilter.value,
            allLabel: 'All Employees',
            values: controller.activeEmployees.map((item) => item.id).toList(),
            labelFor: (id) => controller.employeeFor(id)?.fullName ?? id,
            onChanged: controller.setEmployeeFilter,
          ),
          _FilterDropdown<AttendanceStatus>(
            label: 'Status',
            width: 176,
            value: controller.statusFilter.value,
            allLabel: 'All Status',
            values: AttendanceStatus.values,
            labelFor: (status) => status.label,
            onChanged: controller.setStatusFilter,
          ),
          Tooltip(
            message: 'Reset filters',
            child: IconButton.outlined(
              onPressed: controller.resetFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
          ),
        ],
      ),
    );
    if (embedded) {
      return Padding(padding: const EdgeInsets.all(12), child: content);
    }
    return _Surface(padding: const EdgeInsets.all(12), child: content);
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.label, required this.child, this.width});

  final String label;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3C5178),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 39,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDE6F4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.allLabel,
    required this.values,
    required this.onChanged,
    this.width,
    this.labelFor,
  });

  final String label;
  final T? value;
  final String allLabel;
  final List<T> values;
  final ValueChanged<T?> onChanged;
  final double? width;
  final String Function(T value)? labelFor;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      width: width,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
          items: [
            DropdownMenuItem<T?>(value: null, child: Text(allLabel)),
            ...values.map(
              (item) => DropdownMenuItem<T?>(
                value: item,
                child: Text(
                  labelFor?.call(item) ?? item.toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onChanged,
          style: const TextStyle(color: Color(0xFF263B62), fontSize: 12),
        ),
      ),
    );
  }
}

// Kept temporarily as a reusable calendar component; it is intentionally not
// mounted in the attendance screen after the reference-led layout update.
// ignore: unused_element
class _CalendarColumn extends StatelessWidget {
  const _CalendarColumn({required this.controller});

  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Surface(
          padding: const EdgeInsets.all(15),
          child: _Calendar(controller: controller),
        ),
        const SizedBox(height: 14),
        _Surface(
          padding: const EdgeInsets.all(15),
          child: _AttendanceOverview(controller: controller),
        ),
      ],
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({required this.controller});

  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final month = controller.selectedMonth.value;
      final selectedDate = controller.selectedDate.value;
      // This read intentionally belongs inside this small Obx scope so calendar
      // dots refresh when Firestore attendance records change.
      controller.records.length;
      final leading = DateTime(month.year, month.month, 1).weekday % 7;
      final days = DateTime(month.year, month.month + 1, 0).day;
      return Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: controller.previousMonth,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: controller.nextMonth,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DayHeader('Sun'),
              _DayHeader('Mon'),
              _DayHeader('Tue'),
              _DayHeader('Wed'),
              _DayHeader('Thu'),
              _DayHeader('Fri'),
              _DayHeader('Sat'),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leading + days,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final date = DateTime(
                month.year,
                month.month,
                index - leading + 1,
              );
              final status = _statusForDate(controller, date);
              final selected = controller.sameDay(date, selectedDate);
              final today = controller.sameDay(date, DateTime.now());
              return InkWell(
                borderRadius: BorderRadius.circular(19),
                onTap: () => controller.selectDate(date),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 31,
                      height: 31,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF2468F2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: today && !selected
                            ? Border.all(color: const Color(0xFF2468F2))
                            : null,
                      ),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF273D65),
                        ),
                      ),
                    ),
                    if (status != null && !selected)
                      Positioned(
                        bottom: 2,
                        child: Container(
                          height: 5,
                          width: 5,
                          decoration: BoxDecoration(
                            color: _statusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 10,
            runSpacing: 5,
            children: [
              _Legend(color: Color(0xFF12B979), label: 'Present'),
              _Legend(color: Color(0xFFFF5964), label: 'Absent'),
              _Legend(color: Color(0xFFFFB51D), label: 'Late'),
            ],
          ),
        ],
      );
    });
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 31,
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 10,
        color: Color(0xFF667B9E),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        height: 10,
        width: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF667B9E)),
      ),
    ],
  );
}

AttendanceStatus? _statusForDate(
  AttendanceController controller,
  DateTime date,
) {
  final dayRecords = controller.records
      .where((record) => controller.sameDay(record.date, date))
      .toList();
  if (dayRecords.any((record) => record.status == AttendanceStatus.late)) {
    return AttendanceStatus.late;
  }
  if (dayRecords.any((record) => record.status == AttendanceStatus.present)) {
    return AttendanceStatus.present;
  }
  if (dayRecords.any((record) => record.status == AttendanceStatus.absent)) {
    return AttendanceStatus.absent;
  }
  return null;
}

class _AttendanceOverview extends StatelessWidget {
  const _AttendanceOverview({required this.controller});
  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final month = controller.selectedMonth.value;
      final records = controller.records;
      final totalEmployees = controller.totalEmployees;
      final days = DateTime(month.year, month.month + 1, 0).day;
      final maxCount = (totalEmployees == 0 ? 1 : totalEmployees).toDouble();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Overview',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 116,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (week) {
                final start = week * 7 + 1;
                final end = (start + 6).clamp(1, days);
                final set = records.where(
                  (record) =>
                      record.date.day >= start && record.date.day <= end,
                );
                final present = set
                    .where(
                      (record) => record.status == AttendanceStatus.present,
                    )
                    .length;
                final absent = set
                    .where((record) => record.status == AttendanceStatus.absent)
                    .length;
                final late = set
                    .where((record) => record.status == AttendanceStatus.late)
                    .length;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _Bar(
                                value: present / maxCount,
                                color: const Color(0xFF12B979),
                              ),
                              const SizedBox(width: 2),
                              _Bar(
                                value: absent / maxCount,
                                color: const Color(0xFFFF5964),
                              ),
                              const SizedBox(width: 2),
                              _Bar(
                                value: late / maxCount,
                                color: const Color(0xFFFFB51D),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'W${week + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF5D7195),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 10,
            children: [
              _Legend(color: Color(0xFF12B979), label: 'Present'),
              _Legend(color: Color(0xFFFF5964), label: 'Absent'),
              _Legend(color: Color(0xFFFFB51D), label: 'Late'),
            ],
          ),
        ],
      );
    });
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      width: 8,
      height: 82 * value.clamp(0, 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    ),
  );
}

class _AttendanceDirectory extends StatelessWidget {
  const _AttendanceDirectory({required this.controller, this.embedded = false});
  final AttendanceController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 13, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Attendance Records',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: controller.resetFilters,
                child: const Text('Reset Filters'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Obx(() {
          final employeesError = controller.employeesError.value;
          if (employeesError != null) {
            return _AttendanceStreamError(
              title: 'Employees could not be loaded',
              message: employeesError,
              onRetry: controller.retryLiveData,
            );
          }
          final attendanceError = controller.attendanceError.value;
          if (controller.visibleRows.isEmpty) {
            final hasEmployees = controller.employees.isNotEmpty;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 58, horizontal: 20),
              child: Column(
                children: [
                  const Icon(
                    Icons.event_busy_outlined,
                    color: Color(0xFF8196B9),
                    size: 42,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasEmployees
                        ? 'No employees match the selected filters'
                        : 'No employee records found',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasEmployees
                        ? 'Reset the filters to show your employee list.'
                        : 'Add employees in Firebase to show the attendance register.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF7083A5)),
                  ),
                ],
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (attendanceError != null)
                _AttendanceStreamError(
                  compact: true,
                  title: 'Attendance records are unavailable',
                  message: attendanceError,
                  onRetry: controller.retryLiveData,
                ),
              isMobile(context)
                  ? _AttendanceCards(controller: controller)
                  : _AttendanceTable(controller: controller),
            ],
          );
        }),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        _Pagination(controller: controller),
      ],
    );
    return embedded
        ? content
        : _Surface(padding: EdgeInsets.zero, child: content);
  }
}

class _AttendanceStreamError extends StatelessWidget {
  const _AttendanceStreamError({
    required this.title,
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: EdgeInsets.all(compact ? 10 : 18),
    padding: EdgeInsets.all(compact ? 10 : 18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E8),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFF4D7A0)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: Color(0xFFE08A00),
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                message,
                maxLines: compact ? 2 : 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6A5732)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 17),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

class _AttendanceTable extends StatelessWidget {
  const _AttendanceTable({required this.controller});
  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    // A horizontal scroll view provides its child unlimited width. The table
    // rows use Expanded cells, so they must first receive one explicit finite
    // width; otherwise Flutter cannot lay them out or hit-test them.
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 730.0;
        final width = availableWidth < 730 ? 730.0 : availableWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                const _TableHeader(),
                ...controller.visibleRows.map(
                  (row) =>
                      _AttendanceTableRow(controller: controller, row: row),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();
  @override
  Widget build(BuildContext context) => Container(
    height: 37,
    color: const Color(0xFFF5F8FD),
    padding: const EdgeInsets.symmetric(horizontal: 13),
    child: const Row(
      children: [
        SizedBox(
          width: 28,
          child: Icon(
            Icons.check_box_outline_blank,
            size: 17,
            color: Color(0xFF8498BA),
          ),
        ),
        Expanded(flex: 25, child: _HeaderLabel('EMPLOYEE')),
        Expanded(flex: 15, child: _HeaderLabel('DATE')),
        Expanded(flex: 14, child: _HeaderLabel('CHECK IN')),
        Expanded(flex: 14, child: _HeaderLabel('CHECK OUT')),
        Expanded(flex: 15, child: _HeaderLabel('WORK HOURS')),
        Expanded(flex: 14, child: _HeaderLabel('STATUS')),
        SizedBox(width: 36, child: _HeaderLabel('')),
      ],
    ),
  );
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 10,
      color: Color(0xFF50658B),
      fontWeight: FontWeight.w700,
    ),
  );
}

class _AttendanceTableRow extends StatelessWidget {
  const _AttendanceTableRow({required this.controller, required this.row});
  final AttendanceController controller;
  final AttendanceListRow row;

  @override
  Widget build(BuildContext context) => Obx(() {
    final record = row.record;
    final selected = controller.selectedEmployeeId.value == row.employee.id;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.selectRow(row),
      child: Container(
        height: 60,
        color: selected ? const Color(0xFFF6F9FF) : null,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: Row(
          children: [
            const SizedBox(
              width: 28,
              child: Icon(
                Icons.check_box_outline_blank,
                size: 17,
                color: Color(0xFF9BAECC),
              ),
            ),
            Expanded(flex: 25, child: _EmployeeCell(employee: row.employee)),
            Expanded(
              flex: 15,
              child: _CellText(
                DateFormat('dd MMM yyyy').format(controller.selectedDate.value),
              ),
            ),
            Expanded(flex: 14, child: _CellText(_time(record?.checkIn))),
            Expanded(flex: 14, child: _CellText(_time(record?.checkOut))),
            Expanded(flex: 15, child: _CellText(record?.workHoursLabel ?? '—')),
            Expanded(
              flex: 14,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusChip(status: row.effectiveStatus),
              ),
            ),
            SizedBox(
              width: 36,
              child: IconButton(
                tooltip: 'View details',
                onPressed: () => controller.selectRow(row),
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFF2568F3),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  });
}

class _EmployeeCell extends StatelessWidget {
  const _EmployeeCell({required this.employee});
  final EmployeeModel employee;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _EmployeeAvatar(employee: employee, radius: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              employee.fullName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              employee.employeeCode,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Color(0xFF7185A8)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CellText extends StatelessWidget {
  const _CellText(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Text(
    value,
    style: const TextStyle(fontSize: 11, color: Color(0xFF40567E)),
  );
}

class _AttendanceCards extends StatelessWidget {
  const _AttendanceCards({required this.controller});
  final AttendanceController controller;
  @override
  Widget build(BuildContext context) => ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(12),
    itemCount: controller.visibleRows.length,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
      final row = controller.visibleRows[index];
      final record = row.record;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.selectRow(row),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE4EBF6)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _EmployeeAvatar(employee: row.employee, radius: 19),
                  const SizedBox(width: 10),
                  Expanded(child: _EmployeeCellText(employee: row.employee)),
                  _StatusChip(status: row.effectiveStatus),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: _MiniValue(
                      label: 'Check in',
                      value: _time(record?.checkIn),
                    ),
                  ),
                  Expanded(
                    child: _MiniValue(
                      label: 'Check out',
                      value: _time(record?.checkOut),
                    ),
                  ),
                  Expanded(
                    child: _MiniValue(
                      label: 'Work hours',
                      value: record?.workHoursLabel ?? '—',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _EmployeeCellText extends StatelessWidget {
  const _EmployeeCellText({required this.employee});
  final EmployeeModel employee;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        employee.fullName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      Text(
        '${employee.employeeCode} • ${employee.jobTitle ?? 'Employee'}',
        style: const TextStyle(fontSize: 11, color: Color(0xFF7185A8)),
      ),
    ],
  );
}

class _MiniValue extends StatelessWidget {
  const _MiniValue({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF7185A8)),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.controller});
  final AttendanceController controller;
  @override
  Widget build(BuildContext context) => Obx(
    () => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          Text(
            'Showing ${controller.showingStart} to ${controller.showingEnd} of ${controller.filteredRows.length} records',
            style: const TextStyle(fontSize: 11, color: Color(0xFF5F749A)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                onPressed: controller.hasPreviousPage
                    ? () =>
                          controller.goToPage(controller.currentPage.value - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 6),
              ...List.generate(
                controller.pageCount.clamp(1, 4),
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: FilledButton(
                      onPressed: () => controller.goToPage(index),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: controller.currentPage.value == index
                            ? const Color(0xFF2468F2)
                            : const Color(0xFFF2F6FC),
                        foregroundColor: controller.currentPage.value == index
                            ? Colors.white
                            : const Color(0xFF345178),
                      ),
                      child: Text('${index + 1}'),
                    ),
                  ),
                ),
              ),
              IconButton.outlined(
                onPressed: controller.hasNextPage
                    ? () =>
                          controller.goToPage(controller.currentPage.value + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AttendanceDetails extends StatelessWidget {
  const _AttendanceDetails({required this.controller});
  final AttendanceController controller;
  @override
  Widget build(BuildContext context) => _Surface(
    padding: EdgeInsets.zero,
    child: Obx(() {
      final employee = controller.selectedEmployee;
      final record = controller.selectedDayRecord;
      final activeTab = controller.detailTab.value;
      if (employee == null) {
        return const Padding(
          padding: EdgeInsets.all(28),
          child: Center(
            child: Text('Select an employee to view attendance details.'),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 11, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Employee Attendance Details',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.resetFilters,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Reset Filters'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9EFF8)),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _EmployeeAvatar(employee: employee, radius: 32),
                    const SizedBox(width: 11),
                    Expanded(child: _EmployeeDetailsText(employee: employee)),
                    _EmploymentChip(label: employee.employmentStatus.label),
                  ],
                ),
                const SizedBox(height: 15),
                _DetailTabs(controller: controller, activeTab: activeTab),
                if (activeTab == 'attendance') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailMetric(
                          icon: Icons.login_rounded,
                          label: 'Check In',
                          value: _time(record?.checkIn),
                          color: const Color(0xFF10B979),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailMetric(
                          icon: Icons.logout_rounded,
                          label: 'Check Out',
                          value: _time(record?.checkOut),
                          color: const Color(0xFFFF5964),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailMetric(
                          icon: Icons.timer_outlined,
                          label: 'Work Hours',
                          value: record?.workHoursLabel ?? '—',
                          color: const Color(0xFF2E6CF6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailMetric(
                          icon: Icons.verified_outlined,
                          label: 'Status',
                          value:
                              (record?.status ?? AttendanceStatus.absent).label,
                          color: _statusColor(
                            record?.status ?? AttendanceStatus.absent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Recent Attendance (Last 7 Days)',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 9),
                  ...List.generate(7, (index) {
                    final date = controller.selectedDate.value.subtract(
                      Duration(days: index),
                    );
                    final entry =
                        controller.selectedEmployeeLastSevenDays[index];
                    return _RecentDayRow(date: date, record: entry);
                  }),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => controller.setDetailTab('summary'),
                      icon: const Icon(Icons.query_stats_rounded, size: 18),
                      label: const Text('View Full Attendance History'),
                    ),
                  ),
                ] else if (activeTab == 'summary') ...[
                  const SizedBox(height: 16),
                  _MonthlyHistoryContent(controller: controller),
                ] else ...[
                  const SizedBox(height: 16),
                  _AttendanceStatisticsContent(controller: controller),
                ],
              ],
            ),
          ),
        ],
      );
    }),
  );
}

class _MonthlyHistoryContent extends StatelessWidget {
  const _MonthlyHistoryContent({required this.controller});

  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    final entries = controller.selectedEmployeeMonthlyRecords;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Monthly Attendance History',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(controller.selectedMonth.value),
              style: const TextStyle(fontSize: 10, color: Color(0xFF6C80A3)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No attendance has been recorded this month.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF7185A8)),
              ),
            ),
          )
        else
          ...entries.map(
            (entry) => _RecentDayRow(date: entry.date, record: entry),
          ),
      ],
    );
  }
}

class _AttendanceStatisticsContent extends StatelessWidget {
  const _AttendanceStatisticsContent({required this.controller});

  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    final entries = controller.selectedEmployeeMonthlyRecords;
    final present = entries
        .where((entry) => entry.status == AttendanceStatus.present)
        .length;
    final late = entries
        .where((entry) => entry.status == AttendanceStatus.late)
        .length;
    final workMinutes = entries.fold<int>(
      0,
      (total, entry) => total + entry.workMinutes,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Statistics',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _StatisticLine(
          icon: Icons.check_circle_outline_rounded,
          label: 'Present days',
          value: '$present',
          color: const Color(0xFF10B979),
        ),
        const SizedBox(height: 8),
        _StatisticLine(
          icon: Icons.schedule_rounded,
          label: 'Late days',
          value: '$late',
          color: const Color(0xFFF29A14),
        ),
        const SizedBox(height: 8),
        _StatisticLine(
          icon: Icons.timer_outlined,
          label: 'Recorded work hours',
          value: _workHours(workMinutes),
          color: const Color(0xFF2468F2),
        ),
      ],
    );
  }
}

class _StatisticLine extends StatelessWidget {
  const _StatisticLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F9FD),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF50658B)),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _DetailTabs extends StatelessWidget {
  const _DetailTabs({required this.controller, required this.activeTab});

  final AttendanceController controller;
  final String activeTab;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _DetailTab(
        label: 'Attendance',
        active: activeTab == 'attendance',
        onTap: () => controller.setDetailTab('attendance'),
      ),
      _DetailTab(
        label: 'Monthly Summary',
        active: activeTab == 'summary',
        onTap: () => controller.setDetailTab('summary'),
      ),
      _DetailTab(
        label: 'Statistics',
        active: activeTab == 'statistics',
        onTap: () => controller.setDetailTab('statistics'),
      ),
    ],
  );
}

class _DetailTab extends StatelessWidget {
  const _DetailTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF2468F2) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? const Color(0xFF2468F2) : const Color(0xFF65799D),
          ),
        ),
      ),
    ),
  );
}

class _RecentDayRow extends StatelessWidget {
  const _RecentDayRow({required this.date, this.record});

  final DateTime date;
  final AttendanceRecordModel? record;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    margin: const EdgeInsets.only(bottom: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFE),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 12,
          child: Text(
            DateFormat('dd MMM').format(date),
            style: const TextStyle(fontSize: 10),
          ),
        ),
        Expanded(
          flex: 11,
          child: Text(
            _time(record?.checkIn),
            style: const TextStyle(fontSize: 10),
          ),
        ),
        Expanded(
          flex: 11,
          child: Text(
            _time(record?.checkOut),
            style: const TextStyle(fontSize: 10),
          ),
        ),
        record == null
            ? const _NoRecordChip()
            : _StatusChip(status: record!.status, compact: true),
      ],
    ),
  );
}

class _NoRecordChip extends StatelessWidget {
  const _NoRecordChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFE8EDF5),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text(
      'No Record',
      style: TextStyle(
        fontSize: 9,
        color: Color(0xFF667B9E),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _EmploymentChip extends StatelessWidget {
  const _EmploymentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final active = label.toLowerCase() == 'active';
    final color = active ? const Color(0xFF0EAF70) : const Color(0xFFFF5964);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmployeeDetailsText extends StatelessWidget {
  const _EmployeeDetailsText({required this.employee});
  final EmployeeModel employee;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        employee.fullName,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      Text(
        employee.employeeCode,
        style: const TextStyle(fontSize: 11, color: Color(0xFF61769B)),
      ),
      Text(
        employee.jobTitle ?? 'Employee',
        style: const TextStyle(fontSize: 11, color: Color(0xFF61769B)),
      ),
      Text(
        employee.department ?? '—',
        style: const TextStyle(fontSize: 11, color: Color(0xFF61769B)),
      ),
    ],
  );
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F8FC),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Container(
          height: 29,
          width: 29,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF62769B)),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ignore: unused_element
class _RecentRow extends StatelessWidget {
  const _RecentRow(this.record);
  final AttendanceRecordModel record;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    margin: const EdgeInsets.only(bottom: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFE),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 12,
          child: Text(
            DateFormat('dd MMM').format(record.date),
            style: const TextStyle(fontSize: 10),
          ),
        ),
        Expanded(
          flex: 11,
          child: Text(
            _time(record.checkIn),
            style: const TextStyle(fontSize: 10),
          ),
        ),
        Expanded(
          flex: 11,
          child: Text(
            _time(record.checkOut),
            style: const TextStyle(fontSize: 10),
          ),
        ),
        _StatusChip(status: record.status, compact: true),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.compact = false});
  final AttendanceStatus status;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: compact ? 9 : 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmployeeAvatar extends StatelessWidget {
  const _EmployeeAvatar({required this.employee, required this.radius});
  final EmployeeModel employee;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final initials = employee.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8EFFC),
      foregroundImage: employee.displayPhotoUrl?.isNotEmpty == true
          ? NetworkImage(employee.displayPhotoUrl!)
          : null,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: radius * .52,
          color: const Color(0xFF42628F),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A294E85),
          blurRadius: 18,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

Color _statusColor(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => const Color(0xFF0EAF70),
  AttendanceStatus.absent => const Color(0xFFFF4F5E),
  AttendanceStatus.late => const Color(0xFFF29A14),
};

String _time(DateTime? value) =>
    value == null ? '—' : DateFormat('hh:mm a').format(value);

String _workHours(int minutes) {
  if (minutes <= 0) return '—';
  return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
}

String _attendancePercent(int value, int total) => total == 0
    ? 'No active employees'
    : '${(value * 100 / total).toStringAsFixed(1)}% attendance';
