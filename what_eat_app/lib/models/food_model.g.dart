// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodModelAdapter extends TypeAdapter<FoodModel> {
  @override
  final int typeId = 0;

  @override
  FoodModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodModel(
      id: fields[0] as String,
      name: fields[1] as String,
      searchKeywords: (fields[2] as List).cast<String>(),
      description: fields[3] as String,
      images: (fields[4] as List).cast<String>(),
      cuisineId: fields[5] as String,
      mealTypeId: fields[6] as String,
      flavorProfile: (fields[7] as List).cast<String>(),
      allergenTags: (fields[8] as List).cast<String>(),
      priceSegment: fields[9] as int,
      avgCalories: fields[10] as int?,
      availableTimes: (fields[11] as List).cast<String>(),
      contextScoresJson: fields[12] as String,
      mapQuery: fields[13] as String,
      isActive: fields[14] as bool,
      createdAtMillis: fields[15] as int,
      updatedAtMillis: fields[16] as int,
      viewCount: fields[17] as int,
      pickCount: fields[18] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FoodModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.searchKeywords)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.images)
      ..writeByte(5)
      ..write(obj.cuisineId)
      ..writeByte(6)
      ..write(obj.mealTypeId)
      ..writeByte(7)
      ..write(obj.flavorProfile)
      ..writeByte(8)
      ..write(obj.allergenTags)
      ..writeByte(9)
      ..write(obj.priceSegment)
      ..writeByte(10)
      ..write(obj.avgCalories)
      ..writeByte(11)
      ..write(obj.availableTimes)
      ..writeByte(12)
      ..write(obj.contextScoresJson)
      ..writeByte(13)
      ..write(obj.mapQuery)
      ..writeByte(14)
      ..write(obj.isActive)
      ..writeByte(15)
      ..write(obj.createdAtMillis)
      ..writeByte(16)
      ..write(obj.updatedAtMillis)
      ..writeByte(17)
      ..write(obj.viewCount)
      ..writeByte(18)
      ..write(obj.pickCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
