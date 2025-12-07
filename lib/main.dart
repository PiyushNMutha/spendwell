import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:spendwell/budget_page.dart';
import 'package:spendwell/recurring_payments_page.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'bill_reminders_page.dart';
import 'database_helper.dart';
import 'goals_page.dart';
import 'insights_page.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

void main() {
  runApp(const MyApp());
}

// Data model for transactions to make code cleaner
class Transaction {
  final int? id;
  final DateTime date;
  final String description;
  final double amount;
  final String type;
  final String category;
  final String paymentMethod;
  final String notes;

  Transaction({
    this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      amount: map['amount'],
      type: map['type'],
      category: map['category'],
      paymentMethod: map['paymentMethod'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}

// Splash Screen Widget with Animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _animationController.forward();

    // Navigate to the main screen after the animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The logo fade-in animation
    final logoAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    // The staggered text animation
    const String appName = 'SpendWell';
    List<Widget> animatedLetters = [];
    final totalLetters = appName.length;
    final textAnimationStart = 0.5;
    final textAnimationEnd = 1.0;
    final letterDelay = (textAnimationEnd - textAnimationStart) / totalLetters;

    for (int i = 0; i < totalLetters; i++) {
      final letter = appName[i];
      animatedLetters.add(
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final start = textAnimationStart + (i * letterDelay);
            final end = start + letterDelay; // Each letter's animation takes up its allocated time slot
            final letterAnimation = CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                start,
                end,
                curve: Curves.easeIn,
              ),
            );
            return FadeTransition(
              opacity: letterAnimation,
              child: Text(
                letter,
                style: GoogleFonts.satisfy(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2539ec),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            FadeTransition(
              opacity: logoAnimation,
              child: Image.asset(
                'assets/images/spendwellicon.png',
                height: 150,
                width: 150,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.account_balance_wallet,
                  size: 150,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Animated staggered text
            FittedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: animatedLetters,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendwell',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: Colors.blueAccent.shade700,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// MainScreen to handle the Bottom Navigation Bar and page changes
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  double balance = 0.0;

  final GlobalKey<_HomePageState> _homePageKey = GlobalKey<_HomePageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      HomePage(key: _homePageKey),
//      const DashboardPage(),
      const ReportsPage(),
    ];
    loadBalance();
  }
  Future<void> loadBalance() async {
    double bal = await DatabaseHelper.instance.getBalance();
    setState(() {
      balance = bal;
    });
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _showMoreMenu();   // 👈 our custom menu
      return;            // do NOT change selectedIndex
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Title
              Text(
                "More Options",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // BUDGET
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text("Budget"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const BudgetPage()));
                },
              ),

              // GOALS
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text("Savings Goals"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const GoalsPage()));
                },
              ),

              // BILL REMINDERS
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text("Bill Reminders"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const BillRemindersPage()));
                },
              ),

              // RECURRING PAYMENTS
              ListTile(
                leading: const Icon(Icons.autorenew_outlined),
                title: const Text("Recurring Payments"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const RecurringPaymentsPage()));
                },
              ),

              // INSIGHTS
              ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text("Monthly Insights"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const InsightsPage()));
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2539ec),
        title: Text(
          'SpendWell',
          style: GoogleFonts.satisfy(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  '₹ ${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 0) {
            _homePageKey.currentState?.showTransactionForm(context);
          }
        },
        backgroundColor: const Color(0xFF2539ec),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 6, left: 18, right: 18, bottom: 24), // Reduced bottom padding
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 48, // Reduced height
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home, size: 20),
                  label: 'Home',
                ),
                // BottomNavigationBarItem(
                //   icon: Icon(Icons.dashboard, size: 20),
                //   label: 'Dashboard',
                // ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment, size: 20),
                  label: 'Reports',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu),
                  label: 'More',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.blue.shade200,
              backgroundColor: const Color(0xFF2539ec),
              onTap: _onItemTapped,
              selectedFontSize: 10,
              unselectedFontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool _isLoading = false;
  List<Transaction> _transactions = [];

  final List<String> _categories = [
    'Food',
    'Travel',
    'Trip',
    'Salary',
    'Entertainment',
    'Groceries',
    'Utilities',
    'Other'
  ];
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  double balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    loadBalance();
  }
  Future<void> loadBalance() async {
    double bal = await DatabaseHelper.instance.getBalance();
    setState(() {
      balance = bal;
    });
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    final dbData = await DatabaseHelper.instance.fetchTransactions();
    loadBalance();

    setState(() {
      _transactions = dbData.map((e) => Transaction.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  // ================= CHART DATA HELPERS =================

  Map<int, Map<String, double>> _getMonthlyData() {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
    final filteredTransactions =
    _transactions.where((t) => t.date.isAfter(threeMonthsAgo)).toList();

    Map<int, Map<String, double>> monthlyData = {};

    for (int i = 0; i < 3; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = date.month;
      monthlyData[monthKey] = {'income': 0.0, 'expense': 0.0};
    }

    for (var t in filteredTransactions) {
      final monthKey = t.date.month;
      if (!monthlyData.containsKey(monthKey)) continue;

      if (t.type == 'Income') {
        monthlyData[monthKey]!['income'] =
            monthlyData[monthKey]!['income']! + t.amount;
      } else if (t.type == 'Expense') {
        monthlyData[monthKey]!['expense'] =
            monthlyData[monthKey]!['expense']! + t.amount;
      }
    }

    return monthlyData;
  }

  Map<String, double> _getCategoryData() {
    final categoryData = <String, double>{};
    final expenseTransactions =
    _transactions.where((t) => t.type == 'Expense');
    for (var t in expenseTransactions) {
      categoryData[t.category] =
          (categoryData[t.category] ?? 0) + t.amount;
    }
    return categoryData;
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Travel':
      case 'Trip':
        return Colors.blue;
      case 'Salary':
        return Colors.green;
      case 'Entertainment':
        return Colors.purple;
      case 'Groceries':
        return Colors.brown;
      case 'Utilities':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),

          // ---------------- CAROUSEL ADDED HERE ----------------
          if (_transactions.isNotEmpty) _buildCarouselSection(),

          const SizedBox(height: 10),

          // ------------- ORIGINAL LOGIC (unchanged) -------------
          _transactions.isEmpty
              ? _buildWelcomeMessage()
              : SizedBox(
            height: MediaQuery.of(context).size.height,
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }


  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to Spendwell!',
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the button below to add a new transaction.',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildCarouselSection() {
    final monthlyData = _getMonthlyData();
    final categoryData = _getCategoryData();

    return SizedBox(
      height: 180,
      child: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          _buildLineChartCard(monthlyData),
          _buildPieChartCard(categoryData),
        ],
      ),
    );
  }
  Widget _buildLineChartCard(Map<int, Map<String, double>> monthlyData) {
    final now = DateTime.now();
    List<ChartData> chartData = [];

    for (int i = 0; i < 3; i++) {
      final month = now.month - i;
      chartData.add(
        ChartData(
          DateFormat.MMM().format(DateTime(now.year, month)),
          monthlyData[month]!['income']!,
          monthlyData[month]!['expense']!,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Income vs Expense",
                style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 2),
            Expanded(
              child: SfCartesianChart(
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  tooltipPosition: TooltipPosition.pointer,
                  textStyle: const TextStyle(fontSize: 10),
                  canShowMarker: false,
                ),
                primaryXAxis: CategoryAxis(),
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.right,
                  alignment: ChartAlignment.near,
                  iconHeight: 10,
                  iconWidth: 10,
                  textStyle: const TextStyle(fontSize: 8),
                ),
                series: <CartesianSeries>[
                  LineSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData d, _) => d.x,
                    yValueMapper: (ChartData d, _) => d.y1,
                    color: Colors.green,
                    name: "Income",
                  ),
                  LineSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData d, _) => d.x,
                    yValueMapper: (ChartData d, _) => d.y2,
                    color: Colors.red,
                    name: "Expense",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPieChartCard(Map<String, double> categoryData) {
    List<PieData> pieData = categoryData.entries.map((entry) {
      return PieData(
        entry.key,
        entry.value,
        _getColorForCategory(entry.key),
      );
    }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Category-wise Spending",
                style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 10),
            Expanded(
              child: SfCircularChart(
                tooltipBehavior: TooltipBehavior(enable: true),
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.right,
                  alignment: ChartAlignment.near,
                  iconHeight: 10,
                  iconWidth: 10,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                series: <CircularSeries>[
                  DoughnutSeries<PieData, String>(
                    dataSource: pieData,
                    pointColorMapper: (PieData d, _) => d.color,
                    xValueMapper: (PieData d, _) => d.x,
                    yValueMapper: (PieData d, _) => d.y,
                    dataLabelSettings:
                    const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildTransactionList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80.0), // Adds padding at the bottom to avoid overlap
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final isExpense = transaction.type == 'Expense';
        final amountColor = isExpense ? Colors.red : Colors.green;
        final amountSign = isExpense ? '-' : '+';

        final subtitleParts = <String>[];
        if (transaction.category.isNotEmpty) {
          subtitleParts.add(transaction.category);
        }
        if (transaction.paymentMethod.isNotEmpty) {
          subtitleParts.add(transaction.paymentMethod);
        }
        if (transaction.notes.isNotEmpty) {
          subtitleParts.add(transaction.notes);
        }
        final combinedSubtitle = subtitleParts.join(' | ');

        return Dismissible(
          key: Key(transaction.date.toIso8601String()),
          // Allows swiping in both directions
          direction: DismissDirection.horizontal,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          // Background for swipe-to-edit (right to left)
          secondaryBackground: Container(
            color: Color(0xFF2539ec),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          // Handles the delete action
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              DatabaseHelper.instance.deleteTransaction(transaction.id!)
                  .then((_) {
                _loadTransactions().then((_) {
                  loadBalance();
                });
              });
            }
          },
          // Confirms the dismissal for editing
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              // Open the edit form with pre-filled data
              showTransactionForm(context, transactionToEdit: transaction);
              return Future.value(false); // Do not dismiss the item from the list
            }
            return Future.value(true); // Allow dismissal for delete
          },
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isExpense ? Colors.red.shade100 : Colors.green.shade100,
                child: Icon(
                  isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                  color: amountColor,
                ),
              ),
              title: Text(
                transaction.description,
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(combinedSubtitle, style: GoogleFonts.roboto(),),
              trailing: Text(
                '$amountSign₹${transaction.amount.toStringAsFixed(2)}',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: amountColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Updated function to show the transaction form with an optional transaction to edit
  void showTransactionForm(BuildContext context, {Transaction? transactionToEdit}) {
    final _amountController = TextEditingController(text: transactionToEdit?.amount.toStringAsFixed(2));
    final _descriptionController = TextEditingController(text: transactionToEdit?.description);
    final _paymentMethodController = TextEditingController(text: transactionToEdit?.paymentMethod);
    final _notesController = TextEditingController(text: transactionToEdit?.notes);

    String _selectedType = transactionToEdit?.type ?? 'Expense';
    String? _selectedCategory = transactionToEdit?.category;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Stack(
              alignment: Alignment.topCenter,
              children: [
          Positioned(
          top: MediaQuery.of(context).size.height * 0.25 - 25,
          child: FloatingActionButton(
          mini: true,
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 5,
          child: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
          if (Navigator.canPop(context)) {
          Navigator.pop(context);
          }
          },
          ),
          ),
          DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.7,
          minChildSize: 0.7,
          builder: (BuildContext context, ScrollController scrollController) {
          return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
          return Container(
          decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          ),
          ),
          padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
          ),
          child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transactionToEdit == null ? 'Add Transaction' : 'Update Transaction',
                      style: GoogleFonts.roboto(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    ToggleButtons(
                      isSelected: [
                        _selectedType == 'Income',
                        _selectedType == 'Expense',
                      ],
                      onPressed: (index) {
                        modalSetState(() {
                          _selectedType = index == 0 ? 'Income' : 'Expense';
                        });
                      },
                      borderRadius: BorderRadius.circular(10.0),
                      borderColor: Colors.black,
                      selectedBorderColor: Colors.blue.shade600,
                      selectedColor: Colors.white,
                      fillColor: Colors.blue.shade600,
                      color: Colors.blue.shade600,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text('Income', style: GoogleFonts.roboto(fontSize: 16)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text('Expense', style: GoogleFonts.roboto(fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount (in ₹)',
                          labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500, color: Colors.black87),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                          ),
                        ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                          labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500, color: Colors.black87),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                          ),
                        ),
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                          labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500, color: Colors.black87),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                          ),
                        ),
                      items: _categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        modalSetState(() {
                          _selectedCategory = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _paymentMethodController..text = 'UPI',
                      decoration: InputDecoration(
                        labelText: 'Payment Method (Optional)',
                          labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500, color: Colors.black87),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                          ),
                        ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                          labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500, color: Colors.black87),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                          ),
                        ),
                    ),
                    const SizedBox(height: 30),

                    Align(
                      alignment: Alignment.bottomRight,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : FilledButton.icon(
                          key: const ValueKey('save_button'),
                          onPressed: () {
                            if (_amountController.text.isEmpty ||
                                _descriptionController.text.isEmpty ||
                                _selectedCategory == null) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill in all required fields.'),
                                  backgroundColor: Colors.black,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            final data = {
                              'date': DateTime.now().toIso8601String(),
                              'description': _descriptionController.text,
                              'amount': double.tryParse(_amountController.text) ?? 0.0,
                              'type': _selectedType,
                              'category': _selectedCategory,
                              'paymentMethod': _paymentMethodController.text,
                              'notes': _notesController.text,
                            };
                            if (transactionToEdit == null) {
                              DatabaseHelper.instance.insertTransaction(data).then((_) {
                                _loadTransactions().then((_) {
                                  loadBalance();   // 👈 refresh balance
                                });
                              });
                            } else {
                              DatabaseHelper.instance.updateTransaction(
                                transactionToEdit.id!,
                                data,
                              ).then((_) {
                                _loadTransactions().then((_) {
                                  loadBalance();   // 👈 refresh balance
                                });
                              });
                            }
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2539ec),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            elevation: 2,
                          ),
                          icon: Icon(transactionToEdit == null ? Icons.save : Icons.update),
                          label: Text(transactionToEdit == null ? 'Save' : 'Update'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
          ),
          );
          },
          );
          },
          ),
              ],
          );
        },
    );
  }
}

// Data class for Syncfusion charts
class ChartData {
  ChartData(this.x, this.y1, this.y2);
  final String x;
  final double y1;
  final double y2;
}

class PieData {
  PieData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = false;
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    final dbData = await DatabaseHelper.instance.fetchTransactions();

    setState(() {
      _transactions = dbData.map((e) => Transaction.fromMap(e)).toList();
      _isLoading = false;
    });
  }


  Map<int, Map<String, double>> _getMonthlyData() {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
    final filteredTransactions = _transactions.where((t) => t.date.isAfter(threeMonthsAgo)).toList();

    Map<int, Map<String, double>> monthlyData = {};

    for (int i = 0; i < 3; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = date.month;
      monthlyData[monthKey] = {'income': 0.0, 'expense': 0.0};
    }

    for (var t in filteredTransactions) {
      final monthKey = t.date.month;
      if (t.type == 'Income') {
        monthlyData[monthKey]?['income'] = monthlyData[monthKey]!['income']! + t.amount;
      } else if (t.type == 'Expense') {
        monthlyData[monthKey]?['expense'] = monthlyData[monthKey]!['expense']! + t.amount;
      }
    }

    return monthlyData;
  }

  Map<String, double> _getCategoryData() {
    final categoryData = <String, double>{};
    final expenseTransactions = _transactions.where((t) => t.type == 'Expense');
    for (var t in expenseTransactions) {
      categoryData[t.category] = (categoryData[t.category] ?? 0) + t.amount;
    }
    return categoryData;
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Rent':
        return Colors.purple;
      case 'Salary':
        return Colors.green;
      case 'Entertainment':
        return Colors.yellow;
      case 'Groceries':
        return Colors.brown;
      case 'Utilities':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Add your first transaction Now!',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final monthlyData = _getMonthlyData();
    final categoryData = _getCategoryData();

    List<ChartData> chartData = [];
    final now = DateTime.now();
    final months = monthlyData.keys.toList();
    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      chartData.add(ChartData(
        DateFormat.MMM().format(DateTime(now.year, month)),
        monthlyData[month]!['income']!,
        monthlyData[month]!['expense']!,
      ));
    }

    List<PieData> pieData = categoryData.entries.map((entry) {
      return PieData(
        entry.key,
        entry.value,
        _getColorForCategory(entry.key),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Line Chart for Income vs Expenditure
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Income vs. Expenditure (Last 3 Months)',
                    style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      legend: const Legend(isVisible: true),
                      tooltipBehavior: TooltipBehavior(enable: true, header: ''),
                      series: <CartesianSeries>[
                        LineSeries<ChartData, String>(
                          dataSource: chartData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y1,
                          name: 'Income',
                          color: Colors.green,
                          markerSettings: const MarkerSettings(isVisible: true),
                          animationDuration: 1500,
                        ),
                        LineSeries<ChartData, String>(
                          dataSource: chartData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y2,
                          name: 'Expense',
                          color: Colors.red,
                          markerSettings: const MarkerSettings(isVisible: true),
                          animationDuration: 1500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Pie Chart for Category-wise Expenditure
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Category-wise Expenditure',
                    style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: SfCircularChart(
                      legend: const Legend(
                        isVisible: true,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        format: 'point.x : point.y%',
                      ),
                      series: <CircularSeries>[
                        DoughnutSeries<PieData, String>(
                          dataSource: pieData,
                          pointColorMapper: (PieData data, _) => data.color,
                          xValueMapper: (PieData data, _) => data.x,
                          yValueMapper: (PieData data, _) => data.y,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelPosition: ChartDataLabelPosition.outside,
                            connectorLineSettings: ConnectorLineSettings(type: ConnectorType.curve),
                          ),
                          radius: '80%',
                          innerRadius: '60%',
                          animationDuration: 1500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = false;
  List<Transaction> _allTransactions = [];
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    final dbData = await DatabaseHelper.instance.fetchTransactions();

    setState(() {
      _allTransactions = dbData.map((e) => Transaction.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  List<String> get _availableMonths {
    if (_allTransactions.isEmpty) return [];
    final months = _allTransactions
        .map((t) => DateFormat('MMMM yyyy').format(t.date))
        .toSet()
        .toList();

    months.sort((a, b) {
      final dateA = DateFormat('MMMM yyyy').parse(a);
      final dateB = DateFormat('MMMM yyyy').parse(b);
      return dateA.compareTo(dateB);
    });

    return months.reversed.toList();
  }

  List<Transaction> get _filteredTransactions {
    if (_selectedMonth == null) return [];
    return _allTransactions
        .where(
          (t) => DateFormat('MMMM yyyy').format(t.date) == _selectedMonth,
    )
        .toList();
  }

  // ---------------- EXPORT TO EXCEL (CSV) ----------------
  Future<void> _exportCurrentMonthReport() async {
    if (_selectedMonth == null || _filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a month with transactions to export.'),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Build CSV data
      final rows = <List<dynamic>>[];

      // Header row
      rows.add([
        'Date',
        'Description',
        'Type',
        'Category',
        'Payment Method',
        'Notes',
        'Amount',
      ]);

      // Data rows
      for (final t in _filteredTransactions) {
        rows.add([
          DateFormat('dd-MM-yyyy').format(t.date),
          t.description,
          t.type,
          t.category,
          t.paymentMethod,
          t.notes,
          t.amount.toStringAsFixed(2),
        ]);
      }

      final csvData = const ListToCsvConverter().convert(rows);

      // Get directory
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access storage.'),
            backgroundColor: Colors.black,
          ),
        );
        return;
      }

      final reportsDir = Directory('${dir.path}/SpendwellReports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final safeMonthName = _selectedMonth!.replaceAll(' ', '_');
      final filePath = '${reportsDir.path}/Spendwell_Report_$safeMonthName.csv';

      final file = File(filePath);
      await file.writeAsString(csvData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report exported:\n$filePath'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Add your first transaction to view reports!',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    double totalIncome = 0;
    double totalExpenditure = 0;
    for (var t in _filteredTransactions) {
      if (t.type == 'Income') {
        totalIncome += t.amount;
      } else {
        totalExpenditure += t.amount;
      }
    }
    final net = totalIncome - totalExpenditure;

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Heading ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Monthly Reports",
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.insert_chart_outlined, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 16),

            // ---------- Month Dropdown ----------
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Select Month",
                labelStyle: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500, color: Colors.black87),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide:
                  const BorderSide(color: Colors.blue, width: 1.5),
                ),
              ),
              value: _selectedMonth,
              items: _availableMonths.map((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMonth = newValue;
                });
              },
            ),
            const SizedBox(height: 20),

            // ---------- Summary + Export Button ----------
            if (_selectedMonth != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Card(
                  key: ValueKey(_selectedMonth),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.shade50,
                              ),
                              child: const Icon(Icons.summarize,
                                  color: Colors.blue),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Summary - $_selectedMonth',
                              style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Income',
                                    style: GoogleFonts.roboto(
                                        fontSize: 12, color: Colors.green)),
                                Text(
                                  '₹${totalIncome.toStringAsFixed(2)}',
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Expenditure',
                                    style: GoogleFonts.roboto(
                                        fontSize: 12, color: Colors.red)),
                                Text(
                                  '₹${totalExpenditure.toStringAsFixed(2)}',
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Net',
                                    style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: net >= 0
                                            ? Colors.green
                                            : Colors.red)),
                                Text(
                                  '₹${net.toStringAsFixed(2)}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: net >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Export button
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: _filteredTransactions.isEmpty
                                ? null
                                : _exportCurrentMonthReport,
                            icon: const Icon(Icons.download),
                            label: const Text("Export as Excel"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade800,
                              side: BorderSide(color: Colors.blue.shade800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ---------- Transactions List ----------
            if (_selectedMonth != null && _filteredTransactions.isNotEmpty) ...[
              Text(
                'Transactions',
                style: GoogleFonts.roboto(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction =
                  _filteredTransactions.reversed.toList()[index];
                  final isExpense = transaction.type == 'Expense';
                  final amountColor =
                  isExpense ? Colors.red : Colors.green;
                  final amountSign = isExpense ? '-' : '+';

                  final subtitleParts = <String>[];
                  if (transaction.category.isNotEmpty) {
                    subtitleParts.add(transaction.category);
                  }
                  if (transaction.paymentMethod.isNotEmpty) {
                    subtitleParts.add(transaction.paymentMethod);
                  }
                  if (transaction.notes.isNotEmpty) {
                    subtitleParts.add(transaction.notes);
                  }
                  final combinedSubtitle =
                  subtitleParts.join(' | ');

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isExpense
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        child: Icon(
                          isExpense
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: amountColor,
                        ),
                      ),
                      title: Text(
                        transaction.description,
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        combinedSubtitle,
                        style: GoogleFonts.roboto(),
                      ),
                      trailing: Text(
                        '$amountSign₹${transaction.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: amountColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            if (_selectedMonth != null && _filteredTransactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Text(
                    "No transactions found for this month.",
                    style: GoogleFonts.roboto(
                        fontSize: 16, color: Colors.grey.shade700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
