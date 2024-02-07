import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meta/meta.dart' show immutable;
import 'package:yaml/yaml.dart' show YamlList;

import '../../utils/constants.dart';
import '../../utils/typedef.dart';

@immutable
class BooleanPrefixOptions {
  const BooleanPrefixOptions({
    List<String>? validPrefixes,
  }) : _validPrefixes = validPrefixes;

  static const defaultValidPrefixes = [
    'is',
    'are',
    'was',
    'were',
    'has',
    'have',
    'had',
    'can',
    'should',
    'will',
    'do',
    'does',
    'did',
  ];

  final List<String>? _validPrefixes;

  List<String> get validPrefixes => [
        ...defaultValidPrefixes,
        ...?_validPrefixes,
      ];

  factory BooleanPrefixOptions.fromJson(Json json) {
    final validPrefixes = switch (json['valid_prefixes']) {
      final YamlList validPrefixes => validPrefixes.cast<String>(),
      _ => null,
    };

    return BooleanPrefixOptions(
      validPrefixes: validPrefixes,
    );
  }
}

class BooleanPrefix extends DartLintRule {
  const BooleanPrefix._(this.options)
      : super(
          code: const LintCode(
            name: name,
            problemMessage: '{0} should be named with a valid prefix.',
            correctionMessage: 'Try naming your {1} with a valid prefix.',
            url: '$dartLintDocUrl/${BooleanPrefix.name}',
            errorSeverity: ErrorSeverity.INFO,
          ),
        );

  static const name = 'boolean_prefix';

  final BooleanPrefixOptions options;

  factory BooleanPrefix.fromConfigs(CustomLintConfigs configs) {
    final json = configs.rules[BooleanPrefix.name]?.json ?? {};
    final options = BooleanPrefixOptions.fromJson(json);

    return BooleanPrefix._(options);
  }

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBooleanLiteral((node) {
      final parent = node.parent;
      if (parent is! VariableDeclaration) return;

      final name = parent.name.lexeme;
      if (isNameValid(name)) return;

      reporter.reportErrorForToken(
        code,
        parent.name,
        [
          'Boolean variable',
          'variable',
        ],
      );
    });

    context.registry.addMethodDeclaration((node) {
      final returnType = node.returnType?.type;
      if (returnType == null || !returnType.isDartCoreBool) return;

      final element = node.declaredElement;
      if (element == null || element.hasOverride) return;

      final name = node.name.lexeme;
      if (isNameValid(name)) return;

      final parameter = node.parameters;
      switch (parameter) {
        case null:
          reporter.reportErrorForToken(
            code,
            node.name,
            [
              'Getter that returns a boolean',
              'getter',
            ],
          );
        case _:
          reporter.reportErrorForToken(
            code,
            node.name,
            [
              'Method that returns a boolean',
              'method',
            ],
          );
      }
    });

    context.registry.addFunctionDeclaration((node) {
      final returnType = node.returnType?.type;
      if (returnType == null || !returnType.isDartCoreBool) return;

      final name = node.name.lexeme;
      if (isNameValid(name)) return;

      reporter.reportErrorForToken(
        code,
        node.name,
        [
          'Function that returns a boolean',
          'function',
        ],
      );
    });
  }

  bool isNameValid(String name) {
    final nameWithoutUnderscore =
        name.startsWith('_') ? name.substring(1) : name;

    if (options.validPrefixes.any(nameWithoutUnderscore.startsWith)) {
      return true;
    }

    return false;
  }
}