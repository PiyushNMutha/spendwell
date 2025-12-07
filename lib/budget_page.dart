import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database_helper.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<Map<String, dynamic>> _budgets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchBudgets();
    setState(() {
      _budgets = data;
      _isLoading = false;
    });
  }

  // --------------------------------------------------------------------
  // PREMIUM UI — Add Budget Modal
  // --------------------------------------------------------------------
  void _showAddBudgetForm({Map<String, dynamic>? existingBudget}) {
    final amountController = TextEditingController(
      text: existingBudget?['limit_amount']?.toString() ?? "",
    );

    int selectedMonth = existingBudget?['month'] ?? DateTime.now().month;
    int selectedYear = existingBudget?['year'] ?? DateTime.now().year;
    String? selectedCategory = existingBudget?['category'];

    const categories = [
      "Food",
      "Travel",
      "Trip",
      "Salary",
      "Entertainment",
      "Groceries",
      "Utilities",
      "Other"
    ];

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
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  "Create Budget",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 20),

                // Month selector with icons
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: _inputDecoration("Month"),
                        items: List.generate(
                          12,
                              (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text("${i + 1}"),
                          ),
                        ),
                        onChanged: (v) => modalSet(() => selectedMonth = v!),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Year selector
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 20, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: _inputDecoration("Year"),
                        items: List.generate(
                          4,
                              (i) => DropdownMenuItem(
                            value: DateTime.now().year + i,
                            child: Text("${DateTime.now().year + i}"),
                          ),
                        ),
                        onChanged: (v) => modalSet(() => selectedYear = v!),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Category selector
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: _inputDecoration("Category (optional)"),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => modalSet(() => selectedCategory = v),
                ),

                const SizedBox(height: 12),

                // Amount field
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Budget Amount (₹)"),
                ),

                const SizedBox(height: 20),

                // SAVE BUTTON
                ElevatedButton.icon(
                  onPressed: () async {
                    if (amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Please enter budget amount."),
                        backgroundColor: Colors.black,
                      ));
                      return;
                    }

                    final data = {
                      "month": selectedMonth,
                      "year": selectedYear,
                      "category": selectedCategory,
                      "limit_amount": double.tryParse(amountController.text) ?? 0.0,
                    };

                    if (existingBudget == null) {
                      await DatabaseHelper.instance.insertBudget(data);
                    } else {
                      await DatabaseHelper.instance.updateBudget(existingBudget['id'], data);
                    }
                    Navigator.pop(context);
                    _loadBudgets();
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text("Save Budget"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2539ec),
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }

  Future<double> _calculateSpent(int m, int y, String? cat) async {
    final all = await DatabaseHelper.instance.fetchTransactions();
    double sum = 0;

    for (var row in all) {
      final date = DateTime.parse(row["date"]);
      if (date.month == m && date.year == y && row["type"] == "Expense") {
        if (cat == null || row["category"] == cat) sum += row["amount"];
      }
    }
    return sum;
  }

  // --------------------------------------------------------------------
  // MAIN UI
  // --------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetForm,
        backgroundColor: const Color(0xFF2539ec),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // --------------------- Premium AppBar ---------------------
      appBar: AppBar(
        backgroundColor: const Color(0xFF2539ec),
        iconTheme: const IconThemeData(
          color: Colors.white, // <-- makes the back arrow white
        ),
        title: Text(
          'Budgets',
          style: GoogleFonts.satisfy(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      backgroundColor: Colors.grey.shade100,

      // --------------------- BODY ---------------------
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _budgets.isEmpty
          ? Center(
        child: Text(
          "No budgets added yet",
          style: GoogleFonts.roboto(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _budgets.length,
        itemBuilder: (context, index) {
          final b = _budgets[index];

          return FutureBuilder<double>(
            future: _calculateSpent(
                b["month"], b["year"], b["category"]),
            builder: (ctx, snap) {
              final spent = snap.data ?? 0;
              final limit = b["limit_amount"];
              final pct = (spent / limit).clamp(0.0, 1.0);

              return _buildBudgetCard(b, spent, limit, pct);
            },
          );
        },
      ),
    );
  }
  Future<bool> _confirmDelete(int id) async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Budget"),
        content: const Text("Are you sure you want to delete this budget?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteBudget(id);
              _loadBudgets();
              Navigator.pop(context, true); // allow dismiss
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---------- Modern Gradient Budget Card ----------
  Widget _buildBudgetCard(b, double spent, double limit, double pct) {
    return Dismissible(
      key: Key("budget_${b['id']}"),
      direction: DismissDirection.horizontal, // swipe BOTH sides
      background: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe RIGHT → Edit Budget
          _showAddBudgetForm(existingBudget: b);
          return false;
        } else {
          // Swipe LEFT → Delete Budget
          return await _confirmDelete(b['id']);
        }
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b["category"] ?? "Overall Budget",
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${b["month"]}/${b["year"]}",
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 16),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 12,
                  color: pct >= 1 ? Colors.red : Colors.blue.shade700,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Spent: ₹${spent.toStringAsFixed(2)}",
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "Limit: ₹${limit.toStringAsFixed(2)}",
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              if (spent >= limit)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "⚠ Overspending Alert!",
                    style: GoogleFonts.roboto(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
