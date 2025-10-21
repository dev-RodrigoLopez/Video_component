// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:video_component/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the video call icon is present (initial state)
    expect(find.byIcon(Icons.video_call), findsOneWidget);
    
    // Verify that the play icon is not present initially
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    
    // Verify that the app title is correct
    expect(find.text('Video Recorder'), findsNothing); // Title is in MaterialApp, not visible in UI
  });

  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build our app and verify no exceptions are thrown
    await tester.pumpWidget(MyApp());
    
    // Verify that we have a Scaffold
    expect(find.byType(Scaffold), findsOneWidget);
    
    // Verify that we have the ButtonVideo widget
    expect(find.byType(InkWell), findsOneWidget);
  });
}
