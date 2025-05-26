import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final TextEditingController _categoryController = TextEditingController();

  void _addCategory() async {
    final name = _categoryController.text.trim();
    if (name.isEmpty) return;

    await FirebaseFirestore.instance.collection('performance_categories').add({
      'name': name,
      'metrics': [],
    });

    _categoryController.clear();
  }

  void _deleteCategory(String id) async {
    await FirebaseFirestore.instance.collection('performance_categories').doc(id).delete();
  }

  void _updateCategoryName(String id, String newName) async {
    await FirebaseFirestore.instance.collection('performance_categories').doc(id).update({
      'name': newName,
    });
  }

  void _addMetric(String categoryId, String metric) async {
    if (metric.isEmpty) return;

    await FirebaseFirestore.instance.collection('performance_categories').doc(categoryId).update({
      'metrics': FieldValue.arrayUnion([metric]),
    });
  }

  void _deleteMetric(String categoryId, String metric) async {
    await FirebaseFirestore.instance.collection('performance_categories').doc(categoryId).update({
      'metrics': FieldValue.arrayRemove([metric]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Title
        Row(
          children: [
            Icon(Icons.category, color: Colors.blueGrey.shade900),
            SizedBox(width: 8),
            Text(
              "Manage Categories and Metrics",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade900),
            ),
          ],
        ),
        SizedBox(height: 24),

        // 🔹 Add Category Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'New Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade900,
                foregroundColor: Colors.white,
              ),
              child: Text("Add Category"),
            ),
          ],
        ),

        SizedBox(height: 24),

        // 🔹 Categories Grid
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('performance_categories').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

              final categories = snapshot.data!.docs;

              if (categories.isEmpty) {
                return Center(child: Text("No categories yet.", style: TextStyle(color: Colors.grey.shade600)));
              }

              return GridView.count(
                crossAxisCount: screenWidth > 1000 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: categories.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final categoryId = doc.id;
                  final categoryName = data['name'];
                  final metrics = List<String>.from(data['metrics']);

                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category name and manage options
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                categoryName,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade900),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'manage') {
                                  _showManageMetricsDialog(categoryId, categoryName, metrics);
                                } else if (value == 'delete') {
                                  _deleteCategory(categoryId);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'manage', child: Text("Manage")),
                                PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                              ],
                              icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Metrics Chips or no metrics text
                        Expanded(
                          child: metrics.isEmpty
                              ? Center(child: Text("No metrics yet", style: TextStyle(color: Colors.grey.shade500)))
                              : SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: metrics.map((metric) {
                                return Chip(
                                  backgroundColor: Colors.blueGrey.shade50,
                                  label: Text(metric, style: TextStyle(color: Colors.blueGrey.shade900)),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showManageMetricsDialog(String categoryId, String categoryName, List<String> metrics) {
    final TextEditingController _editCategoryController = TextEditingController(text: categoryName);
    final Map<String, TextEditingController> _editMetricControllers = {
      for (var metric in metrics) metric: TextEditingController(text: metric),
    };
    final List<TextEditingController> _newMetricControllers = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Icon(Icons.manage_accounts, color: Colors.blueGrey.shade900),
                  SizedBox(width: 8),
                  Text("Manage Metrics & Category"),
                ],
              ),
              content: Container(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Edit category name
                      SizedBox(height: 24),

                      TextField(
                        controller: _editCategoryController,
                        decoration: InputDecoration(
                          labelText: "Edit Category Name",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      SizedBox(height: 24),
                      Divider(),

                      // Existing metrics title
                      Text("Existing Metrics", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
                      SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Column(
                          children: metrics.map((metric) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _editMetricControllers[metric],
                                      decoration: InputDecoration(
                                        hintText: "Metric",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _deleteMetric(categoryId, metric);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      SizedBox(height: 24),
                      Divider(),

                      // New metrics section
                      Text("Add New Metrics", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
                      SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Column(
                          children: [
                            ..._newMetricControllers.map((controller) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          hintText: "New Metric",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _newMetricControllers.remove(controller);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _newMetricControllers.add(TextEditingController());
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey.shade900,
                                  foregroundColor: Colors.white,
                                ),
                                icon: Icon(Icons.add),
                                label: Text("Add Metric Field"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newName = _editCategoryController.text.trim();
                    if (newName.isNotEmpty && newName != categoryName) {
                      _updateCategoryName(categoryId, newName);
                    }

                    _editMetricControllers.forEach((oldMetric, controller) {
                      final newMetric = controller.text.trim();
                      if (newMetric.isNotEmpty && newMetric != oldMetric) {
                        _deleteMetric(categoryId, oldMetric);
                        _addMetric(categoryId, newMetric);
                      }
                    });

                    for (var controller in _newMetricControllers) {
                      final newMetric = controller.text.trim();
                      if (newMetric.isNotEmpty) {
                        _addMetric(categoryId, newMetric);
                      }
                    }

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade900,
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Save Changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
