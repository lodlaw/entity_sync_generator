// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spaceship_proxy.dart';

// **************************************************************************
// IsSerializerGenerator
// **************************************************************************

abstract class $_SpaceshipSerializer extends Serializer<SpaceshipProxy> {
  int validateId(int value);
  String validateName(String value);
  Map toMap() {
    return {
      'validateId': validateId,
      'validateName': validateName,
    };
  }
}

// **************************************************************************
// UseSerializationGenerator
// **************************************************************************

class $_SpaceshipProxy extends Spaceship with SerializableMixin {
  $_SpaceshipProxy({
    int id,
    String name,
    String location,
  }) : super(
          id: id,
          name: name,
          location: location,
        );
  @override
  Map toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
    };
  }
}
