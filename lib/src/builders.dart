import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:entity_sync/entity_sync.dart';
import 'package:source_gen/source_gen.dart';

part 'is_serializer.dart';
part 'use_serialization.dart';

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
