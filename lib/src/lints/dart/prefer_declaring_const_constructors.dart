import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/ast_node_extensions.dart';
import '../../utils/constants.dart';

class PreferDeclaringConstConstructors extends DartLintRule {
  const PreferDeclaringConstConstructors()
      : super(
          code: const LintCode(
            name: name,
            problemMessage:
                'Constructors of classes with only final fields should be declared as '
                'const constructors when possible.',
            correctionMessage:
                'Consider adding a const keyword to the constructor.',
            url: '$dartLintDocUrl/${PreferDeclaringConstConstructors.name}',
            errorSeverity: ErrorSeverity.INFO,
          ),
        );

  static const name = 'prefer_declaring_const_constructors';

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addConstructorDeclaration((node) {
      if (node.constKeyword != null || node.factoryKeyword != null) return;

      final parent = node.parent;
      if (parent is! ClassDeclaration) return;

      final fieldDeclarations = parent.members.fieldDeclarations;
      if (fieldDeclarations.isEmpty) return;

      final hasNonFinalField = fieldDeclarations.any((e) => !e.fields.isFinal);
      if (hasNonFinalField) return;

      final fieldInitializers = node.initializers.constructorFieldInitializers;
      if (fieldInitializers.isNotEmpty) {
        final allExpressionResolveToConstant = fieldInitializers.every(
          (e) {
            // TODO: find a better way to check if the expression resolves to a constant value.
            if (e.expression is BooleanLiteral ||
                e.expression is DoubleLiteral ||
                e.expression is IntegerLiteral ||
                e.expression is StringLiteral) {
              return true;
            } else {
              return e.expression.inConstantContext;
            }
          },
        );

        if (!allExpressionResolveToConstant) return;
      }

      reporter.reportErrorForNode(code, node);
    });
  }

  @override
  List<Fix> getFixes() => [_AddConst()];
}

class _AddConst extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addConstructorDeclaration((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add const keyword',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
          node.offset,
          'const ',
        );
      });
    });
  }
}
