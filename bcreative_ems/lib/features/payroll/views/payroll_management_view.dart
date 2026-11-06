import 'dart:ui' show PointerDeviceKind;

import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/core/widgets/app_loading.dart';
import 'package:bcreative_ems/core/widgets/header_action_layout.dart';
import 'package:bcreative_ems/core/widgets/page_intro.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/payroll/models/payroll_record_model.dart';
import 'package:bcreative_ems/features/payroll/viewmodels/payroll_controller.dart';
import 'package:bcreative_ems/features/shell/views/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PayrollManagementView extends GetView<PayrollController> {
  const PayrollManagementView({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Payroll',
    body: Obx(
      () => controller.isLoading.value
          ? const AppLoading()
          : _PayrollContent(controller: controller),
    ),
  );
}

class _PayrollContent extends StatelessWidget {
  const _PayrollContent({required this.controller});
  final PayrollController controller;

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
                _PayrollHeader(controller: controller),
                const SizedBox(height: 18),
                _PayrollStatCards(controller: controller),
                const SizedBox(height: 14),
                _PayrollRecordsLayout(controller: controller),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PayrollHeader extends StatelessWidget {
  const _PayrollHeader({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) => HeaderActionLayout(
    heading: const PageIntro(
      icon: Icons.account_balance_wallet_rounded,
      description: 'Manage employee payroll records and payment status.',
      iconSize: 28,
    ),
    action: Obx(
      () => FilledButton.icon(
        onPressed: controller.isCreating.value
            ? null
            : controller.openCreatePayroll,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          backgroundColor: const Color(0xFF2468F2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: controller.isCreating.value
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add_rounded),
        label: const Text('Create Payroll'),
      ),
    ),
  );
}

class _PayrollStatCards extends StatelessWidget {
  const _PayrollStatCards({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Obx(() {
      final cards = [
        _PayrollStatCard(
          icon: Icons.groups_rounded,
          label: 'Total Employees',
          value: '${controller.totalEmployees}',
          caption: 'All active employees',
          color: const Color(0xFF2E6CF6),
          background: const Color(0xFFE8F0FF),
        ),
        _PayrollStatCard(
          icon: Icons.payments_rounded,
          label: 'Total Payroll',
          value: _money(controller.totalPayroll),
          caption: controller.displayMonth,
          color: const Color(0xFF10B979),
          background: const Color(0xFFE0F9EE),
        ),
        _PayrollStatCard(
          icon: Icons.receipt_long_rounded,
          label: 'Paid Employees',
          value: '${controller.paidEmployees}',
          caption: _percent(
            controller.paidEmployees,
            controller.totalEmployees,
          ),
          color: const Color(0xFF9146F5),
          background: const Color(0xFFF1E6FF),
        ),
        _PayrollStatCard(
          icon: Icons.description_outlined,
          label: 'Salary Slips',
          value: '${controller.salarySlipCount}',
          caption: 'Attached to paid payrolls',
          color: const Color(0xFFFF8616),
          background: const Color(0xFFFFECDC),
        ),
        _PayrollStatCard(
          icon: Icons.money_off_csred_outlined,
          label: 'Total Deductions',
          value: _money(controller.totalDeductions),
          caption: 'Tax, loans, other deductions',
          color: const Color(0xFFFF4960),
          background: const Color(0xFFFFE8ED),
        ),
      ];
      if (constraints.maxWidth >= 980) {
        return Row(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      }
      return GridView.count(
        crossAxisCount: constraints.maxWidth >= 720 ? 3 : 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: constraints.maxWidth >= 720 ? 2.9 : 3.6,
        children: cards,
      );
    }),
  );
}

class _PayrollStatCard extends StatelessWidget {
  const _PayrollStatCard({
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
  Widget build(BuildContext context) => _PayrollSurface(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
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
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
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

class _PayrollRecordsLayout extends StatelessWidget {
  const _PayrollRecordsLayout({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final records = _PayrollSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PayrollFilterBar(controller: controller, embedded: true),
            const Divider(height: 1, color: Color(0xFFE9EFF8)),
            _PayrollDirectory(controller: controller, embedded: true),
          ],
        ),
      );
      final details = _PayrollDetails(controller: controller);

      // Keep the filter and employee records together in the left working
      // column. The selected-record or create-payroll panel remains beside it.
      // A typical desktop workspace can be about 1,000 logical pixels wide
      // after the permanent sidebar and page padding. Keep the detail panel
      // beside records at that size; only stack it for tablet/mobile widths.
      if (constraints.maxWidth >= 900) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: records),
            const SizedBox(width: 14),
            SizedBox(width: 350, child: details),
          ],
        );
      }
      return Column(children: [records, const SizedBox(height: 14), details]);
    },
  );
}

class _PayrollFilterBar extends StatelessWidget {
  const _PayrollFilterBar({required this.controller, this.embedded = false});
  final PayrollController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Obx(
      () => Wrap(
        alignment: WrapAlignment.start,
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          _PayrollSearchField(controller: controller),
          _MonthFilter(controller: controller),
          _PayrollDropdown<String>(
            label: 'Department',
            width: 148,
            value: controller.departmentFilter.value,
            allLabel: 'All Departments',
            values: controller.departments,
            onChanged: controller.setDepartmentFilter,
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
    return _PayrollSurface(padding: const EdgeInsets.all(12), child: content);
  }
}

class _PayrollSearchField extends StatelessWidget {
  const _PayrollSearchField({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 270,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Search payroll', style: _fieldLabel),
        const SizedBox(height: 5),
        SizedBox(
          height: 39,
          child: TextField(
            controller: controller.searchController,
            onChanged: controller.setQuery,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Name, ID, department...',
              hintStyle: const TextStyle(fontSize: 11),
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              filled: true,
              fillColor: const Color(0xFFF4F7FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDE6F4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDE6F4)),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MonthFilter extends StatelessWidget {
  const _MonthFilter({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payroll Month', style: _fieldLabel),
          const SizedBox(height: 5),
          Container(
            height: 39,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: _fieldDecoration,
            child: Row(
              children: [
                IconButton(
                  onPressed: controller.previousMonth,
                  iconSize: 18,
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    controller.displayMonth,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: controller.nextMonth,
                  iconSize: 18,
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PayrollDropdown<T> extends StatelessWidget {
  const _PayrollDropdown({
    required this.label,
    required this.value,
    required this.allLabel,
    required this.values,
    required this.onChanged,
    required this.width,
    this.labelFor,
  });
  final String label;
  final T? value;
  final String allLabel;
  final List<T> values;
  final ValueChanged<T?> onChanged;
  final double width;
  final String Function(T value)? labelFor;

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

class _PayrollDirectory extends StatelessWidget {
  const _PayrollDirectory({required this.controller, this.embedded = false});
  final PayrollController controller;
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
                  'Employee Payroll Records',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              if (MediaQuery.sizeOf(context).width < 900)
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
          if (controller.visibleItems.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(45),
              child: Text('No payroll records match the selected filters.'),
            );
          }
          return _PayrollTable(controller: controller);
        }),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        _PayrollPagination(controller: controller),
      ],
    );
    return embedded
        ? content
        : _PayrollSurface(padding: EdgeInsets.zero, child: content);
  }
}

class _PayrollTable extends StatelessWidget {
  const _PayrollTable({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : 980.0;
      final width = availableWidth < 980 ? 980.0 : availableWidth;
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
                  const _PayrollTableHeader(),
                  ...controller.visibleItems.map(
                    (item) =>
                        _PayrollTableRow(controller: controller, item: item),
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

class _PayrollTableHeader extends StatelessWidget {
  const _PayrollTableHeader();
  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    color: const Color(0xFFF5F8FD),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: const Row(
      children: [
        SizedBox(
          width: 28,
          child: Icon(Icons.check_box_outline_blank, size: 17),
        ),
        Expanded(flex: 26, child: _PayrollHeaderLabel('EMPLOYEE')),
        Expanded(flex: 12, child: _PayrollHeaderLabel('EMP ID')),
        Expanded(flex: 16, child: _PayrollHeaderLabel('DEPARTMENT')),
        Expanded(flex: 14, child: _PayrollHeaderLabel('BASIC SALARY')),
        Expanded(flex: 13, child: _PayrollHeaderLabel('ALLOWANCES')),
        Expanded(flex: 13, child: _PayrollHeaderLabel('DEDUCTIONS')),
        Expanded(flex: 14, child: _PayrollHeaderLabel('NET SALARY')),
        Expanded(flex: 13, child: _PayrollHeaderLabel('STATUS')),
      ],
    ),
  );
}

class _PayrollHeaderLabel extends StatelessWidget {
  const _PayrollHeaderLabel(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Text(
    value,
    style: const TextStyle(
      fontSize: 9,
      color: Color(0xFF50658B),
      fontWeight: FontWeight.w700,
    ),
  );
}

class _PayrollTableRow extends StatelessWidget {
  const _PayrollTableRow({required this.controller, required this.item});
  final PayrollController controller;
  final PayrollListItem item;

  @override
  Widget build(BuildContext context) => Obx(() {
    final selected = controller.selectedEmployeeId.value == item.employee.id;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.selectItem(item),
      child: Container(
        height: 61,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        color: selected ? const Color(0xFFF6F9FF) : null,
        child: Row(
          children: [
            const SizedBox(
              width: 28,
              child: Icon(
                Icons.check_box_outline_blank,
                color: Color(0xFF9BAECC),
                size: 17,
              ),
            ),
            Expanded(
              flex: 26,
              child: _PayrollEmployeeCell(employee: item.employee),
            ),
            Expanded(
              flex: 12,
              child: _PayrollValue(item.employee.employeeCode),
            ),
            Expanded(
              flex: 16,
              child: _DepartmentTag(value: item.employee.department ?? '—'),
            ),
            Expanded(flex: 14, child: _PayrollValue(_money(item.basicSalary))),
            Expanded(
              flex: 13,
              child: _PayrollValue(_money(item.totalAllowances)),
            ),
            Expanded(
              flex: 13,
              child: _PayrollValue(_money(item.totalDeductions)),
            ),
            Expanded(
              flex: 14,
              child: _PayrollValue(_money(item.netSalary), emphasis: true),
            ),
            Expanded(
              flex: 13,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _PayrollStatusChip(status: item.status),
              ),
            ),
          ],
        ),
      ),
    );
  });
}

class _PayrollEmployeeCell extends StatelessWidget {
  const _PayrollEmployeeCell({required this.employee});
  final EmployeeModel employee;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFFE8F0FF),
        foregroundImage: employee.displayPhotoUrl?.isNotEmpty == true
            ? NetworkImage(employee.displayPhotoUrl!)
            : null,
        child: Text(
          _initials(employee.fullName),
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF2E6CF6),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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
              employee.jobTitle ?? 'Employee',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Color(0xFF7185A8)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _PayrollValue extends StatelessWidget {
  const _PayrollValue(this.value, {this.emphasis = false});
  final String value;
  final bool emphasis;
  @override
  Widget build(BuildContext context) => Text(
    value,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: 11,
      color: emphasis ? const Color(0xFF182448) : const Color(0xFF40567E),
      fontWeight: emphasis ? FontWeight.w800 : FontWeight.w500,
    ),
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
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF2468F2),
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _PayrollStatusChip extends StatelessWidget {
  const _PayrollStatusChip({required this.status});
  final PayrollStatus? status;
  @override
  Widget build(BuildContext context) {
    final created = status != null;
    final color = created ? const Color(0xFF0FAF70) : const Color(0xFF7185A8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        created ? PayrollStatus.paid.label : 'Not Created',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PayrollPagination extends StatelessWidget {
  const _PayrollPagination({required this.controller});
  final PayrollController controller;
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
            'Showing ${controller.showingStart} to ${controller.showingEnd} of ${controller.filteredItems.length} employees',
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
                    height: 34,
                    width: 34,
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

class _PayrollDetails extends StatelessWidget {
  const _PayrollDetails({required this.controller});
  final PayrollController controller;
  @override
  Widget build(BuildContext context) => _PayrollSurface(
    padding: EdgeInsets.zero,
    child: Obx(() {
      if (controller.isCreatePanelOpen.value) {
        return _CreatePayrollPanel(controller: controller);
      }
      final item = controller.selectedItem;
      if (item == null) {
        return const Padding(
          padding: EdgeInsets.all(28),
          child: Center(
            child: Text('Select an employee to view payroll details.'),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Payroll Details',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: controller.resetFilters,
                  tooltip: 'Reset filters',
                  icon: const Icon(Icons.refresh_rounded, size: 19),
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
                  children: [
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: const Color(0xFFE8F0FF),
                      foregroundImage:
                          item.employee.displayPhotoUrl?.isNotEmpty == true
                          ? NetworkImage(item.employee.displayPhotoUrl!)
                          : null,
                      child: Text(
                        _initials(item.employee.fullName),
                        style: const TextStyle(
                          color: Color(0xFF2468F2),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.employee.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            item.employee.employeeCode,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF61769A),
                            ),
                          ),
                          Text(
                            item.employee.jobTitle ?? 'Employee',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF61769A),
                            ),
                          ),
                          Text(
                            item.employee.department ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF61769A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PayrollStatusChip(status: item.status),
                  ],
                ),
                const SizedBox(height: 16),
                _PayrollDetailTabs(controller: controller),
                if (controller.detailTab.value == 'payroll') ...[
                  const SizedBox(height: 14),
                  _DetailMonthHeader(controller: controller),
                  const SizedBox(height: 10),
                  _DetailLine(
                    icon: Icons.account_balance_outlined,
                    label: 'Basic Salary',
                    value: _money(item.basicSalary),
                  ),
                  _DetailLine(
                    icon: Icons.home_outlined,
                    label: 'House Allowance',
                    value: _money(item.houseAllowance),
                  ),
                  _DetailLine(
                    icon: Icons.directions_car_outlined,
                    label: 'Transport Allowance',
                    value: _money(item.transportAllowance),
                  ),
                  _DetailLine(
                    icon: Icons.add_circle_outline,
                    label: 'Other Allowances',
                    value: _money(item.otherAllowances),
                  ),
                  _DetailTotal(
                    label: 'Total Allowances',
                    value: _money(item.totalAllowances),
                    color: const Color(0xFF0FAF70),
                  ),
                  const SizedBox(height: 8),
                  _DetailLine(
                    icon: Icons.receipt_long_outlined,
                    label: 'Tax Deduction',
                    value: _money(item.taxDeduction),
                    negative: true,
                  ),
                  _DetailLine(
                    icon: Icons.payments_outlined,
                    label: 'Loan Deduction',
                    value: _money(item.loanDeduction),
                    negative: true,
                  ),
                  _DetailLine(
                    icon: Icons.remove_circle_outline,
                    label: 'Other Deductions',
                    value: _money(item.otherDeductions),
                    negative: true,
                  ),
                  _DetailTotal(
                    label: 'Total Deductions',
                    value: _money(item.totalDeductions),
                    color: const Color(0xFFFF4960),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Net Salary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2468F2),
                            ),
                          ),
                        ),
                        Text(
                          _money(item.netSalary),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2468F2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: item.record != null
                          ? const Color(0xFFE1FAEE)
                          : const Color(0xFFF1F4F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Payment Status',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _PayrollStatusChip(status: item.status),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  _PayrollSlipDetails(controller: controller, item: item),
                ],
              ],
            ),
          ),
        ],
      );
    }),
  );
}

class _PayrollDetailTabs extends StatelessWidget {
  const _PayrollDetailTabs({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) {
    final active = controller.detailTab.value;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PayrollDetailTabButton(
              label: 'Payroll',
              icon: Icons.account_balance_wallet_outlined,
              active: active == 'payroll',
              onTap: () => controller.setDetailTab('payroll'),
            ),
          ),
          Expanded(
            child: _PayrollDetailTabButton(
              label: 'Salary Slip',
              icon: Icons.description_outlined,
              active: active == 'slip',
              onTap: () => controller.setDetailTab('slip'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollDetailTabButton extends StatelessWidget {
  const _PayrollDetailTabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      foregroundColor: active
          ? const Color(0xFF2468F2)
          : const Color(0xFF60749A),
      backgroundColor: active ? Colors.white : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
    icon: Icon(icon, size: 16),
    label: Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _PayrollSlipDetails extends StatelessWidget {
  const _PayrollSlipDetails({required this.controller, required this.item});
  final PayrollController controller;
  final PayrollListItem item;

  @override
  Widget build(BuildContext context) {
    final record = item.record;
    if (record == null) {
      return const _PayrollSlipEmpty(
        title: 'No payroll for this month',
        message: 'Create a paid payroll record before adding its salary slip.',
      );
    }
    if (!record.hasSalarySlip) {
      return const _PayrollSlipEmpty(
        title: 'No salary slip attached',
        message: 'No salary slip was attached when this payroll was created.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2EE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFFE7503E),
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.slipFileName ?? 'Salary Slip',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      controller.displayMonth,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF60749A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => FilledButton.icon(
            onPressed: controller.isOpeningSlip.value
                ? null
                : controller.previewSelectedSalarySlip,
            icon: controller.isOpeningSlip.value
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.visibility_outlined),
            label: const Text('Preview Salary Slip'),
          ),
        ),
      ],
    );
  }
}

class _PayrollSlipEmpty extends StatelessWidget {
  const _PayrollSlipEmpty({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F9FD),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2EAF6)),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.description_outlined,
          size: 34,
          color: Color(0xFF7185A8),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Color(0xFF60749A)),
        ),
      ],
    ),
  );
}

class _CreatePayrollPanel extends StatelessWidget {
  const _CreatePayrollPanel({required this.controller});

  final PayrollController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final step = controller.createStep.value;
    // This scoped read refreshes only the wizard summary when an amount field
    // changes, rather than rebuilding the directory table.
    controller.draftRevision.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Create Payroll',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: controller.closeCreatePayroll,
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 14, 13, 8),
          child: _CreatePayrollSteps(currentStep: step),
        ),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step == 1) _CreateEmployeeStep(controller: controller),
              if (step == 2) _CreateSalaryStep(controller: controller),
              if (step == 3) _CreateDeductionStep(controller: controller),
              if (step == 4) _CreatePreviewStep(controller: controller),
              if (step == 5) _CreateSalarySlipStep(controller: controller),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9EFF8)),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: step == 1
                      ? controller.closeCreatePayroll
                      : controller.previousCreateStep,
                  child: Text(step == 1 ? 'Cancel' : 'Back'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.isCreating.value
                      ? null
                      : step == 5
                      ? controller.saveDraftPayroll
                      : controller.nextCreateStep,
                  icon: controller.isCreating.value
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          step == 5
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(step == 5 ? 'Create Payroll' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  });
}

class _CreatePayrollSteps extends StatelessWidget {
  const _CreatePayrollSteps({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Employee', 'Salary', 'Deductions', 'Preview', 'Slip'];
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          _CreateStepDot(
            number: index + 1,
            label: labels[index],
            active: currentStep == index + 1,
            complete: currentStep > index + 1,
          ),
          if (index != labels.length - 1)
            Expanded(
              child: Container(
                height: 1,
                color: currentStep > index + 1
                    ? const Color(0xFF2468F2)
                    : const Color(0xFFDDE6F4),
              ),
            ),
        ],
      ],
    );
  }
}

class _CreateStepDot extends StatelessWidget {
  const _CreateStepDot({
    required this.number,
    required this.label,
    required this.active,
    required this.complete,
  });
  final int number;
  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        height: 22,
        width: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active || complete ? const Color(0xFF2468F2) : Colors.white,
          border: Border.all(
            color: active || complete
                ? const Color(0xFF2468F2)
                : const Color(0xFFBFCDE6),
          ),
        ),
        child: Text(
          complete ? '✓' : '$number',
          style: TextStyle(
            color: active || complete ? Colors.white : const Color(0xFF7185A8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: active ? const Color(0xFF2468F2) : const Color(0xFF7185A8),
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ],
  );
}

class _CreateEmployeeStep extends StatelessWidget {
  const _CreateEmployeeStep({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) {
    final employee = controller.draftEmployee;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Select Employee & Period',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const _CreateFieldLabel('Employee *'),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: controller.draftEmployeeId.value,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          ),
          items: controller.activeEmployees
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(
                    '${item.fullName} (${item.employeeCode})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: controller.setDraftEmployee,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ReadonlyCreateField(
                label: 'Payroll Month *',
                value: controller.displayMonth,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ReadonlyCreateField(
                label: 'Payment Date *',
                value: 'End of month',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ReadonlyCreateField(
                label: 'Employment Type',
                value: employee?.employmentType?.label ?? 'Full Time',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _ReadonlyCreateField(label: 'Working Days', value: '22'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CreateSalaryStep extends StatelessWidget {
  const _CreateSalaryStep({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '2. Salary Details',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      _CreateAmountRow(
        left: _CreateAmountField(
          label: 'Basic Salary (SAR) *',
          controller: controller.basicSalaryController,
          onChanged: (_) => controller.refreshDraft(),
        ),
        right: _CreateAmountField(
          label: 'Overtime (SAR)',
          controller: controller.overtimeController,
          onChanged: (_) => controller.refreshDraft(),
        ),
      ),
      const SizedBox(height: 10),
      _CreateAmountRow(
        left: _CreateAmountField(
          label: 'House Allowance (SAR)',
          controller: controller.houseAllowanceController,
          onChanged: (_) => controller.refreshDraft(),
        ),
        right: _CreateAmountField(
          label: 'Transport Allowance (SAR)',
          controller: controller.transportAllowanceController,
          onChanged: (_) => controller.refreshDraft(),
        ),
      ),
      const SizedBox(height: 10),
      _CreateAmountField(
        label: 'Other Allowances (SAR)',
        controller: controller.otherAllowancesController,
        onChanged: (_) => controller.refreshDraft(),
      ),
    ],
  );
}

class _CreateDeductionStep extends StatelessWidget {
  const _CreateDeductionStep({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '3. Deductions',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      _CreateAmountRow(
        left: _CreateAmountField(
          label: 'Tax Deduction (SAR)',
          controller: controller.taxDeductionController,
          onChanged: (_) => controller.refreshDraft(),
        ),
        right: _CreateAmountField(
          label: 'Loan Deduction (SAR)',
          controller: controller.loanDeductionController,
          onChanged: (_) => controller.refreshDraft(),
        ),
      ),
      const SizedBox(height: 10),
      _CreateAmountField(
        label: 'Other Deductions (SAR)',
        controller: controller.otherDeductionsController,
        onChanged: (_) => controller.refreshDraft(),
      ),
    ],
  );
}

class _CreateSalarySlipStep extends StatelessWidget {
  const _CreateSalarySlipStep({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) {
    final file = controller.draftSlipFile.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '5. Attach Salary Slip',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        const Text(
          'Optionally attach the salary slip for this paid payroll record.',
          style: TextStyle(fontSize: 11, color: Color(0xFF60749A)),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: file == null
                ? const Color(0xFFF7F9FD)
                : const Color(0xFFEAF8F1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: file == null
                  ? const Color(0xFFE0E8F5)
                  : const Color(0xFFBCECD4),
            ),
          ),
          child: Column(
            children: [
              Icon(
                file == null
                    ? Icons.upload_file_outlined
                    : Icons.description_rounded,
                size: 34,
                color: file == null
                    ? const Color(0xFF60749A)
                    : const Color(0xFF0FAF70),
              ),
              const SizedBox(height: 8),
              Text(
                file?.name ?? 'No salary slip selected',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                file == null
                    ? 'Optional: PDF, PNG, or JPG up to 10 MB'
                    : '${(file.size / 1024).toStringAsFixed(1)} KB selected',
                style: const TextStyle(fontSize: 10, color: Color(0xFF60749A)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: controller.pickDraftSalarySlip,
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: Text(
                  file == null ? 'Choose Salary Slip' : 'Choose Another',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreatePreviewStep extends StatelessWidget {
  const _CreatePreviewStep({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) {
    final employee = controller.draftEmployee;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('4. Summary', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _DetailLine(
          icon: Icons.person_outline,
          label: employee?.fullName ?? 'Employee',
          value: controller.displayMonth,
        ),
        _DetailLine(
          icon: Icons.account_balance_outlined,
          label: 'Basic Salary',
          value: _money(controller.draftBasicSalary),
        ),
        _DetailTotal(
          label: 'Total Allowances',
          value: _money(controller.draftTotalAllowances),
          color: const Color(0xFF0FAF70),
        ),
        const SizedBox(height: 8),
        _DetailTotal(
          label: 'Total Deductions',
          value: _money(controller.draftTotalDeductions),
          color: const Color(0xFFFF4960),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Net Salary',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2468F2),
                  ),
                ),
              ),
              Text(
                _money(controller.draftNetSalary),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2468F2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateAmountRow extends StatelessWidget {
  const _CreateAmountRow({required this.left, required this.right});
  final Widget left;
  final Widget right;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: left),
      const SizedBox(width: 10),
      Expanded(child: right),
    ],
  );
}

class _CreateAmountField extends StatelessWidget {
  const _CreateAmountField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _CreateFieldLabel(label),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    ],
  );
}

class _ReadonlyCreateField extends StatelessWidget {
  const _ReadonlyCreateField({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _CreateFieldLabel(label),
      const SizedBox(height: 5),
      Container(
        height: 39,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6FB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF60749A)),
        ),
      ),
    ],
  );
}

class _CreateFieldLabel extends StatelessWidget {
  const _CreateFieldLabel(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Text(
    value,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF263B62),
    ),
  );
}

class _DetailMonthHeader extends StatelessWidget {
  const _DetailMonthHeader({required this.controller});
  final PayrollController controller;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE3EAF6)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.calendar_month_outlined,
          size: 18,
          color: Color(0xFF2468F2),
        ),
        const SizedBox(width: 8),
        Text(
          controller.displayMonth,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.negative = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool negative;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: negative ? const Color(0xFFFF4960) : const Color(0xFF6078A3),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF40567E)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _DetailTotal extends StatelessWidget {
  const _DetailTotal({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PayrollSurface extends StatelessWidget {
  const _PayrollSurface({
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

const _fieldLabel = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: Color(0xFF3C5178),
);
const _fieldDecoration = BoxDecoration(
  border: Border.fromBorderSide(BorderSide(color: Color(0xFFDDE6F4))),
  borderRadius: BorderRadius.all(Radius.circular(8)),
);

String _money(double value) => 'SAR ${value.toStringAsFixed(0)}';
String _percent(int value, int total) => total == 0
    ? '0% of total'
    : '${(value * 100 / total).toStringAsFixed(1)}% of total';
String _initials(String value) {
  final letters = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join();
  return letters.isEmpty ? '?' : letters.toUpperCase();
}
