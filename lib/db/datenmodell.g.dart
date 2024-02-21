// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datenmodell.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeinDatenmodellAdapter extends TypeAdapter<MeinDatenmodell> {
  @override
  final int typeId = 0;

  @override
  MeinDatenmodell read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeinDatenmodell(
      wort: fields[0] as String,
      satz: fields[1] as String,
      satzlaenge: fields[2] as int,
      buchstabenlaenge: fields[3] as int,
      kategorie: fields[4] as String,
      bildUrl: fields[5] as String?,
      fileTyp: fields[6] as String,
      bildBytes: fields[7] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, MeinDatenmodell obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.wort)
      ..writeByte(1)
      ..write(obj.satz)
      ..writeByte(2)
      ..write(obj.satzlaenge)
      ..writeByte(3)
      ..write(obj.buchstabenlaenge)
      ..writeByte(4)
      ..write(obj.kategorie)
      ..writeByte(5)
      ..write(obj.bildUrl)
      ..writeByte(6)
      ..write(obj.fileTyp)
      ..writeByte(7)
      ..write(obj.bildBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeinDatenmodellAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoriesAdapter extends TypeAdapter<Categories> {
  @override
  final int typeId = 1;

  @override
  Categories read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Categories(
      categories: (fields[0] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Categories obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.categories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoriesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
