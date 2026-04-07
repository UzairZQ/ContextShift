import 'dart:async';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';
import '../genui_catalog.dart';
import '../widgets/task_module.dart';
import '../widgets/habit_module.dart';
import '../widgets/focus_module.dart';
import '../widgets/notes_module.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SurfaceController _controller;
  late final A2uiTransportAdapter _transport;
  late final Conversation _conversation;
  late final IO.Socket _socket;
  final List<String> _surfaceIds = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _controller = SurfaceController(catalogs: [ContextShiftCatalog.getCatalog()]);
    _transport = A2uiTransportAdapter(onSend: _mockSendToLLM);

    _conversation = Conversation(
      controller: _controller,
      transport: _transport,
    );

    _conversation.events.listen((event) {
      if (event is ConversationSurfaceAdded) {
        setState(() => _surfaceIds.add(event.surfaceId));
      } else if (event is ConversationSurfaceRemoved) {
        setState(() => _surfaceIds.remove(event.surfaceId));
      }
    });

    _initSocket();
  }

  void _initSocket() {
    _socket = IO.io('http://localhost:3000', IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket.connect();
    _socket.onConnect((_) {
      debugPrint('Flutter: Connected to Node Socket.io server');
      _triggerBackend();
    });

    _socket.on('layout_update', (data) {
      debugPrint('Flutter: Received layout update from node.');
      if (data != null && data['a2ui_payloads'] != null) {
        final payloads = data['a2ui_payloads'] as List;
        for (final p in payloads) {
          _transport.addChunk(p.toString());
        }
      }
    });
  }

  Future<void> _triggerBackend({String? command}) async {
    try {
      // Fetch real Firestore events to send to AI
      final events = await FirebaseService.instance.getRecentEvents(limit: 30);
      await http.post(
        Uri.parse('http://localhost:8000/analyze-behavior'),
        headers: {'Content-Type': 'application/json'},
        body: '{"user_id": "uzair", "events": ${events.isEmpty ? "[]" : "[]"}, "command": ${command != null ? "\"$command\"" : "null"}}',
      );
    } catch (e) {
      debugPrint('Error triggering backend: $e');
    }
  }

  Future<void> _mockSendToLLM(ChatMessage message) async {
    // Replaced later by vertex/gemini websocket
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    _conversation.dispose();
    _transport.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: switch (_currentIndex) {
        0 => _buildHomeTab(),
        1 => const TasksModule(),
        2 => const HabitModule(),
        3 => const FocusTimerModule(),
        4 => const NotesModule(),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        _buildHeader(),
        _buildAICommandBar(),
        Expanded(child: _buildDynamicLayout()),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ContextShift',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  letterSpacing: -1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'AI-Adapted Sanctuary',
                style: TextStyle(color: AppTheme.primary, fontSize: 10, letterSpacing: 2),
              ),
            ],
          ),
          const _AIPulsar(),
        ],
      ),
    );
  }

  Widget _buildAICommandBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: TextField(
        style: const TextStyle(color: AppTheme.onSurface),
        decoration: InputDecoration(
          icon: const Icon(LucideIcons.sparkles, color: AppTheme.primary, size: 20),
          hintText: 'Tell ContextShift what to do...',
          hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
          border: InputBorder.none,
        ),
        onSubmitted: (val) {
          if (val.trim().isEmpty) return;
          FirebaseService.instance.logEvent(
            eventType: 'ai_command',
            module: 'home',
            metadata: {'command': val},
          );
          _triggerBackend(command: val);
        },
      ),
    );
  }

  Widget _buildDynamicLayout() {
    if (_surfaceIds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'AI is analyzing your patterns…',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _surfaceIds.length,
      itemBuilder: (context, index) {
        final id = _surfaceIds[index];
        final surfaceContext = _controller.contextFor(id);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Surface(surfaceContext: surfaceContext),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.white38,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          final modules = ['home', 'tasks', 'habits', 'focus', 'notes'];
          FirebaseService.instance.logEvent(
            eventType: 'tab_tap',
            module: modules[i],
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            activeIcon: Icon(LucideIcons.layoutDashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.checkSquare),
            activeIcon: Icon(LucideIcons.checkSquare),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.activity),
            activeIcon: Icon(LucideIcons.activity),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.timer),
            activeIcon: Icon(LucideIcons.timer),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.stickyNote),
            activeIcon: Icon(LucideIcons.stickyNote),
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}

class _AIPulsar extends StatefulWidget {
  const _AIPulsar();

  @override
  State<_AIPulsar> createState() => _AIPulsarState();
}

class _AIPulsarState extends State<_AIPulsar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 12 + (16 * _controller.value),
              height: 12 + (16 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 1 - _controller.value),
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
