import 'package:flutter_test/flutter_test.dart';
import 'package:mdtool/core/services/frontmatter/nyx_schema.dart';

void main() {
  test('accepts a valid block', () {
    final r = validateNyxBlock({
      'project': 'p', 'persona': 'P', 'provider': 'claude', 'memento': 'on',
    });
    expect(r.isValid, true);
    expect(r.errors, isEmpty);
  });

  test('rejects unknown provider', () {
    final r = validateNyxBlock({'provider': 'bogus'});
    expect(r.isValid, false);
    expect(r.errors.first, contains('provider'));
  });

  test('rejects wrong type for private', () {
    final r = validateNyxBlock({'private': 'yes'});
    expect(r.isValid, false);
  });
}
