import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

// ignore: must_be_immutable
class ExpenseCategory extends HiveObject with Equatable {
  ExpenseCategory({
    required this.id,
    required this.label,
    required this.iconCodePoint,
    required this.colorValue,
    this.emoji,
  });

  final String id;
  final String label;
  final int iconCodePoint;
  final String? emoji;
  final int colorValue;

  @override
  List<Object?> get props => [id, label, iconCodePoint, emoji, colorValue];
}

class ExpenseCategoryAdapter extends TypeAdapter<ExpenseCategory> {
  @override
  final int typeId = 1;

  @override
  ExpenseCategory read(BinaryReader reader) {
    final id = reader.readString();
    final label = reader.readString();
    final iconCodePoint = reader.readInt();
    final colorValue = reader.readInt();
    // Older versions stored only the four fields above — the emoji field is
    // appended last so existing data still reads correctly.
    String? emoji;
    if (reader.availableBytes > 0 && reader.readBool()) {
      emoji = reader.readString();
    }
    return ExpenseCategory(
      id: id,
      label: label,
      iconCodePoint: iconCodePoint,
      emoji: emoji,
      colorValue: colorValue,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseCategory obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.label)
      ..writeInt(obj.iconCodePoint)
      ..writeInt(obj.colorValue)
      ..writeBool(obj.emoji != null)
      ..writeString(obj.emoji ?? '');
  }
}
