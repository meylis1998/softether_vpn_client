import 'package:flutter_test/flutter_test.dart';

import 'package:softether_vpn_client/main.dart';

void main() {
  testWidgets('SoftEther VPN app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SoftEtherVPNApp());

    // Verify that the main screen loads
    expect(find.text('SoftEther VPN'), findsOneWidget);
  });
}