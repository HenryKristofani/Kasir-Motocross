import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/kasir/kasir_screen.dart';
import 'features/riwayat/riwayat_screen.dart';
import 'features/settings/kategori_tiket_screen.dart';
import 'core/theme/app_theme.dart';
import 'providers/init_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Motocross',
      theme: AppTheme.light,
      home: const RootScreen(),
    );
  }
}

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _index = 0;

  final _pages = const [
    KasirScreen(),
    RiwayatScreen(),
    KategoriTiketScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize seed data saat app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(initKategoriTiketProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Kategori'),
        ],
      ),
    );
  }
}