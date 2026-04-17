import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _stores = [];
  List<dynamic> _drivers = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final stats = await AdminService().getStats();
    final stores = await AdminService().getStores();
    final drivers = await AdminService().getDrivers();
    
    if (mounted) {
      setState(() {
        _stats = stats;
        _stores = stores;
        _drivers = drivers;
        _isLoading = false;
      });
    }
  }

  void _updateStore(int id, String? status, String? level) async {
    final result = await AdminService().updateStoreStatus(id, status: status, level: level);
    if (mounted) {
      if (result['success']) {
        AppAlert.success('Update Berhasil', result['message'] ?? 'Status berhasil diperbarui');
      } else {
        AppAlert.error('Update Gagal', result['message'] ?? 'Terjadi kesalahan');
      }
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Admin Console',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AdminService().logout();
              Navigator.pop(context);
            },
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
        : IndexedStack(
            index: _selectedIndex,
            children: [
              _buildStatsView(),
              _buildStoresView(),
              _buildDriversView(),
            ],
          ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.amber[800],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Stores'),
          BottomNavigationBarItem(icon: Icon(Icons.motorcycle_outlined), label: 'Drivers'),
        ],
      ),
    );
  }

  Widget _buildStatsView() {
    if (_stats == null) return const Center(child: Text('Gagal memuat statistik'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Overview', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _statCard('Total Stores', _stats!['stores'].toString(), Icons.store, Colors.blue),
              _statCard('Total Drivers', _stats!['drivers'].toString(), Icons.motorcycle, Colors.green),
              _statCard('Total Products', _stats!['products'].toString(), Icons.inventory_2, Colors.orange),
              _statCard('Categories', _stats!['categories'].toString(), Icons.category, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStoresView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stores.length,
      itemBuilder: (context, index) {
        final store = _stores[index];
        bool isPending = store['status'] == 'pending';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: isPending ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
              child: Icon(Icons.store, color: isPending ? Colors.orange : Colors.green),
            ),
            title: Text(store['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Level: ${store['level']} • Status: ${store['status']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (isPending)
                      ElevatedButton(
                        onPressed: () => _updateStore(store['id'], 'approved', null),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('APPROVE'),
                      ),
                    ElevatedButton(
                      onPressed: () => _showBadgeDialog(store['id'], store['level']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                      child: const Text('CHANGE BADGE', style: TextStyle(color: Colors.black)),
                    ),
                    TextButton(
                      onPressed: () => _updateStore(store['id'], 'rejected', null),
                      child: const Text('REJECT', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBadgeDialog(int storeId, String currentLevel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Badge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Regular'),
              leading: const Icon(Icons.store),
              onTap: () {
                Navigator.pop(context);
                _updateStore(storeId, null, 'regular');
              },
            ),
            ListTile(
              title: const Text('Star Seller'),
              leading: const Icon(Icons.stars, color: Colors.orange),
              onTap: () {
                Navigator.pop(context);
                _updateStore(storeId, null, 'star');
              },
            ),
            ListTile(
              title: const Text('Official Mall'),
              leading: const Icon(Icons.verified, color: Colors.blue),
              onTap: () {
                Navigator.pop(context);
                _updateStore(storeId, null, 'mall');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriversView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _drivers.length,
      itemBuilder: (context, index) {
        final driver = _drivers[index];
        bool isPending = driver['status'] == 'pending';
        return ListTile(
          leading: const Icon(Icons.motorcycle),
          title: Text(driver['plate_number']),
          subtitle: Text('Status: ${driver['status']}'),
          trailing: isPending 
            ? ElevatedButton(
                onPressed: () async {
                  final res = await AdminService().updateDriverStatus(driver['id'], 'approved');
                  if (mounted) {
                    if (context.mounted) {
                      AppAlert.success('Update Driver', res['message'] ?? 'Driver telah disetujui');
                    }
                    _loadDashboardData();
                  }
                },
                child: const Text('Approve'),
              ) 
            : const Icon(Icons.check_circle, color: Colors.green),
        );
      },
    );
  }
}
