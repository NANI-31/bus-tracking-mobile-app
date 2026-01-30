import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/services/admin/super_admin_service.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/utils/constants.dart';

class CollegesTab extends StatefulWidget {
  const CollegesTab({super.key});

  @override
  State<CollegesTab> createState() => _CollegesTabState();
}

class _CollegesTabState extends State<CollegesTab> {
  String _searchQuery = '';
  bool? _verifiedFilter;

  Future<void> _verifyCollege(
    BuildContext context,
    CollegeModel college,
  ) async {
    try {
      // TODO: Add updateCollege method to DataService
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${college.name} verification - feature coming soon'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify college: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saService = Provider.of<SuperAdminService>(context);
    final allColleges = saService.colleges;

    final filteredColleges = allColleges.where((college) {
      if (_verifiedFilter != null && college.verified != _verifiedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return college.name.toLowerCase().contains(query) ||
            college.allowedDomains.any((d) => d.toLowerCase().contains(query));
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search colleges...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _verifiedFilter == null,
                      onSelected: (val) =>
                          setState(() => _verifiedFilter = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Verified'),
                      selected: _verifiedFilter == true,
                      onSelected: (val) =>
                          setState(() => _verifiedFilter = val ? true : null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Pending'),
                      selected: _verifiedFilter == false,
                      onSelected: (val) =>
                          setState(() => _verifiedFilter = val ? false : null),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredColleges.isEmpty
              ? const Center(child: Text('No colleges found'))
              : ListView.builder(
                  itemCount: filteredColleges.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMedium,
                  ),
                  itemBuilder: (context, index) {
                    final college = filteredColleges[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: college.verified
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          child: Icon(
                            Icons.school,
                            color: college.verified
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        title: Text(
                          college.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 4,
                              children: college.allowedDomains.map((d) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    d,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: !college.verified
                            ? ElevatedButton(
                                onPressed: () =>
                                    _verifyCollege(context, college),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                child: const Text('Verify'),
                              )
                            : const Icon(Icons.verified, color: Colors.green),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
