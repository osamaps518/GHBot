import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'l10n/app_localizations.dart';

/// Shows whether the backend's `/health` answered.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.client, required this.apiBaseUrl});

  final http.Client client;
  final String apiBaseUrl;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<bool> _reached;

  @override
  void initState() {
    super.initState();
    _reached = _checkHealth();
  }

  Future<bool> _checkHealth() async {
    try {
      final baseUrl = widget.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
      final response = await widget.client
          .get(Uri.parse('$baseUrl/health'))
          // Without a timeout, an unreachable address can spin for minutes.
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } on Exception {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: FutureBuilder<bool>(
          future: _reached,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            return Text(
              snapshot.data == true
                  ? l10n.backendReached
                  : l10n.backendNotReached,
            );
          },
        ),
      ),
    );
  }
}
