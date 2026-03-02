import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../providers/class_provider.dart';
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
  final _classSearchController = TextEditingController();

  bool _isEditing = false;
  Student? _existingStudent;
  final Set<String> _selectedClassIds = {};
  bool _isSubmitting = false;
  String _selectedGrade = '10'; // Default grade
  bool _isFreeCard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().init();
    });

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
      _selectedClassIds.addAll(student.classIds);
      _selectedGrade = student.grade.isEmpty ? '10' : student.grade;
      _isFreeCard = student.isFreeCard;
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
    _classSearchController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final studentProvider = context.read<StudentProvider>();
      final classProvider = context.read<ClassProvider>();

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
        studentId: _existingStudent?.studentId ?? '',
        grade: _selectedGrade,
        isFreeCard: _isFreeCard,
        classIds: _selectedClassIds.toList(),
        createdAt: _existingStudent?.createdAt,
        status: _existingStudent?.status ?? StudentStatus.active,
      );

      bool success;
      Student? createdStudent;
      if (_isEditing) {
        success = await studentProvider.updateStudent(student);
      } else {
        createdStudent = await studentProvider.createStudent(student);
        success = createdStudent != null;
      }

      if (success) {
        final studentIdToUse = _isEditing ? student.id : createdStudent!.id;

        // Calculate differences for class enrollments
        final previousClassIds = _existingStudent?.classIds ?? [];
        final addedClasses = _selectedClassIds
            .where((id) => !previousClassIds.contains(id))
            .toList();
        final removedClasses = previousClassIds
            .where((id) => !_selectedClassIds.contains(id))
            .toList();

        for (final classId in addedClasses) {
          await classProvider.enrollStudent(classId, studentIdToUse);
        }
        for (final classId in removedClasses) {
          await classProvider.removeStudent(classId, studentIdToUse);
        }

        if (mounted) {
          if (!_isEditing) {
            // Navigate to QR print screen after student creation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Student created: ${createdStudent!.studentId}',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('/students/${createdStudent.id}/qr');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Student updated successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop();
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<StudentProvider, ClassProvider>(
      builder: (context, studentProvider, classProvider, _) {
        final isLoading = studentProvider.isLoading ||
            _isSubmitting ||
            classProvider.isLoading;

        return LoadingOverlay(
          isLoading: isLoading,
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
                        // Student ID display (for editing)
                        if (_isEditing && _existingStudent != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.badge_outlined),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Student ID: ${_existingStudent!.studentId}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Personal Information
                        Text(
                          'Personal Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Grade selector
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGrade,
                          decoration: const InputDecoration(
                            labelText: 'Grade *',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          items: GradeConfig.gradePrefixMap.keys
                              .map(
                                (grade) => DropdownMenuItem(
                                  value: grade,
                                  child: Text(
                                    'Grade $grade (${GradeConfig.prefixForGrade(grade)})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _isEditing
                              ? null // Can't change grade after creation
                              : (value) {
                                  if (value != null) {
                                    setState(() => _selectedGrade = value);
                                  }
                                },
                          validator: (v) => v == null ? 'Required' : null,
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

                        const SizedBox(height: 24),

                        // Free Card toggle
                        SwitchListTile(
                          title: const Text('Free Card'),
                          subtitle: const Text(
                            'Student is exempt from class fees',
                          ),
                          value: _isFreeCard,
                          onChanged: (v) => setState(() => _isFreeCard = v),
                          secondary: Icon(
                            _isFreeCard
                                ? Icons.card_giftcard
                                : Icons.card_giftcard_outlined,
                            color:
                                _isFreeCard ? theme.colorScheme.primary : null,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Class Assignment - Searchable dropdown with chips
                        Text(
                          'Class Assignment',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Selected classes as chips
                        if (_selectedClassIds.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: _selectedClassIds.map((classId) {
                                final classModel =
                                    classProvider.getClassById(classId);
                                return Chip(
                                  label: Text(
                                    classModel?.className ?? 'Unknown',
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedClassIds.remove(classId);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),

                        // Searchable class dropdown
                        if (classProvider.classes.isEmpty)
                          const Text('No classes available.')
                        else
                          Autocomplete<String>(
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return classProvider.classes
                                    .where(
                                      (c) => !_selectedClassIds.contains(c.id),
                                    )
                                    .map((c) => c.id);
                              }
                              final query = textEditingValue.text.toLowerCase();
                              return classProvider.classes
                                  .where(
                                    (c) =>
                                        !_selectedClassIds.contains(c.id) &&
                                        c.className
                                            .toLowerCase()
                                            .contains(query),
                                  )
                                  .map((c) => c.id);
                            },
                            displayStringForOption: (classId) {
                              final c = classProvider.getClassById(classId);
                              return c?.className ?? 'Unknown';
                            },
                            onSelected: (classId) {
                              setState(() {
                                _selectedClassIds.add(classId);
                              });
                              // Clear the text field after selection
                              _classSearchController.clear();
                            },
                            fieldViewBuilder: (context, controller, focusNode,
                                onFieldSubmitted) {
                              // Keep reference to clear it later
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Search & Add Class',
                                  prefixIcon: Icon(Icons.search),
                                  hintText: 'Type to search classes...',
                                ),
                              );
                            },
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
