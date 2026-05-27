import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/app_state_provider.dart';
import 'setup/setup_screen.dart';
import 'grading/grading_screen.dart';
import '../widgets/title_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Column(
        children: [
          // Custom title bar (draggable, with window controls)
          const CustomTitleBar(),
          // Main content area
          Expanded(
            child: Consumer<AppStateProvider>(
              builder: (context, state, _) {
                Widget childScreen;
                switch (state.currentScreen) {
                  case AppScreen.setup:
                    childScreen = const SetupScreen(key: ValueKey('setup'));
                    break;
                  case AppScreen.grading:
                    childScreen = const GradingScreen(key: ValueKey('grading'));
                    break;
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.02, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: childScreen,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
