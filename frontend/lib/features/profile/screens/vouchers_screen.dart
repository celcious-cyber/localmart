import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class VouchersScreen extends StatelessWidget {
  const VouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> vouchers = [
      {
        'title': 'Gratis Ongkir Instan',
        'desc': 'Khusus pengiriman LocalSend se-KSB',
        'code': 'LOCOFREE',
        'expiry': 'Hingga 20 Apr 2026',
        'color': Colors.blue,
        'icon': Icons.local_shipping,
      },
      {
        'title': 'Diskon Makanan 20%',
        'desc': 'Minimal belanja Rp 50rb di Merchant Food',
        'code': 'MAKANLAGI',
        'expiry': 'Hingga 15 Apr 2026',
        'color': Colors.orange,
        'icon': Icons.restaurant,
      },
      {
        'title': 'Cashback Point 10K',
        'desc': 'Tanpa minimal belanja untuk UMKM',
        'code': 'UMKMJUARA',
        'expiry': 'Hingga 30 Apr 2026',
        'color': AppColors.primary,
        'icon': Icons.stars,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Voucher Saya',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          final voucher = vouchers[index];
          return _buildVoucherTicket(voucher);
        },
      ),
    );
  }

  Widget _buildVoucherTicket(Map<String, dynamic> voucher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side (Icon)
          Container(
            width: 90,
            decoration: BoxDecoration(
              color: voucher['color'].withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(voucher['icon'], color: voucher['color'], size: 32),
                const SizedBox(height: 4),
                Text(
                  'KLAIM',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: voucher['color'],
                  ),
                ),
              ],
            ),
          ),
          // Vertical Dash line (simulated)
          CustomPaint(
            size: const Size(1, double.infinity),
            painter: _DashLinePainter(),
          ),
          // Right side (Details)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    voucher['title'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    voucher['desc'],
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        voucher['expiry'],
                        style: GoogleFonts.poppins(fontSize: 9, color: Colors.red[300], fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Pakai',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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

class _DashLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 5;
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 2;
    while (startY < size.height - 5) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
