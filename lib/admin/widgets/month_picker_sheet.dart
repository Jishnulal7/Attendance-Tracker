import 'package:flutter/material.dart';

class MonthPickerSheet extends StatefulWidget {
  final DateTime selectedMonth;

  const MonthPickerSheet({
    super.key,
    required this.selectedMonth,
  });

  @override
  State<MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<MonthPickerSheet> {
  late DateTime _currentMonth;
  late int _selectedYear;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedMonth;
    _selectedYear = widget.selectedMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildYearSelector(),
          _buildMonthGrid(),
          _buildActions(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Select Month',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the month for salary calculation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - 2 + index);

    return Container(
      margin: const EdgeInsets.all(24),
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final year = years[index];
          final isSelected = year == _selectedYear;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedYear = year;
                _currentMonth = DateTime(_selectedYear, _currentMonth.month);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: Center(
                child: Text(
                  year.toString(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final isSelected = month == _currentMonth.month && 
                            _selectedYear == _currentMonth.year;
          final monthDate = DateTime(_selectedYear, month);
          final isCurrentMonth = monthDate.year == DateTime.now().year && 
                                monthDate.month == DateTime.now().month;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentMonth = DateTime(_selectedYear, month);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentMonth
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                      : isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor.withOpacity(0.2),
                  width: isCurrentMonth && !isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _monthNames[index],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                  if (isCurrentMonth && !isSelected) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _currentMonth),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Select'),
            ),
          ),
        ],
      ),
    );
  }
}