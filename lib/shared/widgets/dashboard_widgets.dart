import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_ronda_ti/app/theme.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2), 
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 15,
              spreadRadius: -5,
            )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (isDark)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTheme.monoStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.deepNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Color? color;

  const SectionTitle({super.key, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryColor, primaryColor.withValues(alpha: 0.5)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          margin: const EdgeInsets.only(right: 12),
        ),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: isDark ? Colors.white : AppTheme.deepNavy,
          ),
        ),
      ],
    );
  }
}

class RankingItem extends StatelessWidget {
  final String label;
  final int count;
  final double progress;
  final Color color;
  final String suffix;

  const RankingItem({
    super.key,
    required this.label,
    required this.count,
    required this.progress,
    required this.color,
    this.suffix = "rondas",
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.deepNavy,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                count.toString(),
                style: AppTheme.monoStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                width: MediaQuery.of(context).size.width * 0.5 * progress, // Simplified width
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    if (isDark)
                      BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrendChart extends StatelessWidget {
  final Map<String, int> data;
  final Color color;

  const TrendChart({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keys = data.keys.toList();
    final values = data.values.toList();
    
    double maxY = values.isNotEmpty ? values.map((e) => e.toDouble()).reduce((a, b) => a > b ? a : b) : 10;
    if (maxY < 5) maxY = 5;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < keys.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(keys[idx], style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.grey)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (keys.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
              isCurved: true,
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.3)]),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: isDark ? AppTheme.deepNavy : Colors.white,
                  strokeWidth: 2,
                  strokeColor: color,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoverageChart extends StatelessWidget {
  final double auditado;
  final double pendente;

  const CoverageChart({super.key, required this.auditado, required this.pendente});

  @override
  Widget build(BuildContext context) {
    final total = auditado + pendente;
    final percent = total > 0 ? (auditado / total * 100).toStringAsFixed(1) : "0";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: AppTheme.electricBlue,
                  value: auditado,
                  title: '',
                  radius: 12,
                  badgeWidget: _badge(percent, AppTheme.electricBlue),
                  badgePositionPercentageOffset: .98,
                ),
                PieChartSectionData(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  value: pendente > 0 ? pendente : 1,
                  title: '',
                  radius: 8,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$percent%",
                style: AppTheme.monoStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.deepNavy,
                ),
              ),
              Text(
                "HEALTH",
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String p, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 10),
    );
  }
}

class CriticalAlertBanner extends StatelessWidget {
  final List<String> alerts;
  const CriticalAlertBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.ruby.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.ruby.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: alerts.map((a) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: AppTheme.ruby, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  a, 
                  style: const TextStyle(
                    color: AppTheme.ruby, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 13,
                  )
                )
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class GoalProgressCard extends StatelessWidget {
  final String title;
  final double current;
  final double goal;
  final Color color;
  final String unit;

  const GoalProgressCard({
    super.key,
    required this.title,
    required this.current,
    required this.goal,
    required this.color,
    this.unit = "",
  });

  @override
  Widget build(BuildContext context) {
    final double percent = goal > 0 ? (current / goal).clamp(0.0, 1.2) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            title, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.grey)
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 90,
            width: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withValues(alpha: 0.4)],
                  ).createShader(rect),
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: color.withValues(alpha: 0.05),
                    color: Colors.white,
                  ),
                ),
                Text(
                  "${(percent * 100).toInt()}%",
                  style: AppTheme.monoStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "${current.toInt()} / ${goal.toInt()}",
            style: AppTheme.monoStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            unit.toUpperCase(),
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ComparisonChart extends StatelessWidget {
  final Map<String, Map<String, int>> data;
  final String metric;
  final Color color;

  const ComparisonChart({
    super.key,
    required this.data,
    required this.metric,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < keys.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        keys[idx].substring(0, 3).toUpperCase(), 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey)
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: keys.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: data[e.value]![metric]!.toDouble(),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, color.withValues(alpha: 0.6)],
                  ),
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class StatusIndicatorCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const StatusIndicatorCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.1)),
      ),
      color: isDark ? AppTheme.charcoal : Colors.white,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 12,
            letterSpacing: 0.5,
            color: isDark ? Colors.white70 : AppTheme.deepNavy,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            count,
            style: AppTheme.monoStyle(
              color: color, 
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
