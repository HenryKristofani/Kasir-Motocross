import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/sync/sync_service.dart';

/// Sync status indicator widget untuk AppBar dengan error state support
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = SyncService();

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () => _showSyncDialog(context, syncService),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(syncService),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: _buildStatusText(syncService),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(SyncService syncService) {
    if (syncService.isSyncing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      );
    } else if (syncService.hasError) {
      return const Icon(Icons.cloud_off, color: Colors.red, size: 20);
    } else if (syncService.pendingCount > 0) {
      return const Icon(Icons.cloud_off, color: Colors.orange, size: 20);
    } else {
      return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
    }
  }

  Widget _buildStatusText(SyncService syncService) {
    if (syncService.isSyncing) {
      return const Text(
        'Sedang sync...',
        key: ValueKey('syncing'),
        style: TextStyle(
          fontSize: 12,
          color: Colors.orange,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (syncService.hasError) {
      return const Text(
        'Gagal sync',
        key: ValueKey('error'),
        style: TextStyle(
          fontSize: 12,
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (syncService.pendingCount > 0) {
      return Text(
        '${syncService.pendingCount} belum sync',
        key: ValueKey('pending_${syncService.pendingCount}'),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.orange,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      return const Text(
        'Tersinkron',
        key: ValueKey('synced'),
        style: TextStyle(
          fontSize: 12,
          color: Colors.green,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  void _showSyncDialog(BuildContext context, SyncService syncService) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Status Sinkronisasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pending: ${syncService.pendingCount} record'),
              const SizedBox(height: 8),
              Text('Status: ${_statusLabel(syncService.status)}'),
              if (syncService.hasError) ...[
                const SizedBox(height: 16),
                const Text(
                  'Error:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 4),
                Text(
                  syncService.lastError,
                  style: const TextStyle(fontSize: 11, color: Colors.red),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'App akan otomatis retry saat:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text('• Koneksi internet aktif (WiFi atau data)'),
              const Text('• Ada record pending (isSynced = false)'),
              const Text('• Dengan jeda minimal 15 detik antar percobaan'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '⚠️ Jika kategori tidak sync (409 FK error):',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              ),
              const Text(
                'Klik "Force Re-sync Kategori" untuk reset & sync ulang.',
                style: TextStyle(fontSize: 11, color: Colors.orange),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            if (!syncService.isSyncing)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  syncService.forceResyncAllCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Force re-sync kategori dimulai...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Force Re-sync Kategori',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            if (syncService.pendingCount > 0 && !syncService.isSyncing)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  syncService.syncPending();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sync dimulai...')),
                  );
                },
                child: const Text('Sync Sekarang'),
              ),
          ],
        );
      },
    );
  }

  String _statusLabel(SyncStatus status) {
    return switch (status) {
      SyncStatus.idle => 'Siap (tidak ada pending)',
      SyncStatus.syncing => 'Sedang sinkronisasi...',
      SyncStatus.error => 'Error (tidak disimpan)',
      SyncStatus.errorWaitingRetry => 'Error, menunggu retry...',
    };
  }
}
