import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/kasir/kasir_screen.dart';
import 'features/riwayat/riwayat_screen.dart';
import 'features/settings/kategori_tiket_screen.dart';
import 'features/rekap/rekap_screen.dart';
import 'core/theme/app_theme.dart';
import 'providers/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://qwgkqgniqmkbqoktkkwq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Z2txZ25pcW1rYnFva3Rra3dxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY3NjA4NzQsImV4cCI6MjEwMjMzNjg3NH0.E7sgh8Bi1OHJZWvRU6GetSAyHw9VJWEOKZrw20ojwcs',
  );

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
    RekapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(databaseProvider);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale),
            label: 'Kasir',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Kategori'),
          NavigationDestination(icon: Icon(Icons.assessment), label: 'Rekap'),
        ],
      ),
    );
  }
}
