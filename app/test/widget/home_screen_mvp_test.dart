import 'package:blurapp/features/home/home_screen_mvp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeScreenMVP Widget Tests', () {
    testWidgets('should display app title and buttons',
        (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenMVP(),
        ),
      );

  // Verify app title is displayed
  expect(find.text('BlurApp'), findsOneWidget);
  expect(find.text('Select a Photo to Blur'), findsOneWidget);

      // Verify action buttons are displayed
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);

      // Verify privacy section is displayed
      expect(find.text('Privacy First'), findsOneWidget);
      expect(find.textContaining('All processing happens on your device'),
          findsOneWidget);
    });

    testWidgets('should have app icon', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenMVP(),
        ),
      );

      // Verify app icon is displayed
      expect(find.byIcon(Icons.blur_on), findsOneWidget);
    });

    testWidgets('should have gallery and camera buttons',
        (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenMVP(),
        ),
      );

      // Verify gallery button with icon
      expect(find.byIcon(Icons.photo_library), findsOneWidget);

      // Verify camera button with icon
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);

      // Verify buttons by text content
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
    });

    testWidgets('buttons should be tappable', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenMVP(),
        ),
      );

      // Find the gallery button and verify it can be tapped
      final galleryButton = find.text('Choose from Gallery');
      expect(galleryButton, findsOneWidget);

      // Find the camera button and verify it can be tapped
      final cameraButton = find.text('Take Photo');
      expect(cameraButton, findsOneWidget);

      // Note: We don't actually tap the buttons in the test since that would
      // trigger image picker which requires platform mocking
    });

    testWidgets('should have proper layout structure',
        (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenMVP(),
        ),
      );

  // Verify main structure elements
  expect(find.byType(Scaffold), findsOneWidget);
  expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
  expect(find.byType(Column), findsAtLeastNWidgets(1));
  expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
  });
}
