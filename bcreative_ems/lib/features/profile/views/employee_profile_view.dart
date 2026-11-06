import 'package:bcreative_ems/core/utils/responsive.dart';
import 'package:bcreative_ems/core/widgets/app_loading.dart';
import 'package:bcreative_ems/core/widgets/empty_state.dart';
import 'package:bcreative_ems/core/widgets/page_intro.dart';
import 'package:bcreative_ems/features/profile/models/employee_profile_model.dart';
import 'package:bcreative_ems/features/profile/viewmodels/employee_profile_controller.dart';
import 'package:bcreative_ems/features/shell/views/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EmployeeProfileView extends GetView<EmployeeProfileController> {
  const EmployeeProfileView({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'My Profile',
    body: Obx(() {
      if (controller.isLoading.value) return const AppLoading();

      final error = controller.errorMessage.value;
      if (error != null) {
        return EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Profile could not be loaded',
          subtitle: error,
          action: OutlinedButton.icon(
            onPressed: controller.retry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        );
      }

      final profile = controller.profile.value;
      if (profile == null) {
        return const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Profile unavailable',
          subtitle: 'Please contact your Super Admin for assistance.',
        );
      }
      return _ProfileContent(profile: profile);
    }),
  );
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final EmployeeProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return ListView(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PageHeader(),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final profileCard = _EmployeeProfileCard(profile: profile);
                    final information = _ProfileInformation(profile: profile);

                    if (constraints.maxWidth >= 1050) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 288, child: profileCard),
                          const SizedBox(width: 18),
                          Expanded(child: information),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        profileCard,
                        const SizedBox(height: 18),
                        information,
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

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) => const PageIntro(
    icon: Icons.account_circle_rounded,
    description: 'View your personal, employment and work information.',
    iconColor: Color(0xFF2168F3),
    backgroundColor: Color(0xFFE8F0FF),
    boxSize: 48,
    iconSize: 30,
  );
}

class _EmployeeProfileCard extends StatelessWidget {
  const _EmployeeProfileCard({required this.profile});

  final EmployeeProfileModel profile;

  @override
  Widget build(BuildContext context) => _ProfileSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ProfileAvatar(url: profile.displayPhotoUrl),
        const SizedBox(height: 15),
        Text(
          _text(profile.fullName),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          _text(profile.jobTitle),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF314C7C),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 13),
        _StatusBadge(profile: profile),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFE8EDF7), height: 1),
        const SizedBox(height: 18),
        _ProfileFact(
          icon: Icons.badge_outlined,
          label: 'Employee ID',
          value: _text(profile.employeeCode),
        ),
        const SizedBox(height: 15),
        _ProfileFact(
          icon: Icons.business_outlined,
          label: 'Department',
          value: _text(profile.department),
        ),
        const SizedBox(height: 15),
        _ProfileFact(
          icon: Icons.calendar_month_outlined,
          label: 'Joining Date',
          value: _date(profile.joiningDate),
        ),
        const SizedBox(height: 15),
        _ProfileFact(
          icon: Icons.work_outline_rounded,
          label: 'Employment Type',
          value: profile.employmentType?.label ?? 'Not set',
        ),
      ],
    ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    return Container(
      height: 142,
      width: 142,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Color(0xFFE4EEFF),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _AvatarFallback(),
              )
            : const _AvatarFallback(),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFF2F6FD),
    child: Center(
      child: Icon(Icons.person_rounded, color: Color(0xFF7D96C1), size: 72),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.profile});

  final EmployeeProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final active = profile.isCurrentlyActive;
    final color = active ? const Color(0xFF10B96F) : const Color(0xFFFF9B1A);
    final background = active
        ? const Color(0xFFE0F8EA)
        : const Color(0xFFFFF0D8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            profile.employmentStatusLabel,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ProfileFact extends StatelessWidget {
  const _ProfileFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5FF),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: const Color(0xFF2168F3), size: 21),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF59709A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ProfileInformation extends StatelessWidget {
  const _ProfileInformation({required this.profile});

  final EmployeeProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final personal = _InformationSection(
      icon: Icons.person_outline_rounded,
      title: 'Personal Information',
      child: Column(
        children: [
          _InformationRow(
            label: 'Date of Birth',
            value: _date(profile.dateOfBirth),
          ),
          _InformationRow(
            label: 'CNIC / Passport',
            value: _text(profile.cnicPassport),
          ),
          _InformationRow(
            label: 'Nationality',
            value: _text(profile.nationality),
            showDivider: false,
          ),
        ],
      ),
    );
    final contact = _InformationSection(
      icon: Icons.phone_in_talk_outlined,
      title: 'Contact Information',
      child: Column(
        children: [
          _InformationRow(
            label: 'Email',
            value: _text(profile.email),
            icon: Icons.mail_outline_rounded,
          ),
          _InformationRow(
            label: 'Phone',
            value: _text(profile.contactNumber),
            icon: Icons.phone_outlined,
          ),
          _InformationRow(
            label: 'Address',
            value: _text(profile.residentialAddress),
            icon: Icons.location_on_outlined,
            showDivider: false,
          ),
        ],
      ),
    );

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 650) {
              return Column(
                children: [personal, const SizedBox(height: 18), contact],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: personal),
                const SizedBox(width: 18),
                Expanded(child: contact),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _EmploymentSection(profile: profile),
      ],
    );
  }
}

class _EmploymentSection extends StatelessWidget {
  const _EmploymentSection({required this.profile});

  final EmployeeProfileModel profile;

  @override
  Widget build(BuildContext context) => _InformationSection(
    icon: Icons.business_center_outlined,
    title: 'Employment Information',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final left = Column(
          children: [
            _InformationRow(
              label: 'Job Title',
              value: _text(profile.jobTitle),
              icon: Icons.badge_outlined,
            ),
            _InformationRow(
              label: 'Department',
              value: _text(profile.department),
              icon: Icons.account_tree_outlined,
            ),
            _InformationRow(
              label: 'Bank',
              value: _text(profile.bankName),
              icon: Icons.account_balance_outlined,
              showDivider: false,
            ),
          ],
        );
        final right = Column(
          children: [
            _InformationRow(
              label: 'Employment Type',
              value: profile.employmentType?.label ?? 'Not set',
              icon: Icons.layers_outlined,
            ),
            _InformationRow(
              label: 'Joining Date',
              value: _date(profile.joiningDate),
              icon: Icons.calendar_month_outlined,
            ),
            _InformationRow(
              label: 'Account No.',
              value: _text(profile.accountNumber),
              icon: Icons.credit_card_outlined,
              showDivider: false,
            ),
          ],
        );
        if (constraints.maxWidth < 680) {
          return Column(
            children: [
              left,
              const SizedBox(height: 9),
              const Divider(color: Color(0xFFE8EDF7)),
              const SizedBox(height: 9),
              right,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 24),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFE2EAF7),
              ),
              const SizedBox(width: 24),
              Expanded(child: right),
            ],
          ),
        );
      },
    ),
  );
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => _ProfileSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 39,
              width: 39,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: const Color(0xFF2168F3), size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        child,
      ],
    ),
  );
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.label,
    required this.value,
    this.icon,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: showDivider
          ? const Border(bottom: BorderSide(color: Color(0xFFE8EDF7)))
          : null,
    ),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: const Color(0xFF5F76A0), size: 20),
          const SizedBox(width: 11),
        ],
        Expanded(
          flex: icon == null ? 4 : 3,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4F6692),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _ProfileSurface extends StatelessWidget {
  const _ProfileSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE5ECF8)),
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

String _text(String? value, {String fallback = 'Not set'}) {
  final text = value?.trim();
  return text == null || text.isEmpty ? fallback : text;
}

String _date(DateTime? value) =>
    value == null ? 'Not set' : DateFormat('dd MMM yyyy').format(value);
