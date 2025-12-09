import 'package:attendance_tracker/model/salary_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SalaryCalculationService {
  static const int coreStartHour = 7; // 07:00
  static const int coreEndHour = 19; // 19:00

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate monthly salaries for all employees in an organization
  Future<List<EmployeeSalaryRow>> calculateMonthlySalaries({
    required String orgId,
    required DateTime month,
  }) async {
    final start = _monthStart(month);
    final end = _monthEndExclusive(month);

    // Get employees for this organization
    final employees = await _getEmployees(orgId);
    if (employees.isEmpty) {
      return [];
    }

    // Get attendance records for the month
    final attendanceRecords = await _getAttendanceRecords(orgId, start, end);

    // Group attendance records by employee
    final recordsByEmployee = _groupRecordsByEmployee(attendanceRecords);

    // Calculate hours for each employee
    final salaryRows = <EmployeeSalaryRow>[];
    
    for (final employee in employees) {
      final employeeRecords = recordsByEmployee[employee.id] ?? [];
      final hours = _calculateEmployeeHours(employeeRecords, start, end);
      
      salaryRows.add(
        EmployeeSalaryRow(
          employeeId: employee.id,
          displayName: employee.name,
          wage: employee.wage,
          regularHours: hours.regularHours,
          overtimeHours: hours.overtimeHours,
        ),
      );
    }

    // Sort by salary (highest first)
    salaryRows.sort((a, b) => b.salary.compareTo(a.salary));
    
    return salaryRows;
  }

  /// Get all employees for an organization
  Future<List<Employee>> _getEmployees(String orgId) async {
    try {
      final snapshot = await _firestore
          .collection('orgs')
          .doc(orgId)
          .collection('employees')
          .get();

      return snapshot.docs
          .map((doc) => Employee.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch employees: $error');
    }
  }

  /// Get attendance records for the specified period
  Future<List<AttendanceRecord>> _getAttendanceRecords(
    String orgId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('attendanceRecords')
          .where('orgId', isEqualTo: orgId)
          .where('capturedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('capturedAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('capturedAt')
          .get();

      return snapshot.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc.data()))
          .where((record) => record.employeeId != null)
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch attendance records: $error');
    }
  }

  /// Group attendance records by employee ID
  Map<String, List<AttendanceRecord>> _groupRecordsByEmployee(
    List<AttendanceRecord> records,
  ) {
    final Map<String, List<AttendanceRecord>> grouped = {};
    
    for (final record in records) {
      final employeeId = record.employeeId;
      if (employeeId != null) {
        (grouped[employeeId] ??= []).add(record);
      }
    }
    
    return grouped;
  }

  /// Calculate regular and overtime hours for an employee
  EmployeeHours _calculateEmployeeHours(
    List<AttendanceRecord> records,
    DateTime monthStart,
    DateTime monthEnd,
  ) {
    // Group records by calendar day to ensure pairs don't cross days
    final recordsByDay = <DateTime, List<AttendanceRecord>>{};
    
    for (final record in records) {
      final dayKey = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      (recordsByDay[dayKey] ??= []).add(record);
    }

    Duration totalRegular = Duration.zero;
    Duration totalOvertime = Duration.zero;

    for (final entry in recordsByDay.entries) {
      final day = entry.key;
      final dayRecords = entry.value;
      
      // Sort records by timestamp
      dayRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      final dayHours = _calculateDayHours(day, dayRecords);
      totalRegular += dayHours.regular;
      totalOvertime += dayHours.overtime;
    }

    return EmployeeHours(
      regularHours: totalRegular.inMinutes / 60.0,
      overtimeHours: totalOvertime.inMinutes / 60.0,
    );
  }

  /// Calculate hours for a single day
  DayHours _calculateDayHours(DateTime day, List<AttendanceRecord> dayRecords) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final coreStart = DateTime(day.year, day.month, day.day, coreStartHour);
    final coreEnd = DateTime(day.year, day.month, day.day, coreEndHour);

    Duration regularDuration = Duration.zero;
    Duration overtimeDuration = Duration.zero;
    DateTime? currentInTime;

    for (final record in dayRecords) {
      if (record.type == 'IN') {
        currentInTime ??= record.timestamp;
      } else if (record.type == 'OUT' && currentInTime != null) {
        final inTime = currentInTime;
        final outTime = record.timestamp;

        if (outTime.isAfter(inTime)) {
          // Clip times to the current day
          final clippedIn = inTime.isBefore(dayStart) ? dayStart : inTime;
          final clippedOut = outTime.isAfter(dayEnd) ? dayEnd : outTime;

          if (clippedOut.isAfter(clippedIn)) {
            // Calculate overlap with core hours (regular time)
            final regularOverlap = _calculateOverlap(
              clippedIn, clippedOut, coreStart, coreEnd,
            );
            
            // Total time within the day
            final totalTime = clippedOut.difference(clippedIn);
            
            // Overtime is total time minus regular time
            final overtimeTime = totalTime - regularOverlap;

            regularDuration += regularOverlap;
            overtimeDuration += overtimeTime;
          }
        }
        
        currentInTime = null;
      }
    }

    // Handle case where employee is still clocked in at day end
    if (currentInTime != null) {
      final inTime = currentInTime;
      final outTime = dayEnd; // Assume clocked out at day end

      final clippedIn = inTime.isBefore(dayStart) ? dayStart : inTime;
      final clippedOut = outTime;

      if (clippedOut.isAfter(clippedIn)) {
        final regularOverlap = _calculateOverlap(
          clippedIn, clippedOut, coreStart, coreEnd,
        );
        
        final totalTime = clippedOut.difference(clippedIn);
        final overtimeTime = totalTime - regularOverlap;

        regularDuration += regularOverlap;
        overtimeDuration += overtimeTime;
      }
    }

    return DayHours(
      regular: regularDuration,
      overtime: overtimeDuration,
    );
  }

  /// Calculate overlap between two time ranges
  Duration _calculateOverlap(
    DateTime start1, DateTime end1,
    DateTime start2, DateTime end2,
  ) {
    final overlapStart = start1.isAfter(start2) ? start1 : start2;
    final overlapEnd = end1.isBefore(end2) ? end1 : end2;
    
    if (overlapEnd.isAfter(overlapStart)) {
      return overlapEnd.difference(overlapStart);
    }
    
    return Duration.zero;
  }

  /// Get the start of a month
  DateTime _monthStart(DateTime month) {
    return DateTime(month.year, month.month, 1);
  }

  /// Get the start of the next month (exclusive end)
  DateTime _monthEndExclusive(DateTime month) {
    return DateTime(
      month.month == 12 ? month.year + 1 : month.year,
      month.month == 12 ? 1 : month.month + 1,
      1,
    );
  }
}

/// Helper class to store employee hours
class EmployeeHours {
  final double regularHours;
  final double overtimeHours;

  const EmployeeHours({
    required this.regularHours,
    required this.overtimeHours,
  });

  double get totalHours => regularHours + overtimeHours;
}

/// Helper class to store day hours
class DayHours {
  final Duration regular;
  final Duration overtime;

  const DayHours({
    required this.regular,
    required this.overtime,
  });

  Duration get total => regular + overtime;
}