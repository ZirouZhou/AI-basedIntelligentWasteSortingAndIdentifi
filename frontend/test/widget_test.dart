import 'package:flutter_test/flutter_test.dart';
import 'package:intelligent_waste_sorting_app/app/waste_sorting_app.dart';

void main() {
  testWidgets('renders the main app shell', (tester) async {
    await tester.pumpWidget(const WasteSortingApp());

    expect(find.text('EcoSort AI'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Classify'), findsOneWidget);
    expect(find.text('Rewards'), findsOneWidget);
  });


  
}
