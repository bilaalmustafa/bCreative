import 'dart:ui' show PointerDeviceKind;

import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/core/widgets/app_loading.dart';
import 'package:bcreative_ems/core/widgets/header_action_layout.dart';
import 'package:bcreative_ems/core/widgets/page_intro.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/tasks/models/employee_task_model.dart';
import 'package:bcreative_ems/features/tasks/repositories/task_repository.dart';
import 'package:bcreative_ems/features/tasks/viewmodels/task_controller.dart';
import 'package:bcreative_ems/features/shell/views/app_shell.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TaskListView extends GetView<TaskController> {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: controller.isAdmin ? 'Tasks' : 'My Tasks',
    body: Obx(
      () => controller.isLoading.value
          ? const AppLoading()
          : controller.isAdmin
          ? _AdminTaskContent(controller: controller)
          : _EmployeeTaskContent(controller: controller),
    ),
  );
}

class _AdminTaskContent extends StatelessWidget {
  const _AdminTaskContent({required this.controller});
  final TaskController controller;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(isMobile(context) ? 16 : 24),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdminTaskHeader(controller: controller),
              const SizedBox(height: 18),
              _TaskStats(controller: controller),
              const SizedBox(height: 14),
              _TaskWorkspace(controller: controller),
            ],
          ),
        ),
      ),
    ],
  );
}

class _AdminTaskHeader extends StatelessWidget {
  const _AdminTaskHeader({required this.controller});
  final TaskController controller;

  @override
  Widget build(BuildContext context) => HeaderActionLayout(
    heading: const PageIntro(
      icon: Icons.assignment_rounded,
      description: 'Create, assign, and track project tasks and progress.',
    ),
    action: FilledButton.icon(
      onPressed: controller.openCreateTask,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        backgroundColor: const Color(0xFF2468F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Create Task'),
    ),
  );
}

class _TaskStats extends StatelessWidget {
  const _TaskStats({required this.controller});
  final TaskController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Obx(() {
      final cards = [
        _TaskStatCard(
          icon: Icons.assignment_outlined,
          label: 'Total Tasks',
          value: '${controller.totalTasks}',
          caption: 'Across all projects',
          color: const Color(0xFF2E6CF6),
          background: const Color(0xFFE8F0FF),
        ),
        _TaskStatCard(
          icon: Icons.schedule_rounded,
          label: 'Pending Tasks',
          value: '${controller.pendingTasks}',
          caption: _percentage(controller.pendingTasks, controller.totalTasks),
          color: const Color(0xFFFF8616),
          background: const Color(0xFFFFECDC),
        ),
        _TaskStatCard(
          icon: Icons.play_circle_outline_rounded,
          label: 'In Progress',
          value: '${controller.inProgressTasks}',
          caption: _percentage(
            controller.inProgressTasks,
            controller.totalTasks,
          ),
          color: const Color(0xFF2468F2),
          background: const Color(0xFFE7F0FF),
        ),
        _TaskStatCard(
          icon: Icons.task_alt_rounded,
          label: 'Completed',
          value: '${controller.completedTasks}',
          caption: _percentage(
            controller.completedTasks,
            controller.totalTasks,
          ),
          color: const Color(0xFF10B979),
          background: const Color(0xFFE0F9EE),
        ),
        _TaskStatCard(
          icon: Icons.warning_amber_rounded,
          label: 'Overdue',
          value: '${controller.overdueTasks}',
          caption: 'Past due date',
          color: const Color(0xFFE65050),
          background: const Color(0xFFFFE7EA),
        ),
      ];
      if (constraints.maxWidth >= 1180) {
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
        crossAxisCount: constraints.maxWidth >= 690 ? 3 : 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: constraints.maxWidth >= 690 ? 2.8 : 3.7,
        children: cards,
      );
    }),
  );
}

class _TaskStatCard extends StatelessWidget {
  const _TaskStatCard({
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
  Widget build(BuildContext context) => _TaskSurface(
    padding: const EdgeInsets.all(13),
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
        const SizedBox(width: 10),
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

class _TaskWorkspace extends StatelessWidget {
  const _TaskWorkspace({required this.controller});
  final TaskController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final directory = _TaskSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TaskFilterBar(controller: controller, embedded: true),
            const Divider(height: 1, color: Color(0xFFE9EFF8)),
            _TaskDirectory(controller: controller, embedded: true),
          ],
        ),
      );
      final sidePanel = _TaskSidePanel(controller: controller);
      if (constraints.maxWidth >= 1050) {
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

class _TaskFilterBar extends StatelessWidget {
  const _TaskFilterBar({required this.controller, this.embedded = false});
  final TaskController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Obx(
      () => Wrap(
        spacing: 9,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: 245,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Search tasks', style: _fieldLabel),
                const SizedBox(height: 5),
                SizedBox(
                  height: 39,
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: controller.setQuery,
                    style: const TextStyle(fontSize: 12),
                    decoration: _searchDecoration('Task, project, employee...'),
                  ),
                ),
              ],
            ),
          ),
          _TaskFilterDropdown<String>(
            label: 'Project',
            width: 135,
            value: controller.projectFilter.value,
            allLabel: 'All Projects',
            values: controller.projects.map((project) => project.id).toList(),
            labelFor: (id) => controller.projectName(id) ?? 'Project',
            onChanged: controller.setProjectFilter,
          ),
          _TaskFilterDropdown<String>(
            label: 'Assignee',
            width: 130,
            value: controller.employeeFilter.value,
            allLabel: 'All Assignees',
            values: controller.employees
                .map((employee) => employee.id)
                .toList(),
            labelFor: controller.employeeName,
            onChanged: controller.setEmployeeFilter,
          ),
          _TaskFilterDropdown<EmployeeTaskStatus>(
            label: 'Status',
            width: 120,
            value: controller.statusFilter.value,
            allLabel: 'All Statuses',
            values: EmployeeTaskStatus.values,
            labelFor: (status) => status.label,
            onChanged: controller.setStatusFilter,
          ),
          _TaskFilterDropdown<TaskPriority>(
            label: 'Priority',
            width: 118,
            value: controller.priorityFilter.value,
            allLabel: 'All Priorities',
            values: TaskPriority.values,
            labelFor: (priority) => priority.label,
            onChanged: controller.setPriorityFilter,
          ),
          FilterChip(
            label: const Text('Overdue'),
            selected: controller.overdueOnly.value,
            onSelected: (value) => controller.overdueOnly.value = value,
            selectedColor: const Color(0xFFFFE7EA),
            labelStyle: const TextStyle(fontSize: 11),
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
    return _TaskSurface(padding: const EdgeInsets.all(12), child: content);
  }
}

class _TaskFilterDropdown<T> extends StatelessWidget {
  const _TaskFilterDropdown({
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

class _TaskDirectory extends StatelessWidget {
  const _TaskDirectory({required this.controller, this.embedded = false});
  final TaskController controller;
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
                  'Tasks List',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              if (MediaQuery.sizeOf(context).width < 1050)
                const Text(
                  'Swipe table',
                  style: TextStyle(fontSize: 10, color: Color(0xFF60749A)),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Obx(() {
          final visible = controller.filteredTasks;
          if (visible.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(44),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_late_outlined,
                    size: 38,
                    color: Color(0xFF8799B9),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.tasks.isEmpty
                        ? 'No tasks created yet.'
                        : 'No tasks match the selected filters.',
                    style: const TextStyle(color: Color(0xFF60749A)),
                  ),
                  if (controller.tasks.isEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: controller.openCreateTask,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create first task'),
                    ),
                  ],
                ],
              ),
            );
          }
          return _TaskTable(controller: controller, tasks: visible);
        }),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Obx(
          () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Showing ${controller.filteredTasks.length} of ${controller.totalTasks} tasks',
              style: const TextStyle(fontSize: 11, color: Color(0xFF60749A)),
            ),
          ),
        ),
      ],
    );
    return embedded
        ? content
        : _TaskSurface(padding: EdgeInsets.zero, child: content);
  }
}

class _TaskTable extends StatelessWidget {
  const _TaskTable({required this.controller, required this.tasks});
  final TaskController controller;
  final List<EmployeeTaskModel> tasks;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : 1100.0;
      final width = available < 1120 ? 1120.0 : available;
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
                  const _TaskTableHeader(),
                  ...tasks.map(
                    (task) => _TaskTableRow(controller: controller, task: task),
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

class _TaskTableHeader extends StatelessWidget {
  const _TaskTableHeader();
  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    color: const Color(0xFFF5F8FD),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: const Row(
      children: [
        Expanded(flex: 28, child: _TaskTableLabel('TASK')),
        Expanded(flex: 20, child: _TaskTableLabel('PROJECT')),
        Expanded(flex: 18, child: _TaskTableLabel('ASSIGNED TO')),
        Expanded(flex: 12, child: _TaskTableLabel('PRIORITY')),
        Expanded(flex: 15, child: _TaskTableLabel('STATUS')),
        Expanded(flex: 14, child: _TaskTableLabel('DUE DATE')),
        Expanded(flex: 19, child: _TaskTableLabel('PROGRESS')),
        Expanded(flex: 14, child: _TaskTableLabel('ACTIONS')),
      ],
    ),
  );
}

class _TaskTableLabel extends StatelessWidget {
  const _TaskTableLabel(this.label);
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

class _TaskTableRow extends StatelessWidget {
  const _TaskTableRow({required this.controller, required this.task});
  final TaskController controller;
  final EmployeeTaskModel task;

  @override
  Widget build(BuildContext context) => Obx(() {
    final selected = controller.selectedTaskId.value == task.id;
    final overdue = controller.isOverdue(task);
    return InkWell(
      onTap: () => controller.selectTask(task),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: selected ? const Color(0xFFF4F8FF) : null,
        child: Row(
          children: [
            Expanded(flex: 28, child: _TaskNameCell(task: task)),
            Expanded(
              flex: 20,
              child: _ProjectCell(name: controller.projectName(task.projectId)),
            ),
            Expanded(
              flex: 18,
              child: _AssigneeCell(
                employee: controller.employeeForId(task.employeeId),
              ),
            ),
            Expanded(flex: 12, child: _PriorityChip(priority: task.priority)),
            Expanded(flex: 15, child: _TaskStatusChip(status: task.status)),
            Expanded(
              flex: 14,
              child: Text(
                _formatDate(task.dueDate),
                style: TextStyle(
                  fontSize: 11,
                  color: overdue
                      ? const Color(0xFFE65050)
                      : const Color(0xFF40567E),
                  fontWeight: overdue ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            Expanded(flex: 19, child: _TaskProgress(progress: task.progress)),
            Expanded(
              flex: 14,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'View task',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.selectTask(task),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Edit task',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.openEditTask(task),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More actions',
                    icon: const Icon(Icons.more_vert_rounded, size: 19),
                    onSelected: (action) {
                      if (action == 'delete') controller.deleteTask(task);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete task'),
                      ),
                    ],
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

class _TaskNameCell extends StatelessWidget {
  const _TaskNameCell({required this.task});
  final EmployeeTaskModel task;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: _priorityColor(task.priority).withValues(alpha: .14),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          Icons.assignment_rounded,
          size: 19,
          color: _priorityColor(task.priority),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            Text(
              task.description.isEmpty
                  ? (task.taskType ?? 'Project task')
                  : task.description,
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

class _ProjectCell extends StatelessWidget {
  const _ProjectCell({this.name});
  final String? name;
  @override
  Widget build(BuildContext context) => Text(
    name ?? 'No project',
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontSize: 11,
      color: Color(0xFF40567E),
      fontWeight: FontWeight.w600,
    ),
  );
}

class _AssigneeCell extends StatelessWidget {
  const _AssigneeCell({this.employee});
  final EmployeeModel? employee;
  @override
  Widget build(BuildContext context) {
    final name = employee?.fullName ?? 'Employee';
    final photoUrl = employee?.displayPhotoUrl;
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFFE8F0FF),
          foregroundImage: photoUrl?.isNotEmpty == true
              ? NetworkImage(photoUrl!)
              : null,
          child: Text(
            _initials(name),
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF2468F2),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final TaskPriority priority;
  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          priority.label,
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

class _TaskStatusChip extends StatelessWidget {
  const _TaskStatusChip({required this.status});
  final EmployeeTaskStatus status;
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
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

class _TaskProgress extends StatelessWidget {
  const _TaskProgress({required this.progress});
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

class _TaskSidePanel extends StatelessWidget {
  const _TaskSidePanel({required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) => _TaskSurface(
    padding: EdgeInsets.zero,
    child: Obx(() {
      if (controller.isEditorOpen.value) {
        return _TaskEditor(controller: controller);
      }
      if (controller.selectedTaskId.value == null) {
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
                'Select a task to view details or create a new task.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF60749A)),
              ),
            ],
          ),
        );
      }
      return _TaskDetails(controller: controller);
    }),
  );
}

class _TaskDetails extends StatelessWidget {
  const _TaskDetails({required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) => Obx(() {
    final task = controller.selectedTask;
    if (task == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Task Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Edit task',
                onPressed: () => controller.openEditTask(task),
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              IconButton(
                tooltip: 'Close details',
                onPressed: () => controller.selectedTaskId.value = null,
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
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  task.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF40567E),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _TaskProgress(progress: task.progress),
              const SizedBox(height: 4),
              Text(
                '${task.progress}% complete',
                style: const TextStyle(fontSize: 10, color: Color(0xFF60749A)),
              ),
              const SizedBox(height: 15),
              _DetailLine(
                icon: Icons.folder_outlined,
                label: 'Project',
                value: controller.projectName(task.projectId) ?? 'No project',
              ),
              _DetailLine(
                icon: Icons.person_outline_rounded,
                label: 'Assignee',
                value: controller.employeeName(task.employeeId),
              ),
              _DetailLine(
                icon: Icons.flag_outlined,
                label: 'Priority',
                value: task.priority.label,
              ),
              _DetailLine(
                icon: Icons.track_changes_outlined,
                label: 'Status',
                value: task.status.label,
              ),
              _DetailLine(
                icon: Icons.calendar_today_outlined,
                label: 'Due date',
                value: _formatDate(task.dueDate),
              ),
              if (task.estimatedHours != null)
                _DetailLine(
                  icon: Icons.timer_outlined,
                  label: 'Estimated',
                  value: '${task.estimatedHours} hours',
                ),
              if (task.taskType?.isNotEmpty ?? false)
                _DetailLine(
                  icon: Icons.category_outlined,
                  label: 'Type',
                  value: task.taskType!,
                ),
              if (task.labels.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Labels',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: task.labels
                      .map(
                        (label) => Chip(
                          label: Text(label),
                          visualDensity: VisualDensity.compact,
                          labelStyle: const TextStyle(fontSize: 10),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => Get.bottomSheet(
                  TaskUpdatesSheet(
                    task: task,
                    repository: Get.find<TaskRepository>(),
                    employeeId: null,
                    allowEmployeeUpdates: false,
                  ),
                  isScrollControlled: true,
                ),
                icon: const Icon(Icons.forum_outlined, size: 18),
                label: const Text('Updates & files'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => controller.deleteTask(task),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE64242),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete Task'),
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

class _TaskEditor extends StatelessWidget {
  const _TaskEditor({required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) => Obx(() {
    final editing = controller.editingTaskId.value != null;
    final availableEmployees = controller.assignableEmployees;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  editing ? 'Edit Task' : 'Create New Task',
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.titleController,
                decoration: const InputDecoration(labelText: 'Task title *'),
              ),
              const SizedBox(height: 11),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'task-project-${controller.formProjectId.value ?? 'new'}',
                ),
                initialValue: controller.formProjectId.value,
                decoration: const InputDecoration(labelText: 'Project *'),
                hint: const Text('Select project'),
                items: controller.projects
                    .map(
                      (project) => DropdownMenuItem(
                        value: project.id,
                        child: Text(project.name),
                      ),
                    )
                    .toList(),
                onChanged: controller.setFormProject,
              ),
              const SizedBox(height: 11),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'task-assignee-${controller.formProjectId.value ?? 'none'}',
                ),
                initialValue: controller.formEmployeeId.value,
                decoration: const InputDecoration(
                  labelText: 'Assigned employee *',
                ),
                hint: Text(
                  availableEmployees.isEmpty
                      ? 'Assign project team first'
                      : 'Select team member',
                ),
                items: availableEmployees
                    .map(
                      (employee) => DropdownMenuItem(
                        value: employee.id,
                        child: Text(employee.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => controller.formEmployeeId.value = value,
              ),
              const SizedBox(height: 11),
              TextField(
                controller: controller.descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Priority *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: TaskPriority.values.map((priority) {
                  final selected = controller.formPriority.value == priority;
                  return ChoiceChip(
                    label: Text(priority.label),
                    selected: selected,
                    selectedColor: _priorityColor(priority)
                        .withValues(alpha: .18),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? _priorityColor(priority)
                          : const Color(0xFF60749A),
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => controller.formPriority.value = priority,
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller.taskTypeController,
                decoration: const InputDecoration(labelText: 'Task type'),
              ),
              const SizedBox(height: 11),
              DropdownButtonFormField<EmployeeTaskStatus>(
                key: ValueKey(
                  'task-status-${controller.formStatus.value.value}',
                ),
                initialValue: controller.formStatus.value,
                decoration: const InputDecoration(labelText: 'Status *'),
                items: EmployeeTaskStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                    )
                    .toList(),
                onChanged: controller.setFormStatus,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${controller.formProgress.value}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2468F2),
                    ),
                  ),
                ],
              ),
              Slider(
                value: controller.formProgress.value.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: controller.setFormProgress,
              ),
              const SizedBox(height: 3),
              OutlinedButton.icon(
                onPressed: () => controller.pickDueDate(context),
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(
                  'Deadline: ${_formatDate(controller.dueDate.value)}',
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: 11),
              TextField(
                controller: controller.estimatedHoursController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Estimated hours'),
              ),
              const SizedBox(height: 11),
              TextField(
                controller: controller.labelsController,
                decoration: const InputDecoration(
                  labelText: 'Labels',
                  hintText: 'UI, backend, urgent',
                ),
              ),
              const SizedBox(height: 18),
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
                          : controller.saveTask,
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

class _EmployeeTaskContent extends StatelessWidget {
  const _EmployeeTaskContent({required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(isMobile(context) ? 16 : 24),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageIntro(
                icon: Icons.assignment_rounded,
                description: 'Update your task status and completion progress.',
              ),
              const SizedBox(height: 18),
              _EmployeeTaskStats(controller: controller),
              const SizedBox(height: 14),
              Obx(() {
                if (controller.tasks.isEmpty) {
                  return const _TaskSurface(
                    padding: EdgeInsets.all(44),
                    child: Center(
                      child: Text(
                        'No tasks have been assigned to you yet.',
                        style: TextStyle(color: Color(0xFF60749A)),
                      ),
                    ),
                  );
                }
                return Column(
                  children: controller.tasks
                      .map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _EmployeeTaskCard(
                            controller: controller,
                            task: task,
                          ),
                        ),
                      )
                      .toList(),
                );
              }),
            ],
          ),
        ),
      ),
    ],
  );
}

class _EmployeeTaskStats extends StatelessWidget {
  const _EmployeeTaskStats({required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) => Obx(
    () => Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MiniTaskStat(
          label: 'Pending',
          value: '${controller.pendingTasks}',
          color: const Color(0xFFFF8616),
        ),
        _MiniTaskStat(
          label: 'In Progress',
          value: '${controller.inProgressTasks}',
          color: const Color(0xFF2468F2),
        ),
        _MiniTaskStat(
          label: 'Completed',
          value: '${controller.completedTasks}',
          color: const Color(0xFF10B979),
        ),
        _MiniTaskStat(
          label: 'Overdue',
          value: '${controller.overdueTasks}',
          color: const Color(0xFFE65050),
        ),
      ],
    ),
  );
}

class _MiniTaskStat extends StatelessWidget {
  const _MiniTaskStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 165,
    child: _TaskSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.task_alt_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF60749A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmployeeTaskCard extends StatelessWidget {
  const _EmployeeTaskCard({required this.controller, required this.task});
  final TaskController controller;
  final EmployeeTaskModel task;
  @override
  Widget build(BuildContext context) => _TaskSurface(
    padding: const EdgeInsets.all(17),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF40567E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _TaskStatusChip(status: task.status),
          ],
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            if (task.dueDate != null)
              Text(
                'Due ${_formatDate(task.dueDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: controller.isOverdue(task)
                      ? const Color(0xFFE65050)
                      : const Color(0xFF60749A),
                ),
              ),
            _PriorityChip(priority: task.priority),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '${task.progress}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2468F2),
              ),
            ),
          ],
        ),
        Slider(
          value: task.progress.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          onChanged: (_) {},
          onChangeEnd: (value) => controller.updateOwnProgress(task, value),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<EmployeeTaskStatus>(
              value: task.status,
              items: EmployeeTaskStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                  )
                  .toList(),
              onChanged: (status) {
                if (status != null) controller.updateOwnStatus(task, status);
              },
            ),
            OutlinedButton.icon(
              onPressed: () => Get.bottomSheet(
                TaskUpdatesSheet(
                  task: task,
                  repository: Get.find<TaskRepository>(),
                  employeeId: controller.employeeId,
                  allowEmployeeUpdates: true,
                ),
                isScrollControlled: true,
              ),
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: const Text('Updates & files'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TaskSurface extends StatelessWidget {
  const _TaskSurface({required this.child, required this.padding});
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
String _formatDate(DateTime? value) {
  if (value == null) return '-';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String _percentage(int value, int total) =>
    total == 0 ? '0% of total' : '${((value / total) * 100).round()}% of total';
String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  return words.isEmpty
      ? '?'
      : words.take(2).map((word) => word[0].toUpperCase()).join();
}

Color _priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.low => const Color(0xFF10B979),
  TaskPriority.medium => const Color(0xFF2468F2),
  TaskPriority.high => const Color(0xFFFF8A13),
  TaskPriority.urgent => const Color(0xFFE65050),
};
Color _statusColor(EmployeeTaskStatus status) => switch (status) {
  EmployeeTaskStatus.assigned => const Color(0xFFFF8616),
  EmployeeTaskStatus.inProgress => const Color(0xFF2468F2),
  EmployeeTaskStatus.completed => const Color(0xFF10B979),
};

class TaskUpdatesSheet extends StatefulWidget {
  const TaskUpdatesSheet({
    super.key,
    required this.task,
    required this.repository,
    required this.employeeId,
    required this.allowEmployeeUpdates,
  });
  final EmployeeTaskModel task;
  final TaskRepository repository;
  final String? employeeId;
  final bool allowEmployeeUpdates;
  @override
  State<TaskUpdatesSheet> createState() => _TaskUpdatesSheetState();
}

class _TaskUpdatesSheetState extends State<TaskUpdatesSheet> {
  final _textController = TextEditingController();
  PlatformFile? _file;
  bool _isPosting = false;
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.single);
    }
  }

  Future<void> _post() async {
    final employeeId = widget.employeeId;
    if (employeeId == null || employeeId.isEmpty) {
      return;
    }
    setState(() => _isPosting = true);
    try {
      await widget.repository.createUpdate(
        taskId: widget.task.id,
        employeeId: employeeId,
        text: _textController.text,
        file: _file,
      );
      if (mounted) {
        _textController.clear();
        setState(() => _file = null);
      }
    } catch (error) {
      if (mounted) Get.snackbar('Update not saved', error.toString());
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _copyDownloadLink(TaskUpdateModel update) async {
    final url = await widget.repository.getDownloadUrl(update.storagePath);
    if (url == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      Get.snackbar(
        'Link copied',
        'Paste the secure download link in your browser.',
      );
    }
  }

  Future<void> _edit(TaskUpdateModel update) async {
    final input = TextEditingController(text: update.text);
    final edited = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Edit update'),
        content: TextField(controller: input, minLines: 2, maxLines: 5),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Get.back(result: input.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    input.dispose();
    if (edited == null) {
      return;
    }
    try {
      await widget.repository.updateUpdateText(update, edited);
    } catch (error) {
      if (mounted) {
        Get.snackbar('Update not saved', error.toString());
      }
    }
  }

  Future<void> _delete(TaskUpdateModel update) async {
    try {
      await widget.repository.deleteUpdate(update);
    } catch (error) {
      if (mounted) {
        Get.snackbar('Update not deleted', error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeId = widget.allowEmployeeUpdates ? widget.employeeId : null;
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text('Updates and shared files'),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<TaskUpdateModel>>(
                stream: widget.repository.watchUpdates(
                  taskId: widget.task.id,
                  employeeId: employeeId,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const AppLoading();
                  final updates = snapshot.data!;
                  if (updates.isEmpty) {
                    return const Center(child: Text('No updates yet.'));
                  }
                  return ListView.separated(
                    itemCount: updates.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final update = updates[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          update.text.isEmpty ? 'File update' : update.text,
                        ),
                        subtitle: update.fileName == null
                            ? null
                            : Text('Attachment: ${update.fileName}'),
                        trailing: widget.allowEmployeeUpdates
                            ? PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit') _edit(update);
                                  if (action == 'delete') _delete(update);
                                  if (action == 'download') {
                                    _copyDownloadLink(update);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit text'),
                                  ),
                                  if (update.hasFile)
                                    const PopupMenuItem(
                                      value: 'download',
                                      child: Text('Copy download link'),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              )
                            : update.hasFile
                            ? IconButton(
                                tooltip: 'Copy download link',
                                onPressed: () => _copyDownloadLink(update),
                                icon: const Icon(Icons.download_outlined),
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            if (widget.allowEmployeeUpdates) ...[
              const Divider(height: 28),
              TextField(
                controller: _textController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Add a text update',
                  hintText: 'Describe progress or add a note',
                ),
              ),
              if (_file != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _file!.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _file = null),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isPosting ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Attach file'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _isPosting ? null : _post,
                    icon: _isPosting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: const Text('Post update'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
