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

    // add constructor if it does exist
    if (visitor.parameters.isNotEmpty) {
      final requiredPositionalArguments =
          visitor.parameters.where((element) => element.isRequiredPositional);
      final namedArguments =
          visitor.parameters.where((element) => element.isNamed);

      sourceBuilder.write("\$_${element.displayName}(");

      for (final parameter in requiredPositionalArguments) {
        sourceBuilder.write("$parameter,");
      }

      if (namedArguments.isNotEmpty) {
        sourceBuilder.write("{");

        namedArguments.forEach((element) {
          sourceBuilder.write("${element.type} ${element.name}, ");
        });

        sourceBuilder.write("}");
      }

      sourceBuilder.write(") : super(");

      for (final parameter in requiredPositionalArguments) {
        sourceBuilder.write("${parameter.name},");
      }

      if (namedArguments.isNotEmpty) {
        namedArguments.forEach((element) {
          sourceBuilder.write("${element.name}: ${element.name},");
        });
      }

      sourceBuilder.writeln(");");
    }

    // override annotation for toMap()
    sourceBuilder.writeln("@override");

    // open toMap method
    sourceBuilder.writeln("Map toMap() { return {");

    // properties of map
    for (final propertyName in visitor.fields.keys) {
      sourceBuilder.writeln("'$propertyName': $propertyName,");
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
  List<ParameterElement> parameters = [];

  @override
  visitConstructorElement(ConstructorElement element) {
    className = element.type.returnType;
    parameters = element.parameters;

    return super.visitConstructorElement(element);
  }

  @override
  visitFieldElement(FieldElement element) {
    fields[element.name] = element.type;

    return super.visitFieldElement(element);
  }
}
