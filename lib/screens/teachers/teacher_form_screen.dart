import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/teacher.dart';
import '../../providers/teacher_provider.dart';
import '../../core/widgets/loading_overlay.dart';

class TeacherFormScreen extends StatefulWidget {
  final String? teacherId;
  const TeacherFormScreen({super.key, this.teacherId});

  @override
  State<TeacherFormScreen> createState() => _TeacherFormScreenState();
}

class _TeacherFormScreenState extends State<TeacherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _nicController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _branchController = TextEditingController();

  bool _isEditing = false;
  Teacher? _existingTeacher;

  @override
  void initState() {
    super.initState();
    if (widget.teacherId != null) {
      _isEditing = true;
      _loadTeacher();
    }
  }

  void _loadTeacher() {
    final provider = context.read<TeacherProvider>();
    final teacher =
        provider.teachers.where((t) => t.id == widget.teacherId).firstOrNull;
    if (teacher != null) {
      _existingTeacher = teacher;
      _nameController.text = teacher.name;
      _emailController.text = teacher.email;
      _contactController.text = teacher.contactNo;
      _addressController.text = teacher.address;
      _nicController.text = teacher.nic;
      _bankNameController.text = teacher.bankDetails.bankName;
      _accountNoController.text = teacher.bankDetails.accountNo;
      _branchController.text = teacher.bankDetails.branch;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _nicController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TeacherProvider>();

    final teacher = Teacher(
      id: _existingTeacher?.id ?? '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      contactNo: _contactController.text.trim(),
      address: _addressController.text.trim(),
      nic: _nicController.text.trim(),
      bankDetails: BankDetails(
        bankName: _bankNameController.text.trim(),
        accountNo: _accountNoController.text.trim(),
        branch: _branchController.text.trim(),
      ),
      createdAt: _existingTeacher?.createdAt,
    );

    bool success;
    if (_isEditing) {
      success = await provider.updateTeacher(teacher);
    } else {
      final created = await provider.createTeacher(teacher);
      success = created != null;
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Teacher ${_isEditing ? 'updated' : 'created'} successfully',
          ),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TeacherProvider>(
      builder: (context, provider, _) {
        return LoadingOverlay(
          isLoading: provider.isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: Text(_isEditing ? 'Edit Teacher' : 'New Teacher'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Personal Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nicController,
                          decoration: const InputDecoration(
                            labelText: 'NIC',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Bank Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bankNameController,
                          decoration: const InputDecoration(
                            labelText: 'Bank Name',
                            prefixIcon: Icon(Icons.account_balance_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accountNoController,
                          decoration: const InputDecoration(
                            labelText: 'Account Number',
                            prefixIcon: Icon(Icons.numbers_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _branchController,
                          decoration: const InputDecoration(
                            labelText: 'Branch',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: _handleSubmit,
                          child: Text(
                            _isEditing ? 'Update Teacher' : 'Create Teacher',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
