import 'package:flutter_test/flutter_test.dart';
import 'package:learnit/models/course_model.dart';

void main() {
  test('CourseItem fromJson parses correctly', () {
    final json = {
      "grade": "06",
      "subject": "Mathematics",
      "language": "English",
      "youtubeUrl": "https://www.youtube.com/watch?v=bHUljcOOCLI",
      "courseId": 288,
      "courseName": "Mathematics - Grade - 06"
    };
    final item = CourseItem.fromJson(json);
    expect(item.id, '288');
    expect(item.title, 'Mathematics - Grade - 06');
    expect(item.subject, 'Mathematics');
    expect(item.grade, '06');
    expect(item.language, 'English');
    expect(item.youtubeUrl, 'https://www.youtube.com/watch?v=bHUljcOOCLI');
    expect(item.courseId, 288);
    expect(item.thumbnailUrl, 'https://img.youtube.com/vi/bHUljcOOCLI/hqdefault.jpg');
    expect(item.type, 'video');
  });
}
