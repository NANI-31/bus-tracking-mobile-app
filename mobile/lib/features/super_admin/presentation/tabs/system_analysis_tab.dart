import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collegebus/features/super_admin/application/super_admin_provider.dart';
import 'package:collegebus/features/super_admin/application/system_analysis_provider.dart';

class SystemAnalysisTab extends ConsumerStatefulWidget {
  const SystemAnalysisTab({super.key});

  @override
  ConsumerState<SystemAnalysisTab> createState() => _SystemAnalysisTabState();
}

class _SystemAnalysisTabState extends ConsumerState<SystemAnalysisTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCollegeId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  int? _lastTouchedTrendsIndex;
  int? _lastTouchedTenantIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(systemAnalysisProvider.notifier).fetchStorageStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double _parseSize(dynamic size) {
    if (size == null) return 0.0;
    if (size is num) return size.toDouble();
    final str = size.toString().toLowerCase().trim();
    
    // Extract the numeric portion (digits and decimal points)
    final RegExp numericRegex = RegExp(r'[0-9\.]+');
    final match = numericRegex.firstMatch(str);
    if (match == null) return 0.0;
    
    final value = double.tryParse(match.group(0)!) ?? 0.0;
    
    if (str.contains('g')) return value * 1024; // GB or G
    if (str.contains('k')) return value / 1024; // KB or K
    if (str.contains('b') && !str.contains('m') && !str.contains('k') && !str.contains('g')) {
      // If size is represented in bytes only, convert to MB
      return value / (1024 * 1024);
    }
    return value; // MB or M
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
      if (_selectedCollegeId != null) {
        _fetchHistory();
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      if (_selectedCollegeId != null) {
        _fetchHistory();
      }
    }
  }

  void _fetchHistory() {
    if (_selectedCollegeId == null) return;
    ref.read(systemAnalysisProvider.notifier).fetchCollegeStorageHistory(
          _selectedCollegeId!,
          startDate: DateFormat('yyyy-MM-dd').format(_startDate),
          endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        );
  }

  List<dynamic> _downsampleHistory(List<dynamic> history, int maxPoints) {
    if (history.length <= maxPoints) return history;
    
    final List<dynamic> result = [];
    final double bucketSize = history.length / maxPoints;
    
    // Always include the first point
    result.add(history.first);
    
    for (int i = 1; i < maxPoints - 1; i++) {
      final int start = (i * bucketSize).floor();
      final int end = ((i + 1) * bucketSize).floor();
      
      double sumEstimated = 0;
      double sumS3 = 0;
      int sumUsers = 0;
      int sumBuses = 0;
      
      int count = 0;
      for (int j = start; j < end && j < history.length; j++) {
        final entry = history[j] as Map<String, dynamic>;
        sumEstimated += _parseSize(entry['estimatedStorageMB']);
        sumS3 += _parseSize(entry['s3StorageMB']);
        final counts = entry['counts'] as Map<String, dynamic>? ?? {};
        sumUsers += (counts['users'] as num? ?? 0).toInt();
        sumBuses += (counts['buses'] as num? ?? 0).toInt();
        count++;
      }
      
      if (count > 0) {
        final midIndex = ((start + end) / 2).floor().clamp(0, history.length - 1);
        final template = history[midIndex] as Map<String, dynamic>;
        
        result.add({
          'date': template['date'],
          'estimatedStorageMB': sumEstimated / count,
          's3StorageMB': sumS3 / count,
          'counts': {
            'users': (sumUsers / count).round(),
            'buses': (sumBuses / count).round(),
          }
        });
      }
    }
    
    // Always include the last point to preserve latest accurate data
    result.add(history.last);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final superAdminState = ref.watch(superAdminServiceProvider).valueOrNull;
    final colleges = superAdminState?.colleges ?? [];

    return Column(
      children: [
        // Tab Header Segmented Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorPadding: EdgeInsets.zero,
            indicator: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: isDark ? Colors.white : Colors.black87,
            unselectedLabelColor: isDark ? Colors.white38 : Colors.black45,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: const [
              Tab(text: 'Infrastructure'),
              Tab(text: 'Tenant Distribution'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInfrastructureView(isDark),
              _buildTenantView(colleges, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfrastructureView(bool isDark) {
    final analysisState = ref.watch(systemAnalysisProvider);

    if (analysisState.isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (analysisState.statsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load storage statistics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                analysisState.statsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(systemAnalysisProvider.notifier).fetchStorageStats(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stats = analysisState.storageStats;
    if (stats == null) {
      return const Center(child: Text('No stats available'));
    }

    final mongo = stats['mongodb'] as Map<String, dynamic>? ?? {};
    final redis = stats['redis'] as Map<String, dynamic>? ?? {};
    final s3 = stats['s3'] as Map<String, dynamic>? ?? {};
    final history = stats['history'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(systemAnalysisProvider.notifier).fetchStorageStats();
      },
      color: Colors.deepPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          children: [
            // MongoDB Card
            _buildMongoCard(mongo, isDark),
            const SizedBox(height: 16),

            // Redis & S3 Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildRedisCard(redis, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildS3Card(s3, isDark)),
              ],
            ),
            const SizedBox(height: 16),

            // 24 Hour storage trends
            _buildTrendsCard(history, isDark),
            const SizedBox(height: 16),

            // Infrastructure insights info card
            _buildInsightsCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMongoCard(Map<String, dynamic> mongo, bool isDark) {
    final double dataSize = _parseSize(mongo['dataSize']);
    final double indexSize = _parseSize(mongo['indexSize']);
    final double storageSize = _parseSize(mongo['storageSize']);
    final double overhead = (storageSize - dataSize - indexSize).clamp(0.0, double.infinity);

    final double totalForChart = dataSize + indexSize + overhead;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E90FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.storage_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'MongoDB Primary Storage',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Donut Chart
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 120,
                    child: totalForChart == 0
                        ? const Center(child: Text('No data'))
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 32,
                              sections: [
                                PieChartSectionData(
                                  value: dataSize,
                                  color: const Color(0xFF1E90FF),
                                  radius: 12,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: indexSize,
                                  color: const Color(0xFF8B5CF6),
                                  radius: 12,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: overhead,
                                  color: const Color(0xFFA5B4FC),
                                  radius: 12,
                                  showTitle: false,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details Grid/List
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      _buildMiniMetric('Collections', '${mongo['collections'] ?? 0}', null, isDark),
                      _buildMiniMetric('Documents', '${mongo['objects'] ?? 0}', null, isDark),
                      _buildMiniMetric('Data Size', '${mongo['dataSize'] ?? '0.00 MB'}', const Color(0xFF1E90FF), isDark),
                      _buildMiniMetric('Index Size', '${mongo['indexSize'] ?? '0.00 MB'}', const Color(0xFF8B5CF6), isDark),
                      _buildMiniMetric('Disk Storage', '${mongo['storageSize'] ?? '0.00 MB'}', const Color(0xFFA5B4FC), isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color? indicatorColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (indicatorColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedisCard(Map<String, dynamic> redis, bool isDark) {
    final double used = _parseSize(redis['usedMemory']);
    final double peak = _parseSize(redis['peakMemory']);
    final double maxVal = (peak > 0 ? peak : (used > 0 ? used * 1.5 : 10.0));

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE11D48),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Redis Cache',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frag Ratio: ${redis['fragmentation'] ?? '0.0'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => isDark ? const Color(0xFF1E293B) : Colors.white,
                            tooltipBorder: BorderSide(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                              width: 1,
                            ),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final valueStr = rodIndex == 0
                                  ? (redis['usedMemory'] ?? '0.00 MB')
                                  : (redis['peakMemory'] ?? '0.00 MB');
                              return BarTooltipItem(
                                valueStr,
                                TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              );
                            },
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: used,
                                color: const Color(0xFFF43F5E),
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxVal,
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                ),
                              ),
                              BarChartRodData(
                                toY: peak,
                                color: const Color(0xFFFB7185),
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxVal,
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPillLegend('Used: ${redis['usedMemory'] ?? '0.00 MB'}', const Color(0xFFF43F5E)),
                      _buildPillLegend('Peak: ${redis['peakMemory'] ?? '0.00 MB'}', const Color(0xFFFB7185)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildS3Card(Map<String, dynamic> s3, bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFF9900),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_queue_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'AWS S3 Assets',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s3['totalSize'] ?? '0.00 MB',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'TOTAL VOICE NOTES',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                  const SizedBox(height: 12),
                  _buildS3MetricRow('Voice Notes', '${s3['objectCount'] ?? 0}', isDark),
                  const SizedBox(height: 4),
                  _buildS3MetricRow('Retention', '5 Days', isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildS3MetricRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsCard(List<dynamic> history, bool isDark) {
    if (history.isEmpty) return const SizedBox.shrink();

    // Map history to FlSpot lists
    final List<FlSpot> mongoSpots = [];
    final List<FlSpot> redisSpots = [];
    final List<FlSpot> s3Spots = [];

    for (int i = 0; i < history.length; i++) {
      final entry = history[i] as Map<String, dynamic>;
      final double idx = i.toDouble();

      final mongoSize = _parseSize(entry['mongodb']?['storageSize']);
      final redisSize = _parseSize(entry['redis']?['usedMemoryBytes']) / (1024 * 1024); // to MB
      final s3Size = _parseSize(entry['s3']?['totalSize']);

      mongoSpots.add(FlSpot(idx, mongoSize));
      redisSpots.add(FlSpot(idx, redisSize));
      s3Spots.add(FlSpot(idx, s3Size));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '24-HOUR STORAGE TRENDS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white54 : Colors.grey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    if (!event.isInterestedForInteractions ||
                        touchResponse == null ||
                        touchResponse.lineBarSpots == null ||
                        touchResponse.lineBarSpots!.isEmpty) {
                      return;
                    }
                    final int index = touchResponse.lineBarSpots!.first.spotIndex;
                    if (index != _lastTouchedTrendsIndex) {
                      _lastTouchedTrendsIndex = index;
                      HapticFeedback.lightImpact();
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => isDark ? const Color(0xFF1E293B) : Colors.white,
                    tooltipBorder: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      width: 1,
                    ),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      if (touchedSpots.isEmpty) return [];
                      
                      final int index = touchedSpots.first.x.toInt();
                      if (index < 0 || index >= history.length) return [];
                      
                      final entry = history[index] as Map<String, dynamic>;
                      
                      String timeStr = '';
                      try {
                        final parsedDate = DateTime.parse(entry['timestamp']);
                        timeStr = DateFormat('HH:mm').format(parsedDate.toLocal());
                      } catch (_) {
                        timeStr = entry['timestamp']?.toString() ?? '';
                      }
                      
                      final mongoVal = _parseSize(entry['mongodb']?['storageSize']).toStringAsFixed(2);
                      final redisVal = (_parseSize(entry['redis']?['usedMemoryBytes']) / (1024 * 1024)).toStringAsFixed(2);
                      final s3Val = _parseSize(entry['s3']?['totalSize']).toStringAsFixed(2);
                      
                      return touchedSpots.asMap().entries.map((e) {
                        if (e.key != 0) return null;
                        return LineTooltipItem(
                          'Time: $timeStr\n',
                          TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: 'Mongo: $mongoVal MB\n',
                              style: const TextStyle(
                                color: Color(0xFF1E90FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            TextSpan(
                              text: 'Redis: $redisVal MB\n',
                              style: const TextStyle(
                                color: Color(0xFFF43F5E),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            TextSpan(
                              text: 'S3: $s3Val MB',
                              style: const TextStyle(
                                color: Color(0xFFFF9900),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: mongoSpots,
                    isCurved: true,
                    color: const Color(0xFF1E90FF),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1E90FF).withValues(alpha: 0.05),
                    ),
                  ),
                  LineChartBarData(
                    spots: redisSpots,
                    isCurved: true,
                    color: const Color(0xFFF43F5E),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.05),
                    ),
                  ),
                  LineChartBarData(
                    spots: s3Spots,
                    isCurved: true,
                    color: const Color(0xFFFF9900),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFF9900).withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPillLegend('MongoDB Storage', const Color(0xFF1E90FF)),
              _buildPillLegend('Redis Memory', const Color(0xFFF43F5E)),
              _buildPillLegend('AWS S3 Assets', const Color(0xFFFF9900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E90FF).withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E90FF).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF1E90FF),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Infrastructure Insight',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These metrics reflect the current load on the primary storage and caching layers. Monitor fragmentation ratio and storage size closely to ensure optimal performance. High fragmentation may indicate a need for cache eviction policy reviews.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantView(List<dynamic> colleges, bool isDark) {
    final analysisState = ref.watch(systemAnalysisProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          // Select Tenant Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E90FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: Color(0xFF1E90FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Per-College Analysis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Text(
                            'Track storage and document growth by tenant',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Selection Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCollegeId,
                      hint: const Text('Select a College', style: TextStyle(fontSize: 13)),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      items: colleges.map<DropdownMenuItem<String>>((c) {
                        return DropdownMenuItem<String>(
                          value: c.id as String,
                          child: Text(c.name as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCollegeId = value;
                        });
                        _fetchHistory();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Date Filters Box
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectStartDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('yyyy-MM-dd').format(_startDate),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('to', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectEndDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('yyyy-MM-dd').format(_endDate),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detail Section or Placeholder
          _selectedCollegeId == null
              ? _buildTenantPlaceholder(isDark)
              : analysisState.isLoadingHistory
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _buildTenantStatsSection(analysisState.collegeStorageHistory, isDark),
        ],
      ),
    );
  }

  Widget _buildTenantPlaceholder(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 44,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          const Text(
            'Select a college to view storage metrics and trends',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantStatsSection(List<dynamic> history, bool isDark) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Text(
          'No historical records found for this timeframe.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    // Process down-sampling virtualization for range > 60 days
    final int days = _endDate.difference(_startDate).inDays.abs();
    final List<dynamic> displayedHistory = days > 60
        ? _downsampleHistory(history, 30)
        : history;

    // Process Spots
    final List<FlSpot> storageSpots = [];
    final List<FlSpot> s3Spots = [];

    for (int i = 0; i < displayedHistory.length; i++) {
      final entry = displayedHistory[i] as Map<String, dynamic>;
      final double idx = i.toDouble();
      final storageVal = _parseSize(entry['estimatedStorageMB']);
      final s3Val = _parseSize(entry['s3StorageMB']);

      storageSpots.add(FlSpot(idx, storageVal));
      s3Spots.add(FlSpot(idx, s3Val));
    }

    final latestEntry = history.last as Map<String, dynamic>;
    final counts = latestEntry['counts'] as Map<String, dynamic>? ?? {};

    final activeUsers = counts['users'] ?? 0;
    final totalBuses = counts['buses'] ?? 0;
    final s3MB = _parseSize(latestEntry['s3StorageMB']).toStringAsFixed(2);

    return Column(
      children: [
        // Line Chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STORAGE TREND',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white54 : Colors.grey,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                        if (!event.isInterestedForInteractions ||
                            touchResponse == null ||
                            touchResponse.lineBarSpots == null ||
                            touchResponse.lineBarSpots!.isEmpty) {
                          return;
                        }
                        final int index = touchResponse.lineBarSpots!.first.spotIndex;
                        if (index != _lastTouchedTenantIndex) {
                          _lastTouchedTenantIndex = index;
                          HapticFeedback.lightImpact();
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => isDark ? const Color(0xFF1E293B) : Colors.white,
                        tooltipBorder: BorderSide(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          width: 1,
                        ),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          if (touchedSpots.isEmpty) return [];
                          
                          final int index = touchedSpots.first.x.toInt();
                          if (index < 0 || index >= displayedHistory.length) return [];
                          
                          final entry = displayedHistory[index] as Map<String, dynamic>;
                          
                          String dateStr = '';
                          try {
                            final parsedDate = DateTime.parse(entry['date']);
                            dateStr = DateFormat('MMM dd').format(parsedDate.toLocal());
                          } catch (_) {
                            dateStr = entry['date']?.toString() ?? '';
                          }
                          
                          final dbVal = _parseSize(entry['estimatedStorageMB']).toStringAsFixed(2);
                          final s3Val = _parseSize(entry['s3StorageMB']).toStringAsFixed(2);
                          
                          return touchedSpots.asMap().entries.map((e) {
                            if (e.key != 0) return null;
                            return LineTooltipItem(
                              'Date: $dateStr\n',
                              TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              children: [
                                TextSpan(
                                  text: 'DB Storage: $dbVal MB\n',
                                  style: const TextStyle(
                                    color: Color(0xFF1E90FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                TextSpan(
                                  text: 'S3 Assets: $s3Val MB',
                                  style: const TextStyle(
                                    color: Color(0xFFFF9900),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (val) => FlLine(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: storageSpots,
                        isCurved: true,
                        color: const Color(0xFF1E90FF),
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF1E90FF).withValues(alpha: 0.05),
                        ),
                      ),
                      LineChartBarData(
                        spots: s3Spots,
                        isCurved: true,
                        color: const Color(0xFFFF9900),
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFFFF9900).withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPillLegend('DB Storage (MB)', const Color(0xFF1E90FF)),
                  _buildPillLegend('S3 Assets (MB)', const Color(0xFFFF9900)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Breakdown grid (Cards Row/Grid)
        Row(
          children: [
            Expanded(
              child: _buildBreakdownCard(
                'Active Users',
                '$activeUsers',
                const Color(0xFFEFF6FF),
                const Color(0xFF1D4ED8),
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBreakdownCard(
                'Total Buses',
                '$totalBuses',
                const Color(0xFFFFF1F2),
                const Color(0xFFBE123C),
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBreakdownCard(
                'S3 Assets',
                '${s3MB}MB',
                const Color(0xFFFEF3C7),
                const Color(0xFFB45309),
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Technical note
        _buildTechnicalNoteCard(isDark),
      ],
    );
  }

  Widget _buildBreakdownCard(
    String label,
    String value,
    Color bg,
    Color textCol,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? bg.withValues(alpha: 0.08) : bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? textCol.withValues(alpha: 0.15) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? textCol.withValues(alpha: 0.85) : textCol,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalNoteCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Storage metrics for colleges are estimated based on document counts across core collections multiplied by the global average object size. Detailed byte-level filtering is partially sampled from the primary metadata store.',
              style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedRadialProgressRing extends StatefulWidget {
  final double percentage;
  final double size;

  const AnimatedRadialProgressRing({
    super.key,
    required this.percentage,
    this.size = 64,
  });

  @override
  State<AnimatedRadialProgressRing> createState() => _AnimatedRadialProgressRingState();
}

class _AnimatedRadialProgressRingState extends State<AnimatedRadialProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedRadialProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.percentage,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RadialProgressPainter(
            progress: _animation.value,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _RadialProgressPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _RadialProgressPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF9900), Color(0xFFFFC04D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFFFF9900).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    const startAngle = -3.14159 / 2;
    final sweepAngle = 2 * 3.14159 * progress.clamp(0.0, 1.0);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).toInt()}%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant _RadialProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
