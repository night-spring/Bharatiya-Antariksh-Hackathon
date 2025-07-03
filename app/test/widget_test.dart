import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart'; // Import your main app file

void main() {
  testWidgets('Splash screen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MaterialApp(
      home: SpaceSplashScreen(),
    ));

    // Verify the app title exists
    expect(find.text('AIR SPECTRA'), findsOneWidget);

    // Verify the tagline exists
    expect(find.text('Breathe the cosmos, monitor your atmosphere'),
        findsOneWidget);

    // Verify the loading indicator exists
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
