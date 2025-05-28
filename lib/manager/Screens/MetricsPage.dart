import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MetricsPage extends StatefulWidget {
  final String userId;
  const MetricsPage({super.key, required this.userId});

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  DateTime _selectedMonth = DateTime.now();
  Map<String, dynamic> selectedMetrics = {};

  final List<String> _ratingOptions = [
    'Highly Met (Very Good)',
    'Met (Good)',
    'Partially Met (Average)',
    'Not Met (Need Improvement)',
    'Need to Focus(Yet to Start)'
  ];

  String get _formattedMonth => DateFormat('yyyy-MM').format(_selectedMonth);

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF00B4D8),
              onPrimary: Colors.white,
              surface: Color(0xFF004BA0),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedMonth = DateFormat('yyyy-MM').format(picked);
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('performance')
          .doc(formattedMonth)
          .get();

      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        selectedMetrics = {}; // ✅ Clear controller before loading new data
        selectedMetrics = (docSnapshot.data()?['metrics'] as Map?)?.cast<String, dynamic>() ?? {};
      });
    }

  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Monthly Performance",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Selected Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickMonth(context),
                    icon: Icon(Icons.date_range),
                    label: Text("Pick Month"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueGrey.shade900,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Metrics UI
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('performance_categories').snapshots(),
                builder: (context, categoriesSnapshot) {
                  if (!categoriesSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  Map<String, List<String>> categoryMetrics = {};
                  for (var doc in categoriesSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final List<dynamic> metrics = data['metrics'] ?? [];
                    final String categoryName = data['name'] ?? "Unnamed Category";
                    categoryMetrics[categoryName] = metrics.cast<String>();
                  }

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('performance')
                        .doc(_formattedMonth)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.data() != null) {
                        selectedMetrics = Map<String, dynamic>.from(
                            (snapshot.data!.data() as Map<String, dynamic>)['metrics'] ?? {});
                      }

                      return Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Metrics for $_formattedMonth",
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),

                            ...categoryMetrics.entries.map((entry) {
                              final category = entry.key;
                              final metrics = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category, style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                  ...metrics.map((metric) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(metric, style: TextStyle(color: Colors.white)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: DropdownButtonFormField<String>(
                                              value: selectedMetrics[metric],
                                              dropdownColor: Colors.blueGrey.shade900,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.white.withOpacity(0.1),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              items: _ratingOptions.map((rating) {
                                                return DropdownMenuItem<String>(
                                                  value: rating,
                                                  child: Text(rating, style: TextStyle(color: Colors.white)),
                                                );
                                              }).toList(),
                                              onChanged: (value) async {
                                                if (value != null) {
                                                  setState(() {
                                                    selectedMetrics[metric] = value;
                                                  });

                                                  // Points mapping
                                                  final Map<String, double> pointsMap = {
                                                    'Highly Met (Very Good)': 4.0,
                                                    'Met (Good)': 3.0,
                                                    'Not Met (Need Improvement)': 1.0,
                                                    'Partially Met (Average)': 1.5,
                                                    'Need to Focus(Yet to Start)': 0.0,
                                                  };

                                                  // Count categories
                                                  Map<String, int> categoryCounts = {
                                                    'Highly Met (Very Good)': 0,
                                                    'Met (Good)': 0,
                                                    'Not Met (Need Improvement)': 0,
                                                    'Partially Met (Average)': 0,
                                                    'Need to Focus(Yet to Start)': 0,
                                                  };

                                                  double totalScore = 0.0;

                                                  selectedMetrics.forEach((key, val) {
                                                    if (pointsMap.containsKey(val)) {
                                                      categoryCounts[val] = (categoryCounts[val] ?? 0) + 1;
                                                      totalScore += pointsMap[val]!;
                                                    }
                                                  });

                                                  await FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(widget.userId)
                                                      .collection('performance')
                                                      .doc(_formattedMonth)
                                                      .set({
                                                    'metrics': selectedMetrics,
                                                    'score': totalScore,
                                                    'category_counts': categoryCounts,
                                                  }, SetOptions(merge: true));
                                                }
                                              },

                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),

                                  Divider(color: Colors.white24, height: 32,),

                                ],
                              );
                            }).toList(),
                            Divider(color: Colors.white24, height: 64,thickness: 4,),


                            if (snapshot.hasData && snapshot.data!.data() != null) ...[
                              SizedBox(height: 32),
                              Text(
                                "Category Summary",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text("Category", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                        Expanded(child: Text("Count", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                        Expanded(child: Text("Score", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                    Divider(color: Colors.white24),
                                    ...((snapshot.data!.data() as Map<String, dynamic>)['category_counts'] ?? {})
                                        .entries
                                        .map<Widget>((entry) {
                                      final label = entry.key;
                                      final count = (entry.value as num).toInt();
                                      final pointsMap = {
                                        'Highly Met (Very Good)': 4.0,
                                        'Met (Good)': 3.0,
                                        'Not Met (Need Improvement)': 1.0,
                                        'Partially Met (Average)': 1.5,
                                        'Need to Focus(Yet to Start)': 0.0,
                                      };
                                      final total = (pointsMap[label] ?? 0.0) * count;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                        child: Row(
                                          children: [
                                            Expanded(child: Text(label, style: TextStyle(color: Colors.white))),
                                            Expanded(child: Text("x $count", style: TextStyle(color: Colors.white70))),
                                            Expanded(child: Text("${total.toStringAsFixed(1)}", style: TextStyle(color: Colors.greenAccent))),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    Divider(color: Colors.white24),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        "Total Score: ${(snapshot.data!.data() as Map<String, dynamic>)['score']?.toStringAsFixed(1) ?? '0.0'}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],


                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        Container()
      ],
    );
  }
}
