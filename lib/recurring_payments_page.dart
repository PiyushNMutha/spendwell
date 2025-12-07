import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database_helper.dart';

class RecurringPaymentsPage extends StatefulWidget {
  const RecurringPaymentsPage({super.key});

  @override
  State<RecurringPaymentsPage> createState() => _RecurringPaymentsPageState();
}

class _RecurringPaymentsPageState extends State<RecurringPaymentsPage> {
  List<Map<String, dynamic>> _recurrings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecurringPayments();
    _checkDueRecurringPayments(); // Auto-run logic stays as it is
  }

  // -----------------------------------------------------------------------------
  // LOAD RECURRING RULES
  // -----------------------------------------------------------------------------
  Future<void> _loadRecurringPayments() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchRecurringPayments();
    setState(() {
      _recurrings = data;
      _isLoading = false;
    });
  }

  // -----------------------------------------------------------------------------
  // AUTO PROCESS DUE RECURRING PAYMENTS
  // -----------------------------------------------------------------------------
  Future<void> _checkDueRecurringPayments() async {
    final today = DateTime.now();
    final all = await DatabaseHelper.instance.fetchRecurringPayments();

    for (var r in all) {
      final nextDate = DateTime.parse(r['next_date']);

      if (!nextDate.isAfter(today)) {
        // Insert auto transaction
        await DatabaseHelper.instance.insertTransaction({
          "date": DateTime.now().toIso8601String(),
          "description": r["title"],
          "amount": r["amount"],
          "type": r["type"],
          "category": r["category"],
          "paymentMethod": r["payment_method"] ?? "Auto",
          "notes": "Recurring payment",
        });

        // Move to next date
        DateTime newDate = nextDate;
        switch (r['frequency']) {
          case 'daily':
            newDate = nextDate.add(const Duration(days: 1));
            break;
          case 'weekly':
            newDate = nextDate.add(const Duration(days: 7));
            break;
          case 'monthly':
            newDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
            break;
          case 'yearly':
            newDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
            break;
        }

        await DatabaseHelper.instance.updateRecurringPayment(r['id'], {
          "next_date": newDate.toIso8601String()
        });
      }
    }
    _loadRecurringPayments();
  }

  // -----------------------------------------------------------------------------
  // DELETE CONFIRMATION
  // -----------------------------------------------------------------------------
  Future<bool> _confirmDelete(int id) async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Recurring Payment"),
        content: const Text("Are you sure you want to delete this recurring rule?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await DatabaseHelper.instance.deleteRecurringPayment(id);
              Navigator.pop(context, true);
              _loadRecurringPayments();
            },
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // BOTTOM SHEET FORM (ADD + EDIT)
  // -----------------------------------------------------------------------------
  void _showRecurringForm({Map<String, dynamic>? existing}) {
    final isEditing = existing != null;

    final titleC = TextEditingController(text: existing?['title'] ?? "");
    final amountC = TextEditingController(
      text: existing?['amount']?.toString() ?? "",
    );
    final notesC = TextEditingController(text: existing?['notes'] ?? "");

    String type = existing?['type'] ?? "Expense";
    String frequency = existing?['frequency'] ?? "monthly";
    String category = existing?['category'] ?? "Other";

    DateTime nextDate = existing != null
        ? DateTime.parse(existing['next_date'])
        : DateTime.now();

    const categories = [
      "Food",
      "Travel",
      "Rent",
      "Salary",
      "Entertainment",
      "Groceries",
      "Utilities",
      "Other"
    ];

    const frequencies = ["daily", "weekly", "monthly", "yearly"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          StatefulBuilder(builder: (context, modalSet) {
            return AnimatedContainer(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              duration: const Duration(milliseconds: 350),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditing ? "Edit Recurring Payment" : "Add Recurring Payment",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TITLE
                  TextField(
                    controller: titleC,
                    decoration: _input("Title", Icons.repeat),
                  ),
                  const SizedBox(height: 12),

                  // AMOUNT
                  TextField(
                    controller: amountC,
                    keyboardType: TextInputType.number,
                    decoration: _input("Amount (₹)", Icons.currency_rupee),
                  ),
                  const SizedBox(height: 12),

                  // TYPE
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: _input("Type", Icons.swap_vert),
                    items: ["Income", "Expense"]
                        .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v),
                    ))
                        .toList(),
                    onChanged: (v) => modalSet(() => type = v!),
                  ),
                  const SizedBox(height: 12),

                  // CATEGORY
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: _input("Category", Icons.category),
                    items: categories
                        .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v),
                    ))
                        .toList(),
                    onChanged: (v) => modalSet(() => category = v!),
                  ),
                  const SizedBox(height: 12),

                  // FREQUENCY
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: _input("Frequency", Icons.av_timer),
                    items: frequencies
                        .map((f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.toUpperCase()),
                    ))
                        .toList(),
                    onChanged: (v) => modalSet(() => frequency = v!),
                  ),
                  const SizedBox(height: 12),

                  // NEXT DATE
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: nextDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) modalSet(() => nextDate = picked);
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
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            "${nextDate.day}/${nextDate.month}/${nextDate.year}",
                            style: GoogleFonts.roboto(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // NOTES
                  TextField(
                    controller: notesC,
                    decoration: _input("Notes (optional)", Icons.note_alt),
                  ),
                  const SizedBox(height: 20),

                  // SAVE BUTTON
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2539ec),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26)),
                    ),
                    icon: Icon(isEditing ? Icons.save : Icons.add),
                    label: Text(isEditing ? "Update" : "Save"),
                    onPressed: () async {
                      if (titleC.text.isEmpty ||
                          amountC.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Fill all required fields")));
                        return;
                      }

                      final data = {
                        "title": titleC.text,
                        "amount": double.tryParse(amountC.text) ?? 0.0,
                        "type": type,
                        "category": category,
                        "frequency": frequency,
                        "next_date": nextDate.toIso8601String(),
                        "payment_method": "Auto",
                        "notes": notesC.text,
                      };

                      if (isEditing) {
                        await DatabaseHelper.instance.updateRecurringPayment(
                            existing!['id'], data);
                      } else {
                        await DatabaseHelper.instance.insertRecurringPayment(data);
                      }

                      Navigator.pop(context);
                      _loadRecurringPayments();
                    },
                  )
                ],
              ),
            );
          }),
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

  // -----------------------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2539ec),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showRecurringForm(),
      ),

      appBar: AppBar(
        backgroundColor: const Color(0xFF2539ec),
        iconTheme: const IconThemeData(
          color: Colors.white, // <-- makes the back arrow white
        ),
        title: Text(
          'Recurring Payments',
          style: GoogleFonts.satisfy(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recurrings.isEmpty
          ? Center(
        child: Text(
          "No recurring payments added.",
          style: GoogleFonts.roboto(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
      )
          : _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recurrings.length,
      itemBuilder: (context, index) {
        final r = _recurrings[index];
        final next = DateTime.parse(r['next_date']);
        final color = r['type'] == "Expense" ? Colors.red : Colors.green;

        return Dismissible(
          key: Key("recurring_${r['id']}"),
          direction: DismissDirection.horizontal,
          background: _swipeBackground(Icons.edit, Colors.green),
          secondaryBackground: _swipeBackground(Icons.delete, Colors.red),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              _showRecurringForm(existing: r);
              return false;
            } else {
              return await _confirmDelete(r['id']);
            }
          },
          child: Card(
            elevation: 4,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(
                      r['type'] == "Expense"
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['title'],
                            style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "₹${r['amount']} • ${r['frequency'].toUpperCase()}",
                            style: GoogleFonts.roboto(
                                fontSize: 14, color: Colors.grey.shade700),
                          ),
                          Text(
                            "Next: ${next.day}/${next.month}/${next.year}",
                            style: GoogleFonts.roboto(
                                fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _swipeBackground(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
