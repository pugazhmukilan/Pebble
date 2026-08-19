import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

/// Single expense entry stored in Hive (typeId: 0).
/// Manual TypeAdapter avoids build_runner codegen dependency.
// ignore: must_be_immutable
class Expense extends HiveObject with Equatable {
  Expense({
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    this.note,
  });

  double amount;
  String categoryId;
  DateTime date;
  DateTime createdAt;
  String? note;

  @override
  List<Object?> get props => [amount, categoryId, date, createdAt, note];
}

/// Manual Hive TypeAdapter for [Expense] (typeId: 0).
class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    // Fallback for old enum data
    String catId;
    if (fields[1] is String) {
      catId = fields[1] as String;
    } else {
      catId = 'other';
    }

    return Expense(
      amount: fields[0] as double,
      categoryId: catId,
      date: fields[2] as DateTime,
      createdAt: fields[3] as DateTime,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(5) // field count
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.note);
  }
}
