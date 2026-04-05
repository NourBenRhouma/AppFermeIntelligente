import 'package:flutter/material.dart';
import 'dev_dashboard.dart';
import 'cam_dashboard.dart';
import 'alerts_page.dart';
import '../services/alert_service.dart';
import '../intro_page.dart';

// Design tokens from HTML mockup
const Color _bg      = Color(0xFF0A0B0F);
const Color _surface = Color(0xFF13151C);
const Color _green   = Color(0xFF3DDC84);
const Color _amber   = Color(0xFFFFB340);
const Color _red     = Color(0xFFFF5C5C);
const Color _text    = Color(0xFFF0F2FF);
const Color _text2   = Color(0xFF8B90A8);
const Color _text3   = Color(0xFF4A4F68);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  int get _totalAlerts => AlertService.history.length;
  int get _devAlerts   => AlertService.devAlerts.length;
  int get _camAlerts   => AlertService.camAlerts.length;

  void _goBackToIntro() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) => const IntroPage(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Header (dash-header style) ─────────────────────────
          SafeArea(
            bottom: false,
            child: _buildHeader(),
          ),
          // ── Tab bar ────────────────────────────────────────────
          _buildTabBar(),
          // ── Content ────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [DevDashboard(), CamDashboard()],
            ),
          ),
          // ── Bottom nav (tab-bar style from mockup) ─────────────
          _buildBottomNav(),
        ],
      ),
    );
  }

  // .dash-header style
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          // Bouton retour vers IntroPage
          GestureDetector(
            onTap: _goBackToIntro,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _text2,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Icon + title
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Center(child: Text('🚜', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ferme Intelligente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: _text, letterSpacing: -0.4)),
              Text('2 appareils connectés',
                  style: TextStyle(color: _text3, fontSize: 11)),
            ]),
          ),
          // Alert icon-btn (.icon-btn)
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AlertsPage()))
                .then((_) => setState(() {})),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _totalAlerts > 0 ? _red.withOpacity(0.10) : _surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: _totalAlerts > 0
                          ? _red.withOpacity(0.22)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Icon(
                    _totalAlerts > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: _totalAlerts > 0 ? _red : _text2,
                    size: 17,
                  ),
                ),
                if (_totalAlerts > 0)
                  Positioned(
                    top: -3, right: -3,
                    child: Container(
                      // .notif-badge
                      width: 15, height: 15,
                      decoration: const BoxDecoration(
                        color: _red, shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _totalAlerts > 9 ? '9+' : '$_totalAlerts',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // Selector between Serre / Caméra tabs
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 46,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          color: const Color(0xFF1C1F2B),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: (_tab.index == 0 ? _green : _amber).withOpacity(0.22),
          ),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelPadding: EdgeInsets.zero,
        labelColor: _text,
        unselectedLabelColor: _text3,
        dividerColor: Colors.transparent,
        tabs: [
          _buildTab(icon: Icons.eco, label: 'Ferme',
              color: _green, alerts: _devAlerts, isSelected: _tab.index == 0),
          _buildTab(icon: Icons.videocam_rounded, label: 'Caméra',
              color: _amber, alerts: _camAlerts, isSelected: _tab.index == 1),
        ],
      ),
    );
  }

  Widget _buildTab({
    required IconData icon, required String label,
    required Color color, required int alerts, required bool isSelected,
  }) {
    return Tab(
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 15, color: isSelected ? color : _text3),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? _text : _text3,
        )),
        if (alerts > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.15), borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$alerts',
                style: const TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ]),
    );
  }

  // .tab-bar (bottom nav like the mockup)
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(children: [
        _navItem(emoji: '🚜', label: 'Ferme', color: _green, isActive: _tab.index == 0, onTap: () => _tab.animateTo(0)),
        _navItem(emoji: '📷', label: 'Caméra', color: _amber, isActive: _tab.index == 1, onTap: () => _tab.animateTo(1)),
        _navItem(
          emoji: '🔔', label: 'Alertes', color: _red,
          isActive: false, hasDot: _totalAlerts > 0,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsPage()))
              .then((_) => setState(() {})),
        ),
      ]),
    );
  }

  Widget _navItem({
    required String emoji, required String label,
    required Color color, required bool isActive,
    bool hasDot = false, required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1C1F2B) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: isActive ? color.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 14))),
                  ),
                  if (hasDot && !isActive)
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : _text3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}