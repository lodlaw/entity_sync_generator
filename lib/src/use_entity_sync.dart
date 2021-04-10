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
  late Map<String, DartType> fields;
  late Iterable<DartObject> serializableFields;
  late DartObject keyField;
  late DartObject remoteKeyField;
  late DartObject flagField;

  late StringBuffer sourceBuilder;

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    sourceBuilder = StringBuffer();
    final visitor = ModelVisitor();
    this.element = element;

    baseElement = annotation.read('baseClass').typeValue.element!;
    baseElement.visitChildren(visitor);

    requiredPositionalArguments =
        visitor.parameters!.where((element) => element.isRequiredPositional);
    namedArguments = visitor.parameters!.where((element) => element.isNamed);
    fields = visitor.fields;

    serializableFields = annotation.read('fields').listValue;

    if (!annotation.read('keyField').isNull) {
      keyField = annotation.read('keyField').objectValue;
    }
    if (!annotation.read('remoteKeyField').isNull) {
      remoteKeyField = annotation.read('remoteKeyField').objectValue;
    }
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
    // open class name
    final baseClassName = baseElement.displayName;
    final proxyClassName = '${baseClassName}Proxy';
    sourceBuilder.writeln(
        'class $proxyClassName extends $baseClassName with ProxyMixin<$baseClassName>, SyncableMixin, SerializableMixin{');

    sourceBuilder.write("$proxyClassName(");

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

    namedArguments.forEach((element) {
      sourceBuilder.write("${element.name}: ${element.name},");
    });

    sourceBuilder.writeln(");");

    // override annotation for toMap()
    sourceBuilder.writeln("@override");

    // open toMap method
    sourceBuilder.writeln("Map<String, dynamic> toMap() { return {");

    // properties of map
    namedArguments.forEach((element) {
      sourceBuilder.write("'${element.name}': ${element.name},");
    });

    // close toMap method
    sourceBuilder.writeln("};}");

    // override annotation for copyFromMap()
    sourceBuilder.writeln("@override");

    // open copyFromMap method
    sourceBuilder
        .writeln("$proxyClassName copyFromMap(Map<String, dynamic> data) {");

    sourceBuilder.writeln("return $proxyClassName(");

    namedArguments.forEach((element) {
      sourceBuilder.write("${element.name}: data['${element.name}'],");
    });
    sourceBuilder.writeln(");");
    // close method
    sourceBuilder.writeln("}");

    // generate key fields
    sourceBuilder.write("final keyField = ");
    generateSerializableField(keyField);
    sourceBuilder.writeln(';');

    sourceBuilder.write("final remoteKeyField = ");
    generateSerializableField(remoteKeyField);
    sourceBuilder.writeln(';');

    sourceBuilder.write("final flagField = ");
    generateSerializableField(flagField);
    sourceBuilder.writeln(';');

    // build from entity factory
    sourceBuilder
        .writeln("$proxyClassName.fromEntity($baseClassName instance): super(");

    for (final parameter in requiredPositionalArguments) {
      sourceBuilder.write("instance.${parameter.name},");
    }

    namedArguments.forEach((element) {
      sourceBuilder.write("${element.name}: instance.${element.name},");
    });

    sourceBuilder.writeln(");");

    // close the whole class
    sourceBuilder.writeln('}');
  }

  void generateSerializerClass() {
    final baseClassName = baseElement.displayName;
    final proxyClassName = '${baseClassName}Proxy';
    final serializerClassName = 'Base${baseClassName}Serializer';

    // open class name
    sourceBuilder.writeln(
        "class $serializerClassName extends Serializer<$proxyClassName> {");

    // write construtor
    sourceBuilder.writeln("""
    $serializerClassName({Map<String, dynamic> data, $proxyClassName instance, String prefix = ''}): 
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
        sourceBuilder.writeln("""$returnType $methodName($returnType value) {
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

    // write create instance method
    sourceBuilder.writeln("@override");
    sourceBuilder
        .writeln("$proxyClassName createInstance(Map<String, dynamic> data) {");

    sourceBuilder.writeln("return $proxyClassName(");

    serializableFields.forEach((element) {
      String name = ConstantReader(element).read('name').stringValue;
      final constantReaderSource = ConstantReader(element).read('source');

      final source =
          constantReaderSource.isNull ? name : constantReaderSource.stringValue;

      sourceBuilder.writeln("$source: data['$name'],");
    });
    sourceBuilder.writeln("shouldSync: false,");
    sourceBuilder.writeln(");");

    // close create instance method
    sourceBuilder.writeln("}");

    // close class name
    sourceBuilder.writeln('}');
  }

  void generateFactoryClass() {
    final baseClassName = baseElement.displayName;
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
      "$type('$name' ${prefix.isEmpty ? "" : ",prefix: '$prefix'"}, source: '$source')",
    );
  }
}
