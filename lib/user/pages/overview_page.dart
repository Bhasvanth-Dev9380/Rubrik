import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _metricsController = TextEditingController();
  late CalendarController _calendarController;
  List<DateTime> _highlightedDates = [];

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _calendarController.view = CalendarView.month;
    _calendarController.selectedDate = _selectedDate;
    _fetchHighlightedDates();
  }

  @override
  void dispose() {
    _metricsController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _fetchHighlightedDates() async {
    final user = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('performance')
        .get();

    setState(() {
      _highlightedDates = snapshot.docs
          .map((doc) => DateFormat('yyyy-MM-dd').parse(doc.id))
          .toList();
    });
  }

  bool _isHighlighted(DateTime date) {
    return _highlightedDates.any((d) =>
    d.year == date.year && d.month == date.month && d.day == date.day);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Performance Calendar",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),

              // Modern Calendar
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
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Add dropdown/date picker at top
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Go to Today button
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime.now();
                              _calendarController.displayDate = DateTime.now();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueGrey.shade900,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(Icons.today),
                          label: Text("Today"),
                        ),

                        // Pick Date button
                        ElevatedButton.icon(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: Color(0xFF00B4D8), // Picker header and buttons
                                      onPrimary: Colors.white, // Picker header text color
                                      surface: Color(0xFF00B4D8), // Picker background
                                      onSurface: Colors.black54, // Day numbers and others
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(foregroundColor: Color(0xFF00B4D8)),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _selectedDate = pickedDate;
                                _calendarController.displayDate = pickedDate;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueGrey.shade900,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(Icons.calendar_month),
                          label: Text("Pick Date"),
                        ),
                      ],
                    ),


                    SizedBox(height: 12),

                    // Calendar
                    SfCalendar(
                      controller: _calendarController,
                      showNavigationArrow: true,
                      view: CalendarView.month,
                      initialSelectedDate: _selectedDate,
                      onTap: (CalendarTapDetails details) {
                        if (details.date != null) {
                          setState(() {
                            _selectedDate = details.date!;
                          });
                        }
                      },
                      todayHighlightColor: Colors.white,
                      selectionDecoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      monthViewSettings: MonthViewSettings(
                        showAgenda: false,
                        dayFormat: 'EEE',
                      ),
                      monthCellBuilder: (context, details) {
                        final isToday = details.date.year == DateTime.now().year &&
                            details.date.month == DateTime.now().month &&
                            details.date.day == DateTime.now().day;

                        final isSelected = details.date.year == _selectedDate.year &&
                            details.date.month == _selectedDate.month &&
                            details.date.day == _selectedDate.day;

                        final isHighlighted = _isHighlighted(details.date);

                        Color bgColor = Colors.transparent;
                        Color textColor = Colors.white;

                        if (isHighlighted) {
                          bgColor = Color(0xFF00B4D8);
                          textColor = Colors.white;
                        }

                        if (isSelected) {
                          bgColor = Color(0xFF00C7C7);
                          textColor = Colors.white;
                        } else if (isToday && !isHighlighted) {
                          bgColor = Colors.white.withOpacity(0.2);
                          textColor = Colors.white;
                        }

                        return Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(12),
                            child: Text(
                              '${details.date.day}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      backgroundColor: Colors.transparent,
                      headerStyle: CalendarHeaderStyle(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      viewHeaderStyle: ViewHeaderStyle(
                        dayTextStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),


              SizedBox(height: 32),

              // Selected Day Metrics
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('performance_categories')
                    .get(),
                builder: (context, categoriesSnapshot) {
                  if (categoriesSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  // Prepare category-wise metrics
                  Map<String, List<String>> categoryMetrics = {};
                  for (var doc in categoriesSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final List<dynamic> metrics = data['metrics'] ?? [];
                    final String categoryName = data['name'] ?? "Unnamed Category";
                    categoryMetrics[categoryName] = metrics.cast<String>();
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('performance')
                        .doc(_selectedDate.toIso8601String().substring(0, 10))
                        .get(),
                    builder: (context, snapshot) {
                      Map<String, dynamic> selectedMetrics = {};

                      if (snapshot.data?.data() != null) {
                        selectedMetrics = Map<String, dynamic>.from(
                            (snapshot.data!.data() as Map<String, dynamic>)['metrics'] ?? {});
                      }

                      final categoryEntries = categoryMetrics.entries.toList();

                      return Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Metrics for ${_selectedDate.toLocal().toString().split(' ')[0]}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Category wise metrics UI
                            ...categoryEntries.asMap().entries.map((entry) {
                              final index = entry.key;
                              final categoryName = entry.value.key;
                              final metrics = entry.value.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Name
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      categoryName,
                                      style: TextStyle(
                                        color: Color(0xFF00B4D8),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // Metrics under category
                                  ...metrics.map((metric) {
                                    final controller = TextEditingController(
                                      text: selectedMetrics[metric]?.toString() ?? "",
                                    );

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              metric,
                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            flex: 1,
                                            child: TextField(
                                              controller: controller,
                                              keyboardType: TextInputType.number,
                                              style: TextStyle(color: Colors.white),
                                              decoration: InputDecoration(
                                                hintText: "1-10",
                                                hintStyle: TextStyle(color: Colors.white54),
                                                filled: true,
                                                fillColor: Colors.white.withOpacity(0.1),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedMetrics[metric] = value;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),

                                  // Add Divider except for last category
                                  if (index != categoryEntries.length - 1)
                                    Divider(
                                      color: Colors.white24,
                                      thickness: 1,
                                      height: 32,
                                    ),
                                ],
                              );
                            }).toList(),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('performance')
                                      .doc(_selectedDate.toIso8601String().substring(0, 10))
                                      .set({'metrics': selectedMetrics});

                                  await _fetchHighlightedDates();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Saved successfully!")),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blueGrey.shade900,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: Icon(Icons.save),
                                label: Text("Save Metrics"),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
          )
        ],
      ),
    );
  }
}
