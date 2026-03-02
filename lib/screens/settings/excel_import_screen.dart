import 'package:flutter/material.dart';
import '../../services/excel_import_service.dart';

class ExcelImportScreen extends StatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> {
  final ExcelImportService _importService = ExcelImportService();

  ImportType _importType = ImportType.students;
  List<int>? _fileBytes;
  List<String> _headers = [];
  int _rowCount = 0;
  bool _isImporting = false;
  ImportResult? _result;

  // Column mapping: model field name → Excel column index
  Map<String, int?> _mapping = {};

  // Expected fields per import type
  static const _studentFields = [
    'firstName',
    'lastName',
    'grade',
    'mobileNo',
    'address',
    'email',
    'guardianName',
    'guardianMobileNo',
    'isFreeCard',
  ];

  static const _teacherFields = [
    'name',
    'email',
    'contactNo',
    'address',
    'nic',
    'bankName',
    'accountNo',
    'branch',
  ];

  static const _classFields = [
    'className',
    'classFees',
    'teacherCommissionRate',
    'numberOfWeeks',
  ];

  List<String> get _currentFields {
    switch (_importType) {
      case ImportType.students:
        return _studentFields;
      case ImportType.teachers:
        return _teacherFields;
      case ImportType.classes:
        return _classFields;
    }
  }

  List<String> get _requiredFields {
    switch (_importType) {
      case ImportType.students:
        return ['firstName', 'lastName'];
      case ImportType.teachers:
        return ['name'];
      case ImportType.classes:
        return ['className'];
    }
  }

  void _resetFile() {
    setState(() {
      _fileBytes = null;
      _headers = [];
      _rowCount = 0;
      _mapping = {};
      _result = null;
    });
  }

  Future<void> _pickFile() async {
    final bytes = await _importService.pickExcelFile();
    if (bytes == null) return;
    final headers = _importService.getHeaders(bytes);
    final rows = _importService.getDataRows(bytes);

    // Auto-map columns by matching header names (case-insensitive)
    final autoMap = <String, int?>{};
    for (final field in _currentFields) {
      final lower = field.toLowerCase();
      final idx = headers.indexWhere(
        (h) => h.toLowerCase() == lower || _normalize(h) == lower,
      );
      autoMap[field] = idx >= 0 ? idx : null;
    }

    setState(() {
      _fileBytes = bytes;
      _headers = headers;
      _rowCount = rows.length;
      _mapping = autoMap;
      _result = null;
    });
  }

  String _normalize(String s) {
    // Convert "First Name" or "first_name" → "firstname"
    return s.replaceAll(RegExp(r'[\s_-]+'), '').toLowerCase();
  }

  Future<void> _doImport() async {
    if (_fileBytes == null) return;

    // Validate required fields are mapped
    for (final req in _requiredFields) {
      if (_mapping[req] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please map the required field "$req"')),
        );
        return;
      }
    }

    setState(() => _isImporting = true);

    final nonNullMapping = Map<String, int>.fromEntries(
      _mapping.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!)),
    );

    ImportResult result;
    switch (_importType) {
      case ImportType.students:
        result =
            await _importService.importStudents(_fileBytes!, nonNullMapping);
        break;
      case ImportType.teachers:
        result =
            await _importService.importTeachers(_fileBytes!, nonNullMapping);
        break;
      case ImportType.classes:
        result =
            await _importService.importClasses(_fileBytes!, nonNullMapping);
        break;
    }

    if (mounted) {
      setState(() {
        _isImporting = false;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Excel Import')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Choose import type
            Text('1. Select Data Type',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<ImportType>(
              segments: const [
                ButtonSegment(
                    value: ImportType.students,
                    label: Text('Students'),
                    icon: Icon(Icons.school_rounded)),
                ButtonSegment(
                    value: ImportType.teachers,
                    label: Text('Teachers'),
                    icon: Icon(Icons.person_rounded)),
                ButtonSegment(
                    value: ImportType.classes,
                    label: Text('Classes'),
                    icon: Icon(Icons.class_rounded)),
              ],
              selected: {_importType},
              onSelectionChanged: (v) {
                setState(() {
                  _importType = v.first;
                  _resetFile();
                });
              },
            ),
            const SizedBox(height: 24),

            // Step 2: Pick file
            Text('2. Select Excel File (.xlsx)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _isImporting ? null : _pickFile,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(_fileBytes == null ? 'Choose File' : 'Change File'),
                ),
                if (_fileBytes != null) ...[
                  const SizedBox(width: 12),
                  Chip(
                    avatar: const Icon(Icons.table_chart_rounded, size: 18),
                    label: Text(
                        '${_headers.length} columns • $_rowCount rows'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Step 3: Column mapping
            if (_fileBytes != null) ...[
              Text('3. Map Columns',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Match your Excel columns to the data fields. '
                'Fields marked with * are required.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _currentFields.map((field) {
                      final isRequired = _requiredFields.contains(field);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 180,
                              child: Text(
                                '${_fieldLabel(field)}${isRequired ? ' *' : ''}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isRequired
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                initialValue: _mapping[field],
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  hintText: isRequired
                                      ? 'Select column (required)'
                                      : 'Select column',
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('— Skip —'),
                                  ),
                                  ...List.generate(
                                    _headers.length,
                                    (i) => DropdownMenuItem<int?>(
                                      value: i,
                                      child: Text(_headers[i].isNotEmpty
                                          ? _headers[i]
                                          : 'Column ${i + 1}'),
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _mapping[field] = v),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Step 4: Import
              Text('4. Import',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isImporting ? null : _doImport,
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_rounded),
                label: Text(_isImporting
                    ? 'Importing...'
                    : 'Import $_rowCount ${_importType.name}'),
              ),
              const SizedBox(height: 16),

              // Result display
              if (_result != null)
                Card(
                  color: _result!.failed > 0
                      ? colorScheme.errorContainer.withValues(alpha: 0.3)
                      : colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _result!.failed == 0
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_rounded,
                              color: _result!.failed == 0
                                  ? colorScheme.primary
                                  : colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Import Complete',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            '✓ ${_result!.succeeded} succeeded • ✗ ${_result!.failed} failed • Total: ${_result!.total}'),
                        if (_result!.errors.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 4),
                          Text('Errors:',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          ...(_result!.errors.take(20).map(
                                (e) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(e,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: colorScheme.error)),
                                ),
                              )),
                          if (_result!.errors.length > 20)
                            Text(
                                '... and ${_result!.errors.length - 20} more',
                                style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Human-readable label for a field name.
  String _fieldLabel(String field) {
    // camelCase → Title Case
    final spaced = field.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m.group(0)}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
