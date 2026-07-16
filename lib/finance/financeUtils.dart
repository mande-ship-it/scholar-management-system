import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';

// ============================================================
// SHARED MODELS
// ============================================================

enum PaymentCategory { tuition, stipend, stationary, uniform, medical, examFees, upkeep, other }

extension PaymentCategoryLabel on PaymentCategory {
  String get label {
    switch (this) {
      case PaymentCategory.tuition: return 'Tuition / School Fees';
      case PaymentCategory.stipend: return 'Monthly Stipend';
      case PaymentCategory.stationary: return 'Books & Stationary';
      case PaymentCategory.uniform: return 'School Uniform / Clothing';
      case PaymentCategory.medical: return 'Medical / Healthcare';
      case PaymentCategory.examFees: return 'Examination Fees';
      case PaymentCategory.upkeep: return 'Upkeep Allowance';
      case PaymentCategory.other: return 'Other / Miscellaneous';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentCategory.tuition: return Icons.school_rounded;
      case PaymentCategory.stipend: return Icons.payments_rounded;
      case PaymentCategory.stationary: return Icons.menu_book_rounded;
      case PaymentCategory.uniform: return Icons.checkroom_rounded;
      case PaymentCategory.medical: return Icons.medical_services_rounded;
      case PaymentCategory.examFees: return Icons.assignment_turned_in_rounded;
      case PaymentCategory.upkeep: return Icons.home_repair_service_rounded;
      case PaymentCategory.other: return Icons.more_horiz_rounded;
    }
  }
}

enum PaymentStatus { pending, paid, cancelled }

class ScholarshipPayment {
  final String id;
  final String studentId;
  final PaymentCategory category;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  PaymentStatus status;
  final String reference;
  final String notes;
  final String? bankName;

  ScholarshipPayment({
    required this.id,
    required this.studentId,
    required this.category,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.status = PaymentStatus.pending,
    required this.reference,
    this.notes = '',
    this.bankName,
  });
}

class OperationalExpense {
  final String id;
  final String description;
  final String category;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String refNumber;

  OperationalExpense({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.refNumber,
  });
}

class BudgetAllocation {
  final String id;
  final String fiscalYear;
  final String category;
  final double allocatedAmount;
  final double spentAmount;

  BudgetAllocation({
    required this.id,
    required this.fiscalYear,
    required this.category,
    required this.allocatedAmount,
    this.spentAmount = 0.0,
  });

  double get remaining => allocatedAmount - spentAmount;
  double get utilizationRate => allocatedAmount > 0 ? (spentAmount / allocatedAmount) : 0.0;
}

// ============================================================
// SHARED MOCK DATA
// ============================================================

final List<ScholarshipPayment> kPayments = [
  ScholarshipPayment(
    id: 'p1',
    studentId: 's1',
    category: PaymentCategory.tuition,
    amount: 150000.00,
    dueDate: DateTime(2026, 1, 15),
    paidDate: DateTime(2026, 1, 12),
    status: PaymentStatus.paid,
    reference: 'REF-2026-001',
    bankName: 'National Bank of Malawi',
  ),
  ScholarshipPayment(
    id: 'p2',
    studentId: 's2',
    category: PaymentCategory.stipend,
    amount: 45000.00,
    dueDate: DateTime(2026, 7, 30),
    status: PaymentStatus.pending,
    reference: 'STP-JULY-022',
    bankName: 'Standard Bank',
  ),
  ScholarshipPayment(
    id: 'p3',
    studentId: 's3',
    category: PaymentCategory.uniform,
    amount: 35000.00,
    dueDate: DateTime(2026, 2, 10),
    paidDate: DateTime(2026, 2, 12),
    status: PaymentStatus.paid,
    reference: 'REF-2026-045',
  ),
  ScholarshipPayment(
    id: 'p4',
    studentId: 's4',
    category: PaymentCategory.tuition,
    amount: 280000.00,
    dueDate: DateTime(2026, 8, 1),
    status: PaymentStatus.pending,
    reference: 'REF-2026-UNIMA',
    bankName: 'FDH Bank',
  ),
];

final List<OperationalExpense> kExpenses = [
  OperationalExpense(
    id: 'e1',
    description: 'Office Stationary and Printing Supplies',
    category: 'Admin',
    amount: 85000.00,
    date: DateTime(2026, 7, 10),
    paymentMethod: 'Bank Transfer',
    refNumber: 'TXN-99812',
  ),
  OperationalExpense(
    id: 'e2',
    description: 'Fuel for Program Vehicle - Field Visit',
    category: 'Travel',
    amount: 120000.00,
    date: DateTime(2026, 7, 05),
    paymentMethod: 'Cash',
    refNumber: 'TXN-99750',
  ),
];

final List<BudgetAllocation> kBudgets = [
  BudgetAllocation(id: 'b1', fiscalYear: '2026', category: 'Scholarship Tuition', allocatedAmount: 25000000.00, spentAmount: 18500000.00),
  BudgetAllocation(id: 'b2', fiscalYear: '2026', category: 'Scholar Stipends', allocatedAmount: 12000000.00, spentAmount: 7200000.00),
  BudgetAllocation(id: 'b3', fiscalYear: '2026', category: 'Administrative Costs', allocatedAmount: 5000000.00, spentAmount: 1250000.00),
  BudgetAllocation(id: 'b4', fiscalYear: '2026', category: 'Travel & Field Work', allocatedAmount: 3500000.00, spentAmount: 2100000.00),
];

const List<String> kMalawiBanks = [
  'National Bank of Malawi',
  'Standard Bank',
  'FDH Bank',
  'NBS Bank',
  'Ecobank Malawi',
  'First Capital Bank',
  'MyBucks Banking Corporation',
  'CDH Investment Bank',
  'FINCA Malawi',
  'Airtel Money',
  'TNM Mpamba',
];
