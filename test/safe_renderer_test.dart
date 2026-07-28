import 'package:context_shift/core/app_theme.dart';
import 'package:context_shift/core/genui/safe_renderer.dart';
import 'package:context_shift/core/genui/widget_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(WidgetCatalog.instance.init);

  testWidgets('SafeRenderer renders allow-listed JSON', (tester) async {
    late RenderResult result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) {
            result = SafeRenderer(catalog: WidgetCatalog.instance).render(
              '{"widget":"Text","props":{"content":"Rendered safely"}}',
              context,
            );
            return Scaffold(body: result.widget);
          },
        ),
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(find.text('Rendered safely'), findsOneWidget);
  });

  testWidgets('SafeRenderer rejects blocked widget types', (tester) async {
    late RenderResult result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            result = SafeRenderer(
              catalog: WidgetCatalog.instance,
            ).render('{"widget":"WebView","props":{}}', context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(result.error, RenderError.widgetNotAllowed);
    expect(result.widget, isNull);
  });

  testWidgets('does not expose renderer exceptions to the user', (
    tester,
  ) async {
    late RenderResult result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            result = SafeRenderer(catalog: WidgetCatalog.instance).render(
              '{"widget":"Container","props":{"padding":"bad"}}',
              context,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(result.isError, isTrue);
    expect(
      result.errorMessage,
      'The generated view could not be built safely.',
    );
    expect(result.errorMessage, isNot(contains('Exception')));
  });
}
