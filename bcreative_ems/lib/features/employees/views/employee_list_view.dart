import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/core/widgets/app_loading.dart';
import 'package:bcreative_ems/core/widgets/page_intro.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/employees/models/employment_enums.dart';
import 'package:bcreative_ems/features/employees/viewmodels/employee_form_controller.dart';
import 'package:bcreative_ems/features/employees/viewmodels/employee_list_controller.dart';
import 'package:bcreative_ems/features/shell/views/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

void _openEmployeePanel(
  EmployeeListController listController,
  EmployeeModel employee, {
  bool edit = false,
}) {
  final formController = Get.find<EmployeeFormController>(
    tag: 'employeeComposer',
  );
  listController.viewEmployee(employee);
  formController.loadForEmployee(employee);
  if (edit) listController.editSelectedEmployee();
}

class EmployeeListView extends GetView<EmployeeListController> {
  const EmployeeListView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Employees',
      body: Obx(() {
        if (controller.isLoading.value) return const AppLoading();
        return _EmployeesContent(controller: controller);
      }),
    );
  }
}

class _EmployeesContent extends StatelessWidget {
  const _EmployeesContent({required this.controller});

  final EmployeeListController controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final composerForm = Get.find<EmployeeFormController>(
      tag: 'employeeComposer',
    );
    final statColumns = width >= 1120
        ? 4
        : width >= 650
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
                const SizedBox(height: 20),
                Obx(
                  () => GridView.count(
                    crossAxisCount: statColumns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: statColumns == 1 ? 2.8 : 2.05,
                    children: [
                      _EmployeeStatCard(
                        icon: Icons.groups_rounded,
                        label: 'Total Employees',
                        value: '${controller.overview.value?.total ?? 0}',
                        detail: 'All employee records',
                        color: const Color(0xFF2D6DF6),
                        background: const Color(0xFFEAF0FF),
                      ),
                      _EmployeeStatCard(
                        icon: Icons.how_to_reg_rounded,
                        label: 'Active Employees',
                        value: '${controller.overview.value?.active ?? 0}',
                        detail: 'Currently active',
                        color: const Color(0xFF12B979),
                        background: const Color(0xFFE2FAEF),
                      ),
                      _EmployeeStatCard(
                        icon: Icons.flight_takeoff_rounded,
                        label: 'On Leave',
                        value: '${controller.overview.value?.onLeave ?? 0}',
                        detail: 'Based on employee status',
                        color: const Color(0xFFFF8B18),
                        background: const Color(0xFFFFF0DE),
                      ),
                      _EmployeeStatCard(
                        icon: Icons.person_off_rounded,
                        label: 'Inactive Employees',
                        value: '${controller.overview.value?.inactive ?? 0}',
                        detail: 'Inactive or terminated',
                        color: const Color(0xFFFF4E63),
                        background: const Color(0xFFFFE8EE),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final showSideComposer = constraints.maxWidth >= 900;
                    final directory = _EmployeeDirectory(
                      controller: controller,
                    );
                    final composer = _EmployeeComposerPanel(
                      listController: controller,
                      formController: composerForm,
                    );
                    if (showSideComposer) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: directory),
                          const SizedBox(width: 14),
                          Obx(
                            () => controller.isComposerOpen.value
                                ? SizedBox(width: 350, child: composer)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        directory,
                        Obx(
                          () =>
                              controller.isComposerOpen.value &&
                                  controller.composerWasRequested.value
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: composer,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
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

  final EmployeeListController controller;

  @override
  Widget build(BuildContext context) {
    const heading = PageIntro(
      icon: Icons.groups_rounded,
      description: 'Manage employees, add new members, and track their status.',
      iconColor: Color(0xFF2E6BFA),
      backgroundColor: Color(0xFFEAF0FF),
      boxSize: 46,
      iconSize: 28,
    );
    final action = FilledButton.icon(
      onPressed: () {
        Get.find<EmployeeFormController>(tag: 'employeeComposer')
            .resetForCreate();
        controller.openComposer();
      },
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        backgroundColor: const Color(0xFF2468F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Employee'),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 850) {
          return Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: 16),
              action,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: action),
          ],
        );
      },
    );
  }
}

class _EmployeeStatCard extends StatelessWidget {
  const _EmployeeStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return _EmployeeSurface(
      padding: const EdgeInsets.all(16),
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
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7487A8),
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

class _EmployeeDirectory extends StatelessWidget {
  const _EmployeeDirectory({required this.controller});

  final EmployeeListController controller;

  @override
  Widget build(BuildContext context) {
    return _EmployeeSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _FilterBar(controller: controller),
          const Divider(height: 1, color: Color(0xFFEAF0F7)),
          Obx(() {
            if (controller.employees.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 64, horizontal: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 46,
                      color: Color(0xFF89A0C4),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No employees found',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Change the filters or add a new employee.',
                      style: TextStyle(color: Color(0xFF6F83A7)),
                    ),
                  ],
                ),
              );
            }
            return isMobile(context)
                ? _EmployeeCards(controller: controller)
                : _EmployeeTable(controller: controller);
          }),
          const Divider(height: 1, color: Color(0xFFEAF0F7)),
          _Pagination(controller: controller),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final EmployeeListController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Obx(
        () => Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 270,
              child: TextField(
                controller: controller.searchController,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Search by name, email, department...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            SizedBox(
              width: 155,
              child: DropdownButtonFormField<String?>(
                key: ValueKey(controller.departmentFilter.value),
                initialValue: controller.departmentFilter.value,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('All Departments'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Departments'),
                  ),
                  ...controller.departments.map(
                    (department) => DropdownMenuItem<String?>(
                      value: department,
                      child: Text(department, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: controller.setDepartmentFilter,
              ),
            ),
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<EmploymentStatus?>(
                key: ValueKey(controller.statusFilter.value),
                initialValue: controller.statusFilter.value,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('All Status'),
                items: [
                  const DropdownMenuItem<EmploymentStatus?>(
                    value: null,
                    child: Text('All Status'),
                  ),
                  ...EmploymentStatus.values.map(
                    (status) => DropdownMenuItem<EmploymentStatus?>(
                      value: status,
                      child: Text(status.label),
                    ),
                  ),
                ],
                onChanged: controller.setStatusFilter,
              ),
            ),
            SizedBox(
              width: 168,
              child: DropdownButtonFormField<EmploymentType?>(
                key: ValueKey(controller.employmentTypeFilter.value),
                initialValue: controller.employmentTypeFilter.value,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('Employment Type'),
                items: [
                  const DropdownMenuItem<EmploymentType?>(
                    value: null,
                    child: Text('Employment Type'),
                  ),
                  ...EmploymentType.values.map(
                    (type) => DropdownMenuItem<EmploymentType?>(
                      value: type,
                      child: Text(type.label),
                    ),
                  ),
                ],
                onChanged: controller.setEmploymentTypeFilter,
              ),
            ),
            IconButton(
              tooltip: 'Clear filters',
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeTable extends StatelessWidget {
  const _EmployeeTable({required this.controller});

  final EmployeeListController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 810),
        child: Column(
          children: [
            const _EmployeeTableHeader(),
            ...controller.employees.map(
              (employee) =>
                  _EmployeeTableRow(employee: employee, controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeTableHeader extends StatelessWidget {
  const _EmployeeTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F8FC),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: const Row(
        children: [
          SizedBox(
            width: 28,
            child: Icon(
              Icons.check_box_outline_blank_rounded,
              size: 19,
              color: Color(0xFF8094B6),
            ),
          ),
          SizedBox(width: 198, child: _TableLabel('Employee')),
          SizedBox(width: 92, child: _TableLabel('Employee ID')),
          SizedBox(width: 138, child: _TableLabel('Department')),
          SizedBox(width: 128, child: _TableLabel('Position')),
          SizedBox(width: 91, child: _TableLabel('Status')),
          SizedBox(width: 105, child: _TableLabel('Joining Date')),
          SizedBox(width: 103, child: _TableLabel('Actions')),
        ],
      ),
    );
  }
}

class _TableLabel extends StatelessWidget {
  const _TableLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      color: Color(0xFF40567E),
      fontWeight: FontWeight.w700,
    ),
  );
}

class _EmployeeTableRow extends StatelessWidget {
  const _EmployeeTableRow({required this.employee, required this.controller});

  final EmployeeModel employee;
  final EmployeeListController controller;

  @override
  Widget build(BuildContext context) {
    final date = employee.joiningDate == null
        ? '—'
        : DateFormat('dd MMM y').format(employee.joiningDate!);
    return InkWell(
      onTap: () => _openEmployeePanel(controller, employee),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEDF1F7))),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 28,
              child: Icon(
                Icons.check_box_outline_blank_rounded,
                size: 19,
                color: Color(0xFF9BADCA),
              ),
            ),
            SizedBox(width: 198, child: _EmployeeIdentity(employee: employee)),
            SizedBox(width: 92, child: _CellText(employee.employeeCode)),
            SizedBox(
              width: 138,
              child: _DepartmentPill(label: employee.department ?? 'Other'),
            ),
            SizedBox(
              width: 128,
              child: _CellText(employee.jobTitle ?? 'Not set'),
            ),
            SizedBox(
              width: 91,
              child: _StatusPill(status: employee.employmentStatus),
            ),
            SizedBox(width: 105, child: _CellText(date)),
            SizedBox(
              width: 103,
              child: _EmployeeActions(
                employee: employee,
                controller: controller,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeIdentity extends StatelessWidget {
  const _EmployeeIdentity({required this.employee});

  final EmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    final url = employee.displayPhotoUrl;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFE7EEFF),
          backgroundImage: url != null && url.isNotEmpty
              ? NetworkImage(url)
              : null,
          child: url == null || url.isEmpty
              ? Text(
                  _initials(employee.fullName),
                  style: const TextStyle(
                    color: Color(0xFF2F67E8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                employee.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF60779E)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.split(' ').where((part) => part.isNotEmpty).take(2);
    return parts.map((part) => part[0]).join().toUpperCase();
  }
}

class _CellText extends StatelessWidget {
  const _CellText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(fontSize: 11, color: Color(0xFF3D5682)),
  );
}

class _DepartmentPill extends StatelessWidget {
  const _DepartmentPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = <String, Color>{
      'IT & Development': const Color(0xFF2E70FA),
      'Design': const Color(0xFF8B3BF3),
      'HR': const Color(0xFF1AAF70),
      'Finance': const Color(0xFFCB8200),
      'Operations': const Color(0xFFFF7600),
      'Marketing': const Color(0xFFEE3C57),
    };
    final color = colors[label] ?? const Color(0xFF5A718F);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final EmploymentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      EmploymentStatus.active => const Color(0xFF0FA86B),
      EmploymentStatus.onLeave => const Color(0xFFFF9B09),
      EmploymentStatus.inactive => const Color(0xFFEE5364),
      EmploymentStatus.terminated => const Color(0xFF7B879D),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmployeeActions extends StatelessWidget {
  const _EmployeeActions({required this.employee, required this.controller});

  final EmployeeModel employee;
  final EmployeeListController controller;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _ActionButton(
        icon: Icons.visibility_outlined,
        tooltip: 'View employee',
        onTap: () => _openEmployeePanel(controller, employee),
      ),
      const SizedBox(width: 5),
      _ActionButton(
        icon: Icons.edit_outlined,
        tooltip: 'Edit employee',
        onTap: () => _openEmployeePanel(controller, employee, edit: true),
      ),
      const SizedBox(width: 3),
      PopupMenuButton<String>(
        tooltip: 'More actions',
        onSelected: (action) {
          if (action == 'edit') {
            _openEmployeePanel(controller, employee, edit: true);
          }
          if (action == 'view') _openEmployeePanel(controller, employee);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'view', child: Text('View profile')),
          PopupMenuItem(value: 'edit', child: Text('Edit employee')),
        ],
        child: const _ActionButton(
          icon: Icons.more_vert_rounded,
          tooltip: 'More',
        ),
      ),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 31,
            width: 31,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDCE6F6)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF2760D6)),
          ),
        ),
      ),
    );
  }
}

class _EmployeeCards extends StatelessWidget {
  const _EmployeeCards({required this.controller});

  final EmployeeListController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: controller.employees
          .map(
            (employee) => ListTile(
              leading: _EmployeeIdentityAvatar(employee: employee),
              title: Text(
                employee.fullName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${employee.jobTitle ?? 'Not set'} · ${employee.department ?? 'Other'}',
              ),
              trailing: _StatusPill(status: employee.employmentStatus),
              onTap: () => _openEmployeePanel(controller, employee),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _EmployeeIdentityAvatar extends StatelessWidget {
  const _EmployeeIdentityAvatar({required this.employee});

  final EmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    final url = employee.displayPhotoUrl;
    return CircleAvatar(
      backgroundColor: const Color(0xFFE7EEFF),
      backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
      child: url == null || url.isEmpty
          ? Text(
              employee.fullName.isEmpty
                  ? '?'
                  : employee.fullName[0].toUpperCase(),
            )
          : null,
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.controller});

  final EmployeeListController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Obx(
        () => Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Showing ${controller.showingStart} to ${controller.showingEnd} of ${controller.filteredCount} employees',
              style: const TextStyle(fontSize: 11, color: Color(0xFF546B93)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PaginationButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: controller.hasPrevious
                      ? controller.previousPage
                      : null,
                ),
                const SizedBox(width: 5),
                ...List.generate(controller.pageCount.clamp(0, 5).toInt(), (
                  index,
                ) {
                  final page = index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: _PageNumber(
                      page: page,
                      selected: page == controller.currentPage.value,
                      onTap: () => controller.goToPage(page),
                    ),
                  );
                }),
                _PaginationButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: controller.hasMore ? controller.nextPage : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  const _PaginationButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      height: 33,
      width: 33,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 19,
        color: onTap == null
            ? const Color(0xFFB1BDD0)
            : const Color(0xFF3A5F99),
      ),
    ),
  );
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      height: 33,
      width: 33,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2E6CF5) : const Color(0xFFF5F8FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${page + 1}',
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF3A5F99),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _EmployeeComposerPanel extends StatelessWidget {
  const _EmployeeComposerPanel({
    required this.listController,
    required this.formController,
  });

  final EmployeeListController listController;
  final EmployeeFormController formController;

  @override
  Widget build(BuildContext context) {
    return _EmployeeSurface(
      padding: EdgeInsets.zero,
      child: Obx(() {
        final readOnly = listController.isViewingEmployee;
        final title = switch (listController.composerMode.value) {
          EmployeeComposerMode.create => 'Add New Employee',
          EmployeeComposerMode.view => 'Employee Details',
          EmployeeComposerMode.edit => 'Edit Employee',
        };
        return Form(
          key: formController.formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 16, 11, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close employee panel',
                      onPressed: () => listController.closeComposer(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF526A92),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEAF0F7)),
              _ComposerTabs(listController: listController),
              const Divider(height: 1, color: Color(0xFFEAF0F7)),
              Padding(
                padding: const EdgeInsets.all(17),
                child: IndexedStack(
                  index: listController.composerTab.value,
                  children: [
                    _BasicTab(
                      formController: formController,
                      readOnly: readOnly,
                    ),
                    _PersonalTab(
                      formController: formController,
                      readOnly: readOnly,
                    ),
                    _EmploymentTab(
                      formController: formController,
                      readOnly: readOnly,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEAF0F7)),
              _ComposerFooter(
                listController: listController,
                formController: formController,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ComposerTabs extends StatelessWidget {
  const _ComposerTabs({required this.listController});

  final EmployeeListController listController;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (Icons.badge_outlined, 'Basic Info'),
      (Icons.person_outline_rounded, 'Personal'),
      (Icons.business_center_outlined, 'Employment'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = listController.composerTab.value == index;
          return Expanded(
            child: InkWell(
              onTap: () => listController.selectComposerTab(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  children: [
                    Icon(
                      tab.$1,
                      size: 18,
                      color: selected
                          ? const Color(0xFF2465F4)
                          : const Color(0xFF7789A9),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: selected
                            ? const Color(0xFF2465F4)
                            : const Color(0xFF7083A5),
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 2,
                      color: selected
                          ? const Color(0xFF2465F4)
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BasicTab extends StatelessWidget {
  const _BasicTab({required this.formController, required this.readOnly});

  final EmployeeFormController formController;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Obx(() {
            final photo = formController.profilePhoto.value;
            return Column(
              children: [
                InkWell(
                  onTap: readOnly ? null : formController.pickProfilePhoto,
                  borderRadius: BorderRadius.circular(46),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xFFEAF0FA),
                    backgroundImage: photo?.bytes != null
                        ? MemoryImage(photo!.bytes!)
                        : formController.existingPhotoUrl.value?.isNotEmpty ==
                              true
                        ? NetworkImage(formController.existingPhotoUrl.value!)
                        : null,
                    child:
                        photo == null &&
                            formController.existingPhotoUrl.value?.isNotEmpty !=
                                true
                        ? const Icon(
                            Icons.add_a_photo_outlined,
                            color: Color(0xFF6980AA),
                            size: 31,
                          )
                        : null,
                  ),
                ),
                if (!readOnly) ...[
                  const SizedBox(height: 7),
                  TextButton.icon(
                    onPressed: photo == null
                        ? formController.pickProfilePhoto
                        : formController.clearProfilePhoto,
                    icon: Icon(
                      photo == null
                          ? Icons.upload_outlined
                          : Icons.close_rounded,
                      size: 16,
                    ),
                    label: Text(
                      photo == null
                          ? 'Upload Profile Photo'
                          : 'Remove selected photo',
                    ),
                  ),
                  const Text(
                    'JPG or PNG (max 2 MB)',
                    style: TextStyle(color: Color(0xFF7083A6), fontSize: 10),
                  ),
                ],
              ],
            );
          }),
        ),
        const SizedBox(height: 17),
        const _FieldLabel('Full Name *'),
        TextFormField(
          controller: formController.fullNameController,
          readOnly: readOnly,
          decoration: const InputDecoration(hintText: 'Enter full name'),
          validator: formController.validateFullName,
        ),
        const SizedBox(height: 13),
        const _FieldLabel('Email Address *'),
        TextFormField(
          controller: formController.emailController,
          readOnly: readOnly,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'employee@company.com'),
          validator: formController.validateEmail,
        ),
        const SizedBox(height: 13),
        _TwoFields(
          first: _LabeledInput(
            label: 'Department *',
            controller: formController.departmentController,
            hint: 'Select or enter department',
            validator: formController.validateDepartment,
            readOnly: readOnly,
          ),
          second: _LabeledInput(
            label: 'Position *',
            controller: formController.jobTitleController,
            hint: 'Enter position',
            validator: formController.validatePosition,
            readOnly: readOnly,
          ),
        ),
        const SizedBox(height: 13),
        const _FieldLabel('Contact Number *'),
        TextFormField(
          controller: formController.contactController,
          readOnly: readOnly,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '+966 501234567'),
          validator: formController.validateContact,
        ),
      ],
    );
  }
}

class _PersonalTab extends StatelessWidget {
  const _PersonalTab({required this.formController, required this.readOnly});

  final EmployeeFormController formController;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => Obx(() {
    final showTemporaryPassword = !formController.isEditMode.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTemporaryPassword) ...[
          const _FieldLabel('Temporary Password *'),
          TextFormField(
            controller: formController.temporaryPasswordController,
            obscureText: true,
            readOnly: readOnly,
            decoration: const InputDecoration(
              hintText: 'Set a secure temporary password',
            ),
            validator: readOnly
                ? null
                : formController.validateTemporaryPassword,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              'The employee can reset this after first sign-in.',
              style: TextStyle(fontSize: 10, color: Color(0xFF7184A5)),
            ),
          ),
          const SizedBox(height: 13),
        ],
        _TwoFields(
          first: _LabeledInput(
            label: 'Nationality',
            controller: formController.nationalityController,
            hint: 'e.g. Saudi',
            readOnly: readOnly,
          ),
          second: _DateField(
            label: 'Date of Birth',
            value: formController.dateOfBirth,
            onTap: readOnly
                ? null
                : () => formController.pickDateOfBirth(context),
          ),
        ),
        const SizedBox(height: 13),
        const _FieldLabel('CNIC / Passport Number'),
        TextFormField(
          controller: formController.cnicController,
          readOnly: readOnly,
          decoration: const InputDecoration(
            hintText: 'Enter identification number',
          ),
        ),
        const SizedBox(height: 13),
        const _FieldLabel('Residential Address'),
        TextFormField(
          controller: formController.addressController,
          readOnly: readOnly,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter current address'),
        ),
      ],
    );
  });
}

class _EmploymentTab extends StatelessWidget {
  const _EmploymentTab({required this.formController, required this.readOnly});

  final EmployeeFormController formController;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('Employment Type *'),
        Obx(
          () => DropdownButtonFormField<EmploymentType>(
            key: ValueKey(formController.employmentType.value),
            initialValue: formController.employmentType.value,
            decoration: const InputDecoration(
              hintText: 'Select employment type',
            ),
            items: EmploymentType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            validator: (value) =>
                value == null ? 'Employment type is required.' : null,
            onChanged: readOnly
                ? null
                : (value) => formController.employmentType.value = value,
          ),
        ),
        const SizedBox(height: 13),
        _TwoFields(
          first: _StatusPicker(
            formController: formController,
            readOnly: readOnly,
          ),
          second: _DateField(
            label: 'Joining Date',
            value: formController.joiningDate,
            onTap: readOnly
                ? null
                : () => formController.pickJoiningDate(context),
          ),
        ),
        const SizedBox(height: 13),
        const _FieldLabel('Monthly Salary (restricted)'),
        TextFormField(
          controller: formController.salaryController,
          readOnly: readOnly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: 'SAR ',
            hintText: 'Optional',
          ),
        ),
        const SizedBox(height: 13),
        _LabeledInput(
          label: 'Bank Name',
          controller: formController.bankNameController,
          hint: 'Enter bank name',
          readOnly: readOnly,
        ),
        const SizedBox(height: 13),
        _LabeledInput(
          label: 'Account Title',
          controller: formController.accountTitleController,
          hint: 'Enter account title',
          readOnly: readOnly,
        ),
        const SizedBox(height: 13),
        _TwoFields(
          first: _LabeledInput(
            label: 'Account Number',
            controller: formController.accountNumberController,
            hint: 'Enter account number',
            readOnly: readOnly,
          ),
          second: _LabeledInput(
            label: 'IBAN',
            controller: formController.ibanController,
            hint: 'Enter IBAN',
            readOnly: readOnly,
          ),
        ),
      ],
    );
  }
}

class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.formController, required this.readOnly});

  final EmployeeFormController formController;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Employment Status *'),
        Obx(
          () => DropdownButtonFormField<EmploymentStatus>(
            key: ValueKey(formController.employmentStatus.value),
            initialValue: formController.employmentStatus.value,
            decoration: const InputDecoration(),
            items: EmploymentStatus.values
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  ),
                )
                .toList(),
            onChanged: readOnly
                ? null
                : (value) {
                    if (value != null) {
                      formController.employmentStatus.value = value;
                    }
                  },
          ),
        ),
      ],
    );
  }
}

class _ComposerFooter extends StatelessWidget {
  const _ComposerFooter({
    required this.listController,
    required this.formController,
  });

  final EmployeeListController listController;
  final EmployeeFormController formController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Obx(() {
        final onLastTab = listController.composerTab.value == 2;
        final isViewing = listController.isViewingEmployee;
        final isEditing = listController.isEditingEmployee;
        final selected = listController.selectedEmployee.value;
        return Row(
          children: [
            if (listController.composerTab.value > 0)
              IconButton(
                tooltip: 'Previous section',
                onPressed: () => listController.selectComposerTab(
                  listController.composerTab.value - 1,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            const Spacer(),
            TextButton(
              onPressed: () {
                if (isEditing && selected != null) {
                  formController.loadForEmployee(selected);
                  listController.showSelectedEmployee();
                  return;
                }
                formController.resetForCreate();
                listController.closeComposer();
              },
              child: Text(isViewing ? 'Close' : 'Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: isViewing
                  ? listController.editSelectedEmployee
                  : formController.isLoading.value
                  ? null
                  : () async {
                      if (!onLastTab) {
                        listController.selectComposerTab(
                          listController.composerTab.value + 1,
                        );
                        return;
                      }
                      final saved = await formController.submit();
                      if (!saved) return;
                      if (isEditing) {
                        listController.showSelectedEmployee();
                        return;
                      }
                      formController.resetForCreate();
                      listController.closeComposer();
                    },
              icon: formController.isLoading.value
                  ? const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isViewing
                          ? Icons.edit_outlined
                          : onLastTab
                          ? isEditing
                                ? Icons.save_outlined
                                : Icons.person_add_alt_1_rounded
                          : Icons.arrow_forward_rounded,
                    ),
              label: Text(
                isViewing
                    ? 'Edit'
                    : onLastTab
                    ? isEditing
                          ? 'Save Changes'
                          : 'Create'
                    : 'Next',
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label),
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(hintText: hint),
        validator: validator,
      ),
    ],
  );
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, this.onTap});

  final String label;
  final Rxn<DateTime> value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label),
      Obx(
        () => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: onTap == null ? const Color(0xFF92A2BB) : null,
              ),
            ),
            child: Text(
              value.value == null
                  ? 'Select date'
                  : DateFormat('dd MMM y').format(value.value!),
              style: TextStyle(
                fontSize: 12,
                color: value.value == null
                    ? const Color(0xFF8B9AB5)
                    : const Color(0xFF1A2D50),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _TwoFields extends StatelessWidget {
  const _TwoFields({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 330) {
          return Column(children: [first, const SizedBox(height: 13), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _EmployeeSurface extends StatelessWidget {
  const _EmployeeSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09183663),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
