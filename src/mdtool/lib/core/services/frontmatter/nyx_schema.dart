import 'package:json_schema/json_schema.dart';

const Map<String, Object> _schema = {
  'type': 'object',
  'additionalProperties': true,
  'properties': {
    'project': <String, Object>{'type': 'string'},
    'persona': <String, Object>{'type': 'string'},
    'tone': <String, Object>{'type': 'string'},
    'provider': <String, Object>{'enum': ['claude', 'openai', 'ollama']},
    'memento': <String, Object>{'enum': ['on', 'off', 'bulk']},
    'axiom_lint': <String, Object>{'enum': ['on', 'off', 'panel-only']},
    'private': <String, Object>{'type': 'boolean'},
    'sources': <String, Object>{'type': 'object'},
  },
};

class NyxValidationResult {
  final bool isValid;
  final List<String> errors;
  const NyxValidationResult(this.isValid, this.errors);
}

NyxValidationResult validateNyxBlock(Map<dynamic, dynamic> block) {
  final schema = JsonSchema.create(_schema);
  final results = schema.validate(block);
  return NyxValidationResult(
    results.isValid,
    results.errors.map((e) => e.toString()).toList(),
  );
}
