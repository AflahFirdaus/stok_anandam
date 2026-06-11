import 'package:flutter/material.dart';
import 'laporan_page.dart';

class ServisKlaimView extends StatelessWidget {
  const ServisKlaimView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Klaim Distributor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Fitur dalam pengembangan', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class ServisLaporanView extends StatelessWidget {
  const ServisLaporanView({super.key});

  @override
  Widget build(BuildContext context) {
    return const LaporanPage();
  }
}
