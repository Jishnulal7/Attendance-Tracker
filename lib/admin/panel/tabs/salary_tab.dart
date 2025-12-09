import 'package:attendance_tracker/admin/widgets/month_picker_sheet.dart';
import 'package:attendance_tracker/admin/widgets/salary_card.dart';
import 'package:attendance_tracker/admin/widgets/shared_widgets.dart';
import 'package:attendance_tracker/model/salary_model.dart';
import 'package:attendance_tracker/services/salary_calculation_service.dart';
import 'package:flutter/material.dart';

class SalaryTab extends StatefulWidget {
  final String? selectedOrgId;
  final Function(String?) onOrgSelected;

  const SalaryTab({
    super.key,
    required this.selectedOrgId,
    required this.onOrgSelected,
  });

  @override
  State<SalaryTab> createState() => _SalaryTabState();
}

class _SalaryTabState extends State<SalaryTab> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = false;
  List<EmployeeSalaryRow> _salaryRows = [];
  final SalaryCalculationService _salaryService = SalaryCalculationService();

  @override
  void initState() {
    super.initState();
    if (widget.selectedOrgId != null) {
      _calculateSalaries();
    }
  }

  @override
  void didUpdateWidget(covariant SalaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedOrgId != oldWidget.selectedOrgId &&
        widget.selectedOrgId != null) {
      _calculateSalaries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildControls(),
        Expanded(child: _buildSalaryList()), // Wrapped in Expanded
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity, // Added this
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16,
      ), // Made bottom padding consistent
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Salary Management',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate and review monthly salaries for employees',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final monthLabel =
        '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          OrganizationDropdown(
            value: widget.selectedOrgId,
            onChanged: widget.onOrgSelected,
            hint: 'Select organization for salary calculation',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _showMonthPicker,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month),
                      const SizedBox(width: 8),
                      Text(monthLabel),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: (widget.selectedOrgId == null || _isLoading)
                    ? null
                    : _calculateSalaries,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calculate),
                          SizedBox(width: 8),
                          Text('Calculate'),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryList() {
    if (widget.selectedOrgId == null) {
      return const Expanded(
        // Added Expanded wrapper
        child: EmptyState(
          icon: Icons.payments_outlined,
          title: 'Select Organization',
          subtitle: 'Choose an organization to calculate salaries',
        ),
      );
    }

    if (_isLoading) {
      return const Expanded(
        // Added Expanded wrapper
        child: LoadingIndicator(message: 'Calculating salaries...'),
      );
    }

    if (_salaryRows.isEmpty) {
      return Expanded(
        // Added Expanded wrapper
        child: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No Salary Data',
          subtitle: 'No attendance records found for the selected month',
          actionLabel: 'Recalculate',
          onActionPressed: _calculateSalaries,
        ),
      );
    }

    final totalSalary = _salaryRows.fold<double>(
      0.0,
      (sum, row) => sum + row.salary,
    );

    return Expanded(
      // Moved Expanded here to wrap the entire content
      child: RefreshIndicator(
        onRefresh: _calculateSalaries,
        child: CustomScrollView(
          // Changed to CustomScrollView for better control
          slivers: [
            // Total salary card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: StatCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Total Monthly Salary',
                  value: '₹${totalSalary.toStringAsFixed(2)}',
                  subtitle: '${_salaryRows.length} employees',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Employee salary list
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final row = _salaryRows[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    index == _salaryRows.length - 1
                        ? 16
                        : 12, // Add bottom padding for last item
                  ),
                  child: SalaryCard(salaryRow: row),
                );
              }, childCount: _salaryRows.length),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Added this for better modal behavior
      builder: (context) => MonthPickerSheet(selectedMonth: _selectedMonth),
    );

    if (result != null && result != _selectedMonth) {
      setState(() {
        _selectedMonth = result;
      });
      if (widget.selectedOrgId != null) {
        _calculateSalaries();
      }
    }
  }

  Future<void> _calculateSalaries() async {
    if (widget.selectedOrgId == null) return;

    setState(() {
      _isLoading = true;
      _salaryRows = [];
    });

    try {
      final rows = await _salaryService.calculateMonthlySalaries(
        orgId: widget.selectedOrgId!,
        month: _selectedMonth,
      );

      if (mounted) {
        setState(() {
          _salaryRows = rows;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Salary calculation failed: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
