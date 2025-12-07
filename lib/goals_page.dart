import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database_helper.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchGoals();
    setState(() {
      _goals = data;
      _isLoading = false;
    });
  }

  // -------------------------------------------------------------------------
  // MODERN ADD / EDIT GOAL FORM
  // -------------------------------------------------------------------------
  void _showGoalForm({Map<String, dynamic>? existing}) {
    bool isEditing = existing != null;

    final titleC = TextEditingController(text: existing?['title'] ?? "");
    final targetAmountC = TextEditingController(
      text: existing?['target_amount']?.toString() ?? "",
    );
    final notesC = TextEditingController(text: existing?['notes'] ?? "");

    DateTime? selectedDate =
    existing != null && existing['target_date'] != null
        ? DateTime.parse(existing['target_date'])
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, modalSet) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? "Edit Goal" : "Create Savings Goal",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: titleC,
                  decoration: _input("Goal Title", Icons.flag),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: targetAmountC,
                  keyboardType: TextInputType.number,
                  decoration: _input("Target Amount (₹)", Icons.currency_rupee),
                ),
                const SizedBox(height: 12),

                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      initialDate: selectedDate ?? DateTime.now(),
                    );
                    if (picked != null) modalSet(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate == null
                              ? "Select Target Date"
                              : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                          style: GoogleFonts.roboto(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: notesC,
                  decoration: _input("Notes (optional)", Icons.note_alt),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () async {
                    if (titleC.text.isEmpty ||
                        targetAmountC.text.isEmpty ||
                        selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text("Please fill all required fields.")),
                      );
                      return;
                    }

                    final data = {
                      "title": titleC.text,
                      "target_amount":
                      double.tryParse(targetAmountC.text) ?? 0,
                      "saved_amount": existing?['saved_amount'] ?? 0,
                      "target_date": selectedDate!.toIso8601String(),
                      "notes": notesC.text,
                      "is_completed": existing?['is_completed'] ?? 0,
                    };

                    if (isEditing) {
                      await DatabaseHelper.instance.updateGoal(
                          existing!['id'], data);
                    } else {
                      await DatabaseHelper.instance.insertGoal(data);
                    }

                    Navigator.pop(context);
                    _loadGoals();
                  },
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? "Update Goal" : "Create Goal"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2539ec),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // DELETE CONFIRMATION
  // -------------------------------------------------------------------------
  Future<bool> _confirmDelete(int id) async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Goal"),
        content:
        const Text("Are you sure you want to delete this goal permanently?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await DatabaseHelper.instance.deleteGoal(id);
              Navigator.pop(context, true);
              _loadGoals();
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // ADD SAVINGS TO AN EXISTING GOAL
  // -------------------------------------------------------------------------
  void _addSavings(Map<String, dynamic> goal) {
    final amountC = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Savings",
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: amountC,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount (₹)"),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            onPressed: () async {
              if (amountC.text.isEmpty) return;

              final add = double.tryParse(amountC.text) ?? 0;
              final updated = goal['saved_amount'] + add;
              final completed =
              updated >= goal['target_amount'] ? 1 : 0;

              await DatabaseHelper.instance.updateGoal(goal['id'], {
                "saved_amount": updated,
                "is_completed": completed,
              });

              Navigator.pop(context);
              _loadGoals();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2539ec),
              foregroundColor: Colors.white,
            ),
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // UI COMPONENTS
  // -------------------------------------------------------------------------

  Widget _progress(double saved, double target) {
    final pct = (saved / target).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 70,
          width: 70,
          child: CircularProgressIndicator(
            value: pct,
            strokeWidth: 7,
            color: pct >= 1 ? Colors.green : const Color(0xFF2539ec),
            backgroundColor: Colors.grey.shade300,
          ),
        ),
        Text(
          "${(pct * 100).toInt()}%",
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    );
  }

  // -------------------------------------------------------------------------
  // MAIN UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalForm(),
        backgroundColor: const Color(0xFF2539ec),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      appBar: AppBar(
        backgroundColor: const Color(0xFF2539ec),
        iconTheme: const IconThemeData(
          color: Colors.white, // <-- makes the back arrow white
        ),
        title: Text(
          'Saving Goals',
          style: GoogleFonts.satisfy(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
          ? Center(
        child: Text(
          "No goals added yet!",
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _goals.length,
        itemBuilder: (_, i) {
          final g = _goals[i];
          final saved = g['saved_amount'] * 1.0;
          final target = g['target_amount'] * 1.0;

          final targetDate = g['target_date'] == null
              ? null
              : DateTime.parse(g['target_date']);

          return Dismissible(
            key: Key("goal_${g['id']}"),
            direction: DismissDirection.horizontal,
            background:
            _swipeBackground(Icons.edit, Colors.green),
            secondaryBackground:
            _swipeBackground(Icons.delete, Colors.red),
            confirmDismiss: (dir) async {
              if (dir == DismissDirection.startToEnd) {
                _showGoalForm(existing: g);
                return false;
              }
              return await _confirmDelete(g['id']);
            },
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _progress(saved, target),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g['title'],
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Saved: ₹$saved / ₹$target",
                            style: GoogleFonts.roboto(fontSize: 14),
                          ),
                          if (targetDate != null)
                            Text(
                              "Target: ${targetDate!.day}/${targetDate.month}/${targetDate.year}",
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          if ((g['notes'] ?? "").isNotEmpty)
                            Text(
                              g['notes'],
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle,
                          size: 30, color: Color(0xFF2539ec)),
                      onPressed: () => _addSavings(g),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _swipeBackground(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
