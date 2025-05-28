import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

Widget CPTPage() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.category, size: 80, color: Colors.white),
        SizedBox(height: 20),
        Text("CPT", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 12),
        Text("CPT related data will be shown here.", style: TextStyle(fontSize: 16, color: Colors.white70)),
      ],
    ),
  );
}