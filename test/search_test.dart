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

  group('searchText', () {
    /// Stands in for a note result: the display subtitle is the truncated
    /// 80-character preview, while `searchText` keeps the whole body.
    SearchResult note() {
      final body = '${'filler ' * 20}needle';
      return SearchResult(
        type: 'note',
        id: '1',
        title: 'Groceries',
        subtitle: body.substring(0, 80),
        searchText: body,
        payload: const {},
      );
    }

    test('matches text beyond the truncated subtitle', () {
      expect(filterResults([note()], 'needle'), hasLength(1));
    });

    test('still matches title and subtitle', () {
      expect(filterResults([note()], 'groceries'), hasLength(1));
    });

    test('is part of equality', () {
      const a = SearchResult(
        type: 'note',
        id: '1',
        title: 't',
        subtitle: 's',
        searchText: 'x',
        payload: {},
      );
      const b = SearchResult(
        type: 'note',
        id: '1',
        title: 't',
        subtitle: 's',
        searchText: 'y',
        payload: {},
      );
      expect(a, isNot(equals(b)));
    });

    test('defaults to empty so existing callers are unaffected', () {
      const r = SearchResult(
        type: 'note',
        id: '1',
        title: 't',
        subtitle: 's',
        payload: {},
      );
      expect(r.searchText, isEmpty);
    });
  });
}
