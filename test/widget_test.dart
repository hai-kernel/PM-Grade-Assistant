import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pmg_grade/main.dart';
import 'package:pmg_grade/core/providers/app_state_provider.dart';

void main() {
  testWidgets('App loads setup screen directly without login test', (WidgetTester tester) async {
    // Build our app with provider and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ],
        child: const PMGGradeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that setup screen elements exist (e.g. Hero Banner text or creation button).
    expect(find.text('Tạo phiên chấm mới'), findsWidgets);
  });
}
