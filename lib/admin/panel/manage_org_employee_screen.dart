import 'package:attendance_tracker/admin/panel/tabs/employee_tab.dart';
import 'package:attendance_tracker/admin/panel/tabs/org_tab.dart';
import 'package:attendance_tracker/admin/panel/tabs/salary_tab.dart';
import 'package:flutter/material.dart';

class ManageOrgEmployeeScreen extends StatefulWidget {
  const ManageOrgEmployeeScreen({super.key});

  @override
  State<ManageOrgEmployeeScreen> createState() =>
      _ManageOrgEmployeeScreenState();
}

class _ManageOrgEmployeeScreenState extends State<ManageOrgEmployeeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _selectedOrgId;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onOrgSelected(String? orgId) {
    setState(() {
      _selectedOrgId = orgId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        title: Column(
          mainAxisSize: MainAxisSize.min, // Added this
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Management Dashboard',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            if (_selectedOrgId != null)
              Text(
                'Organization: $_selectedOrgId',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(
                    0.8,
                  ), // Fixed color reference
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              icon: Icon(
                Icons.business,
                size: 20,
                color: _currentIndex == 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
              ),
              text: 'Organizations',
            ),
            Tab(
              icon: Icon(
                Icons.people,
                size: 20,
                color: _currentIndex == 1
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
              ),
              text: 'Employees',
            ),
            Tab(
              icon: Icon(
                Icons.payments,
                size: 20,
                color: _currentIndex == 2
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
              ),
              text: 'Salary',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OrganizationsTab(onOrgSelected: _onOrgSelected),
          EmployeesTab(
            selectedOrgId: _selectedOrgId,
            onOrgSelected: _onOrgSelected,
          ),
          SalaryTab(
            selectedOrgId: _selectedOrgId,
            onOrgSelected: _onOrgSelected,
          ),
        ],
      ),
    );
  }
}
