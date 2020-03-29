/*
import 'package:plaid/plaid.dart';
*/
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

String authority = 'cdn.plaid.com';
String unencodedPath = '/link/v2/stable/link.html';
Map<String, String> queryParameters = {
  "key": "cc12481ba9e7bd47809561ea23b521",
  "product": "auth,transactions",
  "apiVersion": "v2", // set this to "v1" if using the legacy Plaid API
  "env": "sandbox",
  "clientName": "Decarbon",
  "selectAccount": "true",
};

// documentation:  https://plaid.com/docs/#webview-integration
class PlaidLink extends StatefulWidget {
  static const id = 'plaid_screen_id';

  @override
  _PlaidLinkState createState() => _PlaidLinkState();
}

class _PlaidLinkState extends State<PlaidLink> {
  Uri uri = Uri.https(authority, unencodedPath, queryParameters);

  Completer<WebViewController> _controller = Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: WebView(
          javascriptMode: JavascriptMode.unrestricted,
          initialUrl: uri.toString(),
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },
          navigationDelegate: (NavigationRequest navRequest) {
            debugPrint("NavigationRequest URL: ${navRequest.url}");
            if (navRequest.url.contains('plaidlink://')) {
              return NavigationDecision.prevent;
            }
            debugPrint(navRequest.url.toString());
            return NavigationDecision.navigate;
          },
        ),
      ),
    );
  }
}

/*
class PlaidLink extends State {

  showPlaidView() {
    bool plaidSandbox = true;

    Configuration configuration = Configuration(
        plaidPublicKey: 'cc12481ba9e7bd47809561ea23b521',
        plaidBaseUrl: 'https://cdn.plaid.com/link/v2/stable/link.html',
        plaidEnvironment: plaidSandbox ? 'sandbox' : 'production',
        environmentPlaidPathAccessToken:
        'https://sandbox.plaid.com/item/public_token/exchange',
        environmentPlaidPathStripeToken:
        'https://sandbox.plaid.com/processor/stripe/bank_account_token/create',
        plaidClientId: '5e37326608bbc300147b421c',
        secret: plaidSandbox ? 'e426be468ca55de1286a829669872d' : '',
        clientName: 'Decarbon',
        webhook: 'Webhook Url',
        products: 'auth,income',
        selectAccount: 'false'
    );

    FlutterPlaidApi flutterPlaidApi = FlutterPlaidApi(configuration);
    flutterPlaidApi.launch(context, (Result result) {
      ///handle result
    }, stripeToken: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}*/