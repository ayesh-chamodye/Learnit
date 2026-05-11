import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnit/main.dart';
import 'package:learnit/screens/splash_screen.dart';
import 'package:learnit/screens/home_screen.dart';

void main() {
  testWidgets('SplashScreen displays image and bouncing dots', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    
    bool dotPredicate(Widget w) {
      if (w is Container && w.decoration is BoxDecoration) {
        final d = w.decoration as BoxDecoration;
        return d.shape == BoxShape.circle && d.color == Colors.white;
      }
      return false;
    }
    expect(find.byWidgetPredicate(dotPredicate), findsNWidgets(3));
    expect(find.text('LearnIt'), findsOneWidget);
    
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('ModernHomeScreen shows all 5 category sections', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    await tester.pump(const Duration(milliseconds: 5100));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    
    // Debug counts
    final allTexts = tester.allWidgets.whereType<Text>().map((t) => t.data).toList();
    debugPrint('All Texts: $allTexts');
    final viewAllCount = allTexts.where((t) => t == 'View All').length;
    debugPrint('View All count: $viewAllCount');
    
    expect(find.byType(ModernHomeScreen), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    
    // Verify each category title by directly scanning Text widgets
    final expectedTitles = ['Past Papers', 'Model Papers', 'Teacher Guides', 'Term Tests', 'Text Books'];
    for (final title in expectedTitles) {
      final matches = allTexts.where((t) => t == title).toList();
      expect(matches, isNotEmpty, reason: 'Category title "$title" should be present');
    }
    
    // Check "View All" buttons exist (one per category)
    expect(viewAllCount, 5);
  });

   testWidgets('App routes work correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    
    await tester.pump(const Duration(milliseconds: 5100));
    await tester.pumpAndSettle();
    
    expect(find.byType(ModernHomeScreen), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
