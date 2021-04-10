import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:entity_sync/entity_sync.dart';
import 'package:source_gen/source_gen.dart';

part 'use_entity_sync.dart';

class ModelVisitor extends SimpleElementVisitor {
  late DartType className;
  Map<String, DartType> fields = Map();
  List<ParameterElement>? parameters;

  @override
  visitConstructorElement(ConstructorElement element) {
    className = element.type.returnType;

    if (parameters == null) {
      parameters = element.parameters;
    }

    return super.visitConstructorElement(element);
  }

  @override
  visitFieldElement(FieldElement element) {
    fields[element.name] = element.type;

    return super.visitFieldElement(element);
  }
}
