import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

class TicketCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get price => integer()();
  IntColumn get quota => integer().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get localNumber => text()(); // mis. A-0001
  TextColumn get deviceId => text()();
  IntColumn get total => integer()();
  TextColumn get paymentMethod => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isVoided => boolean().withDefault(const Constant(false))();
  TextColumn get voidReason => text().nullable()();
  DateTimeColumn get voidedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionItems extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text()();
  TextColumn get categoryId => text()();
  IntColumn get qty => integer()();
  IntColumn get subtotal => integer()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class ShiftReconciliations extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get deviceId => text()();
  IntColumn get totalSistemTunai => integer()();
  IntColumn get totalFisikTunai => integer()();
  IntColumn get selisih => integer()(); // totalFisikTunai - totalSistemTunai
  TextColumn get catatan => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [TicketCategories, Transactions, TransactionItems, ShiftReconciliations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add new columns untuk void transaksi
          await m.addColumn(transactions, transactions.isVoided);
          await m.addColumn(transactions, transactions.voidReason);
          await m.addColumn(transactions, transactions.voidedAt);
        }
        if (oldVersion < 3) {
          // Create ShiftReconciliations table
          await m.createTable(shiftReconciliations);
        }
        if (oldVersion < 4) {
          await m.addColumn(ticketCategories, ticketCategories.isSynced);
          await m.addColumn(transactionItems, transactionItems.isSynced);
          await m.addColumn(shiftReconciliations, shiftReconciliations.isSynced);
        }
      },
    );
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'pos_motocross.sqlite'));
      return NativeDatabase(file);
    });
  }
}