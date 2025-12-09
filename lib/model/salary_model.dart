// Monthly per-employee salary data
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeSalaryRow {
  final String? employeeId;
  final String displayName;
  final double wage; // per hour
  final double regularHours; // sum of 07:00–19:00 across month
  final double overtimeHours; // sum outside 07:00–19:00 across month
  
  const EmployeeSalaryRow({
    required this.employeeId,
    required this.displayName,
    required this.wage,
    required this.regularHours,
    required this.overtimeHours,
  });

  double get totalHours => regularHours + overtimeHours;
  double get salary => wage * totalHours; // add multiplier here if needed

  // Create from Map (for serialization if needed)
  factory EmployeeSalaryRow.fromMap(Map<String, dynamic> map) {
    return EmployeeSalaryRow(
      employeeId: map['employeeId'] as String?,
      displayName: map['displayName'] as String,
      wage: (map['wage'] as num).toDouble(),
      regularHours: (map['regularHours'] as num).toDouble(),
      overtimeHours: (map['overtimeHours'] as num).toDouble(),
    );
  }

  // Convert to Map (for serialization if needed)
  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'displayName': displayName,
      'wage': wage,
      'regularHours': regularHours,
      'overtimeHours': overtimeHours,
      'totalHours': totalHours,
      'salary': salary,
    };
  }

  @override
  String toString() {
    return 'EmployeeSalaryRow{employeeId: $employeeId, displayName: $displayName, '
           'wage: $wage, regularHours: $regularHours, overtimeHours: $overtimeHours, '
           'totalHours: $totalHours, salary: $salary}';
  }
}

// Daily per-employee salary data (if needed for detailed view)
class EmployeeDailySalaryRow {
  final DateTime date; // calendar day at 00:00
  final String? employeeId;
  final String displayName;
  final double wage;
  final double regularHours; // 07:00–19:00
  final double overtimeHours; // before 07:00 & after 19:00
  
  const EmployeeDailySalaryRow({
    required this.date,
    required this.employeeId,
    required this.displayName,
    required this.wage,
    required this.regularHours,
    required this.overtimeHours,
  });

  double get totalHours => regularHours + overtimeHours;
  double get salary => wage * totalHours;

  factory EmployeeDailySalaryRow.fromMap(Map<String, dynamic> map) {
    return EmployeeDailySalaryRow(
      date: DateTime.parse(map['date'] as String),
      employeeId: map['employeeId'] as String?,
      displayName: map['displayName'] as String,
      wage: (map['wage'] as num).toDouble(),
      regularHours: (map['regularHours'] as num).toDouble(),
      overtimeHours: (map['overtimeHours'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'employeeId': employeeId,
      'displayName': displayName,
      'wage': wage,
      'regularHours': regularHours,
      'overtimeHours': overtimeHours,
      'totalHours': totalHours,
      'salary': salary,
    };
  }
}

// Attendance record model for processing
class AttendanceRecord {
  final String? employeeId;
  final String? orgId;
  final String type; // 'IN' or 'OUT'
  final DateTime timestamp;

  const AttendanceRecord({
    required this.employeeId,
    required this.orgId,
    required this.type,
    required this.timestamp,
  });

  factory AttendanceRecord.fromFirestore(Map<String, dynamic> data) {
    final timestamp = ((data['capturedAt'] as Timestamp?) ?? 
                     (data['createdAt'] as Timestamp?))?.toDate() ??
                    DateTime.fromMillisecondsSinceEpoch(0);

    return AttendanceRecord(
      employeeId: data['employeeId'] as String?,
      orgId: data['orgId'] as String?,
      type: (data['type'] as String? ?? '').toUpperCase(),
      timestamp: timestamp,
    );
  }
}

// Employee data model
class Employee {
  final String id;
  final String name;
  final double wage;
  final bool isActive;

  const Employee({
    required this.id,
    required this.name,
    required this.wage,
    required this.isActive,
  });

  factory Employee.fromFirestore(String id, Map<String, dynamic> data) {
    return Employee(
      id: id,
      name: (data['name'] as String?) ?? id,
      wage: (data['wage'] as num?)?.toDouble() ?? 0.0,
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }
}