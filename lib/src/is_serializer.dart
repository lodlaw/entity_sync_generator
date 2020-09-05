part of 'builders.dart';

Builder isSerializerBuilder(BuilderOptions options) =>
    SharedPartBuilder([IsSerializerGenerator()], 'is_serializer_builder');

class IsSerializerGenerator extends GeneratorForAnnotation<IsSerializer> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final proxyClass =
        annotation.read('proxyClass').typeValue.element.displayName;

    final sourceBuilder = StringBuffer();

    // open class name
    sourceBuilder.writeln(
        "abstract class \$_${element.displayName} extends Serializer<$proxyClass> {");

    final methods = <String>[];
    // write validation methods
    annotation.read('fields').listValue.forEach((element) {
      String name = ConstantReader(element).read('name').stringValue;
      name = "${name[0].toUpperCase()}${name.substring(1)}";

      String returnType;
      switch (element.type.element.displayName) {
        case "StringField":
          returnType = "String";
          break;
        case "IntegerField":
          returnType = "int";
          break;
        case "DateTimeField":
          returnType = "DateTime";
          break;
        case "BooleanField":
          returnType = "bool";
          break;
      }

      final methodName = "validate$name";
      methods.add(methodName);

      sourceBuilder.writeln('$returnType $methodName($returnType value);');
    });

    // write toMap method
    sourceBuilder.write("Map toMap() {");
    sourceBuilder.write("return {");
    methods.forEach((element) {
      sourceBuilder.write("'$element': $element,");
    });
    sourceBuilder.write("};");
    sourceBuilder.write("}");

    // close class name
    sourceBuilder.writeln("}");

    return sourceBuilder.toString();
  }
}
