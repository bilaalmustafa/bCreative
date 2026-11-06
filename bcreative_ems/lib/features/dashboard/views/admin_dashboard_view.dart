import 'dart:math' as math;

import 'package:bcreative_ems/app/routes/app_routes.dart';
import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/core/widgets/app_loading.dart';
import 'package:bcreative_ems/core/widgets/header_action_layout.dart';
import 'package:bcreative_ems/core/widgets/page_intro.dart';
import 'package:bcreative_ems/features/dashboard/viewmodels/dashboard_controller.dart';
import 'package:bcreative_ems/features/projects/models/project_model.dart';
import 'package:bcreative_ems/features/shell/views/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminDashboardView extends GetView<DashboardController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Dashboard',
    body: Obx(() {
      if (controller.isLoading.value) return const AppLoading();
      return _DashboardContent(controller: controller);
    }),
  );
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final range = controller.selectedRange.value;
    final loadError = controller.errorMessage.value;
    final attendance = controller.attendanceSummary;
    final taskStatus = controller.taskStatus;
    final statCards = <Widget>[
      _StatCard(
        icon: Icons.groups_rounded,
        iconColor: const Color(0xFF2168F3),
        iconBackground: const Color(0xFFE8F0FF),
        label: 'Total Employees',
        value: '${controller.totalEmployees}',
        detail: '${controller.eligibleEmployeeCount} active employees',
      ),
      _StatCard(
        icon: Icons.fact_check_rounded,
        iconColor: const Color(0xFF13B978),
        iconBackground: const Color(0xFFE1F9EE),
        label: 'Today Attendance',
        value:
            '${controller.checkedInToday} / ${controller.eligibleEmployeeCount}',
        detail: _percentLabel(
          controller.checkedInToday,
          controller.eligibleEmployeeCount,
        ),
      ),
      _StatCard(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFFFFA400),
        iconBackground: const Color(0xFFFFF1D9),
        label: 'Total Payroll',
        value: _currency(controller.selectedMonthPayroll),
        detail: DateFormat('MMMM yyyy').format(range.start),
        compactValue: true,
      ),
      _StatCard(
        icon: Icons.folder_copy_rounded,
        iconColor: const Color(0xFF8C36F2),
        iconBackground: const Color(0xFFF0E8FF),
        label: 'Active Projects',
        value: '${controller.activeProjects}',
        detail: 'Projects in progress',
      ),
      _StatCard(
        icon: Icons.task_alt_rounded,
        iconColor: const Color(0xFFFF514A),
        iconBackground: const Color(0xFFFFE9E8),
        label: 'Total Tasks',
        value: '${controller.totalTasks}',
        detail: '${taskStatus.completed} completed',
      ),
    ];

    return ListView(
      padding: EdgeInsets.all(isMobile(context) ? 16 : 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  range: range,
                  onChooseRange: () => _chooseRange(context, range),
                ),
                if (loadError != null) ...[
                  const SizedBox(height: 14),
                  _DataWarning(message: loadError),
                ],
                const SizedBox(height: 20),
                _StatsLayout(cards: statCards),
                const SizedBox(height: 16),
                _TopSection(
                  projectItems: controller.projectProgress,
                  taskStatus: taskStatus,
                ),
                const SizedBox(height: 16),
                _BottomSection(
                  attendance: attendance,
                  range: range,
                  projectCounts: _ProjectCounts(
                    inProgress: controller.projectStatusCount(
                      ProjectStatus.inProgress,
                    ),
                    completed: controller.projectStatusCount(
                      ProjectStatus.completed,
                    ),
                    onHold: controller.projectStatusCount(ProjectStatus.onHold),
                    cancelled: controller.projectStatusCount(
                      ProjectStatus.cancelled,
                    ),
                  ),
                  trend: controller.attendanceTrend,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  });

  Future<void> _chooseRange(BuildContext context, DateTimeRange current) async {
    final screenSize = MediaQuery.sizeOf(context);
    // Flutter's calendar range picker defaults to a full-screen surface.
    // Supply a smaller local MediaQuery so the original one-calendar range UI
    // is rendered as a centered dashboard dialog instead.
    final pickerSize = Size(
      math.min(780, math.max(1, screenSize.width - 56)),
      math.min(680, math.max(1, screenSize.height - 72)),
    );
    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (dialogContext) => MediaQuery(
        data: MediaQuery.of(dialogContext).copyWith(size: pickerSize),
        child: DateRangePickerDialog(
          initialDateRange: current,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          helpText: 'Select dashboard date range',
          saveText: 'Save',
          cancelText: 'Cancel',
        ),
      ),
    );
    if (result != null) controller.setDateRange(result);
  }
}

class _DashboardDateRangeDialog extends StatefulWidget {
  const _DashboardDateRangeDialog({required this.initialRange});

  final DateTimeRange initialRange;

  @override
  State<_DashboardDateRangeDialog> createState() =>
      _DashboardDateRangeDialogState();
}

class _DashboardDateRangeDialogState extends State<_DashboardDateRangeDialog> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = DateUtils.dateOnly(widget.initialRange.start);
    _end = DateUtils.dateOnly(widget.initialRange.end);
  }

  void _setStart(DateTime value) {
    setState(() {
      _start = DateUtils.dateOnly(value);
      if (_end.isBefore(_start)) _end = _start;
    });
  }

  void _setEnd(DateTime value) {
    setState(() {
      _end = DateUtils.dateOnly(value);
      if (_end.isBefore(_start)) _start = _end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maximumHeight = MediaQuery.sizeOf(context).height - 48;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800, maxHeight: maximumHeight),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.date_range_rounded,
                      color: Color(0xFF2168F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select dashboard date range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SelectedRangeSummary(start: _start, end: _end),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 690;
                      final calendarWidth = wide
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: calendarWidth,
                            child: _RangeCalendar(
                              key: ValueKey('start-$_start'),
                              title: 'Start date',
                              selectedDate: _start,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              onDateChanged: _setStart,
                            ),
                          ),
                          SizedBox(
                            width: calendarWidth,
                            child: _RangeCalendar(
                              key: ValueKey('end-$_end-$_start'),
                              title: 'End date',
                              selectedDate: _end,
                              firstDate: _start,
                              lastDate: DateTime(2100),
                              onDateChanged: _setEnd,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(94, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .pop(DateTimeRange(start: _start, end: _end)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(94, 44),
                      backgroundColor: const Color(0xFF2168F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedRangeSummary extends StatelessWidget {
  const _SelectedRangeSummary({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F7FD),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFDCE6F8)),
    ),
    child: Row(
      children: [
        const Icon(Icons.event_rounded, color: Color(0xFF2168F3), size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '${DateFormat('d MMM y').format(start)} – '
            '${DateFormat('d MMM y').format(end)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF233D70),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RangeCalendar extends StatelessWidget {
  const _RangeCalendar({
    super.key,
    required this.title,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  final String title;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE0E8F6)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF314D7D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        CalendarDatePicker(
          initialDate: selectedDate,
          firstDate: firstDate,
          lastDate: lastDate,
          onDateChanged: onDateChanged,
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.range, required this.onChooseRange});

  final DateTimeRange range;
  final VoidCallback onChooseRange;

  @override
  Widget build(BuildContext context) => HeaderActionLayout(
    heading: const PageIntro(
      icon: Icons.analytics_rounded,
      description:
          'Key insights of your employees, attendance, projects and tasks.',
      iconColor: Colors.white,
      backgroundColor: Color(0xFF2168F3),
      boxSize: 48,
      borderRadius: 13,
    ),
    action: OutlinedButton.icon(
      onPressed: onChooseRange,
      icon: const Icon(Icons.calendar_month_rounded, size: 19),
      label: Text(
        '${DateFormat('d MMM y').format(range.start)} – '
        '${DateFormat('d MMM y').format(range.end)}',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF213D72),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        side: const BorderSide(color: Color(0xFFD4E1F8)),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    required this.detail,
    this.compactValue = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final String detail;
  final bool compactValue;

  @override
  Widget build(BuildContext context) => _Panel(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        final iconSize = compact ? 42.0 : 56.0;
        return Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(compact ? 13 : 17),
              ),
              child: Icon(icon, color: iconColor, size: compact ? 23 : 29),
            ),
            SizedBox(width: compact ? 8 : 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _labelStyle.copyWith(fontSize: compact ? 10 : 12),
                  ),
                  SizedBox(height: compact ? 3 : 4),
                  Expanded(
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: compactValue ? 20 : 26,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 3 : 6),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF6077A2),
                      fontSize: compact ? 9 : 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _StatsLayout extends StatelessWidget {
  const _StatsLayout({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 960) {
        return SizedBox(
          height: 124,
          child: Row(
            children: List.generate(
              cards.length,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 14),
                  child: cards[index],
                ),
              ),
            ),
          ),
        );
      }
      final columns = constraints.maxWidth >= 520 ? 2 : 1;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: columns == 1 ? 3.1 : 1.9,
        children: cards,
      );
    },
  );
}

class _TopSection extends StatelessWidget {
  const _TopSection({required this.projectItems, required this.taskStatus});

  final List<ProjectProgressItem> projectItems;
  final TaskStatusSummary taskStatus;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final projects = _ProjectProgressPanel(items: projectItems);
      final tasks = _TaskStatusPanel(summary: taskStatus);
      if (constraints.maxWidth < 1020) {
        return Column(children: [projects, const SizedBox(height: 16), tasks]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: projects),
          const SizedBox(width: 16),
          Expanded(flex: 4, child: tasks),
        ],
      );
    },
  );
}

class _ProjectProgressPanel extends StatelessWidget {
  const _ProjectProgressPanel({required this.items});

  final List<ProjectProgressItem> items;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _PanelTitle('Project Progress')),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.adminProjects),
              child: const Text('View All Projects'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          const _EmptyPanel(
            icon: Icons.folder_off_outlined,
            message: 'No projects found yet.',
          )
        else ...[
          const _ProjectTableHeader(),
          ...items.take(5).map((item) => _ProjectProgressRow(item: item)),
        ],
      ],
    ),
  );
}

class _ProjectTableHeader extends StatelessWidget {
  const _ProjectTableHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F7FD),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Row(
      children: [
        Expanded(flex: 4, child: Text('Project', style: _tableHeaderStyle)),
        Expanded(flex: 3, child: Text('Progress', style: _tableHeaderStyle)),
        Expanded(flex: 2, child: Text('Tasks', style: _tableHeaderStyle)),
        Expanded(flex: 2, child: Text('Due Date', style: _tableHeaderStyle)),
      ],
    ),
  );
}

class _ProjectProgressRow extends StatelessWidget {
  const _ProjectProgressRow({required this.item});

  final ProjectProgressItem item;

  @override
  Widget build(BuildContext context) {
    final project = item.project;
    final endDate = project.endDate;
    final progress = item.progress;
    final color = progress >= 1
        ? const Color(0xFF13BA78)
        : const Color(0xFF2468F2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEF2F8))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.folder_rounded, size: 19, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project.name.isEmpty ? 'Untitled project' : project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                      color: color,
                      backgroundColor: const Color(0xFFE5ECF8),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.completedTasks} / ${item.totalTasks}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              endDate == null ? '—' : DateFormat('d MMM y').format(endDate),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Color(0xFF48618D)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskStatusPanel extends StatelessWidget {
  const _TaskStatusPanel({required this.summary});

  final TaskStatusSummary summary;

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF15B978),
      Color(0xFF2468F2),
      Color(0xFFFFB21A),
      Color(0xFFFF4D45),
    ];
    final values = [
      summary.completed,
      summary.inProgress,
      summary.pending,
      summary.overdue,
    ];
    const labels = ['Completed', 'In Progress', 'Pending', 'Overdue'];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle('Task Status'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final donut = SizedBox(
                height: 148,
                width: 148,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(148),
                      painter: _DonutPainter(values: values, colors: colors),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${summary.total}',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Tasks',
                          style: TextStyle(color: Color(0xFF667B9F)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
              final legend = Column(
                children: List.generate(values.length, (index) {
                  final count = values[index];
                  final percentage = summary.total == 0
                      ? 0
                      : count * 100 / summary.total;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          height: 11,
                          width: 11,
                          decoration: BoxDecoration(
                            color: colors[index],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            labels[index],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          '$count (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
              if (constraints.maxWidth < 390) {
                return Column(
                  children: [donut, const SizedBox(height: 9), legend],
                );
              }
              return Row(
                children: [
                  donut,
                  const SizedBox(width: 14),
                  Expanded(child: legend),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BottomSection extends StatelessWidget {
  const _BottomSection({
    required this.attendance,
    required this.range,
    required this.projectCounts,
    required this.trend,
  });

  final AttendanceSummary attendance;
  final DateTimeRange range;
  final _ProjectCounts projectCounts;
  final List<AttendanceTrendPoint> trend;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 860) {
        final summary = _AttendanceSummaryPanel(
          attendance: attendance,
          range: range,
        );
        final projectStatus = _ProjectStatusPanel(counts: projectCounts);
        final attendanceTrend = _AttendanceTrendPanel(trend: trend);
        return Column(
          children: [
            summary,
            const SizedBox(height: 16),
            projectStatus,
            const SizedBox(height: 16),
            attendanceTrend,
          ],
        );
      }
      final summary = _AttendanceSummaryPanel(
        attendance: attendance,
        range: range,
        centerContent: true,
      );
      final projectStatus = _ProjectStatusPanel(counts: projectCounts);
      final attendanceTrend = _AttendanceTrendPanel(trend: trend);
      // IntrinsicHeight asks every dashboard card for an intrinsic size. Some
      // chart/progress descendants cannot provide that during a web pointer
      // update, which can leave a render box without a size. A fixed desktop
      // row height keeps the three panels aligned without that extra layout
      // pass. Smaller screens still use the naturally-sized stacked layout.
      return SizedBox(
        height: 310,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 4, child: summary),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: projectStatus),
            const SizedBox(width: 16),
            Expanded(flex: 4, child: attendanceTrend),
          ],
        ),
      );
    },
  );
}

class _AttendanceSummaryPanel extends StatelessWidget {
  const _AttendanceSummaryPanel({
    required this.attendance,
    required this.range,
    this.centerContent = false,
  });

  final AttendanceSummary attendance;
  final DateTimeRange range;
  final bool centerContent;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _PanelTitle('Attendance Summary')),
            Text(
              DateFormat('MMM yyyy').format(range.start),
              style: const TextStyle(
                color: Color(0xFF5070A7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (centerContent)
          Expanded(
            child: Center(
              child: _AttendanceSummaryContent(attendance: attendance),
            ),
          )
        else
          _AttendanceSummaryContent(attendance: attendance),
      ],
    ),
  );
}

class _AttendanceSummaryContent extends StatelessWidget {
  const _AttendanceSummaryContent({required this.attendance});

  final AttendanceSummary attendance;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final ring = SizedBox(
        width: 126,
        height: 126,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(126),
              painter: _PercentageRingPainter(
                value: attendance.percentage / 100,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${attendance.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Attendance',
                  style: TextStyle(fontSize: 11, color: Color(0xFF617698)),
                ),
              ],
            ),
          ],
        ),
      );
      final list = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AttendanceCount(
            'Present',
            attendance.present,
            Icons.check_circle_rounded,
            const Color(0xFF13BA78),
          ),
          _AttendanceCount(
            'Late',
            attendance.late,
            Icons.schedule_rounded,
            const Color(0xFFFFAD19),
          ),
          _AttendanceCount(
            'Absent',
            attendance.absent,
            Icons.cancel_rounded,
            const Color(0xFFFF4D45),
          ),
        ],
      );
      if (constraints.maxWidth < 350) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [ring, const SizedBox(height: 12), list],
          ),
        );
      }
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ring,
            const SizedBox(width: 16),
            SizedBox(width: 150, child: list),
          ],
        ),
      );
    },
  );
}

class _AttendanceCount extends StatelessWidget {
  const _AttendanceCount(this.label, this.count, this.icon, this.color);

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFEDF1F7))),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _ProjectCounts {
  const _ProjectCounts({
    required this.inProgress,
    required this.completed,
    required this.onHold,
    required this.cancelled,
  });

  final int inProgress;
  final int completed;
  final int onHold;
  final int cancelled;
}

class _ProjectStatusPanel extends StatelessWidget {
  const _ProjectStatusPanel({required this.counts});

  final _ProjectCounts counts;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle('Project Status'),
        const SizedBox(height: 10),
        Column(
          children: [
            _ProjectStatusCard(
              'In Progress',
              counts.inProgress,
              Icons.play_circle_rounded,
              const Color(0xFF12B878),
            ),
            const SizedBox(height: 7),
            _ProjectStatusCard(
              'Completed',
              counts.completed,
              Icons.check_circle_rounded,
              const Color(0xFF8B3DF3),
            ),
            const SizedBox(height: 7),
            _ProjectStatusCard(
              'On Hold',
              counts.onHold,
              Icons.pause_circle_rounded,
              const Color(0xFFFFA719),
            ),
            const SizedBox(height: 7),
            _ProjectStatusCard(
              'Cancelled',
              counts.cancelled,
              Icons.cancel_rounded,
              const Color(0xFFFF4E4A),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProjectStatusCard extends StatelessWidget {
  const _ProjectStatusCard(this.label, this.count, this.icon, this.color);

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    width: double.infinity,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7EDF7)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF506A97),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _AttendanceTrendPanel extends StatelessWidget {
  const _AttendanceTrendPanel({required this.trend});

  final List<AttendanceTrendPoint> trend;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(child: _PanelTitle('Attendance Trend')),
            Text(
              'Last 7 days',
              style: TextStyle(
                color: Color(0xFF5070A7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (trend.isEmpty)
          const _EmptyPanel(
            icon: Icons.bar_chart_rounded,
            message: 'No attendance records yet.',
          )
        else
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend
                  .map((item) => Expanded(child: _TrendBar(item: item)))
                  .toList(),
            ),
          ),
      ],
    ),
  );
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({required this.item});

  final AttendanceTrendPoint item;

  @override
  Widget build(BuildContext context) {
    final percent = item.percentage.clamp(0, 100).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${percent.round()}%',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Container(
              width: math.min(31, constraints.maxWidth),
              height: 100 * percent / 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4E8CFF), Color(0xFF2468F2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              DateFormat('EEE').format(item.date),
              style: const TextStyle(fontSize: 11, color: Color(0xFF3E5783)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values, required this.colors});

  final List<int> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (sum, value) => sum + value);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.butt;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.width - 26) / 2,
    );
    if (total == 0) {
      paint.color = const Color(0xFFE8EEF7);
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      return;
    }
    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweep = values[index] / total * math.pi * 2;
      if (sweep > 0) {
        paint.color = colors[index];
        canvas.drawArc(rect, start, math.max(0, sweep - .035), false, paint);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

class _PercentageRingPainter extends CustomPainter {
  const _PercentageRingPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.width - 13) / 2,
    );
    paint.color = const Color(0xFFE4F4EC);
    canvas.drawArc(rect, 0, math.pi * 2, false, paint);
    paint.color = const Color(0xFF13B978);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PercentageRingPainter oldDelegate) =>
      oldDelegate.value != value;
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE7EDF7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A1B3D70),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Center(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8AA0C7), size: 32),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Color(0xFF6B7F9F))),
        ],
      ),
    ),
  );
}

class _DataWarning extends StatelessWidget {
  const _DataWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4DD),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFFD88C)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFFAD7000)),
        const SizedBox(width: 9),
        Expanded(
          child: Text('Some live dashboard data is unavailable: $message'),
        ),
      ],
    ),
  );
}

const _labelStyle = TextStyle(
  fontSize: 12,
  color: Color(0xFF344C78),
  fontWeight: FontWeight.w600,
);
const _tableHeaderStyle = TextStyle(
  fontSize: 10,
  color: Color(0xFF405A89),
  fontWeight: FontWeight.w700,
);

String _currency(double value) =>
    'SAR ${NumberFormat.decimalPattern().format(value.round())}';
String _percentLabel(int numerator, int denominator) => denominator == 0
    ? 'No active employees'
    : '${(numerator * 100 / denominator).toStringAsFixed(1)}% checked in';
