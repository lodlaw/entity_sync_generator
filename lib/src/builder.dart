import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
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
    final visitor = ModelVisitor();

    final baseElement = annotation.read('baseClass').typeValue.element;
    baseElement.visitChildren(visitor);

    final sourceBuilder = StringBuffer();

    // open class name
    sourceBuilder.writeln(
        " class \$_${element.displayName} extends ${baseElement.displayName} with SerializableMixin { ");

    // open toMap method
    sourceBuilder.writeln("Map toMap() { return {");

    // properties of map
    for (final propertyName in visitor.fields.keys) {
      sourceBuilder.writeln("\"$propertyName\": this.$propertyName,");
    }

    // close toMap method
    sourceBuilder.writeln("};}");

    // close class name
    sourceBuilder.writeln("}");

    return sourceBuilder.toString();
  }
}

class ModelVisitor extends SimpleElementVisitor {
  DartType className;
  Map<String, DartType> fields = Map();

  @override
  visitConstructorElement(ConstructorElement element) {
    className = element.type.returnType;
    return super.visitConstructorElement(element);
  }

  @override
  visitFieldElement(FieldElement element) {
    fields[element.name] = element.type;

    return super.visitFieldElement(element);
  }
}
