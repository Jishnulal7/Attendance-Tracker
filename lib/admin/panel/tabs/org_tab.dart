import 'package:attendance_tracker/admin/widgets/edit_organization_sheet.dart';
import 'package:attendance_tracker/admin/widgets/org_card.dart';
import 'package:attendance_tracker/admin/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationsTab extends StatefulWidget {
  final Function(String?) onOrgSelected;

  const OrganizationsTab({super.key, required this.onOrgSelected});

  @override
  State<OrganizationsTab> createState() => _OrganizationsTabState();
}

class _OrganizationsTabState extends State<OrganizationsTab> {
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
        _buildSearchHeader(),
        Expanded(child: _buildOrganizationsList()),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            'Organizations',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your organizations and their settings',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          SearchBar(
            controller: _searchController,
            hintText: 'Search organizations...',
            leading: const Icon(Icons.search),
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainer,
            ),
            elevation: WidgetStateProperty.all(0),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orgs')
          .orderBy('nameLower')
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Loading organizations...');
        }

        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Organizations',
            subtitle: 'Please try again later',
            actionLabel: 'Retry',
            onActionPressed: () => setState(() {}),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyState(
            icon: Icons.business_outlined,
            title: 'No Organizations Found',
            subtitle: 'Create your first organization to get started',
          );
        }

        final docs = snapshot.data!.docs;
        final filteredDocs = docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final data = doc.data();
          final name = (data['name'] as String? ?? '').toLowerCase();
          final email = (data['email'] as String? ?? '').toLowerCase();
          return name.contains(_searchQuery) ||
              email.contains(_searchQuery) ||
              doc.id.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return EmptyState(
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
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              return OrganizationCard(
                orgId: doc.id,
                data: doc.data(),
                onTap: () => _handleOrgTap(doc.id, doc.data()),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleOrgTap(String orgId, Map<String, dynamic> data) async {
    widget.onOrgSelected(orgId);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EditOrganizationSheet(orgId: orgId, initialData: data),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Organization updated successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
