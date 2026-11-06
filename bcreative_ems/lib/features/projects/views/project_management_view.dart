import 'dart:ui' show PointerDeviceKind;

import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/core/widgets/app_loading.dart';
import 'package:bcreative_ems/core/widgets/header_action_layout.dart';
import 'package:bcreative_ems/core/widgets/page_intro.dart';
import 'package:bcreative_ems/features/projects/models/project_model.dart';
import 'package:bcreative_ems/features/projects/viewmodels/project_controller.dart';
import 'package:bcreative_ems/features/shell/views/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProjectManagementView extends GetView<ProjectController> {
  const ProjectManagementView({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Projects',
    body: Obx(
      () => controller.isLoading.value
          ? const AppLoading()
          : _ProjectContent(controller: controller),
    ),
  );
}

class _ProjectContent extends StatelessWidget {
  const _ProjectContent({required this.controller});

  final ProjectController controller;

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return ListView(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProjectHeader(controller: controller),
                const SizedBox(height: 18),
                _ProjectStats(controller: controller),
                const SizedBox(height: 14),
                _ProjectsWorkspace(controller: controller),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.controller});

  final ProjectController controller;

  @override
  Widget build(BuildContext context) => HeaderActionLayout(
    heading: const PageIntro(
      icon: Icons.folder_copy_rounded,
      description:
          'Create projects, assign team members, and track task progress.',
    ),
    action: FilledButton.icon(
      onPressed: controller.openCreateProject,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        backgroundColor: const Color(0xFF2468F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Create Project'),
    ),
  );
}

class _ProjectStats extends StatelessWidget {
  const _ProjectStats({required this.controller});

  final ProjectController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Obx(() {
      final cards = [
        _ProjectStatCard(
          icon: Icons.folder_open_rounded,
          label: 'Total Projects',
          value: '${controller.totalProjects}',
          caption: 'All projects',
          color: const Color(0xFF2E6CF6),
          background: const Color(0xFFE8F0FF),
        ),
        _ProjectStatCard(
          icon: Icons.play_circle_outline_rounded,
          label: 'Active Projects',
          value: '${controller.activeProjects}',
          caption: 'In progress or starting',
          color: const Color(0xFF11B979),
          background: const Color(0xFFE0F9EE),
        ),
        _ProjectStatCard(
          icon: Icons.task_alt_rounded,
          label: 'Completed Projects',
          value: '${controller.completedProjects}',
          caption: 'Tasks fully completed',
          color: const Color(0xFF9146F5),
          background: const Color(0xFFF1E6FF),
        ),
        _ProjectStatCard(
          icon: Icons.pause_circle_outline_rounded,
          label: 'On Hold Projects',
          value: '${controller.onHoldProjects}',
          caption: 'Currently paused',
          color: const Color(0xFFFF8616),
          background: const Color(0xFFFFECDC),
        ),
      ];
      if (constraints.maxWidth >= 940) {
        return Row(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index < cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      }
      return GridView.count(
        crossAxisCount: constraints.maxWidth >= 620 ? 2 : 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: constraints.maxWidth >= 620 ? 2.9 : 3.7,
        children: cards,
      );
    }),
  );
}

class _ProjectStatCard extends StatelessWidget {
  const _ProjectStatCard({
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
  Widget build(BuildContext context) => _ProjectSurface(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 25),
        ),
        const SizedBox(width: 11),
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
                  color: Color(0xFF40567E),
                  fontSize: 11,
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

class _ProjectsWorkspace extends StatelessWidget {
  const _ProjectsWorkspace({required this.controller});

  final ProjectController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final directory = _ProjectSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProjectFilterBar(controller: controller, embedded: true),
            const Divider(height: 1, color: Color(0xFFE9EFF8)),
            _ProjectDirectory(controller: controller, embedded: true),
          ],
        ),
      );
      final sidePanel = _ProjectSidePanel(controller: controller);
      if (constraints.maxWidth >= 1020) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: directory),
            const SizedBox(width: 14),
            SizedBox(width: 355, child: sidePanel),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [directory, const SizedBox(height: 14), sidePanel],
      );
    },
  );
}

class _ProjectFilterBar extends StatelessWidget {
  const _ProjectFilterBar({required this.controller, this.embedded = false});

  final ProjectController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Obx(
      () => Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Search projects', style: _fieldLabel),
                const SizedBox(height: 5),
                SizedBox(
                  height: 39,
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: controller.setQuery,
                    style: const TextStyle(fontSize: 12),
                    decoration: _searchDecoration(
                      'Name, client, department...',
                    ),
                  ),
                ),
              ],
            ),
          ),
          _FilterDropdown<String>(
            label: 'Department',
            width: 145,
            value: controller.departmentFilter.value,
            allLabel: 'All Departments',
            values: controller.departments,
            onChanged: controller.setDepartmentFilter,
          ),
          _FilterDropdown<ProjectStatus>(
            label: 'Status',
            width: 134,
            value: controller.statusFilter.value,
            allLabel: 'All Statuses',
            values: ProjectStatus.values,
            labelFor: (value) => value.label,
            onChanged: controller.setStatusFilter,
          ),
          _FilterDropdown<ProjectPriority>(
            label: 'Priority',
            width: 125,
            value: controller.priorityFilter.value,
            allLabel: 'All Priorities',
            values: ProjectPriority.values,
            labelFor: (value) => value.label,
            onChanged: controller.setPriorityFilter,
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
    return _ProjectSurface(padding: const EdgeInsets.all(12), child: content);
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.width,
    required this.value,
    required this.allLabel,
    required this.values,
    required this.onChanged,
    this.labelFor,
  });

  final String label;
  final double width;
  final T? value;
  final String allLabel;
  final List<T> values;
  final String Function(T value)? labelFor;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _fieldLabel),
        const SizedBox(height: 5),
        Container(
          height: 39,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: _fieldDecoration,
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
                    child: Text(labelFor?.call(item) ?? item.toString()),
                  ),
                ),
              ],
              onChanged: onChanged,
              style: const TextStyle(color: Color(0xFF263B62), fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProjectDirectory extends StatelessWidget {
  const _ProjectDirectory({required this.controller, this.embedded = false});

  final ProjectController controller;
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
                  'Projects',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              if (MediaQuery.sizeOf(context).width < 1020)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swipe_rounded,
                      size: 16,
                      color: Color(0xFF60749A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Swipe table',
                      style: TextStyle(fontSize: 10, color: Color(0xFF60749A)),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Obx(() {
          final visible = controller.filteredProjects;
          if (visible.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(42),
              child: Column(
                children: [
                  const Icon(
                    Icons.folder_open_outlined,
                    size: 38,
                    color: Color(0xFF8799B9),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.projects.isEmpty
                        ? 'No projects created yet.'
                        : 'No projects match the selected filters.',
                    style: const TextStyle(color: Color(0xFF60749A)),
                  ),
                  if (controller.projects.isEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: controller.openCreateProject,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create first project'),
                    ),
                  ],
                ],
              ),
            );
          }
          return _ProjectsTable(controller: controller, projects: visible);
        }),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Obx(
          () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Showing ${controller.filteredProjects.length} of ${controller.totalProjects} projects',
                style: const TextStyle(fontSize: 11, color: Color(0xFF60749A)),
              ),
            ),
          ),
        ),
      ],
    );
    return embedded
        ? content
        : _ProjectSurface(padding: EdgeInsets.zero, child: content);
  }
}

class _ProjectsTable extends StatelessWidget {
  const _ProjectsTable({required this.controller, required this.projects});

  final ProjectController controller;
  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : 1100.0;
      final width = available < 1110 ? 1110.0 : available;
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.mouse,
          },
        ),
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            primary: false,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  const _ProjectTableHeader(),
                  ...projects.map(
                    (project) => _ProjectTableRow(
                      controller: controller,
                      project: project,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ProjectTableHeader extends StatelessWidget {
  const _ProjectTableHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    color: const Color(0xFFF5F8FD),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: const Row(
      children: [
        Expanded(flex: 28, child: _TableLabel('PROJECT')),
        Expanded(flex: 15, child: _TableLabel('CLIENT')),
        Expanded(flex: 15, child: _TableLabel('DEPARTMENT')),
        Expanded(flex: 15, child: _TableLabel('TEAM')),
        Expanded(flex: 13, child: _TableLabel('START DATE')),
        Expanded(flex: 13, child: _TableLabel('END DATE')),
        Expanded(flex: 19, child: _TableLabel('PROGRESS')),
        Expanded(flex: 14, child: _TableLabel('STATUS')),
        Expanded(flex: 9, child: _TableLabel('ACTIONS')),
      ],
    ),
  );
}

class _TableLabel extends StatelessWidget {
  const _TableLabel(this.label);
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

class _ProjectTableRow extends StatelessWidget {
  const _ProjectTableRow({required this.controller, required this.project});

  final ProjectController controller;
  final ProjectModel project;

  @override
  Widget build(BuildContext context) => Obx(() {
    final selected = controller.selectedProjectId.value == project.id;
    final progress = controller.progressFor(project);
    final status = controller.effectiveStatus(project);
    final profilePhotoUrls = <String, String?>{
      for (final employee in controller.employees)
        employee.id: employee.displayPhotoUrl,
    };
    return InkWell(
      onTap: () => controller.selectProject(project),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: selected ? const Color(0xFFF4F8FF) : null,
        child: Row(
          children: [
            Expanded(flex: 28, child: _ProjectNameCell(project: project)),
            Expanded(
              flex: 15,
              child: _TableValue(project.client.isEmpty ? '—' : project.client),
            ),
            Expanded(
              flex: 15,
              child: _DepartmentTag(value: project.department),
            ),
            Expanded(
              flex: 15,
              child: _TeamAvatars(
                members: project.teamMembers,
                profilePhotoUrls: profilePhotoUrls,
              ),
            ),
            Expanded(
              flex: 13,
              child: _TableValue(_formatDate(project.startDate)),
            ),
            Expanded(
              flex: 13,
              child: _TableValue(_formatDate(project.endDate)),
            ),
            Expanded(flex: 19, child: _ProjectProgress(progress: progress)),
            Expanded(
              flex: 14,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusChip(status: status),
              ),
            ),
            Expanded(
              flex: 9,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'View project',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.selectProject(project),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Edit project',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.openEditProject(project),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
}

class _ProjectNameCell extends StatelessWidget {
  const _ProjectNameCell({required this.project});
  final ProjectModel project;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: _priorityColor(project.priority).withValues(alpha: .14),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          Icons.folder_rounded,
          size: 19,
          color: _priorityColor(project.priority),
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            if (project.description.isNotEmpty)
              Text(
                project.description,
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

class _TableValue extends StatelessWidget {
  const _TableValue(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(fontSize: 11, color: Color(0xFF40567E)),
  );
}

class _DepartmentTag extends StatelessWidget {
  const _DepartmentTag({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.isEmpty ? '—' : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF2468F2),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _TeamAvatars extends StatelessWidget {
  const _TeamAvatars({required this.members, required this.profilePhotoUrls});
  final List<ProjectTeamMember> members;
  final Map<String, String?> profilePhotoUrls;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Text(
        'No members',
        style: TextStyle(fontSize: 10, color: Color(0xFF7185A8)),
      );
    }
    final visible = members.take(3).toList();
    return Row(
      children: [
        ...visible.map((member) {
          final photoUrl =
              profilePhotoUrls[member.employeeId] ?? member.profilePhotoUrl;
          return Align(
            widthFactor: .72,
            child: Tooltip(
              message: member.name,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFE3ECFF),
                foregroundImage: photoUrl?.isNotEmpty == true
                    ? NetworkImage(photoUrl!)
                    : null,
                child: Text(
                  _initials(member.name),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF2468F2),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }),
        if (members.length > visible.length) ...[
          const SizedBox(width: 6),
          Text(
            '+${members.length - visible.length}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}

class _ProjectProgress extends StatelessWidget {
  const _ProjectProgress({required this.progress});
  final int progress;

  @override
  Widget build(BuildContext context) {
    final color = progress == 100
        ? const Color(0xFF10B979)
        : const Color(0xFF2468F2);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5ECF7),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '$progress%',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
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
    );
  }
}

class _ProjectSidePanel extends StatelessWidget {
  const _ProjectSidePanel({required this.controller});
  final ProjectController controller;

  @override
  Widget build(BuildContext context) => _ProjectSurface(
    padding: EdgeInsets.zero,
    child: Obx(() {
      if (controller.isEditorOpen.value) {
        return _ProjectEditor(controller: controller);
      }
      if (controller.selectedProjectId.value == null) {
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
                'Select a project to view its details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF60749A)),
              ),
            ],
          ),
        );
      }
      return _ProjectDetails(controller: controller);
    }),
  );
}

class _ProjectDetails extends StatelessWidget {
  const _ProjectDetails({required this.controller});
  final ProjectController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final project = controller.selectedProject;
    if (project == null) return const SizedBox.shrink();
    final projectTasks = controller.tasksFor(project);
    final completed = controller.completedTaskCountFor(project);
    final progress = controller.progressFor(project);
    final employeePhotoUrls = <String, String?>{
      for (final employee in controller.employees)
        employee.id: employee.displayPhotoUrl,
    };
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
                tooltip: 'Edit project',
                onPressed: () => controller.openEditProject(project),
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              IconButton(
                tooltip: 'Close details',
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: _priorityColor(project.priority)
                          .withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      color: _priorityColor(project.priority),
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
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
                        const SizedBox(height: 6),
                        _StatusChip(
                          status: controller.effectiveStatus(project),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  project.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF40567E),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _ProjectProgress(progress: progress),
              const SizedBox(height: 5),
              Text(
                '$completed of ${projectTasks.length} assigned tasks completed',
                style: const TextStyle(fontSize: 10, color: Color(0xFF60749A)),
              ),
              const SizedBox(height: 16),
              _DetailLine(
                icon: Icons.business_outlined,
                label: 'Department',
                value: project.department.isEmpty ? '—' : project.department,
              ),
              _DetailLine(
                icon: Icons.flag_outlined,
                label: 'Priority',
                value: project.priority.label,
              ),
              _DetailLine(
                icon: Icons.calendar_today_outlined,
                label: 'Start date',
                value: _formatDate(project.startDate),
              ),
              _DetailLine(
                icon: Icons.event_outlined,
                label: 'End date',
                value: _formatDate(project.endDate),
              ),
              const SizedBox(height: 15),
              const Text(
                'Assigned Team',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) {
                            final photoUrl =
                                employeePhotoUrls[member.employeeId] ??
                                member.profilePhotoUrl;
                            return CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFFE8F0FF),
                              foregroundImage: photoUrl?.isNotEmpty == true
                                  ? NetworkImage(photoUrl!)
                                  : null,
                              child: Text(
                                _initials(member.name),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF2468F2),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                member.jobTitle ??
                                    member.department ??
                                    'Employee',
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
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => controller.removeProject(project),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE64242),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete Project'),
              ),
            ],
          ),
        ),
      ],
    );
  });
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF60749A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF60749A)),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _ProjectEditor extends StatelessWidget {
  const _ProjectEditor({required this.controller});
  final ProjectController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final editing = controller.editingProjectId.value != null;
    final departmentOptions = <String>{
      'IT & Development',
      'Design',
      'HR',
      'Finance',
      'Operations',
      'Marketing',
      ...controller.departments,
    }.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  editing ? 'Edit Project' : 'Create New Project',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.closeEditor,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Basic Information',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.projectNameController,
                decoration: const InputDecoration(labelText: 'Project name *'),
              ),
              const SizedBox(height: 11),
              TextField(
                controller: controller.clientController,
                decoration: const InputDecoration(
                  labelText: 'Client / organization',
                ),
              ),
              const SizedBox(height: 11),
              TextField(
                controller: controller.descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 11),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'department-${controller.editingProjectId.value ?? 'new'}',
                ),
                initialValue: controller.formDepartment.value,
                decoration: const InputDecoration(labelText: 'Department *'),
                items: departmentOptions
                    .map(
                      (department) => DropdownMenuItem(
                        value: department,
                        child: Text(department),
                      ),
                    )
                    .toList(),
                onChanged: (value) => controller.formDepartment.value = value,
              ),
              const SizedBox(height: 11),
              TextField(
                controller: controller.categoryController,
                decoration: const InputDecoration(
                  labelText: 'Project category',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Priority',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ProjectPriority.values.map((priority) {
                  final selected = controller.formPriority.value == priority;
                  return ChoiceChip(
                    label: Text(priority.label),
                    selected: selected,
                    selectedColor: _priorityColor(priority)
                        .withValues(alpha: .18),
                    labelStyle: TextStyle(
                      color: selected
                          ? _priorityColor(priority)
                          : const Color(0xFF60749A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => controller.formPriority.value = priority,
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ProjectStatus>(
                key: ValueKey(
                  'status-${controller.editingProjectId.value ?? 'new'}',
                ),
                initialValue: controller.formStatus.value,
                decoration: const InputDecoration(labelText: 'Project status'),
                items: ProjectStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) controller.formStatus.value = value;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Start date',
                      value: controller.startDate.value,
                      onTap: () => controller.pickStartDate(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateButton(
                      label: 'End date',
                      value: controller.endDate.value,
                      onTap: () => controller.pickEndDate(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Team & Assignment',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Assigned employees can view this project and their related tasks.',
                style: TextStyle(fontSize: 10, color: Color(0xFF60749A)),
              ),
              const SizedBox(height: 8),
              Container(
                height: 184,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDCE5F3)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: controller.employees.isEmpty
                    ? const Center(
                        child: Text(
                          'No active employees available.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF60749A),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: controller.employees.length,
                        itemBuilder: (context, index) {
                          final employee = controller.employees[index];
                          final checked = controller.assignedEmployeeIds
                              .contains(employee.id);
                          return CheckboxListTile(
                            dense: true,
                            value: checked,
                            onChanged: (value) => controller.toggleEmployee(
                              employee.id,
                              value ?? false,
                            ),
                            title: Text(
                              employee.fullName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              employee.jobTitle ??
                                  employee.department ??
                                  'Employee',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.closeEditor,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveProject,
                      icon: controller.isSaving.value
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(editing ? 'Save' : 'Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  });
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _fieldLabel),
      const SizedBox(height: 5),
      OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_month_outlined, size: 17),
        label: Text(
          value == null ? 'Select' : _formatDate(value),
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(42),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 9),
        ),
      ),
    ],
  );
}

class _ProjectSurface extends StatelessWidget {
  const _ProjectSurface({required this.child, required this.padding});
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

const _fieldLabel = TextStyle(
  fontSize: 11,
  color: Color(0xFF40567E),
  fontWeight: FontWeight.w700,
);

final _fieldDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: const Color(0xFFDDE6F4)),
);

InputDecoration _searchDecoration(String hintText) => InputDecoration(
  hintText: hintText,
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
);

String _formatDate(DateTime? value) =>
    value == null ? '—' : DateFormat('dd MMM yyyy').format(value);

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}

Color _statusColor(ProjectStatus status) => switch (status) {
  ProjectStatus.notStarted => const Color(0xFF7185A8),
  ProjectStatus.inProgress => const Color(0xFFFF8A13),
  ProjectStatus.completed => const Color(0xFF10B979),
  ProjectStatus.onHold => const Color(0xFFE65050),
  ProjectStatus.cancelled => const Color(0xFF6E7180),
};

Color _priorityColor(ProjectPriority priority) => switch (priority) {
  ProjectPriority.low => const Color(0xFF10B979),
  ProjectPriority.medium => const Color(0xFF2468F2),
  ProjectPriority.high => const Color(0xFFFF8A13),
  ProjectPriority.urgent => const Color(0xFFE65050),
};
