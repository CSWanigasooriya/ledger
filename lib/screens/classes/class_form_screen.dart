import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/class_model.dart';
import '../../providers/class_provider.dart';
import '../../providers/teacher_provider.dart';
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
    final cls = provider.classes
        .where((c) => c.id == widget.classId)
        .firstOrNull;
    if (cls != null) {
      _existingClass = cls;
      _classNameController.text = cls.className;
      _feesController.text = cls.classFees.toString();
      _commissionController.text = cls.teacherCommissionRate.toString();
      _selectedTeacherId = cls.teacherId.isNotEmpty ? cls.teacherId : null;
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

    final classModel = ClassModel(
      id: _existingClass?.id ?? '',
      className: _classNameController.text.trim(),
      teacherId: _selectedTeacherId ?? '',
      teacherCommissionRate: double.tryParse(_commissionController.text) ?? 0.0,
      classFees: double.tryParse(_feesController.text) ?? 0.0,
      studentIds: _existingClass?.studentIds ?? [],
      createdAt: _existingClass?.createdAt,
    );

    bool success;
    if (_isEditing) {
      success = await provider.updateClass(classModel);
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
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Class Fees',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _commissionController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Teacher Commission Rate (%)',
                            prefixIcon: Icon(Icons.percent_rounded),
                            suffixText: '%',
                          ),
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
