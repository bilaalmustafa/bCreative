import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/core/utils/validators.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/employees/models/employment_enums.dart';
import 'package:bcreative_ems/features/employees/repositories/employee_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmployeeFormController extends GetxController {
  EmployeeFormController(this._repository);

  final EmployeeRepository _repository;

  final formKey = GlobalKey<FormState>();
  final RxBool isLoading = false.obs;
  final RxBool isEditMode = false.obs;
  final RxBool obscureTemporaryPassword = true.obs;
  String? _employeeId;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final temporaryPasswordController = TextEditingController();
  final jobTitleController = TextEditingController();
  final departmentController = TextEditingController();
  final contactController = TextEditingController();
  final nationalityController = TextEditingController();
  final cnicController = TextEditingController();
  final addressController = TextEditingController();
  final salaryController = TextEditingController();
  final bankNameController = TextEditingController();
  final accountTitleController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ibanController = TextEditingController();

  final Rxn<DateTime> dateOfBirth = Rxn<DateTime>();
  final Rxn<DateTime> joiningDate = Rxn<DateTime>();
  final Rx<EmploymentStatus> employmentStatus = EmploymentStatus.active.obs;
  final Rxn<EmploymentType> employmentType = Rxn<EmploymentType>();
  final Rxn<PlatformFile> profilePhoto = Rxn<PlatformFile>();
  final existingPhotoUrl = RxnString();

  /// Loads an employee into the shared right-side panel. It is deliberately
  /// synchronous because the selected row already contains the latest live
  /// Firestore value from the employee list stream.
  void loadForEmployee(EmployeeModel employee) {
    _employeeId = employee.id;
    isEditMode.value = true;
    // Do not call FormState.reset here. This shared form stays mounted while
    // the list selection changes, and resetting it synchronously can make
    // Flutter rebuild form fields outside their current build scope.
    // Assigning the controllers below is sufficient to load a new employee.
    fullNameController.text = employee.fullName;
    emailController.text = employee.email;
    jobTitleController.text = employee.jobTitle ?? '';
    departmentController.text = employee.department ?? '';
    contactController.text = employee.contactNumber ?? '';
    nationalityController.text = employee.nationality ?? '';
    cnicController.text = employee.cnicPassport ?? '';
    addressController.text = employee.residentialAddress ?? '';
    salaryController.text = employee.salary?.toString() ?? '';
    bankNameController.text = employee.bankDetails.bankName ?? '';
    accountTitleController.text = employee.bankDetails.accountTitle ?? '';
    accountNumberController.text = employee.bankDetails.accountNumber ?? '';
    ibanController.text = employee.bankDetails.iban ?? '';
    dateOfBirth.value = employee.dateOfBirth;
    joiningDate.value = employee.joiningDate;
    employmentStatus.value = employee.employmentStatus;
    employmentType.value = employee.employmentType;
    existingPhotoUrl.value = employee.displayPhotoUrl;
    profilePhoto.value = null;
  }

  Future<void> pickDateOfBirth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth.value ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) dateOfBirth.value = picked;
  }

  Future<void> pickJoiningDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: joiningDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) joiningDate.value = picked;
  }

  Future<bool> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return false;

    isLoading.value = true;
    try {
      if (isEditMode.value) {
        await _update();
        return true;
      } else {
        final employeeId = await _create();
        final photo = profilePhoto.value;
        if (photo != null) {
          try {
            await _repository.uploadProfilePhoto(
              employeeId: employeeId,
              file: photo,
            );
          } catch (_) {
            Get.snackbar(
              'Employee created',
              'The record was saved, but the profile photo could not be uploaded.',
            );
          }
        }
        Get.snackbar('Success', 'Employee account and record created.');
        return true;
      }
    } catch (e) {
      Get.snackbar('Failed', FailureMapper.message(e));
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> _create() async {
    final salary = double.tryParse(salaryController.text.trim());
    final employee = EmployeeModel(
      id: '',
      employeeCode: '',
      email: emailController.text,
      fullName: fullNameController.text,
      jobTitle: jobTitleController.text,
      department: departmentController.text,
      contactNumber: contactController.text,
      employmentStatus: employmentStatus.value,
      isActive:
          employmentStatus.value != EmploymentStatus.inactive &&
          employmentStatus.value != EmploymentStatus.terminated,
      dateOfBirth: dateOfBirth.value,
      nationality: nationalityController.text,
      cnicPassport: cnicController.text,
      residentialAddress: addressController.text,
      joiningDate: joiningDate.value,
      employmentType: employmentType.value,
      salary: salary,
      bankDetails: EmployeeBankDetails(
        bankName: bankNameController.text,
        accountTitle: accountTitleController.text,
        accountNumber: accountNumberController.text,
        iban: ibanController.text,
      ),
    );
    final id = await _repository.createEmployee(
      employee,
      temporaryPassword: temporaryPasswordController.text,
    );
    return id;
  }

  Future<void> _update() async {
    final employeeId = _employeeId;
    if (employeeId == null || employeeId.isEmpty) {
      throw StateError('Employee record is not selected.');
    }
    final existing = await _repository.getById(employeeId);
    if (existing == null) return;

    final salary = double.tryParse(salaryController.text.trim());
    final updated = EmployeeModel(
      id: existing.id,
      employeeCode: existing.employeeCode,
      fullName: fullNameController.text.trim(),
      email: emailController.text.trim(),
      jobTitle: jobTitleController.text.trim(),
      department: departmentController.text.trim(),
      contactNumber: contactController.text.trim(),
      profilePhotoUrl: existing.profilePhotoUrl,
      gender: existing.gender,
      managerName: existing.managerName,
      workLocation: existing.workLocation,
      nationality: nationalityController.text.trim(),
      cnicPassport: cnicController.text.trim(),
      residentialAddress: addressController.text.trim(),
      dateOfBirth: dateOfBirth.value,
      joiningDate: joiningDate.value,
      employmentStatus: employmentStatus.value,
      employmentType: employmentType.value,
      salary: salary,
      bankDetails: EmployeeBankDetails(
        bankName: bankNameController.text.trim(),
        accountTitle: accountTitleController.text.trim(),
        accountNumber: accountNumberController.text.trim(),
        iban: ibanController.text.trim(),
      ),
      isActive:
          employmentStatus.value != EmploymentStatus.inactive &&
          employmentStatus.value != EmploymentStatus.terminated,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
    );
    await _repository.updateEmployee(updated);
    final photo = profilePhoto.value;
    if (photo != null) {
      final url = await _repository.uploadProfilePhoto(
        employeeId: existing.id,
        file: photo,
      );
      existingPhotoUrl.value = url;
      profilePhoto.value = null;
    }
    Get.snackbar('Saved', 'Employee profile updated.');
  }

  String? validateFullName(String? v) =>
      Validators.required(v, field: 'Full name');
  String? validateEmail(String? v) => Validators.email(v);
  String? validateTemporaryPassword(String? v) => Validators.password(v);
  String? validateDepartment(String? v) =>
      Validators.required(v, field: 'Department');
  String? validatePosition(String? v) =>
      Validators.required(v, field: 'Position');
  String? validateContact(String? v) =>
      Validators.required(v, field: 'Contact number');

  Future<void> pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      if (file.bytes == null || file.bytes!.lengthInBytes > 2 * 1024 * 1024) {
        Get.snackbar(
          'Photo not selected',
          'Choose a JPG or PNG image smaller than 2 MB.',
        );
        return;
      }
      profilePhoto.value = file;
    }
  }

  void clearProfilePhoto() => profilePhoto.value = null;

  void toggleTemporaryPasswordVisibility() {
    obscureTemporaryPassword.value = !obscureTemporaryPassword.value;
  }

  void resetForCreate() {
    _employeeId = null;
    isEditMode.value = false;
    obscureTemporaryPassword.value = true;
    // Keep the mounted Form intact; clear its controller-backed values below.
    fullNameController.clear();
    emailController.clear();
    temporaryPasswordController.clear();
    jobTitleController.clear();
    departmentController.clear();
    contactController.clear();
    nationalityController.clear();
    cnicController.clear();
    addressController.clear();
    salaryController.clear();
    bankNameController.clear();
    accountTitleController.clear();
    accountNumberController.clear();
    ibanController.clear();
    dateOfBirth.value = null;
    joiningDate.value = null;
    employmentStatus.value = EmploymentStatus.active;
    employmentType.value = null;
    profilePhoto.value = null;
    existingPhotoUrl.value = null;
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    temporaryPasswordController.dispose();
    jobTitleController.dispose();
    departmentController.dispose();
    contactController.dispose();
    nationalityController.dispose();
    cnicController.dispose();
    addressController.dispose();
    salaryController.dispose();
    bankNameController.dispose();
    accountTitleController.dispose();
    accountNumberController.dispose();
    ibanController.dispose();
    super.onClose();
  }
}
