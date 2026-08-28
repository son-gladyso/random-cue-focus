import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_cue_focus/widgets.dart';

void main() {
  testWidgets('goal-check actions are readable and at least 44 by 44', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: GoalCheckCard(
              goal: '完成测试',
              onTask: () {},
              offTask: () {},
              onSkip: () {},
            ),
          ),
        ),
      ),
    );

    for (final label in ['仍在目标', '刚刚走神', '跳过']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(CupertinoButton),
      );
      expect(button, findsOneWidget);
      final size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(tester.getSemantics(find.text(label)).label, label);
    }
    semantics.dispose();
  });
}
