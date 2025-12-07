import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const _dbName = 'spendwell.db';
  static const _dbVersion = 2; // ⬅️ bumped to 2 for new tables

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // -----------------------------------
  // CREATE DB (fresh install)
  // -----------------------------------
  Future _createDB(Database db, int version) async {
    await _createTransactionsTable(db);
    await _createBudgetsTable(db);
    await _createGoalsTable(db);
    await _createBillRemindersTable(db);
    await _createRecurringPaymentsTable(db);
    await _createMonthlyInsightsTable(db);
  }

  // -----------------------------------
  // UPGRADE DB (existing users)
  // -----------------------------------
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: add all new module tables
      await _createBudgetsTable(db);
      await _createGoalsTable(db);
      await _createBillRemindersTable(db);
      await _createRecurringPaymentsTable(db);
      await _createMonthlyInsightsTable(db);
    }

    // Future versions:
    // if (oldVersion < 3) { ... }
  }

  // ---------- TABLE CREATORS ----------

  Future _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        paymentMethod TEXT,
        notes TEXT
      )
    ''');
  }

  Future _createBudgetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        category TEXT,
        limit_amount REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future _createGoalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0,
        target_date TEXT,
        notes TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future _createBillRemindersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bill_reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL,
        due_date TEXT NOT NULL,
        repeat_cycle TEXT NOT NULL,
        category TEXT,
        notes TEXT,
        is_paid INTEGER NOT NULL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future _createRecurringPaymentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        frequency TEXT NOT NULL,
        next_date TEXT NOT NULL,
        payment_method TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future _createMonthlyInsightsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monthly_insights(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        total_income REAL NOT NULL,
        total_expense REAL NOT NULL,
        top_category TEXT,
        highest_spending_day TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // -----------------------------------
  // BASIC CRUD HELPERS
  // (You can expand these per module later)
  // -----------------------------------

  // TRANSACTIONS
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'id DESC');
  }

  Future<int> updateTransaction(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // BUDGETS
  Future<int> insertBudget(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('budgets', row);
  }

  Future<List<Map<String, dynamic>>> fetchBudgets() async {
    final db = await instance.database;
    return await db.query('budgets', orderBy: 'year DESC, month DESC');
  }

  Future<int> updateBudget(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'budgets',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await instance.database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // GOALS
  Future<int> insertGoal(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('goals', row);
  }

  Future<List<Map<String, dynamic>>> fetchGoals() async {
    final db = await instance.database;
    return await db.query('goals', orderBy: 'created_at DESC');
  }

  Future<int> updateGoal(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'goals',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await instance.database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // BILL REMINDERS
  Future<int> insertBillReminder(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('bill_reminders', row);
  }

  Future<List<Map<String, dynamic>>> fetchBillReminders() async {
    final db = await instance.database;
    return await db.query('bill_reminders', orderBy: 'due_date ASC');
  }

  Future<int> updateBillReminder(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'bill_reminders',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBillReminder(int id) async {
    final db = await instance.database;
    return await db.delete(
      'bill_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // RECURRING PAYMENTS
  Future<int> insertRecurringPayment(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('recurring_payments', row);
  }

  Future<List<Map<String, dynamic>>> fetchRecurringPayments() async {
    final db = await instance.database;
    return await db.query('recurring_payments', orderBy: 'next_date ASC');
  }

  Future<int> updateRecurringPayment(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'recurring_payments',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRecurringPayment(int id) async {
    final db = await instance.database;
    return await db.delete(
      'recurring_payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // MONTHLY INSIGHTS
  Future<int> insertMonthlyInsight(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('monthly_insights', row);
  }

  Future<List<Map<String, dynamic>>> fetchMonthlyInsights() async {
    final db = await instance.database;
    return await db.query('monthly_insights', orderBy: 'year DESC, month DESC');
  }

  // 🔹 Get total income
  Future<double> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT SUM(amount) as total FROM transactions WHERE type = 'Income'");
    return result.first['total'] == null ? 0 : result.first['total'] as double;
  }

  // 🔹 Get total expense
  Future<double> getTotalExpense() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT SUM(amount) as total FROM transactions WHERE type = 'Expense'");
    return result.first['total'] == null ? 0 : result.first['total'] as double;
  }

  // 🔹 Compute balance
  Future<double> getBalance() async {
    final income = await getTotalIncome();
    final expense = await getTotalExpense();
    return income - expense;
  }

  // Close database if ever needed
  Future close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}