import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, color: Colors.blueGrey.shade900),
            SizedBox(width: 8),
            Text(
              "Logged In Users",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade900),
            ),
          ],
        ),

        SizedBox(height: 16),

        // 🔎 Search Bar with clear button
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim().toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: "Search by name or email",
            prefixIcon: Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        SizedBox(height: 24),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No users yet.", style: TextStyle(color: Colors.grey.shade600)));
              }

              final users = snapshot.data!.docs;

              // 🔍 Apply search filter
              final filteredUsers = users.where((doc) {
                final user = doc.data() as Map<String, dynamic>;
                final name = (user['name'] ?? '').toString().toLowerCase();
                final email = (user['email'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();

              if (filteredUsers.isEmpty) {
                return Center(child: Text("No users found for this search.", style: TextStyle(color: Colors.grey.shade600)));
              }

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.blueGrey.shade900),
                        SizedBox(width: 8),
                        Text(
                          "Users",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Scrollable table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: 600),
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith((states) =>
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.blueGrey.shade800
                              : Colors.blueGrey.shade100),
                          dataRowColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered))
                              return Colors.blueGrey.withOpacity(0.08); // subtle hover color
                            return null; // default no color
                          }),
                          columnSpacing: 32,
                          columns: [
                            DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredUsers.map((userDoc) {
                            final user = userDoc.data() as Map<String, dynamic>;
                            final name = user['name'] ?? 'No Name';
                            final email = user['email'] ?? '';

                            return DataRow(
                              cells: [
                                DataCell(_highlightSearch(name)),
                                DataCell(_highlightSearch(email)),
                                DataCell(Row(
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.blueGrey.shade900),
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      icon: Icon(Icons.bar_chart, size: 16, color: Colors.blueGrey.shade900),
                                      label: Text("View Metrics", style: TextStyle(color: Colors.blueGrey.shade900)),
                                      onPressed: () {
                                        // View metrics action
                                      },
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );


            },
          ),
        ),
      ],
    );
  }

  // 🔥 Highlight search keyword
  Widget _highlightSearch(String text) {
    if (_searchQuery.isEmpty) return Text(text);

    final lowerText = text.toLowerCase();
    final startIndex = lowerText.indexOf(_searchQuery);

    if (startIndex == -1) return Text(text);

    final endIndex = startIndex + _searchQuery.length;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: text.substring(0, startIndex), style: TextStyle(color: Colors.black)),
          TextSpan(text: text.substring(startIndex, endIndex), style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          TextSpan(text: text.substring(endIndex), style: TextStyle(color: Colors.black)),
        ],
      ),
    );
  }
}
