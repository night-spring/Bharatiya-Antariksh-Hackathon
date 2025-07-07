import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Splash screen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      const MaterialApp(
        home: SpaceSplashScreen(),
      ),
    );

    // Verify the animated text exists (since AIR SPECTRA is not present, check for animated text)
    expect(find.text('Atmospheric Quality Intelligence'), findsOneWidget);
    expect(find.text('Space-Grade Air Quality Analysis'), findsOneWidget);

    // Verify the loading indicator exists
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
