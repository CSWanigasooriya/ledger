import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
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
  int _selectedWeek = 1;
  List<Student> _classStudents = [];
  Map<String, bool> _attendanceMap = {};
  bool _loading = false;
  final _manualSearchController = TextEditingController();

  @override
  void dispose() {
    _manualSearchController.dispose();
    super.dispose();
  }

  int _calculateWeekNumber(DateTime date) {
    // Week number within the month (1-4+)
    return ((date.day - 1) ~/ 7) + 1;
  }

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
        _selectedWeek = _calculateWeekNumber(_selectedDate);
      });
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClassId == null) return;

    final attendanceProv = context.read<AttendanceProvider>();
    final records = _attendanceMap.entries.map((e) {
      final student = _classStudents.where((s) => s.id == e.key).firstOrNull;
      return Attendance(
        id: '',
        classId: _selectedClassId!,
        studentId: e.key,
        date: _selectedDate,
        weekNumber: _selectedWeek,
        isPresent: e.value,
        markedBy: 'admin',
        studentDisplayId: student?.studentId,
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

  /// Manual attendance mark: search by student ID or name
  void _showManualMarkDialog() {
    if (_selectedClassId == null) return;

    final studentProv = context.read<StudentProvider>();
    final allStudents = studentProv.students;

    showDialog(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = query.isEmpty
                ? <Student>[]
                : allStudents.where((s) {
                    final lq = query.toLowerCase();
                    return s.fullName.toLowerCase().contains(lq) ||
                        s.studentId.toLowerCase().contains(lq);
                  }).toList();

            return AlertDialog(
              title: const Text('Manual Attendance'),
              content: SizedBox(
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search by name or student ID...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => setDialogState(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                query.isEmpty
                                    ? 'Type to search'
                                    : 'No students found',
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final student = filtered[i];
                                final alreadyMarked =
                                    _attendanceMap.containsKey(student.id) &&
                                        _attendanceMap[student.id] == true;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: alreadyMarked
                                        ? Colors.green
                                            .withValues(alpha: 0.15)
                                        : null,
                                    child: Text(
                                      student.studentId.isNotEmpty
                                          ? student.studentId[0]
                                          : '?',
                                    ),
                                  ),
                                  title: Text(student.fullName),
                                  subtitle: Text(student.studentId),
                                  trailing: alreadyMarked
                                      ? const Icon(Icons.check_circle,
                                          color: Colors.green)
                                      : null,
                                  onTap: () {
                                    if (_attendanceMap
                                        .containsKey(student.id)) {
                                      setState(() {
                                        _attendanceMap[student.id] = true;
                                      });
                                      setDialogState(() {});
                                    } else {
                                      // Student not enrolled - add as present
                                      setState(() {
                                        _classStudents.add(student);
                                        _attendanceMap[student.id] = true;
                                      });
                                      setDialogState(() {});
                                    }
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${student.fullName} marked present',
                                        ),
                                        duration:
                                            const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
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
                        setState(() {
                          _selectedDate = date;
                          _selectedWeek = _calculateWeekNumber(date);
                        });
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
                // Week selector
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedWeek,
                    decoration: const InputDecoration(
                      labelText: 'Week',
                      isDense: true,
                      prefixIcon: Icon(Icons.calendar_view_week, size: 18),
                    ),
                    items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('Week ${i + 1}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedWeek = v);
                    },
                  ),
                ),
                // Save Button
                FilledButton.icon(
                  onPressed: _classStudents.isNotEmpty ? _saveAttendance : null,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save'),
                ),
                // QR Scan Button
                FilledButton.tonalIcon(
                  onPressed: _selectedClassId != null
                      ? () => context.go('/attendance/scan/$_selectedClassId')
                      : null,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Scan QR'),
                ),
                // Manual Mark Button
                OutlinedButton.icon(
                  onPressed:
                      _selectedClassId != null ? _showManualMarkDialog : null,
                  icon: const Icon(Icons.person_search_rounded, size: 18),
                  label: const Text('Manual'),
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
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : _classStudents.isEmpty
                        ? Center(
                            child: Text(
                              'No students enrolled in this class',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
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
                                      '${_classStudents.length} students • Week $_selectedWeek',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
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
                                        color:
                                            Colors.green.withValues(alpha: 0.1),
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
                                        color:
                                            Colors.red.withValues(alpha: 0.1),
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
                                          for (final key
                                              in _attendanceMap.keys) {
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  itemCount: _classStudents.length,
                                  itemBuilder: (context, index) {
                                    final student = _classStudents[index];
                                    final isPresent =
                                        _attendanceMap[student.id] ?? false;

                                    return Card(
                                      child: SwitchListTile(
                                        secondary: CircleAvatar(
                                          backgroundColor: isPresent
                                              ? Colors.green
                                                  .withValues(alpha: 0.15)
                                              : Colors.red
                                                  .withValues(alpha: 0.15),
                                          child: Icon(
                                            isPresent
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel_rounded,
                                            color: isPresent
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            if (student.studentId
                                                .isNotEmpty) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  student.studentId,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Expanded(
                                              child: Text(
                                                student.fullName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (student.isFreeCard)
                                              Icon(
                                                Icons.card_giftcard,
                                                size: 16,
                                                color:
                                                    Colors.orange.shade700,
                                              ),
                                          ],
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
