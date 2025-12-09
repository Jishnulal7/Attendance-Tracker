import 'package:attendance_tracker/admin/widgets/edit_employee_sheet.dart';
import 'package:attendance_tracker/admin/widgets/employee_card.dart';
import 'package:attendance_tracker/admin/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeesTab extends StatefulWidget {
  final String? selectedOrgId;
  final Function(String?) onOrgSelected;

  const EmployeesTab({
    super.key,
    required this.selectedOrgId,
    required this.onOrgSelected,
  });

  @override
  State<EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<EmployeesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(child: _buildEmployeesList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
            'Employee Management',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage employees for your selected organization',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Fixed: Wrap OrganizationDropdown with proper constraints
          SizedBox(
            width: double.infinity,
            child: OrganizationDropdown(
              value: widget.selectedOrgId,
              onChanged: widget.onOrgSelected,
              hint: 'Select an organization',
            ),
          ),
          const SizedBox(height: 12),
          // Fixed: Use TextField instead of SearchBar for better constraint handling
          SizedBox(
            width: double.infinity,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesList() {
    if (widget.selectedOrgId == null) {
      return const Center(
        child: EmptyState(
          icon: Icons.people_outline,
          title: 'Select Organization',
          subtitle: 'Choose an organization to view its employees',
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _getEmployeeStream(widget.selectedOrgId!, _searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LoadingIndicator(message: 'Loading employees...'),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Error Loading Employees',
              subtitle: 'Please try again later',
              actionLabel: 'Retry',
              onActionPressed: () => setState(() {}),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.search_off,
                title: 'No Results Found',
                subtitle: 'Try adjusting your search terms',
                actionLabel: 'Clear Search',
                onActionPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
            );
          }

          return const Center(
            child: EmptyState(
              icon: Icons.person_add_outlined,
              title: 'No Employees Found',
              subtitle: 'Add employees to this organization',
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return EmployeeCard(
                employeeId: doc.id,
                data: doc.data(),
                onTap: () => _handleEmployeeTap(doc.id, doc.data()),
              );
            },
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getEmployeeStream(
    String orgId,
    String searchQuery,
  ) {
    final ref = FirebaseFirestore.instance
        .collection('orgs')
        .doc(orgId)
        .collection('employees');

    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return ref.orderBy('nameLower').limit(100).snapshots();
    }

    return ref
        .orderBy('nameLower')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(100)
        .snapshots();
  }

  Future<void> _handleEmployeeTap(
    String employeeId,
    Map<String, dynamic> data,
  ) async {
    if (widget.selectedOrgId == null) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditEmployeeSheet(
        orgId: widget.selectedOrgId!,
        employeeId: employeeId,
        initialData: data,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Employee updated successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
