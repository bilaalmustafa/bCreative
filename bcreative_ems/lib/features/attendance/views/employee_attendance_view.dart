import 'package:bcreative_ems/app/routes/app_routes.dart';
import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/core/widgets/app_loading.dart';
import 'package:bcreative_ems/core/widgets/header_action_layout.dart';
import 'package:bcreative_ems/core/widgets/page_intro.dart';
import 'package:bcreative_ems/features/attendance/models/attendance_record_model.dart';
import 'package:bcreative_ems/features/attendance/viewmodels/employee_attendance_controller.dart';
import 'package:bcreative_ems/features/shell/views/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EmployeeAttendanceView extends GetView<EmployeeAttendanceController> {
  const EmployeeAttendanceView({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'My Attendance',
    body: Obx(
      () => controller.isLoading.value
          ? const AppLoading()
          : _MonthlyAttendanceContent(controller: controller),
    ),
  );
}

/// Shared dashboard body. It is intentionally separate from [AppShell] so the
/// employee dashboard and My Attendance page use one live controller.
class EmployeeAttendanceDashboard extends StatelessWidget {
  const EmployeeAttendanceDashboard({super.key, required this.controller});

  final EmployeeAttendanceController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => controller.isLoading.value
        ? const AppLoading()
        : _EmployeeDashboardAttendanceContent(controller: controller),
  );
}

class _EmployeeDashboardAttendanceContent extends StatelessWidget {
  const _EmployeeDashboardAttendanceContent({required this.controller});

  final EmployeeAttendanceController controller;

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return ListView(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(controller: controller),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final today = _TodayRecordCard(controller: controller);
                    final recent = _RecentAttendanceCard(
                      controller: controller,
                    );
                    if (constraints.maxWidth >= 880) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 11, child: today),
                          const SizedBox(width: 14),
                          Expanded(flex: 9, child: recent),
                        ],
                      );
                    }
                    return Column(
                      children: [today, const SizedBox(height: 14), recent],
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.controller});

  final EmployeeAttendanceController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final name = controller.profile.value?.fullName.trim();
    final displayName = name == null || name.isEmpty ? 'Employee' : name;
    return HeaderActionLayout(
      heading: Row(
        children: [
          Container(
            height: 47,
            width: 47,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F0FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Color(0xFF2468F2),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $displayName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Check in, check out, and review your recent attendance.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFF60749A), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      action: OutlinedButton.icon(
        onPressed: () => Get.toNamed(AppRoutes.employeeAttendance),
        icon: const Icon(Icons.calendar_month_outlined, size: 19),
        label: const Text('My Attendance'),
      ),
    );
  });
}

class _TodayRecordCard extends StatelessWidget {
  const _TodayRecordCard({required this.controller});

  final EmployeeAttendanceController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final record = controller.todayRecord.value;
    final isSaving = controller.isSaving.value;
    return _EmployeeSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Record",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Your attendance updates in real time.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF687DA1),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('EEE, dd MMM').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF41597F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9EFF8)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 390;
                    final metrics = [
                      _AttendanceMetric(
                        icon: Icons.login_rounded,
                        label: 'Check In',
                        value: _time(record?.checkIn),
                        color: const Color(0xFF10B979),
                      ),
                      _AttendanceMetric(
                        icon: Icons.logout_rounded,
                        label: 'Check Out',
                        value: _time(record?.checkOut),
                        color: const Color(0xFFFF5964),
                      ),
                      _AttendanceMetric(
                        icon: Icons.timer_outlined,
                        label: 'Work Hours',
                        value: record?.workHoursLabel ?? '—',
                        color: const Color(0xFF2E6CF6),
                      ),
                      _AttendanceMetric(
                        icon: Icons.verified_outlined,
                        label: 'Status',
                        value: record?.status.label ?? 'Not checked in',
                        color: _recordColor(record),
                      ),
                    ];
                    return GridView.count(
                      crossAxisCount: twoColumns ? 2 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 9,
                      crossAxisSpacing: 9,
                      childAspectRatio: twoColumns ? 3.2 : 4.6,
                      children: metrics,
                    );
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: controller.canCheckIn && !isSaving
                            ? controller.checkIn
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF11B979),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _ActionIcon(
                          saving: isSaving && controller.canCheckIn,
                          icon: Icons.login_rounded,
                        ),
                        label: const Text('Check In'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: controller.canCheckOut && !isSaving
                            ? controller.checkOut
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5964),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _ActionIcon(
                          saving: isSaving && controller.canCheckOut,
                          icon: Icons.logout_rounded,
                        ),
                        label: const Text('Check Out'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _todayHint(controller),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7185A8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.saving, required this.icon});

  final bool saving;
  final IconData icon;

  @override
  Widget build(BuildContext context) => saving
      ? const SizedBox.square(
          dimension: 17,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : Icon(icon);
}

class _AttendanceMetric extends StatelessWidget {
  const _AttendanceMetric({
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
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F8FC),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Container(
          height: 31,
          width: 31,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF667B9F)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
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

class _RecentAttendanceCard extends StatelessWidget {
  const _RecentAttendanceCard({required this.controller});

  final EmployeeAttendanceController controller;

  @override
  Widget build(BuildContext context) => _EmployeeSurface(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Attendance',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.employeeAttendance),
                child: const Text('View all'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Obx(() => _EmployeeAttendanceTable(days: controller.recentDays)),
      ],
    ),
  );
}

class _MonthlyAttendanceContent extends StatelessWidget {
  const _MonthlyAttendanceContent({required this.controller});

  final EmployeeAttendanceController controller;

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return ListView(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MonthlyHeader(controller: controller),
                const SizedBox(height: 18),
                _MonthlySummaryCards(controller: controller),
                const SizedBox(height: 14),
                _EmployeeSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MonthlyFilters(controller: controller, embedded: true),
                      const Divider(height: 1, color: Color(0xFFE9EFF8)),
                      _MonthlyHistoryCard(
                        controller: controller,
                        embedded: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthlyHeader extends StatelessWidget {
  const _MonthlyHeader({required this.controller});

  final EmployeeAttendanceController controller;

  @override
  Widget build(BuildContext context) => HeaderActionLayout(
    heading: const PageIntro(
      icon: Icons.calendar_month_rounded,
      description: 'Review your selected-month attendance history.',
      iconSize: 28,
    ),
    action: _MonthPicker(controller: controller),
  );
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.controller});

  final EmployeeAttendanceController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDDE6F4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: controller.previousMonth,
            tooltip: 'Previous month',
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            DateFormat('MMMM yyyy').format(controller.selectedMonth.value),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          IconButton(
            onPressed: _canGoNext(controller) ? controller.nextMonth : null,
            tooltip: 'Next month',
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    ),
  );
}

class _MonthlySummaryCards extends StatelessWidget {
  const _MonthlySummaryCards({required this.controller});

  final EmployeeAttendanceController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Obx(() {
      final cards = [
        _MonthStatCard(
          icon: Icons.check_circle_outline_rounded,
          label: 'Present Days',
          value: '${controller.presentDays}',
          caption: 'Selected month',
          color: const Color(0xFF10B979),
          background: const Color(0xFFE1FAEE),
        ),
        _MonthStatCard(
          icon: Icons.schedule_rounded,
          label: 'Late Days',
          value: '${controller.lateDays}',
          caption: 'Selected month',
          color: const Color(0xFFF29A14),
          background: const Color(0xFFFFF1D6),
        ),
        _MonthStatCard(
          icon: Icons.person_off_outlined,
          label: 'Absent Days',
          value: '${controller.absentDays}',
          caption: 'No record on past dates',
          color: const Color(0xFFFF5964),
          background: const Color(0xFFFFE7EB),
        ),
      ];
      if (constraints.maxWidth >= 760) {
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        );
      }
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 10),
          cards[1],
          const SizedBox(height: 10),
          cards[2],
        ],
      );
    }),
  );
}

class _MonthStatCard extends StatelessWidget {
  const _MonthStatCard({
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
  Widget build(BuildContext context) => _EmployeeSurface(
    child: Row(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF40567E),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF7185A9)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MonthlyFilters extends StatelessWidget {
  const _MonthlyFilters({required this.controller, this.embedded = false});

  final EmployeeAttendanceController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Obx(
      () => Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          _FilterField(
            label: 'Date',
            width: 230,
            child: InkWell(
              borderRadius: BorderRadius.circular(7),
              onTap: () => _pickDate(context, controller),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range_outlined,
                    size: 19,
                    color: Color(0xFF54709C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.dateFilter.value == null
                          ? 'All dates in month'
                          : DateFormat('dd MMM yyyy')
                                .format(controller.dateFilter.value!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (controller.dateFilter.value != null)
                    InkResponse(
                      onTap: () => controller.setDateFilter(null),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: Color(0xFF7185A8),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _FilterField(
            label: 'Attendance Status',
            width: 210,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AttendanceStatus?>(
                value: controller.statusFilter.value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
                items: [
                  const DropdownMenuItem<AttendanceStatus?>(
                    value: null,
                    child: Text('All Status'),
                  ),
                  ...AttendanceStatus.values.map(
                    (status) => DropdownMenuItem<AttendanceStatus?>(
                      value: status,
                      child: Text(status.label),
                    ),
                  ),
                ],
                onChanged: controller.setStatusFilter,
                style: const TextStyle(color: Color(0xFF263B62), fontSize: 12),
              ),
            ),
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
    return _EmployeeSurface(padding: const EdgeInsets.all(12), child: content);
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.label,
    required this.child,
    required this.width,
  });

  final String label;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
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
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ],
    ),
  );
}

class _MonthlyHistoryCard extends StatelessWidget {
  const _MonthlyHistoryCard({required this.controller, this.embedded = false});

  final EmployeeAttendanceController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly Attendance History',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Obx(
                () => Text(
                  '${controller.filteredMonthlyDays.length} days',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7185A8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Obx(() {
          final rows = controller.filteredMonthlyDays;
          if (rows.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF8196B9),
                    size: 38,
                  ),
                  SizedBox(height: 9),
                  Text(
                    'No attendance days found',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Change the month or reset the filters.',
                    style: TextStyle(color: Color(0xFF7185A8), fontSize: 12),
                  ),
                ],
              ),
            );
          }
          return _EmployeeAttendanceTable(days: rows);
        }),
      ],
    );
    return embedded
        ? content
        : _EmployeeSurface(padding: EdgeInsets.zero, child: content);
  }
}

/// Same visual record-table language as the admin attendance screen, but it
/// deliberately has no employee-name column and no action/detail column.
class _EmployeeAttendanceTable extends StatelessWidget {
  const _EmployeeAttendanceTable({required this.days});

  final List<EmployeeAttendanceDay> days;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : 560.0;
      final width = availableWidth < 560 ? 560.0 : availableWidth;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              const _EmployeeAttendanceTableHeader(),
              ...days.map((day) => _EmployeeAttendanceTableRow(day: day)),
            ],
          ),
        ),
      );
    },
  );
}

class _EmployeeAttendanceTableHeader extends StatelessWidget {
  const _EmployeeAttendanceTableHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    color: const Color(0xFFF5F8FD),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: const Row(
      children: [
        Expanded(flex: 25, child: _EmployeeRecordHeader('DATE')),
        Expanded(flex: 20, child: _EmployeeRecordHeader('CHECK IN')),
        Expanded(flex: 20, child: _EmployeeRecordHeader('CHECK OUT')),
        Expanded(flex: 19, child: _EmployeeRecordHeader('WORK HOURS')),
        Expanded(flex: 16, child: _EmployeeRecordHeader('STATUS')),
      ],
    ),
  );
}

class _EmployeeRecordHeader extends StatelessWidget {
  const _EmployeeRecordHeader(this.label);

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

class _EmployeeAttendanceTableRow extends StatelessWidget {
  const _EmployeeAttendanceTableRow({required this.day});

  final EmployeeAttendanceDay day;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFEFF3F9))),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 25,
          child: Text(
            DateFormat('dd MMM yyyy').format(day.date),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(flex: 20, child: _EmployeeRecordValue(_time(day.checkIn))),
        Expanded(flex: 20, child: _EmployeeRecordValue(_time(day.checkOut))),
        Expanded(flex: 19, child: _EmployeeRecordValue(day.workHoursLabel)),
        Expanded(
          flex: 16,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _EmployeeStatusChip(status: day.status),
          ),
        ),
      ],
    ),
  );
}

class _EmployeeRecordValue extends StatelessWidget {
  const _EmployeeRecordValue(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: const TextStyle(fontSize: 11, color: Color(0xFF40567E)),
  );
}

// Kept only as a visual reference while the employee table mirrors admin UI.
// ignore: unused_element
class _AttendanceDayRow extends StatelessWidget {
  const _AttendanceDayRow({required this.day});

  final EmployeeAttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final color = _recordColorStatus(day.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              day.status == AttendanceStatus.absent
                  ? Icons.person_off_outlined
                  : day.status == AttendanceStatus.late
                  ? Icons.schedule_rounded
                  : Icons.check_circle_outline_rounded,
              size: 19,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(day.date),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_time(day.checkIn)}  •  ${_time(day.checkOut)}  •  ${day.workHoursLabel}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF697FA4),
                  ),
                ),
              ],
            ),
          ),
          _EmployeeStatusChip(status: day.status),
        ],
      ),
    );
  }
}

class _EmployeeStatusChip extends StatelessWidget {
  const _EmployeeStatusChip({required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _recordColorStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _EmployeeSurface extends StatelessWidget {
  const _EmployeeSurface({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
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

Future<void> _pickDate(
  BuildContext context,
  EmployeeAttendanceController controller,
) async {
  final now = DateTime.now();
  final maxDate = controller.monthEnd.isBefore(now)
      ? controller.monthEnd
      : DateTime(now.year, now.month, now.day);
  if (maxDate.isBefore(controller.monthStart)) return;
  final picked = await showDatePicker(
    context: context,
    initialDate: controller.dateFilter.value ?? maxDate,
    firstDate: controller.monthStart,
    lastDate: maxDate,
  );
  if (picked != null) controller.setDateFilter(picked);
}

bool _canGoNext(EmployeeAttendanceController controller) {
  final now = DateTime.now();
  final next = DateTime(
    controller.selectedMonth.value.year,
    controller.selectedMonth.value.month + 1,
  );
  return !next.isAfter(DateTime(now.year, now.month));
}

String _time(DateTime? value) =>
    value == null ? '—' : DateFormat('hh:mm a').format(value);

String _todayHint(EmployeeAttendanceController controller) {
  if (controller.canCheckIn) return 'You can check in once for today.';
  if (controller.canCheckOut) {
    return 'Check-in recorded. Check out when your working day ends.';
  }
  return 'Today\'s attendance is complete.';
}

Color _recordColor(AttendanceRecordModel? record) =>
    _recordColorStatus(record?.status ?? AttendanceStatus.absent);

Color _recordColorStatus(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => const Color(0xFF10B979),
  AttendanceStatus.late => const Color(0xFFF29A14),
  AttendanceStatus.absent => const Color(0xFFFF5964),
};
