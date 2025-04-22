import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = Colors.white;
    final cardShadowColor = Colors.black.withOpacity(0.05);
    final cardBorderRadius = BorderRadius.circular(12);

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Light grey background
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Summary Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4, // Adjust aspect ratio as needed
            children: [
              _buildSummaryCard(
                context,
                title: 'Annual Leave Balance',
                value: '20',
                icon: Icons.calendar_today,
                color: Colors.teal.shade50,
                valueColor: Colors.teal.shade800,
                iconColor: Colors.teal.shade600,
              ),
              _buildSummaryCard(
                context,
                title: 'Sick Leave Balance',
                value: '2',
                icon: Icons.local_hospital_outlined,
                color: Colors.green.shade50,
                valueColor: Colors.green.shade800,
                iconColor: Colors.green.shade600,
              ),
              _buildSummaryCard(
                context,
                title: 'Utilized Short Sick Leave days',
                value: '2',
                icon: Icons.sentiment_dissatisfied_outlined,
                color: Colors.yellow.shade50,
                valueColor: Colors.orange.shade900,
                iconColor: Colors.orange.shade800,
              ),
              _buildSummaryCard(
                context,
                title: 'Overtime hours',
                value: '10',
                icon: Icons.timer_outlined,
                color: Colors.red.shade50,
                valueColor: Colors.red.shade900,
                iconColor: Colors.red.shade700,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Leave History Title
          Text(
            'Leave History Request',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          // Leave History List
          _buildLeaveRequestCard(
            context,
            serviceName: 'Annual Leave',
            dateRange: 'Mar 10, 2025 - Mar 25, 2025',
            applyDays: '15 Days',
            leaveBalance: '15 Days',
            status: 'Pending Approval',
            statusColor: Colors.orange.shade600,
            statusBgColor: Colors.orange.shade50,
            date: 'Mar 06, 2025',
          ),
          const SizedBox(height: 12),
          _buildLeaveRequestCard(
            context,
            serviceName: 'Annual Leave',
            dateRange: 'Mar 10, 2025 - Mar 25, 2025',
            applyDays: '15 Days',
            leaveBalance: '15 Days',
            status: 'Approved',
            statusColor: Colors.green.shade700,
            statusBgColor: Colors.green.shade50,
            date: 'Mar 06, 2025',
            approvedBy: 'Aisha Al Hosani',
          ),
           const SizedBox(height: 12),
           _buildLeaveRequestCard(
            context,
            serviceName: 'Sick Leave',
            dateRange: 'Apr 01, 2025 - Apr 02, 2025',
            applyDays: '2 Days',
            leaveBalance: '0 Days', // Example
            status: 'Rejected',
            statusColor: Colors.red.shade700,
            statusBgColor: Colors.red.shade50,
            date: 'Mar 28, 2025',
            rejectedBy: 'System', // Example
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color valueColor,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valueColor.withOpacity(0.8),
                    ),
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 20, color: iconColor.withOpacity(0.7)),
              ],
            ),

            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveRequestCard(
    BuildContext context, {
    required String serviceName,
    required String dateRange,
    required String applyDays,
    required String leaveBalance,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required String date,
    String? approvedBy,
    String? rejectedBy, // Add rejectedBy
  }) {
    final theme = Theme.of(context);
    final cardBorderRadius = BorderRadius.circular(12);
    final cardColor = Colors.white;
    final cardShadowColor = Colors.black.withOpacity(0.05);

    return Card(
      elevation: 1.5,
      shadowColor: cardShadowColor,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Name: $serviceName',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateRange,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 3,
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                       Text(
                          date,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _buildDetailItem(context, 'Apply Days', applyDays)),
                Flexible(child: _buildDetailItem(context, 'Leave Balance', leaveBalance)),
                if (approvedBy != null)
                  Flexible(child: _buildDetailItem(context, 'Approved By', approvedBy, valueColor: theme.colorScheme.primary)),
                 if (rejectedBy != null) // Show rejectedBy if available
                  Flexible(child: _buildDetailItem(context, 'Rejected By', rejectedBy)),
              ],
            ),
             const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View Details'),
                onPressed: () {
                  // TODO: Implement View Details action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade400, // Keep this specific shade for this button
                  foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildDetailItem(BuildContext context, String label, String value, {Color? valueColor}) {
     final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
} 