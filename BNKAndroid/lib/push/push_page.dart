import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'push_message.dart';
import 'ws_push_service.dart';

class PushPage extends StatefulWidget {
  final String baseUrl;  // 예: http://10.0.2.2:8080
  final int memberNo;
  const PushPage({super.key, required this.baseUrl, required this.memberNo});

  @override
  State<PushPage> createState() => _PushPageState();
}

class _PushPageState extends State<PushPage> with WidgetsBindingObserver {
  late final WsPushService ws;
  final List<PushMessage> messages = [];
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final base = Uri.parse(widget.baseUrl);
    final wsScheme = (base.scheme == 'https') ? 'wss' : 'ws';
    final wsUri = Uri(
      scheme: wsScheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/ws/push',
      queryParameters: {'memberNo': widget.memberNo.toString()},
    );

    ws = WsPushService(wsUri); // ✅ 이제 정상
    _connect();
  }

  Future<void> _connect() async {
    await ws.connect();
    await sub?.cancel();
    sub = ws.stream.listen((m) {
      if (!mounted) return;
      setState(() => messages.insert(0, m));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${m.title}\n${m.content}'), duration: const Duration(seconds: 2)),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    sub?.cancel();
    ws.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { _connect(); }
  }

  Future<void> _setConsent(bool agree) async {
    final uri = Uri.parse('${widget.baseUrl}/me/push-consent?memberNo=${widget.memberNo}');
    await http.put(uri, headers: {'Content-Type': 'application/json'},
        body: '{"pushYn":"${agree ? 'Y' : 'N'}"}');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('마케팅 수신 동의: ${agree ? 'ON' : 'OFF'}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WS Push Demo'),
        actions: [
          IconButton(icon: const Icon(Icons.toggle_on),  onPressed: () => _setConsent(true)),
          IconButton(icon: const Icon(Icons.toggle_off), onPressed: () => _setConsent(false)),
        ],
      ),
      body: ListView.separated(
        itemCount: messages.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final m = messages[i];
          final hh = m.receivedAt.hour.toString().padLeft(2, '0');
          final mm = m.receivedAt.minute.toString().padLeft(2, '0');
          return ListTile(
            title: Text(m.title),
            subtitle: Text(m.content),
            trailing: Text('$hh:$mm', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          );
        },
      ),
    );
  }
}
