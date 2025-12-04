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
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
        ),
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
  final double discount;
  final List<Map<String, dynamic>> items;
  String syncStatus;

  Invoice({
    required this.id,
    required this.customer,
    required this.code,
    required this.date,
    required this.amount,
    this.discount = 0.0,
    this.items = const [],
    this.syncStatus = "Synced",
  });
}

class Product {
  final String code;
  final String name;
  final String unit;
  final double price;
  final int stock;

  Product({required this.code, required this.name, required this.unit, required this.price, required this.stock});
}

class SyncService {
  static bool isOnline = true;

  static final List<Invoice> _localInvoices = [
    Invoice(
        id: "INV-1001",
        customer: "Ali Farms",
        code: "C001",
        date: "2024-11-20 10:30",
        amount: 5000,
        discount: 0,
        items: [
          {"code": "P001", "name": "Urea 50kg", "unit": "Bag", "qty": "1", "rate": "4500", "amount": 4500.0, "tax_amt": 500.0}
        ]
    ),
    Invoice(
        id: "INV-1002",
        customer: "Green Acres",
        code: "C002",
        date: "2024-11-21 14:15",
        amount: 12500,
        syncStatus: "Pending",
        items: [
          {"code": "P002", "name": "DAP Fertilizer", "unit": "Bag", "qty": "1", "rate": "12000", "amount": 12000.0, "tax_amt": 500.0}
        ]
    ),
  ];

  static final List<Product> _localProducts = [
    Product(code: "P001", name: "Urea Fertilizer 50kg", unit: "Bag", price: 4500, stock: 150),
    Product(code: "P002", name: "DAP Fertilizer", unit: "Bag", price: 12000, stock: 45),
    Product(code: "P003", name: "Pesticide Spray X", unit: "Ltr", price: 1500, stock: 300),
    Product(code: "P004", name: "Wheat Seeds (Certified)", unit: "Kg", price: 250, stock: 5000),
  ];

  static List<Invoice> getInvoices() => _localInvoices;
  static List<Product> getProducts() => _localProducts;

  static int getPendingCount() => _localInvoices.where((i) => i.syncStatus == "Pending").length;
  static double getTotalSales() => _localInvoices.fold(0, (sum, item) => sum + item.amount);

  static Future<void> saveInvoice(Invoice invoice) async {
    if (isOnline) {
      await Future.delayed(const Duration(seconds: 1));
      invoice.syncStatus = "Synced";
      _localInvoices.add(invoice);
    } else {
      invoice.syncStatus = "Pending";
      _localInvoices.add(invoice);
    }
  }

  static void addProduct(Product p) {
    _localProducts.add(p);
  }

  static Future<void> syncPendingItems(Function(String) onProgress) async {
    if (!isOnline) return;
    List<Invoice> pendingItems = _localInvoices.where((i) => i.syncStatus == "Pending").toList();
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
      case 0: return DashboardView(
        onNewSale: () => setState(() => _selectedIndex = 3),
        onViewAllInvoices: () => setState(() => _selectedIndex = 2),
      );
      case 1: return const InventoryView();
      case 2: return const InvoiceListView();
      case 3: return InvoiceCreateView(onInvoiceSaved: () => setState(() => _selectedIndex = 2));
      default: return DashboardView(onNewSale: () => setState(() => _selectedIndex = 3), onViewAllInvoices: () => setState(() => _selectedIndex = 2));
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
                NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Inventory')),
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
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Invoices'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'New Sale'),
        ],
      ) : null,
    );
  }
}

// ==========================================
// 4. INVOICE RECEIPT SCREEN (FIXED OVERFLOW)
// ==========================================
class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text("Invoice Details")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              color: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
              child: Padding(
                // FIX: Reduced padding from 30 to 20 to prevent overflow
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.agriculture, size: 50, color: Colors.green),
                          const SizedBox(height: 10),
                          const Text("AgriPOS Inc.", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("Sales Receipt", style: TextStyle(color: Colors.grey[600], letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                    const Divider(height: 40, thickness: 2),

                    // Info Grid (FIXED WITH EXPANDED)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Invoice No:", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            Text(invoice.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text("Customer:", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            Text(invoice.customer, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ]),
                        ),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text("Date & Time:", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            Text(invoice.date, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text("Code:", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            Text(invoice.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Items Table
                    const Text("Purchase Details", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Table(
                      border: TableBorder(bottom: BorderSide(color: Colors.grey.shade300)),
                      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1), 2: FlexColumnWidth(2)},
                      children: [
                        TableRow(
                            decoration: BoxDecoration(color: Colors.grey[100]),
                            children: const [
                              Padding(padding: EdgeInsets.all(8), child: Text("Item")),
                              Padding(padding: EdgeInsets.all(8), child: Text("Qty")),
                              Padding(padding: EdgeInsets.all(8), child: Text("Total", textAlign: TextAlign.right)),
                            ]
                        ),
                        ...invoice.items.map((item) => TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text("@ ${item['rate']}/${item['unit']}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ])),
                              Padding(padding: const EdgeInsets.all(8), child: Text(item['qty'], style: const TextStyle(height: 1.5))),
                              Padding(padding: const EdgeInsets.all(8), child: Text(item['amount'].toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(height: 1.5))),
                            ]
                        )).toList()
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Totals
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text("Discount:", style: TextStyle(color: Colors.grey)),
                      Text("- PKR ${invoice.discount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 5),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text("GRAND TOTAL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("PKR ${invoice.amount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    ]),

                    const SizedBox(height: 40),
                    Center(
                      child: Text("Thank you for your business!", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600])),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (){},
                        icon: const Icon(Icons.print),
                        label: const Text("PRINT RECEIPT"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      ),
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
// 5. DASHBOARD VIEW
// ==========================================
class DashboardView extends StatelessWidget {
  final VoidCallback onNewSale;
  final VoidCallback onViewAllInvoices;

  const DashboardView({super.key, required this.onNewSale, required this.onViewAllInvoices});

  @override
  Widget build(BuildContext context) {
    double totalSales = SyncService.getTotalSales();
    int count = SyncService.getInvoices().length;
    int pending = SyncService.getPendingCount();

    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 900;
    bool isMobile = screenWidth < 600;

    List<Invoice> recentInvoices = SyncService.getInvoices();
    if(recentInvoices.length > 3) recentInvoices = recentInvoices.sublist(recentInvoices.length - 3);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              ElevatedButton.icon(
                onPressed: onNewSale,
                icon: const Icon(Icons.add),
                label: const Text("New Invoice"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sync),
                label: const Text("Force Sync"),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
              ),
            ],
          ),
          const SizedBox(height: 30),

          const Text("Business Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: isMobile ? 0.85 : 1.2,
            children: [
              _buildStatCard("Total Sales", "PKR ${totalSales.toStringAsFixed(0)}", Icons.attach_money, Colors.blue),
              _buildStatCard("Invoices", "$count", Icons.receipt_long, Colors.orange),
              _buildStatCard("Pending Sync", "$pending", Icons.cloud_upload, pending > 0 ? Colors.red : Colors.green),
              _buildStatCard("Customers", "124", Icons.people, Colors.purple),
            ],
          ),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: onViewAllInvoices, child: const Text("View All"))
            ],
          ),
          const SizedBox(height: 10),
          if (recentInvoices.isEmpty)
            const Text("No recent invoices.", style: TextStyle(color: Colors.grey))
          else
            ...recentInvoices.map((inv) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => InvoiceDetailScreen(invoice: inv)));
                },
                leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: const Icon(Icons.receipt, color: Colors.green, size: 20)),
                title: Text(inv.customer, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("PKR ${inv.amount.toStringAsFixed(0)}"),
                trailing: Text(inv.syncStatus, style: TextStyle(color: inv.syncStatus == "Synced" ? Colors.green : Colors.orange, fontSize: 12)),
              ),
            )).toList()
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
              Icon(Icons.more_horiz, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                ),
                Text(title, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 6. INVENTORY VIEW
// ==========================================
class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Add New Product"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Product Code")),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Product Name")),
                const SizedBox(height: 10),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Price (PKR)"), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: "Opening Stock"), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if(nameCtrl.text.isNotEmpty) {
                  setState(() {
                    SyncService.addProduct(Product(
                        code: codeCtrl.text,
                        name: nameCtrl.text,
                        unit: "Unit",
                        price: double.tryParse(priceCtrl.text) ?? 0,
                        stock: int.tryParse(stockCtrl.text) ?? 0
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("Save Product"),
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Product> products = SyncService.getProducts();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              const Text("Inventory & Stock", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.add),
                label: const Text("Add Product"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Text(p.code.substring(0, 1), style: const TextStyle(color: Colors.blue))
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Code: ${p.code} • Unit: ${p.unit}"),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("${p.stock} in stock", style: TextStyle(fontWeight: FontWeight.bold, color: p.stock < 50 ? Colors.red : Colors.green)),
                                Text("PKR ${p.price}", style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                          columns: const [
                            DataColumn(label: Text("Code", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Product Name", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Unit", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Price", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Current Stock", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: products.map((p) => DataRow(cells: [
                            DataCell(Text(p.code, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(p.name)),
                            DataCell(Text(p.unit)),
                            DataCell(Text(p.price.toStringAsFixed(0))),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: p.stock < 50 ? Colors.red.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12)
                              ),
                              child: Text("${p.stock}", style: TextStyle(fontWeight: FontWeight.bold, color: p.stock < 50 ? Colors.red : Colors.green)),
                            )),
                          ])).toList(),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 7. INVOICE LIST VIEW
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
                  if (constraints.maxWidth < 800) {
                    return ListView.builder(
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        final inv = invoices[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => InvoiceDetailScreen(invoice: inv)));
                            },
                            leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: const Icon(Icons.receipt, color: Colors.green)),
                            title: Text(inv.customer, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("#${inv.id} • ${inv.date}"),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("PKR ${inv.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(inv.syncStatus, style: TextStyle(fontSize: 10, color: inv.syncStatus == "Synced" ? Colors.green : Colors.orange)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text("Invoice ID", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Customer", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Code", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: invoices.map((inv) => DataRow(
                              onSelectChanged: (selected) {
                                if (selected != null && selected) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => InvoiceDetailScreen(invoice: inv)));
                                }
                              },
                              cells: [
                                DataCell(Text(inv.id, style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(inv.customer)),
                                DataCell(Text(inv.code)),
                                DataCell(Text(inv.date)),
                                DataCell(Text("PKR ${inv.amount.toStringAsFixed(2)}")),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: inv.syncStatus == "Synced" ? Colors.green.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
                                  child: Text(inv.syncStatus, style: TextStyle(color: inv.syncStatus == "Synced" ? Colors.green.shade800 : Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                                )),
                              ])).toList(),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 8. INVOICE CREATE VIEW
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
  final _discountCtrl = TextEditingController(text: "0");
  String? _paymentTerms;

  List<Map<String, dynamic>> _invoiceItems = [];
  double _grandTotal = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl.text = "${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}";
    _addNewItemRow();
  }

  void _addNewItemRow() {
    setState(() {
      _invoiceItems.add({"code": TextEditingController(), "name": TextEditingController(), "unit": TextEditingController(), "qty": TextEditingController(text: "1"), "rate": TextEditingController(text: "0"), "tax_p": TextEditingController(text: "0"), "amount": 0.0, "tax_amt": 0.0});
    });
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
    double discount = double.tryParse(_discountCtrl.text) ?? 0.0;
    setState(() => _grandTotal = (tempSub + tempTax) - discount);
  }

  Future<void> _submitInvoice() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      List<Map<String, dynamic>> finalItems = _invoiceItems.map((item) {
        return {
          "code": item['code'].text,
          "name": item['name'].text,
          "unit": item['unit'].text,
          "qty": item['qty'].text,
          "rate": item['rate'].text,
          "amount": item['amount'],
          "tax_amt": item['tax_amt']
        };
      }).toList();

      await SyncService.saveInvoice(Invoice(
        id: _invoiceIdCtrl.text,
        customer: _custNameCtrl.text,
        code: _custCodeCtrl.text,
        date: _dateCtrl.text,
        amount: _grandTotal,
        discount: double.tryParse(_discountCtrl.text) ?? 0.0,
        items: finalItems,
      ));

      setState(() => _isSaving = false);
      widget.onInvoiceSaved();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invoice Saved Successfully!"), backgroundColor: Colors.green));
    }
  }

  void _openFullScreenItemEditor() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => Scaffold(
        appBar: AppBar(title: const Text("Manage Invoice Items")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            ...List.generate(_invoiceItems.length, (index) {
              final item = _invoiceItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Row(children: [Expanded(child: _buildTextField("Code", item['code'])), const SizedBox(width: 10), Expanded(child: _buildTextField("Unit", item['unit']))]),
                    const SizedBox(height: 10),
                    _buildTextField("Item Name", item['name']),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _buildTableInput(item['rate'], "Rate", isNum: true, onChange: (v) => _calculateTotals())),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTableInput(item['qty'], "Qty", isNum: true, onChange: (v) => _calculateTotals())),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _buildTableInput(item['tax_p'], "Tax %", isNum: true, onChange: (v) => _calculateTotals())),
                      const SizedBox(width: 10),
                      Expanded(child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Text("Tax: ${item['tax_amt'].toStringAsFixed(1)}", textAlign: TextAlign.center),
                      )),
                    ]),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text("Line Total:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("PKR ${item['amount'].toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    ]),
                    const SizedBox(height: 5),
                    Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { setState(() { if(_invoiceItems.length > 1) _invoiceItems.removeAt(index); }); Navigator.pop(context); _openFullScreenItemEditor(); }))
                  ]),
                ),
              );
            }),
            ElevatedButton.icon(onPressed: () { _addNewItemRow(); Navigator.pop(context); _openFullScreenItemEditor(); }, icon: const Icon(Icons.add), label: const Text("Add Another Item")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)), child: const Text("DONE & RETURN"))
          ]),
        )
    )));
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

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

                // HEADER
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(children: [Expanded(child: _buildTextField("Invoice ID", _invoiceIdCtrl, readOnly: true)), const SizedBox(width: 15), Expanded(child: _buildTextField("Date", _dateCtrl))]),
                        const SizedBox(height: 15),
                        Row(children: [Expanded(child: _buildTextField("Code", _custCodeCtrl)), const SizedBox(width: 15), Expanded(flex: 2, child: _buildTextField("Customer Name", _custNameCtrl))])
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ITEMS
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text("Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          if(!isMobile) ElevatedButton.icon(onPressed: _addNewItemRow, icon: const Icon(Icons.add, size: 16), label: const Text("Add Item"))
                        ]),
                        const Divider(height: 30),

                        if (isMobile)
                          Column(children: [
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Center(child: Text("${_invoiceItems.length} items added. Total: ${_grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold))),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _openFullScreenItemEditor, icon: const Icon(Icons.edit), label: const Text("MANAGE ITEMS (FULL SCREEN)")))
                          ])
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 1000),
                              child: Column(children: [
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
                                  return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
                                    SizedBox(width: 80, child: _buildTextField("Code", item['code'])), const SizedBox(width: 10),
                                    SizedBox(width: 200, child: _buildTextField("Item", item['name'])), const SizedBox(width: 10),
                                    SizedBox(width: 80, child: _buildTextField("Unit", item['unit'])), const SizedBox(width: 10),
                                    SizedBox(width: 100, child: _buildTableInput(item['rate'], "Rate", isNum: true, onChange: (v) => _calculateTotals())), const SizedBox(width: 10),
                                    SizedBox(width: 80, child: _buildTableInput(item['qty'], "Qty", isNum: true, onChange: (v) => _calculateTotals())), const SizedBox(width: 10),
                                    SizedBox(width: 100, child: Text(item['amount'].toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))), const SizedBox(width: 10),
                                    SizedBox(width: 60, child: _buildTableInput(item['tax_p'], "Tax", isNum: true, onChange: (v) => _calculateTotals())), const SizedBox(width: 10),
                                    SizedBox(width: 80, child: Text(item['tax_amt'].toStringAsFixed(2))),
                                  ]));
                                })]),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        SizedBox(width: 200, child: _buildTableInput(_discountCtrl, "Discount (PKR)", isNum: true, onChange: (v) => _calculateTotals())),
                        const SizedBox(height: 10),
                        Text("Grand Total: PKR ${_grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: _isSaving ? null : _submitInvoice, icon: const Icon(Icons.check), label: const Text("Submit Invoice"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(20))))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool readOnly = false, IconData? icon}) {
    return TextFormField(controller: ctrl, readOnly: readOnly, decoration: InputDecoration(labelText: label, suffixIcon: icon != null ? Icon(icon) : null));
  }
  Widget _buildTableInput(TextEditingController ctrl, String hint, {bool isNum = false, Function(String)? onChange}) {
    return TextFormField(controller: ctrl, onChanged: onChange, keyboardType: isNum ? TextInputType.number : TextInputType.text, inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : [], decoration: InputDecoration(labelText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), isDense: true));
  }
}