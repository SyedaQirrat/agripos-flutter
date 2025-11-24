import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(const AgriPosApp());
}

class AgriPosApp extends StatelessWidget {
  const AgriPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriPOS Cloud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FE),
        // FIXED: Removed the 'cardTheme' block that was causing the error.
        // We will rely on default Material 3 card styles which are perfectly fine.
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.green, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 1. DATA MODELS & SYNC SERVICE
// ==========================================

class Invoice {
  final String id;
  final String customer;
  final String code;
  final String date;
  final double amount;
  String syncStatus;

  Invoice({
    required this.id,
    required this.customer,
    required this.code,
    required this.date,
    required this.amount,
    this.syncStatus = "Synced",
  });
}

class SyncService {
  static bool isOnline = true;
  static final List<Invoice> _localDatabase = [];

  static List<Invoice> getInvoices() => _localDatabase;
  static int getPendingCount() => _localDatabase.where((i) => i.syncStatus == "Pending").length;
  static double getTotalSales() => _localDatabase.fold(0, (sum, item) => sum + item.amount);

  static Future<void> saveInvoice(Invoice invoice) async {
    if (isOnline) {
      await Future.delayed(const Duration(seconds: 1));
      invoice.syncStatus = "Synced";
      _localDatabase.add(invoice);
    } else {
      invoice.syncStatus = "Pending";
      _localDatabase.add(invoice);
    }
  }

  static Future<void> syncPendingItems(Function(String) onProgress) async {
    if (!isOnline) return;
    List<Invoice> pendingItems = _localDatabase.where((i) => i.syncStatus == "Pending").toList();
    for (var invoice in pendingItems) {
      onProgress("Syncing ${invoice.id}...");
      await Future.delayed(const Duration(milliseconds: 500));
      invoice.syncStatus = "Synced";
    }
    onProgress("Sync Complete!");
  }
}

// ==========================================
// 2. LOGIN SCREEN
// ==========================================
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Colors.green.shade900, Colors.green.shade500],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Moved shape here directly
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.agriculture, size: 50, color: Colors.green),
                    ),
                    const SizedBox(height: 20),
                    const Text("AgriPOS Admin", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Sign in to manage sales", style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 30),
                    TextFormField(decoration: const InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 15),
                    TextFormField(obscureText: true, decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock_outline))),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayoutShell()));
                      },
                      child: const Text("LOGIN"),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. MAIN LAYOUT
// ==========================================
class MainLayoutShell extends StatefulWidget {
  const MainLayoutShell({super.key});

  @override
  State<MainLayoutShell> createState() => _MainLayoutShellState();
}

class _MainLayoutShellState extends State<MainLayoutShell> {
  int _selectedIndex = 0;
  bool _isSyncing = false;
  String _syncMessage = "";

  void _handleOfflineToggle(bool value) async {
    setState(() => SyncService.isOnline = !value);
    if (SyncService.isOnline && SyncService.getPendingCount() > 0) {
      setState(() { _isSyncing = true; _syncMessage = "Syncing..."; });
      await SyncService.syncPendingItems((status) => setState(() => _syncMessage = status));
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sync Complete!")));
    }
  }

  Widget _getCurrentView() {
    switch (_selectedIndex) {
      case 0: return DashboardView(onNewSale: () => setState(() => _selectedIndex = 2));
      case 1: return const InvoiceListView();
      case 2: return InvoiceCreateView(onInvoiceSaved: () => setState(() => _selectedIndex = 1));
      default: return DashboardView(onNewSale: () => setState(() => _selectedIndex = 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOffline = !SyncService.isOnline;
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text("AgriPOS Cloud", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_isSyncing) ...[
            const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Text(_syncMessage, style: const TextStyle(color: Colors.blue, fontSize: 12)),
            const SizedBox(width: 20),
          ],
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOffline ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isOffline ? Colors.red.shade200 : Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: isOffline ? Colors.red : Colors.green),
                const SizedBox(width: 8),
                Text(isOffline ? "OFFLINE" : "ONLINE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isOffline ? Colors.red.shade700 : Colors.green.shade700)),
                const SizedBox(width: 8),
                SizedBox(
                  height: 20,
                  child: Switch(
                    value: isOffline,
                    onChanged: _handleOfflineToggle,
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              groupAlignment: -0.9,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Overview')),
                NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Invoices')),
                NavigationRailDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: Text('New Sale')),
              ],
            ),
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _getCurrentView()),
        ],
      ),
      bottomNavigationBar: !isDesktop ? NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Invoices'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'New Sale'),
        ],
      ) : null,
    );
  }
}

// ==========================================
// 4. IMPROVED DASHBOARD UI
// ==========================================
class DashboardView extends StatelessWidget {
  final VoidCallback onNewSale;
  const DashboardView({super.key, required this.onNewSale});

  @override
  Widget build(BuildContext context) {
    double totalSales = SyncService.getTotalSales();
    int count = SyncService.getInvoices().length;
    int pending = SyncService.getPendingCount();
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.shade800, Colors.green.shade500]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.green.shade200, blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome back, Admin 👋", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Here is what's happening with your store today.", style: TextStyle(color: Colors.green.shade100, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Quick Actions
          const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onNewSale,
                icon: const Icon(Icons.add),
                label: const Text("New Invoice"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
              ),
              const SizedBox(width: 15),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sync),
                label: const Text("Force Sync"),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Stats Grid
          const Text("Business Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard("Total Sales", "PKR ${totalSales.toStringAsFixed(0)}", Icons.attach_money, Colors.blue),
              _buildStatCard("Invoices", "$count", Icons.receipt_long, Colors.orange),
              _buildStatCard("Pending Sync", "$pending", Icons.cloud_upload, pending > 0 ? Colors.red : Colors.green),
              _buildStatCard("Customers", "124", Icons.people, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color),
              ),
              Icon(Icons.more_horiz, color: Colors.grey.shade400),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// 5. INVOICE LIST VIEW
// ==========================================
class InvoiceListView extends StatelessWidget {
  const InvoiceListView({super.key});

  @override
  Widget build(BuildContext context) {
    List<Invoice> invoices = SyncService.getInvoices();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("All Invoices", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                            columns: const [
                              DataColumn(label: Text("Invoice ID", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Customer", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Code", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: invoices.map((inv) => DataRow(cells: [
                              DataCell(Text(inv.id, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(inv.customer)),
                              DataCell(Text(inv.code)),
                              DataCell(Text(inv.date)),
                              DataCell(Text("PKR ${inv.amount.toStringAsFixed(2)}")),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: inv.syncStatus == "Synced" ? Colors.green.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(inv.syncStatus, style: TextStyle(color: inv.syncStatus == "Synced" ? Colors.green.shade800 : Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                              )),
                            ])).toList(),
                          ),
                        ),
                      ),
                    );
                  }
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 6. INVOICE CREATE VIEW
// ==========================================
class InvoiceCreateView extends StatefulWidget {
  final VoidCallback onInvoiceSaved;
  const InvoiceCreateView({super.key, required this.onInvoiceSaved});

  @override
  State<InvoiceCreateView> createState() => _InvoiceCreateViewState();
}

class _InvoiceCreateViewState extends State<InvoiceCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceIdCtrl = TextEditingController(text: "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}");
  final _dateCtrl = TextEditingController();
  final _custNameCtrl = TextEditingController();
  final _custCodeCtrl = TextEditingController();
  String? _paymentTerms;

  List<Map<String, dynamic>> _invoiceItems = [];
  double _subTotal = 0.0;
  double _totalTax = 0.0;
  double _grandTotal = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateTime.now().toString().split(' ')[0];
    _addNewItemRow();
  }

  void _addNewItemRow() {
    setState(() {
      _invoiceItems.add({
        "code": TextEditingController(),
        "name": TextEditingController(),
        "unit": TextEditingController(),
        "qty": TextEditingController(text: "1"),
        "rate": TextEditingController(text: "0"),
        "tax_p": TextEditingController(text: "0"),
        "amount": 0.0,
        "tax_amt": 0.0
      });
    });
  }

  void _removeRow(int index) {
    if (_invoiceItems.length > 1) {
      setState(() { _invoiceItems.removeAt(index); _calculateTotals(); });
    }
  }

  void _calculateTotals() {
    double tempSub = 0.0;
    double tempTax = 0.0;
    for (var item in _invoiceItems) {
      double qty = double.tryParse(item['qty'].text) ?? 0.0;
      double rate = double.tryParse(item['rate'].text) ?? 0.0;
      double taxP = double.tryParse(item['tax_p'].text) ?? 0.0;
      double lineAmt = qty * rate;
      double taxAmt = lineAmt * (taxP / 100);

      item['amount'] = lineAmt;
      item['tax_amt'] = taxAmt;
      tempSub += lineAmt;
      tempTax += taxAmt;
    }
    setState(() { _subTotal = tempSub; _totalTax = tempTax; _grandTotal = tempSub + tempTax; });
  }

  Future<void> _submitInvoice() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      await SyncService.saveInvoice(Invoice(
        id: _invoiceIdCtrl.text,
        customer: _custNameCtrl.text,
        code: _custCodeCtrl.text,
        date: _dateCtrl.text,
        amount: _grandTotal,
      ));
      setState(() => _isSaving = false);
      widget.onInvoiceSaved();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invoice Saved Successfully!"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("New Sales Invoice", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // HEADER INFO
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Customer Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        LayoutBuilder(builder: (context, constraints) {
                          bool isWide = constraints.maxWidth > 700;
                          return Column(
                            children: [
                              Flex(
                                direction: isWide ? Axis.horizontal : Axis.vertical,
                                children: [
                                  Expanded(flex: isWide?1:0, child: _buildTextField("Invoice ID", _invoiceIdCtrl, readOnly: true)),
                                  SizedBox(width: isWide?15:0, height: isWide?0:15),
                                  Expanded(flex: isWide?1:0, child: _buildTextField("Date", _dateCtrl, icon: Icons.calendar_today)),
                                  SizedBox(width: isWide?15:0, height: isWide?0:15),
                                  Expanded(flex: isWide?1:0, child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(labelText: "Payment Terms"),
                                    value: _paymentTerms,
                                    items: ["Cash", "Net 15", "Net 30"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                    onChanged: (v) => setState(() => _paymentTerms = v),
                                  )),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Flex(
                                direction: isWide ? Axis.horizontal : Axis.vertical,
                                children: [
                                  Expanded(flex: isWide?1:0, child: _buildTextField("Customer Code", _custCodeCtrl)),
                                  SizedBox(width: isWide?15:0, height: isWide?0:15),
                                  Expanded(flex: isWide?2:0, child: _buildTextField("Customer Name", _custNameCtrl)),
                                ],
                              )
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ITEMS TABLE
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text("Items & Products", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(onPressed: _addNewItemRow, icon: const Icon(Icons.add, size: 16), label: const Text("Add Item"))
                        ]),
                        const Divider(height: 30),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1000),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: const Row(children: [
                                    SizedBox(width: 80, child: Text("Code", style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 10),
                                    SizedBox(width: 200, child: Text("Item Name", style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 10),
                                    SizedBox(width: 80, child: Text("Unit", style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 10),
                                    SizedBox(width: 100, child: Text("Rate", style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 10),
                                    SizedBox(width: 80, child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 10),
                                    SizedBox(width: 100, child: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 10),
                                    SizedBox(width: 60, child: Text("Tax%", style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 10),
                                    SizedBox(width: 80, child: Text("Tax Amt", style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 50),
                                  ]),
                                ),
                                ...List.generate(_invoiceItems.length, (index) {
                                  final item = _invoiceItems[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(children: [
                                      SizedBox(width: 80, child: _buildTableInput(item['code'], "")), SizedBox(width: 10),
                                      SizedBox(width: 200, child: _buildTableInput(item['name'], "")), SizedBox(width: 10),
                                      SizedBox(width: 80, child: _buildTableInput(item['unit'], "Kg")), SizedBox(width: 10),
                                      SizedBox(width: 100, child: _buildTableInput(item['rate'], "0", isNum: true, onChange: (v) => _calculateTotals())), SizedBox(width: 10),
                                      SizedBox(width: 80, child: _buildTableInput(item['qty'], "1", isNum: true, onChange: (v) => _calculateTotals())), SizedBox(width: 10),
                                      SizedBox(width: 100, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text(item['amount'].toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)))), SizedBox(width: 10),
                                      SizedBox(width: 60, child: _buildTableInput(item['tax_p'], "0", isNum: true, onChange: (v) => _calculateTotals())), SizedBox(width: 10),
                                      SizedBox(width: 80, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text(item['tax_amt'].toStringAsFixed(2)))),
                                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeRow(index)),
                                    ]),
                                  );
                                })
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // FOOTER
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        _buildFooterRow("Sub Total", _subTotal),
                        const SizedBox(height: 10),
                        _buildFooterRow("Total Tax", _totalTax),
                        const Divider(height: 30),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text("Grand Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("PKR ${_grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        ])
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // SUBMIT
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submitInvoice,
                    icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle),
                    label: Text(_isSaving ? "Processing..." : "Submit Invoice"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterRow(String label, double val) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.grey.shade600)), Text(val.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))]);
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool readOnly = false, IconData? icon}) {
    return TextFormField(controller: ctrl, readOnly: readOnly, decoration: InputDecoration(labelText: label, suffixIcon: icon != null ? Icon(icon) : null));
  }

  Widget _buildTableInput(TextEditingController ctrl, String hint, {bool isNum = false, Function(String)? onChange}) {
    return TextFormField(controller: ctrl, onChanged: onChange, keyboardType: isNum ? TextInputType.number : TextInputType.text, inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : [], decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), isDense: true));
  }
}