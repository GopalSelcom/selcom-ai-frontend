import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selcom_id_auth/selcom_id_auth.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// A mock AppLinks implementation that lets us inject a controlled stream of deep links.
class MockAppLinks implements AppLinks {
  final Stream<Uri> _uriStream;
  final Uri? _initialUri;
  MockAppLinks(this._uriStream, {Uri? initialUri}) : _initialUri = initialUri;

  @override
  Stream<Uri> get uriLinkStream => _uriStream;

  @override
  Stream<String> get stringLinkStream => _uriStream.map((uri) => uri.toString());

  @override
  Future<Uri?> getInitialLink() async => _initialUri;

  @override
  Future<String?> getInitialLinkString() async => _initialUri?.toString();

  @override
  Future<Uri?> getLatestLink() async => null;

  @override
  Future<String?> getLatestLinkString() async => null;
}

// A mock UrlLauncherPlatform to prevent MissingPluginException during unit tests.
class MockUrlLauncher extends UrlLauncherPlatform {
  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => true;

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  LinkDelegate? get linkDelegate => null;
}

// A mock SelcomAuthService to verify widget interaction and behavior.
class MockSelcomAuthService extends SelcomAuthService {
  final StreamController<SelcomAuthResult> _testController = StreamController<SelcomAuthResult>.broadcast();
  bool startAuthFlowCalled = false;
  bool isInstalled = true;
  bool openAppStoreCalled = false;

  MockSelcomAuthService() : super.internal();

  @override
  Stream<SelcomAuthResult> get authResults => _testController.stream;

  @override
  Stream<SelcomAuthResult> startAuthFlow(SelcomAuthConfig config) {
    startAuthFlowCalled = true;
    if (!isInstalled) {
      // Delay emission to allow subscription setup
      scheduleMicrotask(() {
        _testController.add(SelcomAuthResult.failure('AppNotInstalled'));
      });
    }
    return _testController.stream;
  }

  @override
  Future<bool> isSelcomAppInstalled(SelcomAuthConfig config) async {
    return isInstalled;
  }

  @override
  Future<bool> openAppStore(SelcomAuthConfig config, {required bool isAndroid}) async {
    openAppStoreCalled = true;
    return true;
  }

  void triggerResult(SelcomAuthResult result) {
    _testController.add(result);
  }
}

void main() {
  setUpAll(() {
    UrlLauncherPlatform.instance = MockUrlLauncher();
  });

  group('SelcomAuthConfig Tests', () {
    test('should generate correct authUri with parameters', () {
      const config = SelcomAuthConfig(
        clientId: 'zomato_client',
        redirectScheme: 'zomato',
        additionalParams: {'state': 'xyz_state', 'scope': 'read'},
      );

      final uri = config.authUri;

      expect(uri.scheme, 'selcomid');
      expect(uri.host, 'auth');
      expect(uri.queryParameters['client_id'], 'zomato_client');
      expect(uri.queryParameters['redirect_scheme'], 'zomato');
      expect(uri.queryParameters['state'], 'xyz_state');
      expect(uri.queryParameters['scope'], 'read');
    });

    test('should return correct store URIs', () {
      const config = SelcomAuthConfig(
        clientId: 'test',
        redirectScheme: 'test',
        androidPackageName: 'com.test.app',
        iosAppStoreId: '98765',
      );

      expect(config.playStoreUri.toString(), 'market://details?id=com.test.app');
      expect(config.playStoreWebUri.toString(), 'https://play.google.com/store/apps/details?id=com.test.app');
      expect(config.appStoreUri.toString(), 'https://apps.apple.com/app/selcom-id/id98765');
    });
  });

  group('SelcomAuthResult Tests', () {
    test('success result returns correct properties', () {
      final result = SelcomAuthResult.success('token_abc');
      expect(result.status, SelcomAuthStatus.success);
      expect(result.token, 'token_abc');
      expect(result.errorMessage, isNull);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.isCancelled, isFalse);
    });

    test('failure result returns correct properties', () {
      final result = SelcomAuthResult.failure('connection_error');
      expect(result.status, SelcomAuthStatus.failure);
      expect(result.token, isNull);
      expect(result.errorMessage, 'connection_error');
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.isCancelled, isFalse);
    });

    test('cancelled result returns correct properties', () {
      final result = SelcomAuthResult.cancelled();
      expect(result.status, SelcomAuthStatus.cancelled);
      expect(result.token, isNull);
      expect(result.errorMessage, isNull);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isFalse);
      expect(result.isCancelled, isTrue);
    });
  });

  group('SelcomAuthService Deep Link Interception', () {
    late StreamController<Uri> linkStreamController;
    late SelcomAuthService service;
    const config = SelcomAuthConfig(
      clientId: 'zomato',
      redirectScheme: 'zomatoapp',
    );

    setUp(() {
      linkStreamController = StreamController<Uri>.broadcast();
      final mockAppLinks = MockAppLinks(linkStreamController.stream);
      service = SelcomAuthService.internal(appLinks: mockAppLinks);
    });

    tearDown(() {
      linkStreamController.close();
      service.dispose();
    });

    test('should intercept success token deep link', () async {
      final flowStream = service.startAuthFlow(config);

      // Trigger a success link on the stream
      linkStreamController.add(Uri.parse('zomatoapp://success?token=token_12345'));

      final result = await flowStream.first;
      expect(result.isSuccess, isTrue);
      expect(result.token, 'token_12345');
    });

    test('should intercept success deep link with data parameter and URL decode it', () async {
      final flowStream = service.startAuthFlow(config);

      // Trigger a success link with data parameter that contains URL-encoded content
      const rawData = '{"userId":"123","userName":"John Doe"}';
      final encodedData = Uri.encodeComponent(rawData);
      linkStreamController.add(Uri.parse('zomatoapp://success?data=$encodedData'));

      final result = await flowStream.first;
      expect(result.isSuccess, isTrue);
      expect(result.token, rawData);
    });

    test('should handle invalid percent encoding in data parameter gracefully', () async {
      final flowStream = service.startAuthFlow(config);

      // Trigger a success link with malformed percent encoding
      linkStreamController.add(Uri.parse('zomatoapp://success?data=invalid%percent'));

      final result = await flowStream.first;
      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Failed to decode data'));
    });

    test('should intercept error deep link', () async {
      final flowStream = service.startAuthFlow(config);

      // Trigger an error link on the stream
      linkStreamController.add(Uri.parse('zomatoapp://error?error=user_rejected'));

      final result = await flowStream.first;
      expect(result.isFailure, isTrue);
      expect(result.errorMessage, 'user_rejected');
    });

    test('should intercept success deep link containing error', () async {
      final flowStream = service.startAuthFlow(config);

      // Trigger success link containing error
      linkStreamController.add(Uri.parse('zomatoapp://success?error=invalid_client'));

      final result = await flowStream.first;
      expect(result.isFailure, isTrue);
      expect(result.errorMessage, 'invalid_client');
    });

    test('should intercept cancel deep link', () async {
      final flowStream = service.startAuthFlow(config);

      // Trigger a cancel link
      linkStreamController.add(Uri.parse('zomatoapp://cancel'));

      final result = await flowStream.first;
      expect(result.isCancelled, isTrue);
    });

    test('should ignore deep links with non-matching scheme', () async {
      final flowStream = service.startAuthFlow(config);
      final results = <SelcomAuthResult>[];
      final subscription = flowStream.listen(results.add);

      // Trigger a link with unrelated scheme
      linkStreamController.add(Uri.parse('unrelated://success?token=token_12345'));

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results, isEmpty);

      // Trigger correct scheme to resolve it
      linkStreamController.add(Uri.parse('zomatoapp://success?token=resolved_token'));

      await Future.delayed(const Duration(milliseconds: 100));
      expect(results.length, 1);
      expect(results.first.token, 'resolved_token');

      await subscription.cancel();
    });

    test('should handle initial link resolved during initialization', () async {
      final initialLinkController = StreamController<Uri>.broadcast();
      const testConfig = SelcomAuthConfig(
        clientId: 'zomato',
        redirectScheme: 'zomatoapp',
      );
      final initialUri = Uri.parse('zomatoapp://success?data=initial_data_payload');
      final mockAppLinks = MockAppLinks(initialLinkController.stream, initialUri: initialUri);
      
      final testService = SelcomAuthService.internal(appLinks: mockAppLinks);
      
      // Register config which processes the pending/cached initial link
      testService.registerConfig(testConfig);
      
      final result = await testService.authResults.first;
      expect(result.isSuccess, isTrue);
      expect(result.token, 'initial_data_payload');
      
      initialLinkController.close();
      testService.dispose();
    });
  });

  group('SelcomAuthButton Widget Tests', () {
    late MockSelcomAuthService mockService;

    setUp(() {
      mockService = MockSelcomAuthService();
      SelcomAuthService.setMockInstance(mockService);
    });

    testWidgets('renders button with correct text and logo custompaint', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelcomAuthButton(
              clientId: 'test',
              redirectScheme: 'testscheme',
              buttonText: 'Authenticate with Selcom',
              onSuccess: (_) {},
              onError: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Authenticate with Selcom'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is SelcomButtonLogoPainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('taps button and launches SSO success flow', (WidgetTester tester) async {
      String? successToken;
      String? failureMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelcomAuthButton(
              clientId: 'test',
              redirectScheme: 'testscheme',
              onSuccess: (token) => successToken = token,
              onError: (err) => failureMessage = err,
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(SelcomAuthButton));
      await tester.pump();

      expect(mockService.startAuthFlowCalled, isTrue);

      // Verify progress indicator is showing during loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Trigger success event
      mockService.triggerResult(SelcomAuthResult.success('auth_token_xyz'));
      await tester.pumpAndSettle();

      expect(successToken, 'auth_token_xyz');
      expect(failureMessage, isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('taps button, fails to launch (app not installed), displays fallback bottom sheet', (WidgetTester tester) async {
      mockService.isInstalled = false;
      bool cancelledCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelcomAuthButton(
              clientId: 'test',
              redirectScheme: 'testscheme',
              onSuccess: (_) {},
              onError: (_) {},
              onCancelled: () => cancelledCalled = true,
              fallbackTitle: 'Get Selcom ID Test',
            ),
          ),
        ),
      );

      // Tap button to launch flow
      await tester.tap(find.byType(SelcomAuthButton));
      await tester.pumpAndSettle();

      // Fallback BottomSheet should appear
      expect(find.text('Get Selcom ID Test'), findsOneWidget);
      expect(find.text('Install Selcom ID'), findsOneWidget);

      // Tap the install/primary button in the bottom sheet
      await tester.tap(find.text('Install Selcom ID'));
      await tester.pumpAndSettle();

      // Store launcher should be invoked
      expect(mockService.openAppStoreCalled, isTrue);
    });
  });
}
