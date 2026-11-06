import 'dart:ui' show PointerDeviceKind;

import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/core/widgets/app_loading.dart';
import 'package:bcreative_ems/core/widgets/page_intro.dart';
import 'package:bcreative_ems/features/payroll/models/payroll_record_model.dart';
import 'package:bcreative_ems/features/payroll/viewmodels/employee_salary_controller.dart';
import 'package:bcreative_ems/features/shell/views/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmployeeSalaryView extends GetView<EmployeeSalaryController> {
  const EmployeeSalaryView({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'My Salary',
    body: Obx(
      () => controller.isLoading.value
          ? const AppLoading()
          : _EmployeeSalaryContent(controller: controller),
    ),
  );
}

class _EmployeeSalaryContent extends StatelessWidget {
  const _EmployeeSalaryContent({required this.controller});
  final EmployeeSalaryController controller;

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return ListView(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SalaryHeader(controller: controller),
                const SizedBox(height: 18),
                _SalarySummary(controller: controller),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final records = _SalarySurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SalaryMonthFilter(
                            controller: controller,
                            embedded: true,
                          ),
                          const Divider(height: 1, color: Color(0xFFE9EFF8)),
                          _SalaryRecords(
                            controller: controller,
                            embedded: true,
                          ),
                        ],
                      ),
                    );
                    final details = _EmployeeSalaryDetails(
                      controller: controller,
                    );
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

class _SalaryHeader extends StatelessWidget {
  const _SalaryHeader({required this.controller});
  final EmployeeSalaryController controller;

  @override
  Widget build(BuildContext context) => const PageIntro(
    icon: Icons.account_balance_wallet_rounded,
    description: 'Review your paid monthly salary records and salary slips.',
  );
}

class _SalarySummary extends StatelessWidget {
  const _SalarySummary({required this.controller});
  final EmployeeSalaryController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final cards = [
      _SalaryMetric(
        icon: Icons.receipt_long_rounded,
        label: 'Paid Records',
        value: '${controller.filteredRecords.length}',
        caption: controller.selectedMonthLabel,
        color: const Color(0xFF9146F5),
        background: const Color(0xFFF1E6FF),
      ),
      _SalaryMetric(
        icon: Icons.payments_rounded,
        label: 'Net Salary',
        value: _money(controller.totalPaid),
        caption: controller.selectedMonth.value == null
            ? 'All displayed months'
            : 'Selected month',
        color: const Color(0xFF10B979),
        background: const Color(0xFFE0F9EE),
      ),
      _SalaryMetric(
        icon: Icons.description_outlined,
        label: 'Salary Slips',
        value: '${controller.slipCount}',
        caption: 'Available to preview',
        color: const Color(0xFFFF8616),
        background: const Color(0xFFFFECDC),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
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
          crossAxisCount: constraints.maxWidth >= 460 ? 2 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth >= 460 ? 2.9 : 3.8,
          children: cards,
        );
      },
    );
  });
}

class _SalaryMetric extends StatelessWidget {
  const _SalaryMetric({
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
  Widget build(BuildContext context) => _SalarySurface(
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
                  fontSize: 11,
                  color: Color(0xFF40567E),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
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

class _SalaryMonthFilter extends StatelessWidget {
  const _SalaryMonthFilter({required this.controller, this.embedded = false});
  final EmployeeSalaryController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Obx(
      () => Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Salary Month', style: _salaryFieldLabel),
                const SizedBox(height: 5),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: _salaryFieldDecoration,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: controller.previousMonth,
                        tooltip: 'Previous month',
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          controller.selectedMonthLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: controller.nextMonth,
                        tooltip: 'Next month',
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: controller.showAllMonths,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: const Text('All Months'),
          ),
        ],
      ),
    );
    if (embedded) {
      return Padding(padding: const EdgeInsets.all(12), child: content);
    }
    return _SalarySurface(padding: const EdgeInsets.all(12), child: content);
  }
}

class _SalaryRecords extends StatelessWidget {
  const _SalaryRecords({required this.controller, this.embedded = false});
  final EmployeeSalaryController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Obx(() {
      final records = controller.filteredRecords;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Salary Records',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9EFF8)),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No paid salary record is available for this month.',
                ),
              ),
            )
          else
            _SalaryTable(controller: controller, records: records),
        ],
      );
    });
    return embedded
        ? content
        : _SalarySurface(padding: EdgeInsets.zero, child: content);
  }
}

class _SalaryTable extends StatelessWidget {
  const _SalaryTable({required this.controller, required this.records});
  final EmployeeSalaryController controller;
  final List<PayrollRecordModel> records;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : 760.0;
      final width = available < 760 ? 760.0 : available;
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
                  const _SalaryTableHeader(),
                  ...records.map(
                    (record) =>
                        _SalaryTableRow(controller: controller, record: record),
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

class _SalaryTableHeader extends StatelessWidget {
  const _SalaryTableHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 39,
    color: const Color(0xFFF5F8FD),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: const Row(
      children: [
        Expanded(flex: 19, child: _SalaryHeaderLabel('MONTH')),
        Expanded(flex: 17, child: _SalaryHeaderLabel('BASIC SALARY')),
        Expanded(flex: 17, child: _SalaryHeaderLabel('ALLOWANCES')),
        Expanded(flex: 17, child: _SalaryHeaderLabel('DEDUCTIONS')),
        Expanded(flex: 18, child: _SalaryHeaderLabel('NET SALARY')),
        Expanded(flex: 12, child: _SalaryHeaderLabel('STATUS')),
      ],
    ),
  );
}

class _SalaryHeaderLabel extends StatelessWidget {
  const _SalaryHeaderLabel(this.value);
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

class _SalaryTableRow extends StatelessWidget {
  const _SalaryTableRow({required this.controller, required this.record});
  final EmployeeSalaryController controller;
  final PayrollRecordModel record;

  @override
  Widget build(BuildContext context) => Obx(() {
    final selected = controller.selectedRecordId.value == record.id;
    return InkWell(
      onTap: () => controller.selectRecord(record),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F6FF) : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFE9EFF8))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 19,
              child: Text(
                _periodLabel(record.periodKey),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(flex: 17, child: _SalaryCell(_money(record.basicSalary))),
            Expanded(
              flex: 17,
              child: _SalaryCell(_money(record.totalAllowances)),
            ),
            Expanded(
              flex: 17,
              child: _SalaryCell(_money(record.totalDeductions)),
            ),
            Expanded(
              flex: 18,
              child: Text(
                _money(record.netSalary),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Expanded(flex: 12, child: _PaidChip()),
          ],
        ),
      ),
    );
  });
}

class _SalaryCell extends StatelessWidget {
  const _SalaryCell(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Text(
    value,
    style: const TextStyle(fontSize: 11, color: Color(0xFF40567E)),
  );
}

class _EmployeeSalaryDetails extends StatelessWidget {
  const _EmployeeSalaryDetails({required this.controller});
  final EmployeeSalaryController controller;

  @override
  Widget build(BuildContext context) => _SalarySurface(
    padding: EdgeInsets.zero,
    child: Obx(() {
      final record = controller.selectedRecord;
      if (record == null) {
        return const Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: Text('Select a salary record to view details.')),
        );
      }
      final slipTab = controller.detailTab.value == 'slip';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Salary Details',
              style: TextStyle(fontWeight: FontWeight.w800),
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
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: Color(0xFF2468F2),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _periodLabel(record.periodKey),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const _PaidChip(),
                  ],
                ),
                const SizedBox(height: 15),
                _EmployeeDetailTabs(controller: controller, slipTab: slipTab),
                const SizedBox(height: 14),
                if (slipTab)
                  _EmployeeSlipPreview(controller: controller, record: record)
                else
                  _EmployeeSalaryBreakdown(record: record),
              ],
            ),
          ),
        ],
      );
    }),
  );
}

class _EmployeeDetailTabs extends StatelessWidget {
  const _EmployeeDetailTabs({required this.controller, required this.slipTab});
  final EmployeeSalaryController controller;
  final bool slipTab;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF4F7FC),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Expanded(
          child: _EmployeeDetailTab(
            label: 'Salary',
            icon: Icons.account_balance_wallet_outlined,
            active: !slipTab,
            onTap: () => controller.setDetailTab('salary'),
          ),
        ),
        Expanded(
          child: _EmployeeDetailTab(
            label: 'Salary Slip',
            icon: Icons.description_outlined,
            active: slipTab,
            onTap: () => controller.setDetailTab('slip'),
          ),
        ),
      ],
    ),
  );
}

class _EmployeeDetailTab extends StatelessWidget {
  const _EmployeeDetailTab({
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

class _EmployeeSalaryBreakdown extends StatelessWidget {
  const _EmployeeSalaryBreakdown({required this.record});
  final PayrollRecordModel record;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _SalaryDetailLine(
        icon: Icons.account_balance_outlined,
        label: 'Basic Salary',
        value: _money(record.basicSalary),
      ),
      _SalaryDetailLine(
        icon: Icons.home_outlined,
        label: 'House Allowance',
        value: _money(record.houseAllowance),
      ),
      _SalaryDetailLine(
        icon: Icons.directions_car_outlined,
        label: 'Transport Allowance',
        value: _money(record.transportAllowance),
      ),
      _SalaryDetailLine(
        icon: Icons.add_circle_outline,
        label: 'Other Allowances',
        value: _money(record.otherAllowances),
      ),
      _SalaryTotal(
        label: 'Total Allowances',
        value: _money(record.totalAllowances),
        color: const Color(0xFF0FAF70),
      ),
      const SizedBox(height: 8),
      _SalaryDetailLine(
        icon: Icons.receipt_long_outlined,
        label: 'Tax Deduction',
        value: _money(record.taxDeduction),
        negative: true,
      ),
      _SalaryDetailLine(
        icon: Icons.payments_outlined,
        label: 'Loan Deduction',
        value: _money(record.loanDeduction),
        negative: true,
      ),
      _SalaryDetailLine(
        icon: Icons.remove_circle_outline,
        label: 'Other Deductions',
        value: _money(record.otherDeductions),
        negative: true,
      ),
      _SalaryTotal(
        label: 'Total Deductions',
        value: _money(record.totalDeductions),
        color: const Color(0xFFFF4960),
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2468F2),
                ),
              ),
            ),
            Text(
              _money(record.netSalary),
              style: const TextStyle(
                fontSize: 16,
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

class _EmployeeSlipPreview extends StatelessWidget {
  const _EmployeeSlipPreview({required this.controller, required this.record});
  final EmployeeSalaryController controller;
  final PayrollRecordModel record;

  @override
  Widget build(BuildContext context) {
    if (!record.hasSalarySlip) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FD),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2EAF6)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 34,
              color: Color(0xFF7185A8),
            ),
            SizedBox(height: 8),
            Text(
              'No salary slip attached',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'No salary slip was attached when this payroll was created.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF60749A)),
            ),
          ],
        ),
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
                child: Text(
                  record.slipFileName ?? 'Salary Slip',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
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

class _SalaryDetailLine extends StatelessWidget {
  const _SalaryDetailLine({
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

class _SalaryTotal extends StatelessWidget {
  const _SalaryTotal({
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

class _PaidChip extends StatelessWidget {
  const _PaidChip();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE1FAEE),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Text(
      'Paid',
      style: TextStyle(
        fontSize: 10,
        color: Color(0xFF0FAF70),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SalarySurface extends StatelessWidget {
  const _SalarySurface({
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

const _salaryFieldLabel = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: Color(0xFF3C5178),
);
const _salaryFieldDecoration = BoxDecoration(
  border: Border.fromBorderSide(BorderSide(color: Color(0xFFDDE6F4))),
  borderRadius: BorderRadius.all(Radius.circular(8)),
);

String _money(double value) => 'SAR ${value.toStringAsFixed(0)}';

String _periodLabel(String periodKey) {
  final parts = periodKey.split('-');
  if (parts.length != 2) return periodKey;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) {
    return periodKey;
  }
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[month - 1]} $year';
}
