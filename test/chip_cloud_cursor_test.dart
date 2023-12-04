import 'dart:math';

import 'package:chip_cloud/chip_cloud_cursor.dart';
import 'package:chip_cloud/chip_cloud_options.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChipCloudCursor', () {
    const defaultOptions = ChipCloudOptions();

    test('cloning should return an identical entity', () {
      const options = ChipCloudOptions(
          showOverflowIndicator: false,
          elementSpacing: 8,
          rowSpacing: 4,
          padding: EdgeInsets.fromLTRB(1, 2, 3, 4),
          debug: true);
      final cursor1 = ChipCloudCursor.initializeWith(
          options: options,
          row: 2,
          column: 3,
          position: const Point(16, 8),
          determinedElementPositions: {0: const Point(1, 2), 1: const Point(11, 2), 3: const Point(1, 8)},
          elementsPerRow: {0: 2, 1: 1},
          displayedElementsIndices: [0, 1, 3],
          displayedElementsWidth: [10, 10, 15],
          skippedElements: 2);
      final cursor2 = cursor1.clone();

      expect(cursor2.options, cursor1.options);
      expect(cursor2.column, cursor1.column);
      expect(cursor2.determinedElementPositions, cursor1.determinedElementPositions);
      expect(cursor2.skippedElements, cursor1.skippedElements);
      expect(cursor2.isAtStartOfRow, cursor1.isAtStartOfRow);
      expect(cursor2.didSkipElements, cursor1.didSkipElements);
      expect(cursor2.x, cursor1.x);
      expect(cursor2.y, cursor1.y);
    });

    test('changing a cloned cursor should not change the original cursor', () {
      final cursor1 = ChipCloudCursor(defaultOptions);
      final cursor2 = cursor1.clone();

      cursor2.registerElementAtCursorPosition(2, 40);
      expect(cursor1.determinedElementPositions, {});
      expect(cursor1.elementsPerRow, {});
      expect(cursor1.displayedElementsIndices, []);
      expect(cursor1.displayedElementsWidth, []);
    });

    test('moving the cursor to the next column should change the x position and increase the column counter', () {
      const options = ChipCloudOptions(elementSpacing: 5);
      final cursor = ChipCloudCursor.initializeWith(options: options, position: const Point(30, 20), column: 7);

      cursor.moveToNextColumn(65);
      expect(cursor.x, 100); // 5 + 30 + 65
      expect(cursor.y, 20);
      expect(cursor.column, 8);
    });

    test('moving the cursor to the next row should change the y position and set the column counter to 0', () {
      const options = ChipCloudOptions(elementSpacing: 5, rowSpacing: 7);
      final cursor =
          ChipCloudCursor.initializeWith(options: options, position: const Point(30, 200), column: 7, row: 5);
      const previousElementHeight = 12.0;

      cursor.moveToNextRow(previousElementHeight);
      expect(cursor.x, 0);
      expect(cursor.y, 219); // 200 + 12 + 7
      expect(cursor.column, 0);
      expect(cursor.row, 6);
    });

    test('calling registerElementAtCursorPosition() should update all four related collections', () {
      final cursor = ChipCloudCursor.initializeWith(
          options: defaultOptions,
          row: 1,
          column: 2,
          position: const Point(14, 8),
          determinedElementPositions: {0: const Point(1, 2), 1: const Point(11, 2), 2: const Point(1, 8)},
          elementsPerRow: {0: 2, 1: 1},
          displayedElementsIndices: [0, 1, 3],
          displayedElementsWidth: [10, 10, 15]);
      const elementIndex = 3;
      const elementWidth = 20.0;

      cursor.registerElementAtCursorPosition(elementIndex, elementWidth);
      expect(cursor.determinedElementPositions.entries.length, 4);
      expect(cursor.determinedElementPositions.entries.last.key, 3);
      expect(cursor.determinedElementPositions.entries.last.value, const Point(14.0, 8.0));
      expect(cursor.elementsPerRow.entries.length, 2);
      expect(cursor.elementsPerRow[1], 2);
      expect(cursor.displayedElementsIndices.length, 4);
      expect(cursor.displayedElementsIndices.last, 3);
      expect(cursor.displayedElementsWidth.length, 4);
      expect(cursor.displayedElementsWidth.last, 20);
    });

    test('calling registerSkippedElements() should add the number of new skipped elements to the counter', () {
      final cursor = ChipCloudCursor.initializeWith(options: defaultOptions, skippedElements: 8);
      cursor.registerSkippedElements(5);

      expect(cursor.skippedElements, 13);
    });

    test(
        'removing the last displayed element should update all related collections and move the cursor to the last column in the previous row (if the removed element was the first in its row)',
        () {
      const options = ChipCloudOptions(elementSpacing: 5);
      final cursor = ChipCloudCursor.initializeWith(
          options: options,
          row: 1,
          column: 1,
          position: const Point(16, 8),
          determinedElementPositions: {0: const Point(1, 2), 1: const Point(11, 2), 3: const Point(1, 8)},
          elementsPerRow: {0: 2, 1: 1},
          displayedElementsIndices: [0, 1, 3],
          displayedElementsWidth: [10, 10, 15],
          skippedElements: 2);
      cursor.removeLastDisplayedElementAndRepositionCursor();

      expect(cursor.determinedElementPositions.keys, [0, 1]);
      expect(cursor.elementsPerRow.keys, [0]);
      expect(cursor.elementsPerRow[0], 2);
      expect(cursor.displayedElementsIndices.length, 2);
      expect(cursor.displayedElementsWidth.length, 2);
      expect(cursor.row, 0);
      expect(cursor.column, 2);
      expect(
          cursor.x, 26); // 11 (next to last element position) + 10 (next to last element width) + 5 (element spacing)
      expect(cursor.y, 2);
      expect(cursor.skippedElements, 3);
    });

    test(
        'removing the last displayed element should update all related collections and move the cursor to the previous column in the same row (if the removed element was NOT the first in its row)',
        () {
      const options = ChipCloudOptions(elementSpacing: 5);
      final cursor = ChipCloudCursor.initializeWith(
          options: options,
          row: 1,
          column: 2,
          position: const Point(14, 8),
          determinedElementPositions: {
            0: const Point(1, 2),
            1: const Point(11, 2),
            3: const Point(1, 8),
            4: const Point(21, 8)
          },
          elementsPerRow: {0: 2, 1: 2},
          displayedElementsIndices: [0, 1, 3, 4],
          displayedElementsWidth: [10, 10, 15, 12],
          skippedElements: 2);
      cursor.removeLastDisplayedElementAndRepositionCursor();

      expect(cursor.determinedElementPositions.keys, [0, 1, 3]);
      expect(cursor.elementsPerRow[0], 2);
      expect(cursor.elementsPerRow[1], 1);
      expect(cursor.displayedElementsIndices.length, 3);
      expect(cursor.displayedElementsWidth.length, 3);
      expect(cursor.row, 1);
      expect(cursor.column, 1);
      expect(cursor.x, 21); // 1 (next to last element position) + 15 (next to last element width) + 5 (element spacing)
      expect(cursor.y, 8);
      expect(cursor.skippedElements, 3);
    });
  });
}
