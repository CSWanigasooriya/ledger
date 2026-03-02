import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/attendance.dart';
import '../../providers/class_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/student.dart';
import '../../services/payment_service.dart';

class AttendanceScannerScreen extends StatefulWidget {
  final String classId;

  const AttendanceScannerScreen({super.key, required this.classId});

  @override
  State<AttendanceScannerScreen> createState() =>
      _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final PaymentService _paymentService = PaymentService();
  final List<_ScannedEntry> _scannedStudents = [];
  final Set<String> _scannedIds = {};
  bool _isSaving = false;
  String? _className;
  List<Student> _classStudents = [];

  @override
  void initState() {
    super.initState();
    _loadClassInfo();
  }

  void _loadClassInfo() {
    final classProv = context.read<ClassProvider>();
    final cls = classProv.getClassById(widget.classId);
    if (cls != null) {
      setState(() => _className = cls.className);
      // Pre-load enrolled students for validation
      context.read<StudentProvider>().getStudentsByIds(cls.studentIds).then(
        (students) {
          if (mounted) setState(() => _classStudents = students);
        },
      );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue.isEmpty) continue;

      // QR codes now contain the studentId directly (e.g., "B1001")
      // Also support legacy "STU-{id}" format
      String scannedValue = rawValue;
      if (rawValue.startsWith('STU-')) {
        scannedValue = rawValue.substring(4);
      }

      // Skip if already scanned
      if (_scannedIds.contains(scannedValue)) continue;

      // Find student by studentId first, then fall back to document id
      Student? student = _classStudents
          .where((s) => s.studentId == scannedValue)
          .firstOrNull;
      student ??=
          _classStudents.where((s) => s.id == scannedValue).firstOrNull;

      if (student == null) {
        // Student not in this class — show a brief warning
        _showNotEnrolledWarning(scannedValue);
        return;
      }

      // Mark as scanned
      _scannedIds.add(scannedValue);

      // Check payment status
      _checkPaymentStatus(student).then((paymentInfo) {
        if (mounted) {
          setState(() {
            _scannedStudents.insert(
              0,
              _ScannedEntry(
                student: student!,
                scannedAt: DateTime.now(),
                paymentInfo: paymentInfo,
              ),
            );
          });
        }
      });

      // Haptic feedback
      HapticFeedback.mediumImpact();
    }
  }

  Future<String> _checkPaymentStatus(Student student) async {
    if (student.isFreeCard) return 'Free Card';

    final now = DateTime.now();
    try {
      final payments = await _paymentService.getPaymentsByClassAndMonth(
        widget.classId,
        now.month,
        now.year,
      );
      final paid = payments.any((p) => p.studentId == student.id);
      return paid ? 'Paid' : 'Unpaid';
    } catch (_) {
      return 'Unknown';
    }
  }

  void _showNotEnrolledWarning(String value) {
    if (!mounted) return;
    // Try to find student from the global provider
    final studentProv = context.read<StudentProvider>();
    final student = studentProv.students
        .where((s) => s.studentId == value || s.id == value)
        .firstOrNull;
    final name = student?.fullName ?? value;

    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name is not enrolled in this class'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveAllAttendance() async {
    if (_scannedStudents.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final attendanceProv = context.read<AttendanceProvider>();
      final now = DateTime.now();
      final weekNumber = ((now.day - 1) ~/ 7) + 1;

      // Build attendance records: scanned = present, rest = absent
      final records = <Attendance>[];
      for (final student in _classStudents) {
        final isScanned = _scannedStudents.any(
          (e) => e.student.id == student.id,
        );
        records.add(Attendance(
          id: '',
          classId: widget.classId,
          studentId: student.id,
          date: now,
          weekNumber: weekNumber,
          isPresent: isScanned,
          markedBy: 'qr_scanner',
          studentDisplayId: student.studentId,
        ));
      }

      await attendanceProv.deleteAndReplace(widget.classId, now, records);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance saved: ${_scannedStudents.length}/${_classStudents.length} present',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Color _paymentColor(String info) {
    switch (info) {
      case 'Paid':
        return Colors.green;
      case 'Free Card':
        return Colors.orange;
      case 'Unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_className != null ? 'Scan: $_className' : 'QR Scanner'),
        actions: [
          // Torch toggle
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController,
              builder: (context, state, _) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                );
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          // Camera switch
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
                // Scan overlay
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.7),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Count badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.greenAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_scannedStudents.length} / ${_classStudents.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scanned students list
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Scanned Students',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_scannedStudents.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _scannedStudents.clear();
                                _scannedIds.clear();
                              });
                            },
                            icon: const Icon(Icons.clear_all_rounded, size: 18),
                            label: const Text('Clear'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // List
                  Expanded(
                    child: _scannedStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Point camera at student QR codes',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _scannedStudents.length,
                            itemBuilder: (context, index) {
                              final entry = _scannedStudents[index];
                              final pColor = _paymentColor(entry.paymentInfo);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.green.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      if (entry.student.studentId
                                          .isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                colorScheme.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            entry.student.studentId,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Expanded(
                                        child: Text(
                                          entry.student.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        'Scanned at ${TimeOfDay.fromDateTime(entry.scannedAt).format(context)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              pColor.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          entry.paymentInfo,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: pColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: colorScheme.error,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _scannedIds.remove(
                                          entry.student.studentId.isNotEmpty
                                              ? entry.student.studentId
                                              : entry.student.id,
                                        );
                                        _scannedStudents.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Save button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: _scannedStudents.isNotEmpty && !_isSaving
                ? _saveAllAttendance
                : null,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              _isSaving
                  ? 'Saving...'
                  : 'Save Attendance (${_scannedStudents.length}/${_classStudents.length})',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannedEntry {
  final Student student;
  final DateTime scannedAt;
  final String paymentInfo;

  const _ScannedEntry({
    required this.student,
    required this.scannedAt,
    this.paymentInfo = 'Unknown',
  });
}
