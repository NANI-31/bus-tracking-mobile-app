import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _allUsers = [];
  List<CollegeModel> _allColleges = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllUsers();
    _loadAllColleges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    firestoreService.getAllUsers().listen((users) {
      setState(() {
        _allUsers = users;
      });
    });
  }

  Future<void> _loadAllColleges() async {
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    firestoreService.getAllColleges().listen((colleges) {
      setState(() {
        _allColleges = colleges;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: 'Admin Panel - ${user?.fullName ?? 'Admin'}'.text.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor: AppColors.onPrimary.withValues(alpha: 0.7),
          indicatorColor: AppColors.onPrimary,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Colleges', icon: Icon(Icons.school)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview Tab
          VStack([
            'System Overview'.text
                .size(24)
                .bold
                .color(Theme.of(context).colorScheme.onSurface)
                .make(),
            AppSizes.paddingLarge.heightBox,

            // Statistics Cards
            HStack([
              _buildStatCard(
                'Total Colleges',
                _allColleges.length.toString(),
                Icons.school,
                Theme.of(context).primaryColor,
              ).expand(),
              AppSizes.paddingMedium.widthBox,
              _buildStatCard(
                'Verified Colleges',
                _allColleges.where((c) => c.verified).length.toString(),
                Icons.verified,
                Theme.of(context).colorScheme.secondary,
              ).expand(),
            ]),

            AppSizes.paddingMedium.heightBox,

            HStack([
              _buildStatCard(
                'Total Users',
                _allUsers.length.toString(),
                Icons.people,
                Theme.of(context).colorScheme.secondary,
              ).expand(),
              AppSizes.paddingMedium.widthBox,
              _buildStatCard(
                'Pending Approvals',
                _allUsers.where((u) => u.needsManualApproval).length.toString(),
                Icons.pending,
                Theme.of(context).colorScheme.error,
              ).expand(),
            ]),
          ]).p(AppSizes.paddingMedium),

          // Colleges Tab
          _allColleges.isEmpty
              ? VStack(
                  [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    AppSizes.paddingMedium.heightBox,
                    'No colleges registered yet'.text
                        .size(18)
                        .color(AppColors.textSecondary)
                        .make(),
                  ],
                  alignment: MainAxisAlignment.center,
                  crossAlignment: CrossAxisAlignment.center,
                ).centered()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: _allColleges.length,
                  itemBuilder: (context, index) {
                    final college = _allColleges[index];
                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: AppSizes.paddingMedium,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: college.verified
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.error,
                          child: Icon(
                            college.verified ? Icons.verified : Icons.pending,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                        title: Text(
                          college.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: VStack([
                          'Domains: ${college.allowedDomains.join(', ')}'.text
                              .make(),
                          'Status: ${college.verified ? 'Verified' : 'Pending Verification'}'
                              .text
                              .color(
                                college.verified
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.error,
                              )
                              .medium
                              .make(),
                        ]),
                        trailing: !college.verified
                            ? IconButton(
                                icon: Icon(
                                  Icons.check,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                onPressed: () {
                                  // College verification will be implemented in future updates
                                },
                              )
                            : null,
                        isThreeLine: true,
                      ),
                    );
                  },
                ),

          // Users Tab
          _allUsers.isEmpty
              ? VStack(
                  [
                    Icon(
                      Icons.people_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    AppSizes.paddingMedium.heightBox,
                    'No users found'.text
                        .size(18)
                        .color(AppColors.textSecondary)
                        .make(),
                  ],
                  alignment: MainAxisAlignment.center,
                  crossAlignment: CrossAxisAlignment.center,
                ).centered()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: _allUsers.length,
                  itemBuilder: (context, index) {
                    final user = _allUsers[index];
                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: AppSizes.paddingMedium,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.approved
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.error,
                          child: Icon(
                            user.approved ? Icons.check : Icons.pending,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                        title: Text(
                          user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: VStack([
                          user.email.text.make(),
                          if (user.phoneNumber != null &&
                              user.phoneNumber!.isNotEmpty)
                            'Phone: ${user.phoneNumber}'.text.make(),
                          'Role: ${user.role.displayName}'.text
                              .color(Theme.of(context).primaryColor)
                              .medium
                              .make(),
                          'Status: ${user.approved ? 'Approved' : 'Pending'}'
                              .text
                              .color(
                                user.approved
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.error,
                              )
                              .medium
                              .make(),
                        ]),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: VStack([
        Icon(icon, size: 32, color: color),
        AppSizes.paddingSmall.heightBox,
        value.text.size(24).bold.color(color).make(),
        AppSizes.paddingSmall.heightBox,
        title.text
            .size(14)
            .color(
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            )
            .center
            .make(),
      ], crossAlignment: CrossAxisAlignment.center).p(AppSizes.paddingMedium),
    );
  }
}
