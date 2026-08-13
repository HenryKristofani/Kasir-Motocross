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

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionItems extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text()();
  TextColumn get categoryId => text()();
  IntColumn get qty => integer()();
  IntColumn get subtotal => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [TicketCategories, Transactions, TransactionItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'pos_motocross.sqlite'));
      return NativeDatabase(file);
    });
  }
}