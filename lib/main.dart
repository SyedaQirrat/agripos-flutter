import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Required for simulating Server Delay

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
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
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
  final String date;
  final double amount;
  String syncStatus; // "Synced", "Pending", "Failed"

  Invoice({
    required this.id,
    required this.customer,
    required this.date,
    required this.amount,
    this.syncStatus = "Synced",
  });
}

class SyncService {
  // --- STATE ---
  static bool isOnline = true; // Default to Online
  static final List<Invoice> _localDatabase = [];

  // --- DATA ACCESS ---
  static List<Invoice> getInvoices() => _localDatabase;

  static int getPendingCount() {
    return _localDatabase.where((i) => i.syncStatus == "Pending").length;
  }

  static double getTotalSales() {
    return _localDatabase.fold(0, (sum, item) => sum + item.amount);
  }

  // --- CORE SYNC LOGIC ---

  // 1. SAVE INVOICE
  static Future<void> saveInvoice(Invoice invoice) async {
    if (isOnline) {
      // SCENARIO A: ONLINE
      // Simulate sending to server immediately
      await _simulateServerUpload(invoice);
      invoice.syncStatus = "Synced";
      _localDatabase.add(invoice);
    } else {
      // SCENARIO B: OFFLINE
      // Save locally but mark as Pending
      invoice.syncStatus = "Pending";
      _localDatabase.add(invoice);
    }
  }

  // 2. TRIGGER SYNC (Called when switching from Offline -> Online)
  static Future<void> syncPendingItems(Function(String) onProgress) async {
    if (!isOnline) return;

    // Find all pending invoices
    List<Invoice> pendingItems = _localDatabase.where((i) => i.syncStatus == "Pending").toList();

    for (var invoice in pendingItems) {
      onProgress("Syncing Invoice ${invoice.id}...");

      // Simulate upload delay
      await _simulateServerUpload(invoice);

      // Update status
      invoice.syncStatus = "Synced";
    }

    onProgress("All items synced successfully!");
  }

  // --- MOCK SERVER API ---
  static Future<void> _simulateServerUpload(Invoice invoice) async {
    // This pretends to be an HTTP POST request to your Odoo/Laravel backend
    await Future.delayed(const Duration(seconds: 2));
    print("SERVER: Received Invoice ${invoice.id}");
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
      body: Center(
        child: Card(
          elevation: 5,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.agriculture, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                const Text("AgriPOS System", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayoutShell()));
                  },
                  child: const Text("LOGIN AS ADMIN"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. MAIN LAYOUT (CONTROLS SYNC UI)
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
    setState(() {
      SyncService.isOnline = !value; // Switch UI value is "Offline Mode", so invert for "isOnline"
    });

    if (SyncService.isOnline) {
      // If we just went ONLINE, check for pending items
      int pending = SyncService.getPendingCount();
      if (pending > 0) {
        setState(() {
          _isSyncing = true;
          _syncMessage = "Found $pending pending invoices...";
        });

        // Trigger the Sync Process
        await SyncService.syncPendingItems((status) {
          setState(() => _syncMessage = status);
        });

        setState(() {
          _isSyncing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sync Complete!")));
      }
    }
  }

  Widget _getCurrentView() {
    switch (_selectedIndex) {
      case 0: return const DashboardView();
      case 1: return const InvoiceListView(); // Responsive Table inside here
      case 2: return InvoiceCreateView(onInvoiceSaved: () {
        setState(() => _selectedIndex = 1); // Go to list after save
      });
      default: return const DashboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine toggle state
    bool isOfflineMode = !SyncService.isOnline;

    return Scaffold(
      appBar: AppBar(
        title: const Text("AgriPOS Dashboard"),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // SYNC STATUS INDICATOR
          if (_isSyncing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text(_syncMessage, style: const TextStyle(color: Colors.blue, fontSize: 12)),
                ],
              ),
            ),

          // OFFLINE TOGGLE
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0, left: 20.0),
              child: Row(
                children: [
                  Text(
                      isOfflineMode ? "OFFLINE MODE" : "ONLINE CONNECTED",
                      style: TextStyle(fontWeight: FontWeight.bold, color: isOfflineMode ? Colors.red : Colors.green)
                  ),
                  Switch(
                    value: isOfflineMode,
                    onChanged: _handleOfflineToggle,
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green,
                    inactiveTrackColor: Colors.green[100],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.list_alt), label: Text('Invoices')),
              NavigationRailDestination(icon: Icon(Icons.post_add), label: Text('New Sale')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _getCurrentView()),
        ],
      ),
    );
  }
}

// ==========================================
// 4. DASHBOARD VIEW
// ==========================================
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    double totalSales = SyncService.getTotalSales();
    int count = SyncService.getInvoices().length;
    int pending = SyncService.getPendingCount();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Daily Overview", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard("Total Sales", "PKR ${totalSales.toStringAsFixed(0)}", Colors.blue),
              const SizedBox(width: 20),
              _buildStatCard("Invoices Generated", "$count", Colors.orange),
              const SizedBox(width: 20),
              _buildStatCard("Pending Sync", "$pending", pending > 0 ? Colors.red : Colors.green),
            ],
          ),
          const SizedBox(height: 40),
          if (pending > 0)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 10),
                  Text("Warning: You have $pending invoices waiting to sync. Switch to Online mode to upload.", style: const TextStyle(color: Colors.red)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. INVOICE LIST VIEW (RESPONSIVE FIX APPLIED)
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
          const Text("Invoice History", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              // RESPONSIVE FIX: LayoutBuilder + SingleChildScrollView (Horizontal)
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.green[50]),
                            columns: const [
                              DataColumn(label: Text("Inv ID", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Customer", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Sync Status", style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: invoices.map((inv) => DataRow(cells: [
                              DataCell(Text(inv.id)),
                              DataCell(Text(inv.customer)),
                              DataCell(Text(inv.date)),
                              DataCell(Text(inv.amount.toStringAsFixed(2))),
                              DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: inv.syncStatus == "Synced" ? Colors.green[100] : Colors.orange[100],
                                        borderRadius: BorderRadius.circular(20)
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          inv.syncStatus == "Synced" ? Icons.check_circle : Icons.cloud_off,
                                          size: 14,
                                          color: inv.syncStatus == "Synced" ? Colors.green[800] : Colors.orange[800],
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                            inv.syncStatus,
                                            style: TextStyle(
                                                color: inv.syncStatus == "Synced" ? Colors.green[800] : Colors.orange[800],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12
                                            )
                                        ),
                                      ],
                                    ),
                                  )
                              ),
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
  final TextEditingController _invoiceIdCtrl = TextEditingController(text: "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}");
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _custNameCtrl = TextEditingController();
  final TextEditingController _custCodeCtrl = TextEditingController();

  List<Map<String, dynamic>> _invoiceItems = [];
  double _grandTotal = 0.0;
  bool _isSaving = false; // Loading state for Online Save

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateTime.now().toString().split(' ')[0];
    _addNewItemRow();
  }

  void _addNewItemRow() {
    setState(() {
      _invoiceItems.add({
        "item_code": TextEditingController(),
        "item_name": TextEditingController(),
        "qty": TextEditingController(text: "1"),
        "rate": TextEditingController(text: "0"),
        "amount": 0.0,
      });
    });
  }

  void _calculateTotals() {
    double tempTotal = 0.0;
    for (var item in _invoiceItems) {
      double qty = double.tryParse(item['qty'].text) ?? 0.0;
      double rate = double.tryParse(item['rate'].text) ?? 0.0;
      double lineAmount = qty * rate;
      item['amount'] = lineAmount;
      tempTotal += lineAmount;
    }
    setState(() {
      _grandTotal = tempTotal;
    });
  }

  Future<void> _submitInvoice() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true); // Start Loading

      // 1. Create Invoice Object
      final newInvoice = Invoice(
        id: _invoiceIdCtrl.text,
        customer: _custNameCtrl.text,
        date: _dateCtrl.text,
        amount: _grandTotal,
      );

      // 2. Pass to Sync Service (Logic handles Online vs Offline)
      await SyncService.saveInvoice(newInvoice);

      setState(() => _isSaving = false); // Stop Loading

      // 3. Feedback
      String msg = SyncService.isOnline
          ? "Invoice Synced to Server!"
          : "Saved locally (Offline). Will sync when online.";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: SyncService.isOnline ? Colors.green : Colors.orange,
      ));

      // 4. Navigate away
      widget.onInvoiceSaved();
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
                const Text("New Sales Invoice", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildHeaderSection(),
                const SizedBox(height: 20),
                _buildItemsTable(),
                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submitInvoice, // Disable button while saving
                    icon: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isSaving ? "PROCESSING..." : "SUBMIT INVOICE"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // (Helper widgets are abbreviated for brevity, same as previous version)
  Widget _buildHeaderSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: _buildTextField("Invoice ID", _invoiceIdCtrl, readOnly: true)),
              const SizedBox(width: 15),
              Expanded(child: _buildTextField("Date", _dateCtrl, icon: Icons.calendar_today)),
            ]),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: _buildTextField("Customer Name", _custNameCtrl)),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(onPressed: _addNewItemRow, child: const Text("Add Item"))
            ]),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              itemCount: _invoiceItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _invoiceItems[index];
                return Row(children: [
                  Expanded(flex: 2, child: _buildTextField("Item", item['item_name'])),
                  const SizedBox(width: 10),
                  Expanded(flex: 1, child: _buildTableInput(item['rate'], "Rate", isNumber: true, onChange: (v) => _calculateTotals())),
                  const SizedBox(width: 10),
                  Expanded(flex: 1, child: _buildTableInput(item['qty'], "Qty", isNumber: true, onChange: (v) => _calculateTotals())),
                  const SizedBox(width: 10),
                  Expanded(flex: 1, child: Text(item['amount'].toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, IconData? icon}) {
    return TextFormField(controller: controller, readOnly: readOnly, decoration: InputDecoration(labelText: label, suffixIcon: icon != null ? Icon(icon) : null, border: const OutlineInputBorder()));
  }
  Widget _buildTableInput(TextEditingController controller, String hint, {bool isNumber = false, Function(String)? onChange}) {
    return TextFormField(controller: controller, onChanged: onChange, keyboardType: isNumber ? TextInputType.number : TextInputType.text, inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : [], decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.all(12)));
  }
}