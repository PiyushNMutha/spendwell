import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database_helper.dart';

class BillRemindersPage extends StatefulWidget {
  const BillRemindersPage({super.key});

  @override
  State<BillRemindersPage> createState() => _BillRemindersPageState();
}

class _BillRemindersPageState extends State<BillRemindersPage> {
  List<Map<String, dynamic>> _bills = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchBillReminders();
    setState(() {
      _bills = data;
      _isLoading = false;
    });
  }

  // ----------------------------------------------------------------------------
  // PREMIUM FORM FOR ADD / EDIT BILL
  // ----------------------------------------------------------------------------
  void _showBillForm({Map<String, dynamic>? existing}) {
    bool isEditing = existing != null;

    final titleC = TextEditingController(text: existing?['title'] ?? "");
    final amountC = TextEditingController(
        text: existing?['amount']?.toString() ?? "");

    final notesC = TextEditingController(text: existing?['notes'] ?? "");

    DateTime? dueDate =
    existing != null ? DateTime.parse(existing['due_date']) : null;

    String repeat = existing?['repeat_cycle'] ?? "none";

    const repeatOptions = ["none", "monthly", "yearly"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, modalSet) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------ HEADER ------------------
                Text(
                  isEditing ? "Edit Bill Reminder" : "Add Bill Reminder",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // ------------------ TITLE ------------------
                TextField(
                  controller: titleC,
                  decoration: _inputDecoration("Bill Name", Icons.receipt_long),
                ),
                const SizedBox(height: 12),

                // ------------------ AMOUNT ------------------
                TextField(
                  controller: amountC,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                      "Bill Amount (Optional)", Icons.currency_rupee),
                ),
                const SizedBox(height: 12),

                // ------------------ DUE DATE ------------------
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2100),
                      initialDate: dueDate ?? DateTime.now(),
                    );
                    if (picked != null) {
                      modalSet(() => dueDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade100,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          dueDate == null
                              ? "Select Due Date"
                              : "${dueDate!.day}/${dueDate!.month}/${dueDate!.year}",
                          style: GoogleFonts.roboto(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ------------------ REPEAT ------------------
                DropdownButtonFormField<String>(
                  value: repeat,
                  decoration: _inputDecoration("Repeat Cycle", Icons.repeat),
                  items: repeatOptions
                      .map(
                        (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.toUpperCase()),
                    ),
                  )
                      .toList(),
                  onChanged: (val) => modalSet(() => repeat = val!),
                ),
                const SizedBox(height: 12),

                // ------------------ NOTES ------------------
                TextField(
                  controller: notesC,
                  decoration:
                  _inputDecoration("Notes (Optional)", Icons.note_alt),
                ),
                const SizedBox(height: 18),

                // ------------------ SAVE BUTTON ------------------
                ElevatedButton.icon(
                  onPressed: () async {
                    if (titleC.text.isEmpty || dueDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")),
                      );
                      return;
                    }

                    final data = {
                      "title": titleC.text,
                      "amount": double.tryParse(amountC.text) ?? null,
                      "due_date": dueDate!.toIso8601String(),
                      "repeat_cycle": repeat,
                      "category": null,
                      "notes": notesC.text,
                      "is_paid": existing?['is_paid'] ?? 0,
                    };

                    if (isEditing) {
                      await DatabaseHelper.instance
                          .updateBillReminder(existing!['id'], data);
                    } else {
                      await DatabaseHelper.instance.insertBillReminder(data);
                    }

                    Navigator.pop(context);
                    _loadBills();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2539ec),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                  ),
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? "Update Reminder" : "Save Reminder"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
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
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }

  // ----------------------------------------------------------------------------
  // DELETE CONFIRMATION
  // ----------------------------------------------------------------------------
  Future<bool> _confirmDelete(int id) async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Bill Reminder"),
        content:
        const Text("Are you sure you want to delete this bill reminder?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await DatabaseHelper.instance.deleteBillReminder(id);
              Navigator.pop(context, true); // allow dismiss
              _loadBills();
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------------
  // MARK PAID LOGIC
  // ----------------------------------------------------------------------------
  void _markBillAsPaid(Map<String, dynamic> bill) async {
    await DatabaseHelper.instance.updateBillReminder(bill["id"], {
      "is_paid": 1,
    });

    // handle repeating cycle creation
    if (bill["repeat_cycle"] != "none") {
      final old = DateTime.parse(bill["due_date"]);
      late DateTime next;
      if (bill["repeat_cycle"] == "monthly") {
        next = DateTime(old.year, old.month + 1, old.day);
      } else {
        next = DateTime(old.year + 1, old.month, old.day);
      }

      await DatabaseHelper.instance.insertBillReminder({
        "title": bill['title'],
        "amount": bill['amount'],
        "due_date": next.toIso8601String(),
        "repeat_cycle": bill['repeat_cycle'],
        "category": bill['category'],
        "notes": bill['notes'],
        "is_paid": 0,
      });
    }

    _loadBills();
  }

  // ----------------------------------------------------------------------------
  // UI
  // ----------------------------------------------------------------------------
  Color _statusColor(Map<String, dynamic> bill) {
    final due = DateTime.parse(bill['due_date']);
    final now = DateTime.now();

    if (bill['is_paid'] == 1) return Colors.green;
    if (due.isBefore(now)) return Colors.red;

    return Colors.orange.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ------------------ FAB ------------------
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2539ec),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showBillForm(),
      ),

      // ------------------ APP BAR ------------------
        appBar: AppBar(
          backgroundColor: const Color(0xFF2539ec),
          iconTheme: const IconThemeData(
            color: Colors.white, // <-- makes the back arrow white
          ),
          title: Text(
            'Bill Reminders',
            style: GoogleFonts.satisfy(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
          ? _emptyState()
          : _buildBillList(),
    );
  }

  // ------------------ EMPTY STATE ------------------
  Widget _emptyState() {
    return Center(
      child: Text(
        "No bills added yet",
        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ------------------ BILL LIST ------------------
  Widget _buildBillList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bills.length,
      itemBuilder: (_, index) {
        final b = _bills[index];
        final due = DateTime.parse(b['due_date']);
        final isPaid = b['is_paid'] == 1;

        return Dismissible(
          key: Key("bill_${b['id']}"),
          direction: DismissDirection.horizontal,
          background: _swipeBackground(Icons.edit, Colors.green),
          secondaryBackground: _swipeBackground(Icons.delete, Colors.red),
          confirmDismiss: (dir) async {
            if (dir == DismissDirection.startToEnd) {
              _showBillForm(existing: b);
              return false;
            } else {
              return await _confirmDelete(b['id']);
            }
          },
          child: _billCard(b, due, isPaid),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  // ------------------ MODERN CARD ------------------
  Widget _billCard(b, DateTime due, bool isPaid) {
    final color = _statusColor(b);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Icon
            CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Icon(
                isPaid ? Icons.check : Icons.pending_actions,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b['title'],
                    style: GoogleFonts.roboto(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (b['amount'] != null)
                    Text(
                      "₹${b['amount']}",
                      style: GoogleFonts.roboto(
                          fontSize: 15, color: Colors.grey.shade700),
                    ),
                  Text(
                    "Due: ${due.day}/${due.month}/${due.year}",
                    style: GoogleFonts.roboto(
                        fontSize: 14, color: Colors.grey.shade600),
                  ),
                  if (b['notes'] != "")
                    Text(
                      b['notes'],
                      style: GoogleFonts.roboto(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),

            // Mark Paid
            isPaid
                ? const Icon(Icons.check_circle,
                color: Colors.green, size: 30)
                : IconButton(
              icon: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF2539ec), size: 30),
              onPressed: () => _markBillAsPaid(b),
            ),
          ],
        ),
      ),
    );
  }
}
