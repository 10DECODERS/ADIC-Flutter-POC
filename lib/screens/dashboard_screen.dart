import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Added fl_chart import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock data for the chart
  final List<double> _newHiresData = [18, 10, 20, 25, 18, 15]; // Jan to Jun
  final List<double> _leavesData = [13, 14, 13, 13, 9, 0]; // Jan to Jun (Assuming 0 for Jun)
  final List<String> _months = ['Jan', 'Mar', 'Apr', 'May', 'Jun']; // Corrected months based on image

  // Define bar width and spacing
  final double _barWidth = 16.0;
  final double _barSpace = 4.0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color consistentBlue = Colors.blue.shade700; // Define the consistent blue color

    return Scaffold(
      // Added AppBar similar to StaffScreen
      appBar: AppBar(
        elevation: 0, // Match StaffScreen
        backgroundColor: consistentBlue, // Use consistent blue
        title: const Text(
          'Dashboard', // Set title to Dashboard
          style: TextStyle(
            color: Colors.white, // Match StaffScreen title style
            fontWeight: FontWeight.bold,
          ),
        ),
        // actions: [], // No actions added for now, can be added here if needed
      ),
      body: SingleChildScrollView( // Added SingleChildScrollView for responsiveness
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staffing & HR',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your workforce effectively',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement View Insights action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: consistentBlue, // Use consistent blue
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: theme.textTheme.titleMedium,
                  ),
                  child: const Text('View Insights'),
                ),
              ),
              const SizedBox(height: 32),
              // Summary Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard(context, '240', 'TOTAL EMPLOYEES'),
                  const SizedBox(width: 16), // Spacing between cards
                  _buildSummaryCard(context, '12', 'PENDING LEAVES'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard(context, '110', 'APPROVED REQUESTS'),
                  const SizedBox(width: 16), // Spacing between cards
                  _buildSummaryCard(context, '5', 'APPROVERS'),
                ],
              ),
              const SizedBox(height: 32),
              // Monthly KPIs Section
              Text(
                'Monthly KPIs',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start, // Align legend to start
                children: [
                  _buildLegendItem(context, consistentBlue, 'New Hires'), // Use consistent blue
                  const SizedBox(width: 16),
                  _buildLegendItem(context, Colors.grey[400]!, 'Leaves'),
                ],
              ),
              const SizedBox(height: 16),
              // --- Bar Chart Implementation ---
              SizedBox(
                height: 200, // Keep height consistent
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    maxY: 30, // Set max Y based on image
                    minY: 0,
                    groupsSpace: (_barWidth + _barSpace) * 2, // Calculate space needed between month groups
                    borderData: FlBorderData(
                      show: false, // Hide border
                    ),
                    gridData: const FlGridData(
                      show: false, // Hide grid lines
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 10, // Y-axis interval
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == 10 || value == 20 || value == 30) {
                              return Text(
                                value.toInt().toString(),
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.left,
                              );
                            }
                            return Container();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < _months.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0), // Adjust padding if needed
                                child: Text(
                                  _months[index],
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            }
                            return Container();
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: _buildBarGroups(colorScheme, consistentBlue), // Pass consistent blue to helper
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String label = rodIndex == 0 ? 'New Hires' : 'Leaves';
                          return BarTooltipItem(
                            '$label\n${rod.toY.round()}',
                            TextStyle(color: colorScheme.onPrimary, fontSize: 12),
                          );
                        },
                        getTooltipColor: (group) => Colors.black87,
                      ),
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 150), // Optional animation
                  swapAnimationCurve: Curves.linear, // Optional animation curve
                ),
              ),
              // --- End Bar Chart ---
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build BarChartGroup data
  List<BarChartGroupData> _buildBarGroups(ColorScheme colorScheme, Color newHiresColor) { // Accept color parameter
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < _months.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i, // Index representing the month
          barRods: [
            // New Hires bar
            BarChartRodData(
              toY: _newHiresData[i],
              color: newHiresColor, // Use consistent blue for New Hires
              width: _barWidth,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            // Leaves bar
            BarChartRodData(
              toY: _leavesData[i],
              color: Colors.grey[400]!, // Grey color for Leaves
              width: _barWidth,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
          // Optional: showing tooltip on top
          // showingTooltipIndicators: [0, 1], // Show tooltip for both bars if needed
        ),
      );
    }
    return barGroups;
  }

  // Helper widget for summary cards
  Widget _buildSummaryCard(BuildContext context, String value, String label) {
    final ThemeData theme = Theme.of(context);
    return Expanded( // Use Expanded to make cards fill available space
      child: Card(
        elevation: 1.0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        // Added SizedBox to enforce consistent height
        child: SizedBox(
          height: 120, // Adjust this height as needed for your content
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0), // Adjusted padding slightly
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center content vertically within the fixed height
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for legend items
  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
} 