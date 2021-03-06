import 'package:fuzzy/fuzzy.dart';
import 'package:test/test.dart';

import 'fixtures/books.dart';
import 'fixtures/games.dart';

final defaultList = ['Apple', 'Orange', 'Banana'];
final defaultOptions = FuzzyOptions<String>(
  location: 0,
  distance: 100,
  threshold: 0.6,
  maxPatternLength: 32,
  isCaseSensitive: false,
  tokenSeparator: RegExp(r' +'),
  minTokenCharLength: 1,
  findAllMatches: false,
  minMatchCharLength: 1,
  shouldSort: true,
  sortFn: (a, b) => a.score.compareTo(b.score),
  tokenize: false,
  matchAllTokens: false,
  verbose: false,
);

Fuzzy<String> setup({
  List<String>? itemList,
  FuzzyOptions<String>? options,
}) {
  return Fuzzy<String>(
    itemList ?? defaultList,
    options: options ?? defaultOptions,
  );
}

Fuzzy<T> setupGeneric<T>({
  required List<T> itemList,
  required FuzzyOptions<T> options,
}) {
  return Fuzzy<T>(
    itemList,
    options: options,
  );
}

void main() {
  group('Empty list of strings', () {
    late Fuzzy fuse;
    setUp(() {
      fuse = setup(itemList: <String>[]);
    });
    test('empty result is returned', () {
      final result = fuse.search('Bla');
      expect(result.isEmpty, true);
    });
  });

  group('Null list', () {
    late Fuzzy fuse;
    List<String>? items;
    setUp(() {
      fuse = Fuzzy(items, options: defaultOptions);
    });
    test('empty result is returned', () {
      final result = fuse.search('Bla');
      expect(result.isEmpty, true);
    });
  });

  group('Flat list of strings: ["Apple", "Orange", "Banana"]', () {
    late Fuzzy fuse;
    setUp(() {
      fuse = setup();
    });

    test('When searching for the term "Apple"', () {
      final result = fuse.search('Apple');

      expect(result.length, 1, reason: 'we get a list of exactly 1 item');
      expect(result[0].item, equals('Apple'),
          reason: 'whose value is the index 0, representing ["Apple"]');
    });
  });

  group('Flat list of strings: ["Apple", "Orange", "Banana"]', () {
    late Fuzzy fuse;
    setUp(() {
      fuse = setup();
    });

    test('When performing a fuzzy search for the term "ran"', () {
      final result = fuse.search('ran');

      expect(result.length, 2, reason: 'we get a list of containing 2 items');
      expect(result[0].item, equals('Orange'),
          reason: 'whose values represent the indices of ["Orange", "Banana"]');
      expect(result[1].item, equals('Banana'),
          reason: 'whose values represent the indices of ["Orange", "Banana"]');
    });

    test(
        'When performing a fuzzy search for the term "nan" with a limit of 1 result',
        () {
      final result = fuse.search('nan', 1);

      expect(result.length, 1,
          reason: 'we get a list of containing 1 item: [2]');
      expect(result[0].item, equals('Banana'),
          reason: 'whose value is the index 2, representing ["Banana"]');
    });
  });

  group('Include score in result list: ["Apple", "Orange", "Banana"]', () {
    late Fuzzy fuse;
    setUp(() {
      fuse = setup();
    });

    test('When searching for the term "Apple"', () {
      final result = fuse.search('Apple');

      expect(result.length, equals(1),
          reason: 'we get a list of exactly 1 item');
      expect(result[0].item, equals('Apple'),
          reason: 'whose value is the index 0, representing ["Apple"]');
      expect(result[0].score, equals(0),
          reason: 'and the score is a perfect match');
    });

    test('When performing a fuzzy search for the term "ran"', () {
      final result = fuse.search('ran');

      expect(result.length, 2, reason: 'we get a list of containing 2 items');

      expect(result[0].item, equals('Orange'));
      expect(result[0].score, isNot(0), reason: 'score is not zero');

      expect(result[1].item, equals('Banana'));
      expect(result[1].score, isNot(0), reason: 'score is not zero');
    });
  });

  group('Include arrayIndex in result list', () {
    final fuse = setup();

    test('When performing a fuzzy search for the term "ran"', () {
      final result = fuse.search('ran');

      expect(result.length, 2, reason: 'we get a list of containing 2 items');

      expect(result[0].item, equals('Orange'));
      expect(result[0].matches.single.arrayIndex, 1);

      expect(result[1].item, equals('Banana'));
      expect(result[1].matches.single.arrayIndex, 2);
    });
  });

  group('Weighted search on typed list', () {
    test('When searching for the term "John Smith" with author weighted higher',
        () {
      final fuse = Fuzzy<Book>(
        customBookList,
        options: FuzzyOptions(keys: [
          WeightedKey(getter: (i) => i.title, weight: 0.3, name: 'title'),
          WeightedKey(getter: (i) => i.author, weight: 0.7, name: 'author'),
        ]),
      );
      final result = fuse.search('John Smith');

      expect(result[0].item, customBookList[2],
          reason: 'We get the the exactly matching object');
    });

    test('When searching for the term "John Smith" with title weighted higher',
        () {
      final fuse = Fuzzy<Book>(
        customBookList,
        options: FuzzyOptions(keys: [
          WeightedKey(getter: (i) => i.title, weight: 0.7, name: 'title'),
          WeightedKey(getter: (i) => i.author, weight: 0.3, name: 'author'),
        ]),
      );
      final result = fuse.search('John Smith');

      expect(result[0].item, customBookList[3],
          reason: 'We get the the exactly matching object');
    });

    test(
        'When searching for the term "Man", where the author is weighted higher than title',
        () {
      final fuse = Fuzzy<Book>(
        customBookList,
        options: FuzzyOptions(keys: [
          WeightedKey(getter: (i) => i.title, weight: 0.3, name: 'title'),
          WeightedKey(getter: (i) => i.author, weight: 0.7, name: 'author'),
        ]),
      );
      final result = fuse.search('Man');

      expect(result[0].item, customBookList[1],
          reason: 'We get the the exactly matching object');
    });

    test(
        'When searching for the term "Man", where the title is weighted higher than author',
        () {
      final fuse = Fuzzy<Book>(
        customBookList,
        options: FuzzyOptions(keys: [
          WeightedKey(getter: (i) => i.title, weight: 0.7, name: 'title'),
          WeightedKey(getter: (i) => i.author, weight: 0.3, name: 'author'),
        ]),
      );
      final result = fuse.search('Man');

      expect(result[0].item, customBookList[0],
          reason: 'We get the the exactly matching object');
    });

    test(
        'When searching for the term "War", where tags are weighted higher than all other keys',
        () {
      final fuse = Fuzzy<Book>(
        customBookList,
        options: FuzzyOptions(keys: [
          WeightedKey(getter: (i) => i.title, weight: 0.8, name: 'title'),
          WeightedKey(getter: (i) => i.author, weight: 0.3, name: 'author'),
          WeightedKey(
              getter: (i) => i.tags.join(' '), weight: 0.9, name: 'tags'),
        ]),
      );
      final result = fuse.search('War');

      expect(result[0].item, customBookList[0],
          reason: 'We get the the exactly matching object');
    });
  });

  group('Weighted search considers all keys in score', () {
    Fuzzy<Game> getFuzzy({
      required double tournamentWeight,
      required double stageWeight,
    }) {
      return Fuzzy<Game>(
        customGameList,
        options: FuzzyOptions(
          keys: [
            WeightedKey(
                getter: (i) => i.tournament,
                weight: tournamentWeight,
                name: 'tournament'),
            WeightedKey(
                getter: (i) => i.stage, weight: stageWeight, name: 'stage'),
          ],
          tokenize: true,
        ),
      );
    }

    test('When searching for "WorldCup Final", where weights are equal', () {
      final fuse = getFuzzy(
        tournamentWeight: 0.5,
        stageWeight: 0.5,
      );
      final result = fuse.search('WorldCup Final');

      void expectLess(String a, String b) {
        double scoreOf(String s) =>
            result.singleWhere((e) => e.item.toString() == s).score;
        expect(scoreOf(a), lessThanOrEqualTo(scoreOf(b)));
      }

      expectLess('WorldCup Final', 'WorldCup Semi-finals');
      expectLess('WorldCup Semi-finals', 'WorldCup Groups');
      expectLess('WorldCup Groups', 'ChampionsLeague Final');
      expectLess('ChampionsLeague Final', 'ChampionsLeague Semi-finals');
    });

    test(
        'When searching for "WorldCup Final", where the tournament is weighted higher',
        () {
      final fuse = getFuzzy(
        tournamentWeight: 0.8,
        stageWeight: 0.2,
      );
      final result = fuse.search('WorldCup Final');

      void expectLess(String a, String b) {
        double scoreOf(String s) =>
            result.singleWhere((e) => e.item.toString() == s).score;
        expect(scoreOf(a), lessThanOrEqualTo(scoreOf(b)));
      }

      expectLess('WorldCup Final', 'WorldCup Semi-finals');
      expectLess('WorldCup Semi-finals', 'WorldCup Groups');
      expectLess('WorldCup Groups', 'ChampionsLeague Final');
      expectLess('ChampionsLeague Final', 'ChampionsLeague Semi-finals');
    });

    test(
        'When searching for "WorldCup Final", where the stage is weighted higher',
        () {
      final fuse = getFuzzy(
        tournamentWeight: 0.2,
        stageWeight: 0.8,
      );
      final result = fuse.search('WorldCup Final');

      void expectLess(String a, String b) {
        double scoreOf(String s) =>
            result.singleWhere((e) => e.item.toString() == s).score;
        expect(scoreOf(a), lessThanOrEqualTo(scoreOf(b)));
      }

      expectLess('WorldCup Final', 'WorldCup Semi-finals');
      expectLess('WorldCup Semi-finals', 'WorldCup Groups');
      expectLess('ChampionsLeague Final', 'WorldCup Groups');
      expectLess('ChampionsLeague Final', 'ChampionsLeague Semi-finals');
    });
  });

  group('Weighted search with a single key equals non-weighted search', () {
    String gameDescription(Game g) => '${g.tournament} ${g.stage}';

    test('When searching for "WorldCup semi-final"', () {
      final fuseNoKeys = Fuzzy(
        customGameList.map((g) => gameDescription(g)).toList(),
        options: FuzzyOptions(),
      );
      Fuzzy fuseSingleKey = Fuzzy<Game>(
        customGameList,
        options: FuzzyOptions(
          keys: [
            WeightedKey(
                name: 'desc', getter: (g) => gameDescription(g), weight: 1),
          ],
        ),
      );
      final resultNoKeys = fuseNoKeys.search('WorldCup semi-final');
      final resultSingleKey = fuseSingleKey.search('WorldCup semi-final');

      // Check for equality using 'toString()', otherwise it checks for
      // identity equality (i.e. same objects instead of same contents)
      expect(resultNoKeys.toString(), equals(resultSingleKey.toString()));

      expect(resultNoKeys[0].item, 'WorldCup Semi-finals');
      expect(resultNoKeys[0].score, lessThan(resultNoKeys[1].score));
    });
  });

  group('FuzzyOptions normalizes the keys weights', () {
    test("WeightedKey doesn't allow creating a non-positive weight", () {
      expect(
          () => WeightedKey<String>(name: 'name', getter: (i) => i, weight: -1),
          throwsA(isA<AssertionError>()));
      expect(
          () => WeightedKey<String>(name: 'name', getter: (i) => i, weight: 0),
          throwsA(isA<AssertionError>()));
      expect(
          () => WeightedKey<String>(name: 'name', getter: (i) => i, weight: 1),
          returnsNormally);
    });

    test('Normalizes weights', () {
      var options = FuzzyOptions(keys: [
        WeightedKey<String>(name: 'name1', getter: (i) => i, weight: 0.5),
        WeightedKey<String>(name: 'name2', getter: (i) => i, weight: 0.5),
        WeightedKey<String>(name: 'name3', getter: (i) => i, weight: 3),
      ]);

      expect(options.keys[0].weight, 0.125);
      expect(options.keys[1].weight, 0.125);
      expect(options.keys[2].weight, 0.75);
    });
  });

  group(
      'Search with match all tokens in a list of strings with leading and trailing whitespace',
      () {
    late Fuzzy fuse;
    setUp(() {
      final customList = [' Apple', 'Orange ', ' Banana '];
      fuse = setup(
        itemList: customList,
        options: defaultOptions.copyWith(tokenize: true),
      );
    });

    test('When searching for the term "Banana"', () {
      final result = fuse.search('Banana');

      expect(result.length, 1, reason: 'we get a list of exactly 1 item');
      expect(result[0].item, equals(' Banana '),
          reason:
              'whose value is the same, disconsidering leading and trailing whitespace');
    });
  });

  group(
      'Search with tokenize where the search pattern starts or ends with the tokenSeparator',
      () {
    group('With the default tokenSeparator, which is white space', () {
      final fuse = setup(options: FuzzyOptions(tokenize: true));

      test('When the search pattern starts with white space', () {
        final result = fuse.search(' Apple');

        expect(result.length, 1, reason: 'we get a list of exactly 1 item');
        expect(result[0].item, equals('Apple'));
      });

      test('When the search pattern ends with white space', () {
        final result = fuse.search('Apple ');

        expect(result.length, 1, reason: 'we get a list of exactly 1 item');
        expect(result[0].item, equals('Apple'));
      });

      test('When the search pattern contains white space in the middle', () {
        final result = fuse.search('Apple Orange');

        expect(result.length, 2, reason: 'we get a list of exactly 2 itens');
        expect(result[0].item, equals('Orange'));
        expect(result[1].item, equals('Apple'));
      });
    });

    group('With a custom tokenSeparator', () {
      final fuse = setup(
          options: FuzzyOptions(tokenize: true, tokenSeparator: RegExp(';')));

      test('When the search pattern ends with a tokenSeparator match', () {
        final result = fuse.search('Apple;Orange;');

        expect(result.length, 2, reason: 'we get a list of exactly 2 itens');
        expect(result[0].item, equals('Orange'));
        expect(result[1].item, equals('Apple'));
      });
    });
  });

  group('Search with match all tokens', () {
    late Fuzzy fuse;
    setUp(() {
      final customList = [
        'AustralianSuper - Corporate Division',
        'Aon Master Trust - Corporate Super',
        'Promina Corporate Superannuation Fund',
        'Workforce Superannuation Corporate',
        'IGT (Australia) Pty Ltd Superannuation Fund',
      ];
      fuse = setup(
        itemList: customList,
        options: defaultOptions.copyWith(tokenize: true),
      );
    });

    test('When searching for the term "Australia"', () {
      final result = fuse.search('Australia');

      expect(result.length, equals(2),
          reason: 'We get a list containing exactly 2 items');
      expect(result[0].item, equals('AustralianSuper - Corporate Division'));
      expect(result[1].item,
          equals('IGT (Australia) Pty Ltd Superannuation Fund'));
    });

    test('When searching for the term "corporate"', () {
      final result = fuse.search('corporate');

      expect(result.length, equals(4),
          reason: 'We get a list containing exactly 2 items');

      expect(result[0].item, equals('Promina Corporate Superannuation Fund'));
      expect(result[1].item, equals('AustralianSuper - Corporate Division'));
      expect(result[2].item, equals('Aon Master Trust - Corporate Super'));
      expect(result[3].item, equals('Workforce Superannuation Corporate'));
    });
  });

  group('Search with tokenize includes token average on result score', () {
    final customList = ['Apple and Orange Juice'];
    final fuse = setup(
      itemList: customList,
      options: FuzzyOptions(
        threshold: 0.1,
        tokenize: true,
        location: 0,
        distance: 100,
        maxPatternLength: 32,
        isCaseSensitive: false,
        tokenSeparator: RegExp(r' +'),
        minTokenCharLength: 1,
        findAllMatches: false,
        minMatchCharLength: 1,
        shouldSort: true,
        sortFn: (a, b) => a.score.compareTo(b.score),
        matchAllTokens: false,
        verbose: false,
      ),
    );

    test('When searching for the term "Apple Juice"', () {
      final result = fuse.search('Apple Juice');

      // By using a lower threshold, we guarantee that the full text score
      // ("apple juice" on "Apple and Orange Juice") returns a score of 1.0,
      // while the token searches return 0.0 (perfect matches) for "Apple" and
      // "Juice". Thus, the token score average is 0.0, and the result score
      // should be (1.0 + 0.0) / 2 = 0.5
      expect(result.length, 1);
      expect(result[0].score, 0.5);
    });
  });

  group('Searching with default options', () {
    late Fuzzy fuse;
    setUp(() {
      final customList = ['t te tes test tes te t'];
      fuse = setup(itemList: customList);
    });

    test('When searching for the term "test"', () {
      final result = fuse.search('test');

      expect(result[0].matches[0].matchedIndices.length, equals(4),
          reason: 'We get a match containing 4 indices');

      expect(result[0].matches[0].matchedIndices[0].start, equals(0),
          reason: 'and the first index is a single character');
      expect(result[0].matches[0].matchedIndices[0].end, equals(0),
          reason: 'and the first index is a single character');
    });
  });

  group('Searching with findAllMatches', () {
    late Fuzzy fuse;
    setUp(() {
      final customList = ['t te tes test tes te t'];
      fuse = setup(
        itemList: customList,
        options: defaultOptions.copyWith(
          findAllMatches: true,
        ),
      );
    });

    test('When searching for the term "test"', () {
      final result = fuse.search('test');

      expect(result[0].matches[0].matchedIndices.length, equals(7),
          reason: 'We get a match containing 7 indices');

      expect(result[0].matches[0].matchedIndices[0].start, equals(0),
          reason: 'and the first index is a single character');
      expect(result[0].matches[0].matchedIndices[0].end, equals(0),
          reason: 'and the first index is a single character');
    });
  });

  group('Searching with minTokenCharLength', () {
    Fuzzy<Book> setUp({required int minTokenCharLength}) => setupGeneric<Book>(
          itemList: customBookList,
          options: FuzzyOptions(
            threshold: 0.3,
            tokenize: true,
            minTokenCharLength: minTokenCharLength,
            keys: [
              WeightedKey(getter: (i) => i.title, weight: 0.5, name: 'title'),
              WeightedKey(getter: (i) => i.author, weight: 0.5, name: 'author'),
            ],
          ),
        );

    test('When searching for "Plants x Zombies" with min = 1', () {
      final fuse = setUp(minTokenCharLength: 1);
      final result = fuse.search('Plants x Zombies');

      expect(result.length, 1, reason: 'We get a match with 1 item');
      expect(result.single.item.author, 'John X',
          reason: 'Due to the X on John X');
    });

    test('When searching for "Plants x Zombies" with min = 2', () {
      final fuse = setUp(minTokenCharLength: 2);
      final result = fuse.search('Plants x Zombies');

      expect(result.length, 0, reason: 'We get no matches');
    });

    test('When searching for a pattern smaller than the length', () {
      final fuse = setUp(minTokenCharLength: 100);
      final result = fuse.search('John');

      expect(result.length, 3,
          reason: 'We still get matches because of full text search');
    });
  });

  group('Searching with minCharLength', () {
    late Fuzzy fuse;
    setUp(() {
      final customList = ['t te tes test tes te t'];
      fuse = setup(
        itemList: customList,
        options: defaultOptions.copyWith(
          minMatchCharLength: 2,
        ),
      );
    });

    test('When searching for the term "test"', () {
      final result = fuse.search('test');

      expect(result[0].matches[0].matchedIndices.length, equals(3),
          reason: 'We get a match containing 3 indices');

      expect(result[0].matches[0].matchedIndices[0].start, equals(2),
          reason: 'and the first index is a 2 character word');
      expect(result[0].matches[0].matchedIndices[0].end, equals(3),
          reason: 'and the first index is a 2 character word');
    });

    test('When searching for a string shorter than minMatchCharLength', () {
      final result = fuse.search('t');

      expect(result.length, equals(1),
          reason: 'We get a result with no matches');
      expect(result[0].matches[0].matchedIndices.length, equals(0),
          reason: 'We get a result with no matches');
    });
  });

  group('Searching using string large strings', () {
    late Fuzzy fuse;
    setUp(() {
      final customList = [
        'pizza',
        'feast',
        'super+large+much+unique+36+very+wow+',
      ];
      fuse = setup(
        itemList: customList,
        options: defaultOptions.copyWith(
          threshold: 0.5,
          location: 0,
          distance: 0,
          maxPatternLength: 50,
          minMatchCharLength: 4,
          shouldSort: true,
        ),
      );
    });

    test('finds delicious pizza', () {
      final result = fuse.search('pizza');
      expect(result[0].matches[0].value, equals('pizza'));
    });

    test('finds pizza when clumbsy', () {
      final result = fuse.search('pizze');
      expect(result[0].matches[0].value, equals('pizza'));
    });

    test('finds no matches when string is exactly 31 characters', () {
      final result = fuse.search('this-string-is-exactly-31-chars');
      expect(result.isEmpty, isTrue);
    });

    test('finds no matches when string is exactly 32 characters', () {
      final result = fuse.search('this-string-is-exactly-32-chars-');
      expect(result.isEmpty, isTrue);
    });

    test('finds no matches when string is larger than 32 characters', () {
      final result = fuse.search('this-string-is-more-than-32-chars');
      expect(result.isEmpty, isTrue);
    });

    test('should find one match that is larger than 32 characters', () {
      final result = fuse.search('super+large+much+unique+36+very+wow+');
      expect(result[0].matches[0].value,
          equals('super+large+much+unique+36+very+wow+'));
    });
  });

  group('On string normalization', () {
    final diacriticList = ['??ppl??', '??????ng??', 'B??n??n??'];
    late Fuzzy fuse;
    setUp(() {
      fuse = setup(
        itemList: diacriticList,
        options: defaultOptions.copyWith(shouldNormalize: true),
      );
    });

    test('When searching for the term "r??n"', () {
      final result = fuse.search('r??n');

      expect(result.length, equals(2),
          reason: 'we get a list of containing 2 items');
      expect(result[0].item, equals('??????ng??'));
      expect(result[1].item, equals('B??n??n??'));
    });
  });

  group('Without string normalization', () {
    final diacriticList = ['??ppl??', '??????ng??', 'B??n??n??'];
    late Fuzzy fuse;
    setUp(() {
      fuse = setup(itemList: diacriticList);
    });

    test('Nothing is found without normalization', () {
      final result = fuse.search('ran');

      expect(result.length, equals(0));
    });
  });
}
