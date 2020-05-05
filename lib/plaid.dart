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
              // _parseUrl(navRequest.url);
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

_parseUrl(String url) {
  if (url?.isNotEmpty != null) {
    final Uri uri = Uri.parse(url);
    debugPrint('PLAID uri: ' + uri.toString());
    final Map<String, String> queryParams = uri.queryParameters;
    final List<String> segments = uri.pathSegments;
    debugPrint('queryParams: ' + queryParams?.toString());
    debugPrint('segments: ' + segments?.toString());
    // _processParams(queryParams, url);
  }
}