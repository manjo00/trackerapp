import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_item_model.freezed.dart';

/// How a tracker item collects its value.
enum FieldType {
  checkbox,  // boolean: done / not done
  number,    // numeric: sets, reps, weight, count
  text;      // free string: exercise name, notes

  static FieldType fromString(String s) => switch (s) {
        'number' => number,
        'text' => text,
        _ => checkbox,
      };

  String get value => name; // 'checkbox' | 'number' | 'text'
}

/// One item/field belonging to a tracker.
@freezed
abstract class TrackerItemModel with _$TrackerItemModel {
  const factory TrackerItemModel({
    required int id,
    required int trackerId,
    required String name,
    required FieldType fieldType,
    required int sortOrder,
  }) = _TrackerItemModel;
}
