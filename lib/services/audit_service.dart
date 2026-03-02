import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';

/// Service for logging audit trail entries.
class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.auditLogsCollection);

  /// Log an audit entry for any entity change.
  Future<void> logChange({
    required String entityType, // 'class', 'student', 'teacher', 'payment'
    required String entityId,
    required String field,
    dynamic oldValue,
    dynamic newValue,
    String changedBy = '',
  }) async {
    final id = _uuid.v4();
    await _collection.doc(id).set({
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'field': field,
      'oldValue': oldValue?.toString(),
      'newValue': newValue?.toString(),
      'changedAt': Timestamp.fromDate(DateTime.now()),
      'changedBy': changedBy,
    });
  }

  /// Get audit logs for a specific entity.
  Future<List<Map<String, dynamic>>> getLogsForEntity(
    String entityType,
    String entityId,
  ) async {
    final snapshot = await _collection
        .where('entityType', isEqualTo: entityType)
        .where('entityId', isEqualTo: entityId)
        .orderBy('changedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  /// Get all audit logs within a date range.
  Future<List<Map<String, dynamic>>> getLogsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _collection
        .where('changedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('changedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('changedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }
}
