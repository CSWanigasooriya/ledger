import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/class_model.dart';
import '../../providers/class_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/loading_overlay.dart';

class ClassFormScreen extends StatefulWidget {
  final String? classId;
  const ClassFormScreen({super.key, this.classId});

  @override
  State<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends State<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _feesController = TextEditingController();
  final _commissionController = TextEditingController();
  String? _selectedTeacherId;
  bool _isEditing = false;
  ClassModel? _existingClass;
  int _numberOfWeeks = 4;

  @override
  void initState() {
    super.initState();
    if (widget.classId != null) {
      _isEditing = true;
      _loadClass();
    }
  }

  void _loadClass() {
    final provider = context.read<ClassProvider>();
    final cls =
        provider.classes.where((c) => c.id == widget.classId).firstOrNull;
    if (cls != null) {
      _existingClass = cls;
      _classNameController.text = cls.className;
      _feesController.text = cls.classFees.toString();
      _commissionController.text = cls.teacherCommissionRate.toString();
      _selectedTeacherId = cls.teacherId.isNotEmpty ? cls.teacherId : null;
      _numberOfWeeks = cls.numberOfWeeks;
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _feesController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ClassProvider>();
    final authProvider = context.read<AuthProvider>();

    // Check commission rate edit permission
    if (_isEditing && !authProvider.canUpdateCommissions) {
      final oldRate = _existingClass?.teacherCommissionRate ?? 0.0;
      final newRate = double.tryParse(_commissionController.text) ?? 0.0;
      if (oldRate != newRate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Only super admins can change commission rates',
            ),
          ),
        );
        return;
      }
    }

    final classModel = ClassModel(
      id: _existingClass?.id ?? '',
      className: _classNameController.text.trim(),
      teacherId: _selectedTeacherId ?? '',
      teacherCommissionRate: double.tryParse(_commissionController.text) ?? 0.0,
      classFees: double.tryParse(_feesController.text) ?? 0.0,
      studentIds: _existingClass?.studentIds ?? [],
      numberOfWeeks: _numberOfWeeks,
      createdAt: _existingClass?.createdAt,
    );

    bool success;
    if (_isEditing) {
      success = await provider.updateClass(
        classModel,
        changedBy: authProvider.appUser?.email ?? '',
      );
    } else {
      final created = await provider.createClass(classModel);
      success = created != null;
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Class ${_isEditing ? 'updated' : 'created'} successfully',
          ),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Consumer2<ClassProvider, TeacherProvider>(
      builder: (context, classProv, teacherProv, _) {
        return LoadingOverlay(
          isLoading: classProv.isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: Text(_isEditing ? 'Edit Class' : 'New Class'),
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
                          'Class Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _classNameController,
                          decoration: const InputDecoration(
                            labelText: 'Class Name *',
                            prefixIcon: Icon(Icons.class_rounded),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedTeacherId,
                          decoration: const InputDecoration(
                            labelText: 'Assign Teacher',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No teacher'),
                            ),
                            ...teacherProv.teachers.map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedTeacherId = v),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _feesController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Class Fees',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _commissionController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Teacher Commission Rate (%)',
                            prefixIcon: const Icon(Icons.percent_rounded),
                            suffixText: '%',
                            enabled: authProvider.canUpdateCommissions || !_isEditing,
                            helperText: _isEditing && !authProvider.canUpdateCommissions
                                ? 'Only super admins can change commission rates'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Number of weeks per month
                        DropdownButtonFormField<int>(
                          initialValue: _numberOfWeeks,
                          decoration: const InputDecoration(
                            labelText: 'Weeks per Month',
                            prefixIcon: Icon(Icons.calendar_view_week),
                          ),
                          items: List.generate(
                            5,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('${i + 1} week${i > 0 ? 's' : ''}'),
                            ),
                          ),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _numberOfWeeks = v);
                            }
                          },
                        ),

                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: _handleSubmit,
                          child: Text(
                            _isEditing ? 'Update Class' : 'Create Class',
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
