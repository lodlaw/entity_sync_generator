import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:entity_sync/entity_sync.dart';
import 'package:source_gen/source_gen.dart';

Builder useSerializationBuilder(BuilderOptions options) {
  return SharedPartBuilder(
      [UseSerializationGenerator()], 'use_serialization_builder');
}

class UseSerializationGenerator
    extends GeneratorForAnnotation<UseSerialization> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    return '// haha this has worked perfectly123';
  }
}
