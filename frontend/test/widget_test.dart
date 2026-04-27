import 'package:flutter_test/flutter_test.dart';
import 'package:intelligent_waste_sorting_app/app/waste_sorting_app.dart';

void main() {
  testWidgets('renders the auth entry page', (tester) async {
    await tester.pumpWidget(const WasteSortingApp());

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Please login to continue.'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
