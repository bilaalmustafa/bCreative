import 'dart:ui' show PointerDeviceKind;

import 'package:bcreative_ems/app/routes/app_routes.dart';
import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/core/widgets/app_loading.dart';
import 'package:bcreative_ems/core/widgets/page_intro.dart';
import 'package:bcreative_ems/features/projects/models/project_model.dart';
import 'package:bcreative_ems/features/projects/viewmodels/employee_projects_controller.dart';
import 'package:bcreative_ems/features/shell/views/app_shell.dart';
import 'package:bcreative_ems/features/tasks/models/employee_task_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EmployeeProjectsView extends GetView<EmployeeProjectsController> {
  const EmployeeProjectsView({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'My Projects',
    body: Obx(
      () => controller.isLoading.value
          ? const AppLoading()
          : _EmployeeProjectsContent(controller: controller),
    ),
  );
}

class _EmployeeProjectsContent extends StatelessWidget {
  const _EmployeeProjectsContent({required this.controller});
  final EmployeeProjectsController controller;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(isMobile(context) ? 16 : 24),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _EmployeeProjectHeader(),
              const SizedBox(height: 18),
              _EmployeeProjectStats(controller: controller),
              const SizedBox(height: 14),
              _EmployeeProjectWorkspace(controller: controller),
            ],
          ),
        ),
      ),
    ],
  );
}

class _EmployeeProjectHeader extends StatelessWidget {
  const _EmployeeProjectHeader();

  @override
  Widget build(BuildContext context) => const PageIntro(
    icon: Icons.folder_copy_rounded,
    description: 'View your project schedule, team, and assigned tasks.',
  );
}

class _EmployeeProjectStats extends StatelessWidget {
  const _EmployeeProjectStats({required this.controller});
  final EmployeeProjectsController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Obx(() {
      final cards = [
        _EmployeeStat(
          icon: Icons.folder_open_rounded,
          label: 'Assigned Projects',
          value: '${controller.projects.length}',
          color: const Color(0xFF2468F2),
          background: const Color(0xFFE8F0FF),
        ),
        _EmployeeStat(
          icon: Icons.play_circle_outline_rounded,
          label: 'Active Projects',
          value: '${controller.activeProjectCount}',
          color: const Color(0xFF10B979),
          background: const Color(0xFFE0F9EE),
        ),
        _EmployeeStat(
          icon: Icons.task_alt_rounded,
          label: 'My Project Tasks',
          value: '${controller.myTaskCount}',
          color: const Color(0xFF9146F5),
          background: const Color(0xFFF1E6FF),
        ),
      ];
      if (constraints.maxWidth >= 780) {
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
          const SizedBox(height: 12),
          cards[1],
          const SizedBox(height: 12),
          cards[2],
        ],
      );
    }),
  );
}

class _EmployeeStat extends StatelessWidget {
  const _EmployeeStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => _EmployeeSurface(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          height: 47,
          width: 47,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 25),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF40567E),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                'Based on your assignment',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Color(0xFF7185A9)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmployeeProjectWorkspace extends StatelessWidget {
  const _EmployeeProjectWorkspace({required this.controller});
  final EmployeeProjectsController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final directory = _EmployeeSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EmployeeFilter(controller: controller, embedded: true),
            const Divider(height: 1, color: Color(0xFFE9EFF8)),
            _EmployeeDirectory(controller: controller, embedded: true),
          ],
        ),
      );
      final details = _EmployeeProjectDetails(controller: controller);
      if (constraints.maxWidth >= 900) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: directory),
            const SizedBox(width: 14),
            SizedBox(width: 340, child: details),
          ],
        );
      }
      return Column(children: [directory, const SizedBox(height: 14), details]);
    },
  );
}

class _EmployeeFilter extends StatelessWidget {
  const _EmployeeFilter({required this.controller, this.embedded = false});
  final EmployeeProjectsController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Obx(
      () => Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 270,
            height: 40,
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search projects, client, department...',
                hintStyle: const TextStyle(fontSize: 11),
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                filled: true,
                fillColor: const Color(0xFFF4F7FC),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDE6F4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDE6F4)),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            height: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDE6F4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ProjectStatus?>(
                  value: controller.statusFilter.value,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<ProjectStatus?>(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ...ProjectStatus.values.map(
                      (status) => DropdownMenuItem<ProjectStatus?>(
                        value: status,
                        child: Text(status.label),
                      ),
                    ),
                  ],
                  onChanged: (value) => controller.statusFilter.value = value,
                ),
              ),
            ),
          ),
          Tooltip(
            message: 'Reset filters',
            child: IconButton.outlined(
              onPressed: controller.resetFilters,
              icon: const Icon(Icons.refresh_rounded),
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

class _EmployeeDirectory extends StatelessWidget {
  const _EmployeeDirectory({required this.controller, this.embedded = false});
  final EmployeeProjectsController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Assigned Projects',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              if (MediaQuery.sizeOf(context).width < 900)
                const Text(
                  'Swipe table',
                  style: TextStyle(fontSize: 10, color: Color(0xFF60749A)),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Obx(() {
          final projects = controller.visibleProjects;
          if (projects.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(44),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 38,
                    color: Color(0xFF8799B9),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No assigned projects found.',
                    style: TextStyle(color: Color(0xFF60749A)),
                  ),
                ],
              ),
            );
          }
          return _EmployeeProjectsTable(
            controller: controller,
            projects: projects,
          );
        }),
      ],
    );
    return embedded
        ? content
        : _EmployeeSurface(padding: EdgeInsets.zero, child: content);
  }
}

class _EmployeeProjectsTable extends StatelessWidget {
  const _EmployeeProjectsTable({
    required this.controller,
    required this.projects,
  });
  final EmployeeProjectsController controller;
  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 760 ? 760.0 : constraints.maxWidth;
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.mouse,
          },
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                Container(
                  height: 38,
                  color: const Color(0xFFF5F8FD),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: const Row(
                    children: [
                      Expanded(flex: 34, child: _EmployeeTableLabel('PROJECT')),
                      Expanded(flex: 16, child: _EmployeeTableLabel('CLIENT')),
                      Expanded(
                        flex: 17,
                        child: _EmployeeTableLabel('DEPARTMENT'),
                      ),
                      Expanded(
                        flex: 20,
                        child: _EmployeeTableLabel('MY TASK PROGRESS'),
                      ),
                      Expanded(flex: 15, child: _EmployeeTableLabel('STATUS')),
                    ],
                  ),
                ),
                ...projects.map(
                  (project) => _EmployeeProjectRow(
                    controller: controller,
                    project: project,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _EmployeeTableLabel extends StatelessWidget {
  const _EmployeeTableLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 9,
      color: Color(0xFF50658B),
      fontWeight: FontWeight.w700,
    ),
  );
}

class _EmployeeProjectRow extends StatelessWidget {
  const _EmployeeProjectRow({required this.controller, required this.project});
  final EmployeeProjectsController controller;
  final ProjectModel project;

  @override
  Widget build(BuildContext context) => Obx(() {
    final selected = controller.selectedProjectId.value == project.id;
    final progress = controller.progressFor(project);
    final relatedTasks = controller.tasksFor(project);
    return InkWell(
      onTap: () => controller.selectProject(project),
      child: Container(
        height: 69,
        color: selected ? const Color(0xFFF4F8FF) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              flex: 34,
              child: Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: Color(0xFF2468F2),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          project.description.isEmpty
                              ? 'Assigned project'
                              : project.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF7185A8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 16,
              child: Text(
                project.client.isEmpty ? '—' : project.client,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF40567E)),
              ),
            ),
            Expanded(
              flex: 17,
              child: Text(
                project.department,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF40567E)),
              ),
            ),
            Expanded(
              flex: 20,
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5ECF7),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF2468F2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$progress% (${relatedTasks.length})',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 15,
              child: _EmployeeStatus(
                status: controller.effectiveStatus(project),
              ),
            ),
          ],
        ),
      ),
    );
  });
}

class _EmployeeStatus extends StatelessWidget {
  const _EmployeeStatus({required this.status});
  final ProjectStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ProjectStatus.inProgress => const Color(0xFFFF8A13),
      ProjectStatus.completed => const Color(0xFF10B979),
      ProjectStatus.onHold => const Color(0xFFE65050),
      ProjectStatus.cancelled => const Color(0xFF6E7180),
      ProjectStatus.notStarted => const Color(0xFF7185A8),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmployeeProjectDetails extends StatelessWidget {
  const _EmployeeProjectDetails({required this.controller});
  final EmployeeProjectsController controller;

  @override
  Widget build(BuildContext context) => _EmployeeSurface(
    padding: EdgeInsets.zero,
    child: Obx(() {
      final project = controller.selectedProject;
      if (project == null) {
        return const Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 34,
                color: Color(0xFF7185A8),
              ),
              SizedBox(height: 10),
              Text(
                'Select a project to view your tasks.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF60749A)),
              ),
            ],
          ),
        );
      }
      final tasks = controller.tasksFor(project);
      final completed = tasks
          .where((task) => task.status == EmployeeTaskStatus.completed)
          .length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Project Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => controller.selectedProjectId.value = null,
                  icon: const Icon(Icons.close_rounded, size: 19),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9EFF8)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (project.client.isNotEmpty)
                  Text(
                    project.client,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF60749A),
                    ),
                  ),
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    project.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF40567E),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                Text(
                  'My task progress: $completed of ${tasks.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: controller.progressFor(project) / 100,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE5ECF7),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF2468F2)),
                  ),
                ),
                const SizedBox(height: 16),
                _EmployeeProjectDetailLine(
                  icon: Icons.business_outlined,
                  label: 'Department',
                  value: project.department.isEmpty ? '—' : project.department,
                ),
                _EmployeeProjectDetailLine(
                  icon: Icons.flag_outlined,
                  label: 'Priority',
                  value: project.priority.label,
                ),
                _EmployeeProjectDetailLine(
                  icon: Icons.calendar_today_outlined,
                  label: 'Start date',
                  value: _employeeProjectDate(project.startDate),
                ),
                _EmployeeProjectDetailLine(
                  icon: Icons.event_outlined,
                  label: 'Deadline',
                  value: _employeeProjectDate(project.endDate),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Assigned Team',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (project.teamMembers.isEmpty)
                  const Text(
                    'No team members assigned.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF60749A)),
                  )
                else
                  ...project.teamMembers.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _EmployeeProjectTeamMember(member: member),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'My Tasks',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                if (tasks.isEmpty)
                  const Text(
                    'No tasks are assigned for this project yet.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF60749A)),
                  )
                else
                  ...tasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: _EmployeeTaskTile(task: task),
                    ),
                  ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.employeeTasks),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Open My Tasks'),
                ),
              ],
            ),
          ),
        ],
      );
    }),
  );
}

class _EmployeeProjectDetailLine extends StatelessWidget {
  const _EmployeeProjectDetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF60749A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF60749A)),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _EmployeeProjectTeamMember extends StatelessWidget {
  const _EmployeeProjectTeamMember({required this.member});

  final ProjectTeamMember member;

  @override
  Widget build(BuildContext context) {
    final photoUrl = member.profilePhotoUrl;
    final role = member.jobTitle?.trim().isNotEmpty == true
        ? member.jobTitle!
        : member.department?.trim().isNotEmpty == true
        ? member.department!
        : 'Employee';
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: const Color(0xFFE8F0FF),
          foregroundImage: photoUrl?.isNotEmpty == true
              ? NetworkImage(photoUrl!)
              : null,
          child: Text(
            _employeeInitials(member.name),
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF2468F2),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF7185A8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmployeeTaskTile extends StatelessWidget {
  const _EmployeeTaskTile({required this.task});
  final EmployeeTaskModel task;
  @override
  Widget build(BuildContext context) {
    final color = switch (task.status) {
      EmployeeTaskStatus.assigned => const Color(0xFF2468F2),
      EmployeeTaskStatus.inProgress => const Color(0xFFFF8A13),
      EmployeeTaskStatus.completed => const Color(0xFF10B979),
    };
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            task.status == EmployeeTaskStatus.completed
                ? Icons.task_alt_rounded
                : Icons.assignment_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (task.dueDate != null)
                  Text(
                    'Due ${DateFormat('dd MMM').format(task.dueDate!)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7185A8),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            task.status.label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _employeeProjectDate(DateTime? date) =>
    date == null ? '—' : DateFormat('dd MMM yyyy').format(date);

String _employeeInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  final initials = words.take(2).map((word) => word[0].toUpperCase()).join();
  return initials.isEmpty ? '?' : initials;
}

class _EmployeeSurface extends StatelessWidget {
  const _EmployeeSurface({required this.child, required this.padding});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8EEF8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F2D66),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}
