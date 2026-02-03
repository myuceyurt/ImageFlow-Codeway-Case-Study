import 'package:flutter_test/flutter_test.dart';
import 'package:image_flow/main.dart';

void main() {
  testWidgets('shows splash title', (WidgetTester tester) async {
    await tester.pumpWidget(const ImageFlowApp());
    await tester.pump();
    expect(find.text('ImageFlow'), findsOneWidget);
  });
}
