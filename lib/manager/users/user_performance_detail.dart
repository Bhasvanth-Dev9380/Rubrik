import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

import '../Screens/CPTPage.dart';
import '../Screens/DashboardPage.dart';
import '../Screens/MetricsPage.dart';

class UserPerformanceDetailPage extends StatefulWidget {
  final String userId;
  final String userName;

  const UserPerformanceDetailPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserPerformanceDetailPage> createState() => _UserPerformanceDetailPageState();
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _UserPerformanceDetailPageState extends State<UserPerformanceDetailPage> {

  int _selectedIndex = 0;






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Color(0xFF001D4A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      widget.userName,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                _buildNavItem(Icons.dashboard, "Dashboard", 0),
                _buildNavItem(Icons.bar_chart, "Metrics", 1),
                _buildNavItem(Icons.category, "CPT", 2),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueGrey.shade900,
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(Icons.close),
                    label: Text("Close"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF001D4A),
                    Color(0xFF004BA0),
                    Color(0xFF0084FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.all(32),
              child: _buildSelectedPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final bool isSelected = _selectedIndex == index;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return DashboardPage(userId: widget.userId);
      case 1:
        return MetricsPage(userId: widget.userId,);
      case 2:
        return CPTPage();
      default:
        return Container();
    }
  }

}
