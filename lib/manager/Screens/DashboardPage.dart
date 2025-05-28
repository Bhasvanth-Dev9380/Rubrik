import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  final String userId;

  const DashboardPage({super.key, required this.userId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime selectedDate = DateTime.now();

  final Map<int, List<String>> quarters = {
    1: ['01', '02', '03'],
    2: ['04', '05', '06'],
    3: ['07', '08', '09'],
    4: ['10', '11', '12'],
  };

  int get selectedYear => selectedDate.year;

  String _getPerformanceLabel(double score) {
    if (score >= 192) return 'High Performer';
    if (score >= 162) return 'Average Performer';
    return 'Inconsistent Performer';
  }

  Future<void> _pickYear(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateTime(picked.year);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('performance')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.where((doc) => doc.id.startsWith('$selectedYear-')).toList();

        Map<String, Map<String, dynamic>> data = {};
        for (var doc in docs) {
          final score = (doc['score'] ?? 0).toDouble();
          data[doc.id] = {
            'score': score,
            'label': _getPerformanceLabel(score),
          };
        }

        double overallScore = 0;
        int scoreCount = 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Select Year: ",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _pickYear(context),
                  icon: Icon(Icons.calendar_today),
                  label: Text("$selectedYear"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueGrey.shade900,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Table header
            Container(
              color: Colors.white.withOpacity(0.1),
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text("Quarter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("Month", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text("Score", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("Ranking", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text("Avg", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
            ),

            ...quarters.entries.map((entry) {
              final quarter = entry.key;
              final months = entry.value;

              List<double> quarterScores = [];

              final rows = months.map((month) {
                final key = '$selectedYear-$month';
                final monthLabel = DateFormat('MMM-yyyy').format(DateTime.parse('$selectedYear-$month-01'));

                final score = (data[key]?['score'] ?? 0.0).toDouble();
                final label = data[key]?['label'] ?? '';
                if (score > 0) quarterScores.add(score);

                return Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Text("Q$quarter", style: TextStyle(color: Colors.white))),
                      Expanded(flex: 2, child: Text(monthLabel, style: TextStyle(color: Colors.white))),
                      Expanded(flex: 1, child: Text(score.toStringAsFixed(1), style: TextStyle(color: Colors.white))),
                      Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.white))),
                      Expanded(flex: 1, child: Text('', style: TextStyle(color: Colors.white))),
                    ],
                  ),
                );
              }).toList();

              final avgScore = quarterScores.isNotEmpty
                  ? (quarterScores.reduce((a, b) => a + b) / quarterScores.length)
                  : 0;

              if (avgScore > 0) {
                overallScore += avgScore;
                scoreCount++;
              }

              return Column(
                children: [
                  ...rows,
                  if (quarterScores.isNotEmpty)
                    Container(
                      color: Colors.white.withOpacity(0.05),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: SizedBox()),
                          Expanded(flex: 2, child: Text("")),
                          Expanded(flex: 1, child: Text("")),
                          Expanded(flex: 2, child: Text("")),
                          Expanded(
                            flex: 1,
                            child: Text(avgScore.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }).toList(),

            SizedBox(height: 24),
            if (scoreCount > 0)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Overall Score for $selectedYear",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (overallScore / scoreCount).toStringAsFixed(1),
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _getPerformanceLabel(overallScore / scoreCount),
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    )
                  ],
                ),
              )
          ],
        );
      },
    );
  }
}
