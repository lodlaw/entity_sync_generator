import 'package:entity_sync/entity_sync.dart';

import 'spaceship.dart';

part 'spaceship_proxy.g.dart';

@UseSerialization(Spaceship)
class SpaceshipProxy extends $_SpaceshipProxy {}

@IsSerializer(SpaceshipProxy, fields: [
  IntegerField('id'),
  StringField('name'),
])
class SpaceshipSerializer extends $_SpaceshipSerializer {}
