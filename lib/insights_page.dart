import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _insights = [];

  @override
  void initState() {
    super.initState();
    _generateAndLoadInsights();
  }

  Future<void> _generateAndLoadInsights() async {
    setState(() => _isLoading = true);

    // 1. Get all transactions
    final txRows = await DatabaseHelper.instance.fetchTransactions();

    // Group by year-month
    final Map<String, List<Map<String, dynamic>>> byMonth = {};

    for (final t in txRows) {
      final date = DateTime.parse(t['date']);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(t);
    }

    // Get DB instance to use for custom queries
    final db = await DatabaseHelper.instance.database;

    // 2. For each month, compute insights & upsert into monthly_insights
    for (final entry in byMonth.entries) {
      final key = entry.key;
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      final txList = entry.value;

      double totalIncome = 0;
      double totalExpense = 0;
      final Map<String, double> categoryExpense = {};
      final Map<String, double> dayExpense = {};

      for (final t in txList) {
        final type = t['type'] as String;
        final amount = (t['amount'] as num).toDouble();
        final date = DateTime.parse(t['date']);
        final category = t['category'] as String? ?? 'Other';

        if (type == 'Income') {
          totalIncome += amount;
        } else if (type == 'Expense') {
          totalExpense += amount;

          // Category-wise
          categoryExpense[category] = (categoryExpense[category] ?? 0) + amount;

          // Day-wise
          final dayKey =
          DateFormat('yyyy-MM-dd').format(date); // per calendar day
          dayExpense[dayKey] = (dayExpense[dayKey] ?? 0) + amount;
        }
      }

      // Top category
      String? topCategory;
      if (categoryExpense.isNotEmpty) {
        final sortedCats = categoryExpense.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // desc
        topCategory = sortedCats.first.key;
      }

      // Highest spending day
      String? highestDay;
      if (dayExpense.isNotEmpty) {
        final sortedDays = dayExpense.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        highestDay = sortedDays.first.key;
      }

      // 3. Upsert into monthly_insights (1 row per month)
      final existing = await db.query(
        'monthly_insights',
        where: 'month = ? AND year = ?',
        whereArgs: [month, year],
        limit: 1,
      );

      final row = {
        'month': month,
        'year': year,
        'total_income': totalIncome,
        'total_expense': totalExpense,
        'top_category': topCategory,
        'highest_spending_day': highestDay,
      };

      if (existing.isEmpty) {
        await DatabaseHelper.instance.insertMonthlyInsight(row);
      } else {
        await db.update(
          'monthly_insights',
          row,
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }
    }

    // 4. Load final list of insights ordered latest first
    final allInsights = await DatabaseHelper.instance.fetchMonthlyInsights();

    setState(() {
      _insights = allInsights;
      _isLoading = false;
    });
  }

  // Small helper to create a friendly label like "Jan 2025"
  String _formatMonth(int month, int year) {
    final date = DateTime(year, month);
    return DateFormat('MMM yyyy').format(date);
  }

  // Generate a simple text insight message
  String _buildInsightMessage(double income, double expense, String? topCat) {
    if (income == 0 && expense == 0) {
      return "No activity recorded this month.";
    }
    final net = income - expense;

    if (net > 0) {
      return "Great! You saved ₹${net.toStringAsFixed(0)} this month."
          "${topCat != null ? ' Highest spending category was $topCat.' : ''}";
    } else if (net < 0) {
      return "You overspent by ₹${(-net).toStringAsFixed(0)}."
          "${topCat != null ? ' Most spending was in $topCat.' : ''}";
    } else {
      return "You broke even this month."
          "${topCat != null ? ' Biggest spending category: $topCat.' : ''}";
    }
  }

  Color _netColor(double net) {
    if (net > 0) return Colors.green;
    if (net < 0) return Colors.red;
    return Colors.orange;
  }

  IconData _netIcon(double net) {
    if (net > 0) return Icons.trending_up;
    if (net < 0) return Icons.trending_down;
    return Icons.horizontal_rule;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2539ec),
        iconTheme: const IconThemeData(
          color: Colors.white, // <-- makes the back arrow white
        ),
        title: Text(
          "Monthly Insights",
          style: GoogleFonts.satisfy(fontSize: 26, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _generateAndLoadInsights,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _insights.isEmpty
          ? Center(
        child: Text(
          "Add some transactions to see insights.",
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _insights.length,
        itemBuilder: (context, index) {
          final row = _insights[index];
          final month = row['month'] as int;
          final year = row['year'] as int;
          final totalIncome =
          (row['total_income'] as num).toDouble();
          final totalExpense =
          (row['total_expense'] as num).toDouble();
          final topCategory = row['top_category'] as String?;
          final highestDayStr =
          row['highest_spending_day'] as String?;

          final net = totalIncome - totalExpense;

          DateTime? highestDay;
          if (highestDayStr != null) {
            highestDay = DateTime.tryParse(highestDayStr);
          }

          final msg =
          _buildInsightMessage(totalIncome, totalExpense, topCategory);

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: Month + Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatMonth(month, year),
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                        _netColor(net).withOpacity(0.15),
                        child: Icon(
                          _netIcon(net),
                          color: _netColor(net),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Income / Expense / Net
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Income",
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.green,
                              )),
                          Text(
                            "₹${totalIncome.toStringAsFixed(2)}",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Expense",
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.red,
                              )),
                          Text(
                            "₹${totalExpense.toStringAsFixed(2)}",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Net",
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: _netColor(net),
                              )),
                          Text(
                            "₹${net.toStringAsFixed(2)}",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _netColor(net),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Top category
                  if (topCategory != null)
                    Text(
                      "Top spending category: $topCategory",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),

                  // Highest spending day
                  if (highestDay != null)
                    Text(
                      "Highest spending day: ${DateFormat('dd MMM').format(highestDay)}",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Message / Hint
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg,
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
