import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

/// A category-limit change effective from a calendar month onward.
// ignore: must_be_immutable
class CategoryLimitChange extends HiveObject with Equatable {
  CategoryLimitChange({
    required this.categoryId,
    required this.effectiveYear,
    required this.effectiveMonth,
    required this.limit,
  });

  final String categoryId;
  final int effectiveYear;
  final int effectiveMonth;
  final double? limit;

  @override
  List<Object?> get props => [categoryId, effectiveYear, effectiveMonth, limit];
}

class CategoryLimitChangeAdapter extends TypeAdapter<CategoryLimitChange> {
  @override
  final int typeId = 2;

  @override
  CategoryLimitChange read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }

    final rawLimit = fields[3];
    return CategoryLimitChange(
      categoryId: fields[0] as String,
      effectiveYear: fields[1] as int,
      effectiveMonth: fields[2] as int,
      limit: rawLimit is num ? rawLimit.toDouble() : null,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryLimitChange change) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(change.categoryId)
      ..writeByte(1)
      ..write(change.effectiveYear)
      ..writeByte(2)
      ..write(change.effectiveMonth)
      ..writeByte(3)
      ..write(change.limit);
  }
}
