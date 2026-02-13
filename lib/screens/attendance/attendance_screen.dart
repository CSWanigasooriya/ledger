import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/attendance.dart';
import '../../providers/class_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/student.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedClassId;
  DateTime _selectedDate = DateTime.now();
  List<Student> _classStudents = [];
  Map<String, bool> _attendanceMap = {};
  bool _loading = false;

  Future<void> _loadData() async {
    if (_selectedClassId == null) return;

    setState(() => _loading = true);

    final classProv = context.read<ClassProvider>();
    final studentProv = context.read<StudentProvider>();
    final attendanceProv = context.read<AttendanceProvider>();

    final cls = classProv.getClassById(_selectedClassId!);
    if (cls == null) return;

    final students = await studentProv.getStudentsByIds(cls.studentIds);
    await attendanceProv.loadAttendance(_selectedClassId!, _selectedDate);

    final map = <String, bool>{};
    for (final s in students) {
      map[s.id] = false;
    }
    for (final record in attendanceProv.records) {
      map[record.studentId] = record.isPresent;
    }

    if (mounted) {
      setState(() {
        _classStudents = students;
        _attendanceMap = map;
        _loading = false;
      });
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClassId == null) return;

    final attendanceProv = context.read<AttendanceProvider>();
    final records = _attendanceMap.entries.map((e) {
      return Attendance(
        id: '',
        classId: _selectedClassId!,
        studentId: e.key,
        date: _selectedDate,
        isPresent: e.value,
        markedBy: 'admin',
      );
    }).toList();

    await attendanceProv.deleteAndReplace(
      _selectedClassId!,
      _selectedDate,
      records,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Column(
        children: [
          // Controls Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                // Class Selector
                SizedBox(
                  width: 260,
                  child: Consumer<ClassProvider>(
                    builder: (context, classProv, _) {
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedClassId,
                        decoration: const InputDecoration(
                          labelText: 'Select Class',
                          prefixIcon: Icon(Icons.class_rounded),
                          isDense: true,
                        ),
                        items: classProv.classes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.className),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedClassId = v);
                          _loadData();
                        },
                      );
                    },
                  ),
                ),
                // Date Picker
                SizedBox(
                  width: 200,
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                        _loadData();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                        isDense: true,
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                ),
                // Save Button
                FilledButton.icon(
                  onPressed: _classStudents.isNotEmpty ? _saveAttendance : null,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _selectedClassId == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fact_check_rounded,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a class to mark attendance',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : _classStudents.isEmpty
                ? Center(
                    child: Text(
                      'No students enrolled in this class',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : Column(
                    children: [
                      // Summary bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${_classStudents.length} students',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Present: ${_attendanceMap.values.where((v) => v).length}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Absent: ${_attendanceMap.values.where((v) => !v).length}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  for (final key in _attendanceMap.keys) {
                                    _attendanceMap[key] = true;
                                  }
                                });
                              },
                              child: const Text('Mark All Present'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _classStudents.length,
                          itemBuilder: (context, index) {
                            final student = _classStudents[index];
                            final isPresent =
                                _attendanceMap[student.id] ?? false;

                            return Card(
                              child: SwitchListTile(
                                secondary: CircleAvatar(
                                  backgroundColor: isPresent
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.15),
                                  child: Icon(
                                    isPresent
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: isPresent
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  student.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  isPresent ? 'Present' : 'Absent',
                                  style: TextStyle(
                                    color: isPresent
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                value: isPresent,
                                onChanged: (v) {
                                  setState(() {
                                    _attendanceMap[student.id] = v;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
