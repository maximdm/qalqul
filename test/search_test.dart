import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/core/utils/search.dart';

void main() {
  final results = [
    const SearchResult(
      type: 'note',
      id: '1',
      title: 'Grocery list',
      subtitle: 'milk eggs bread',
      payload: {},
    ),
    const SearchResult(
      type: 'transaction',
      id: '2',
      title: 'Rent',
      subtitle: 'spending · 1200',
      payload: {},
    ),
    const SearchResult(
      type: 'budget',
      id: '3',
      title: 'New laptop',
      subtitle: 'Target 1500',
      payload: {},
    ),
  ];

  test('empty query returns all', () {
    expect(filterResults(results, ''), hasLength(3));
  });

  test('matches title and subtitle case-insensitively', () {
    expect(filterResults(results, 'rent'), hasLength(1));
    expect(filterResults(results, 'MILK'), hasLength(1));
    expect(filterResults(results, '1500'), hasLength(1));
  });

  test('no match returns empty', () {
    expect(filterResults(results, 'zzz'), isEmpty);
  });

  test('SearchResult equality ignores payload', () {
    const a = SearchResult(
      type: 'note',
      id: '1',
      title: 't',
      subtitle: 's',
      payload: {'x': 1},
    );
    const b = SearchResult(
      type: 'note',
      id: '1',
      title: 't',
      subtitle: 's',
      payload: {'y': 2},
    );
    expect(a, equals(b));
  });
}
