import 'package:bcreative_ems/features/employees/components/employee_field_label.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// A read-only employee form field that opens a date picker.
class EmployeeDateField extends StatelessWidget {
  const EmployeeDateField({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final Rxn<DateTime> value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EmployeeFieldLabel(label),
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
