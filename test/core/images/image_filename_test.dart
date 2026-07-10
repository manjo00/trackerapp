import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/images/image_filename.dart';

void main() {
  test('builds img_<seed>.<ext>', () {
    expect(buildImageFilename(seed: 123, extension: 'png'), 'img_123.png');
  });
  test('defaults to jpg', () {
    expect(buildImageFilename(seed: 5), 'img_5.jpg');
  });
  test('lowercases and strips a leading dot', () {
    expect(buildImageFilename(seed: 7, extension: '.JPEG'), 'img_7.jpeg');
  });
  test('empty extension falls back to jpg', () {
    expect(buildImageFilename(seed: 9, extension: ''), 'img_9.jpg');
  });
}
