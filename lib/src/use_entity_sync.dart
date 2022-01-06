part of 'builders.dart';

Builder useEntitySyncBuilder(BuilderOptions options) {
  return SharedPartBuilder(
      [UseEntitySyncGenerator()], 'use_entity_sync_builder');
}

class UseEntitySyncGenerator extends GeneratorForAnnotation<UseEntitySync> {
  Iterable<ParameterElement> requiredPositionalArguments = [];
  Iterable<ParameterElement> namedArguments = [];
  late Element baseElement;
  late Element element;
  late Element dataclassElement;
  late Map<String, DartType> fields;
  late Iterable<DartObject> serializableFields;
  late DartObject? keyField;
  late DartObject? remoteKeyField;
  late DartObject? flagField;

  ModelVisitor baseElementVisitor = ModelVisitor();
  ModelVisitor dataclassElementVisitor = ModelVisitor();

  late StringBuffer sourceBuilder;

  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    this.element = element;
    sourceBuilder = StringBuffer();

    // read in and interpret the base class element
    baseElementVisitor = ModelVisitor();
    baseElement = annotation.read('baseClass').typeValue.element!;
    baseElement.visitChildren(baseElementVisitor);

    // read in and interpret the data class element
    dataclassElementVisitor = ModelVisitor();
    dataclassElement = annotation.read('dataClass').typeValue.element!;
    dataclassElement.visitChildren(dataclassElementVisitor);

    // read in a list of serializable fields
    serializableFields = annotation.read('fields').listValue;

    // read in key field if not null
    if (!annotation.read('keyField').isNull) {
      keyField = annotation.read('keyField').objectValue;
    }

    // read in the remote key field if not null
    if (!annotation.read('remoteKeyField').isNull) {
      remoteKeyField = annotation.read('remoteKeyField').objectValue;
    }

    // read in the flag field if not null
    if (!annotation.read('flagField').isNull) {
      flagField = annotation.read('flagField').objectValue;
    }

    // ignoring dart compiler warnings
    sourceBuilder.writeln('// ignore_for_file: non_constant_identifier_names');

    generateProxyClass();
    generateSerializerClass();
    generateFactoryClass();
    generateEntitySyncClass();

    return sourceBuilder.toString();
  }

  void generateProxyClass() {
    final baseClassName = baseElement.displayName;
    final companionClassName = baseClassName + 'Companion';
    final dataclassName = dataclassElement.displayName;

    // get the class name for the proxy
    final proxyClassName = '${dataclassName}Proxy';

    // write out the class itself
    sourceBuilder.writeln(
      'class $proxyClassName extends $companionClassName with ProxyMixin<$dataclassName>, SyncableMixin, SerializableMixin{',
    );

    // write out the default constructor
    sourceBuilder.writeln('$proxyClassName({');
    dataclassElementVisitor.parameters!.forEach((element) {
      sourceBuilder.writeln(
        'Value<${element.type}> ${element.name} = const Value.absent(),',
      );
    });
    sourceBuilder.writeln('}) : super(');
    dataclassElementVisitor.parameters!.forEach((element) {
      sourceBuilder.writeln(
        '${element.name}: ${element.name},',
      );
    });
    sourceBuilder.writeln(');');

    // write out toMap method
    sourceBuilder.writeln('@override');
    sourceBuilder.writeln('Map<String, dynamic> toMap() {');
    sourceBuilder.writeln('return {');
    dataclassElementVisitor.parameters!.forEach((element) {
      sourceBuilder.writeln("'${element.name}': ${element.name}.present ? ${element.name}.value : null,");
    });
    sourceBuilder.writeln('};');
    sourceBuilder.writeln('}');

    // generate copyFromMap method
    sourceBuilder.writeln('@override');
    sourceBuilder
        .writeln('${proxyClassName} copyFromMap(Map<String, dynamic> data) {');
    sourceBuilder.writeln('return ${proxyClassName}(');
    dataclassElementVisitor.parameters!.forEach((element) {
      sourceBuilder.writeln(
        "${element.name}: Value<${element.type}>(data['${element.name}'] as ${element.type}),",
      );
    });
    sourceBuilder.writeln(');}');

    // generate key fields
    sourceBuilder.writeln('@override');
    sourceBuilder.write("final keyField = ");
    generateSerializableField(keyField!);
    sourceBuilder.writeln(';');

    // generate remote key fields
    sourceBuilder.writeln('@override');
    sourceBuilder.write("final remoteKeyField = ");
    generateSerializableField(remoteKeyField!);
    sourceBuilder.writeln(';');

    // generate flag field
    sourceBuilder.writeln('@override');
    sourceBuilder.write("final flagField = ");
    generateSerializableField(flagField!);
    sourceBuilder.writeln(';');

    // generate fromEntity factory
    sourceBuilder.writeln(
        'factory ${proxyClassName}.fromEntity(${dataclassName} instance) {');
    sourceBuilder.writeln('return ${proxyClassName}(');
    dataclassElementVisitor.parameters!.forEach((element) {
      sourceBuilder.writeln(
        '${element.name}: Value<${element.type}>(instance.${element.name}),',
      );
    });
    sourceBuilder.writeln(');');
    sourceBuilder.writeln('}');

    // write out the closing brace for the class
    sourceBuilder.writeln('}');
  }

  void generateSerializerClass() {
    final baseClassName = dataclassElement.displayName;
    final proxyClassName = '${baseClassName}Proxy';
    final serializerClassName = 'Base${baseClassName}Serializer';

    // open class name
    sourceBuilder.writeln(
        "class $serializerClassName extends Serializer<$proxyClassName> {");

    // write construtor
    sourceBuilder.writeln("""
    $serializerClassName({Map<String, dynamic>? data, $proxyClassName? instance, String prefix = ''}): 
                          super(data: data, instance: instance, prefix: prefix);
    """);

    // write fields
    sourceBuilder.writeln("@override");
    sourceBuilder.write("final fields = [");
    serializableFields.forEach((element) {
      generateSerializableField(element);
      sourceBuilder.write(',');
    });
    sourceBuilder.writeln("];");

    final methods = <String>[];
    // write validation methods
    serializableFields.forEach((element) {
      String name = ConstantReader(element).read('name').stringValue;
      name = "${name[0].toUpperCase()}${name.substring(1)}";

      String? returnType;
      switch (element.type!.element!.displayName) {
        case "StringField":
          returnType = "String";
          break;
        case "IntegerField":
          returnType = "int";
          break;
        case "DateTimeField":
          returnType = "DateTime";
          break;
        case "BoolField":
          returnType = "bool";
          break;
        case "DateField":
          returnType = "DateTime";
          break;
        case "DoubleField":
          returnType = "double";
          break;
      }

      final methodName = "validate$name";
      methods.add(methodName);

      if (returnType != null) {
        sourceBuilder.writeln("""$returnType? $methodName($returnType? value) {
            return value;
          }""");
      } else {
        throw new Error();
      }
    });

    // write toMap method
    sourceBuilder.writeln("@override");
    sourceBuilder.write("Map toMap() {");
    sourceBuilder.write("return {");
    methods.forEach((element) {
      sourceBuilder.write("'$element': $element,");
    });
    sourceBuilder.write("};");
    sourceBuilder.write("}");

    // write createInstance method
    sourceBuilder.writeln("@override");
    sourceBuilder
        .writeln("$proxyClassName createInstance(Map<String, dynamic> data) {");
    sourceBuilder.writeln("return $proxyClassName(");
    serializableFields.forEach((element) {
      String name = ConstantReader(element).read('name').stringValue;
      final constantReaderSource = ConstantReader(element).read('source');

      final source =
          constantReaderSource.isNull ? name : constantReaderSource.stringValue;

      final sourceType =
          dataclassElementVisitor.parameters!.firstWhere((element) {
        return element.name.toString() == source;
      }).type;

      sourceBuilder.writeln("$source: Value<$sourceType>(data['$name'] as $sourceType),");
    });
    sourceBuilder.writeln("shouldSync: Value<bool>(false),);}");

    // close class name
    sourceBuilder.writeln('}');
  }

  void generateFactoryClass() {
    final baseClassName = dataclassElement.displayName;
    final proxyClassName = '${baseClassName}Proxy';
    final factoryClassName = '${proxyClassName}Factory';

    sourceBuilder.writeln(
        'class $factoryClassName extends ProxyFactory<$proxyClassName, $baseClassName> {');
    sourceBuilder.writeln('@override');
    sourceBuilder
        .writeln('$proxyClassName fromInstance($baseClassName instance) {');
    sourceBuilder.writeln('return $proxyClassName.fromEntity(instance);');
    sourceBuilder.writeln('}');
    sourceBuilder.writeln('}');
  }

  void generateEntitySyncClass() {
    sourceBuilder.writeln('class \$_${element.displayName} {}');
  }

  void generateSerializableField(DartObject element) {
    final name = ConstantReader(element).read('name').stringValue;

    final constantReaderPrefix = ConstantReader(element).read('prefix');
    String prefix =
        constantReaderPrefix.isNull ? "" : constantReaderPrefix.stringValue;

    final constantReaderSource = ConstantReader(element).read('source');
    String source =
        constantReaderSource.isNull ? name : constantReaderSource.stringValue;

    final type = element.type!.element!.displayName;

    sourceBuilder.write(
      "const $type('$name' ${prefix.isEmpty ? "" : ",prefix: '$prefix'"}, source: '$source')",
    );
  }
}
