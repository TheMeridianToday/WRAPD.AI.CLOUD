import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wrapd/main.dart';
import 'package:wrapd/providers/session_provider.dart';
import 'package:wrapd/providers/workflow_provider.dart';
import 'package:wrapd/theme/app_theme.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SessionProvider()),
          ChangeNotifierProvider(create: (_) => WorkflowProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const WrapdApp(),
      ),
    );
    expect(find.byType(WrapdApp), findsOneWidget);
  });
}
