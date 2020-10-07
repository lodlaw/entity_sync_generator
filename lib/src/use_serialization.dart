part of 'builders.dart';

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

    final requiredPositionalArguments =
        visitor.parameters.where((element) => element.isRequiredPositional);
    final namedArguments =
        visitor.parameters.where((element) => element.isNamed);

    // add constructor if it does exist
    if (visitor.parameters.isNotEmpty) {
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
    sourceBuilder.writeln("Map<String, dynamic> toMap() { return {");

    // properties of map
    for (final propertyName in visitor.fields.keys) {
      sourceBuilder.writeln("'$propertyName': $propertyName,");
    }

    // close toMap method
    sourceBuilder.writeln("};}");

    // override annotation for copyFromMap()
    sourceBuilder.writeln("@override");

    // open copyFromMap method
    sourceBuilder.writeln(
        "\$_${element.displayName} copyFromMap(Map<String, dynamic> data) {");

    sourceBuilder.writeln("return \$_${element.displayName}(");

    namedArguments.forEach((element) {
      sourceBuilder.write("${element.name}: data['${element.name}'],");
    });

    sourceBuilder.writeln(");");

    // close method
    sourceBuilder.writeln("}");

    // close class name
    sourceBuilder.writeln("}");

    return sourceBuilder.toString();
  }
}
