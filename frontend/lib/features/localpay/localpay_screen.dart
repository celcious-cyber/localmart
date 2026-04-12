import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class LocalPayScreen extends StatelessWidget {
  const LocalPayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFB),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainBalanceCard(),
                _buildActionGrid(),
                _buildSectionHeader('Transaksi Terakhir'),
                _buildTransactionHistory(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 100,
      elevation: 0,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LocalPay',
            style: GoogleFonts.epilogue(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 10),
              const SizedBox(width: 4),
              Text(
                'Taliwang, KSB',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 14),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.security_rounded, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainBalanceCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Saldo', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Rp 2.450.000', style: GoogleFonts.epilogue(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('Premium', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(Icons.add_box_rounded, 'Topup'),
                _buildQuickAction(Icons.send_rounded, 'Transfer'),
                _buildQuickAction(Icons.qr_code_scanner_rounded, 'Scan'),
                _buildQuickAction(Icons.account_balance_wallet_rounded, 'Minta'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildActionGrid() {
    final items = [
      {'label': 'Voucher', 'icon': Icons.confirmation_number_outlined},
      {'label': 'Asuransi', 'icon': Icons.shield_outlined},
      {'label': 'Investasi', 'icon': Icons.trending_up_rounded},
      {'label': 'Donasi', 'icon': Icons.favorite_outline_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) {
          return Column(
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Icon(item['icon'] as IconData, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(item['label'] as String, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Semua', style: GoogleFonts.manrope(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    final txs = [
      {'title': 'Transfer Masuk', 'name': 'Aditya Pratama', 'amount': '+Rp 500.000', 'type': 'in'},
      {'title': 'Pembayaran', 'name': 'LocalFood - Ayam Geprek', 'amount': '-Rp 25.000', 'type': 'out'},
      {'title': 'Top Up Saldo', 'name': 'Bank NTB Syariah', 'amount': '+Rp 1.000.000', 'type': 'in'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: txs.length,
      itemBuilder: (context, index) {
        final tx = txs[index];
        final isIn = tx['type'] == 'in';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(color: (isIn ? Colors.green : Colors.red).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIn ? Colors.green : Colors.red, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx['title']!, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(tx['name']!, style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(tx['amount']!, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w900, color: isIn ? Colors.green : AppColors.textPrimary)),
            ],
          ),
        );
      },
    );
  }
}
