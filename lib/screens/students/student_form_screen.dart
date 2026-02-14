import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../core/widgets/loading_overlay.dart';

class StudentFormScreen extends StatefulWidget {
  final String? studentId;
  const StudentFormScreen({super.key, this.studentId});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianMobileController = TextEditingController();

  bool _isEditing = false;
  Student? _existingStudent;

  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) {
      _isEditing = true;
      _loadStudent();
    }
  }

  void _loadStudent() {
    final provider = context.read<StudentProvider>();
    final student =
        provider.students.where((s) => s.id == widget.studentId).firstOrNull;
    if (student != null) {
      _existingStudent = student;
      _firstNameController.text = student.firstName;
      _lastNameController.text = student.lastName;
      _mobileController.text = student.mobileNo;
      _addressController.text = student.address;
      _emailController.text = student.email;
      _guardianNameController.text = student.guardianName;
      _guardianMobileController.text = student.guardianMobileNo;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _guardianNameController.dispose();
    _guardianMobileController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<StudentProvider>();

    final student = Student(
      id: _existingStudent?.id ?? '',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      mobileNo: _mobileController.text.trim(),
      address: _addressController.text.trim(),
      email: _emailController.text.trim(),
      guardianName: _guardianNameController.text.trim(),
      guardianMobileNo: _guardianMobileController.text.trim(),
      qrCode: _existingStudent?.qrCode ?? '',
      classIds: _existingStudent?.classIds ?? [],
      createdAt: _existingStudent?.createdAt,
    );

    bool success;
    if (_isEditing) {
      success = await provider.updateStudent(student);
    } else {
      final created = await provider.createStudent(student);
      success = created != null;
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Student ${_isEditing ? 'updated' : 'created'} successfully',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<StudentProvider>(
      builder: (context, provider, _) {
        return LoadingOverlay(
          isLoading: provider.isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: Text(_isEditing ? 'Edit Student' : 'New Student'),
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
                        // Personal Information
                        Text(
                          'Personal Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'First Name *',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name *',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ],
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
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number',
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

                        const SizedBox(height: 32),

                        // Guardian Information
                        Text(
                          'Guardian Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _guardianNameController,
                          decoration: const InputDecoration(
                            labelText: 'Guardian Name',
                            prefixIcon: Icon(Icons.family_restroom_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _guardianMobileController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Guardian Mobile Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Submit Button
                        FilledButton(
                          onPressed: _handleSubmit,
                          child: Text(
                            _isEditing ? 'Update Student' : 'Create Student',
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
