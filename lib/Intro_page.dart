import 'package:flutter/material.dart';
import './pages/dashboard_page.dart';

// Design tokens from HTML mockup
const Color _bg       = Color(0xFF0A0B0F);
const Color _surface  = Color(0xFF13151C);
const Color _surface2 = Color(0xFF1C1F2B);
const Color _green    = Color(0xFF3DDC84);
const Color _amber    = Color(0xFFFFB340);
const Color _blue     = Color(0xFF4A9EFF);
const Color _red      = Color(0xFFFF5C5C);
const Color _purple   = Color(0xFFA78BFA);
const Color _text     = Color(0xFFF0F2FF);
const Color _text2    = Color(0xFF8B90A8);
const Color _text3    = Color(0xFF4A4F68);

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});
  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _titleSlide;
  late Animation<Offset> _cardsSlide;
  late Animation<Offset> _btnSlide;
  late Animation<double> _cardsFade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));
    _cardsSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)));
    _cardsFade  = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)));
    _btnSlide   = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) => const DashboardPage(),
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Background orbs matching .intro-orb / .intro-orb2
            Positioned(
              top: -60, right: -60,
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A3D2B),
                ),
              ),
            ),
            Positioned(
              bottom: 120, left: -50,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3D2A00),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLiveBadge(),
                    const SizedBox(height: 28),
                    _buildHero(),
                    const SizedBox(height: 28),
                    _buildDeviceCards(),
                    const SizedBox(height: 24),
                    _buildFeatGrid(),
                    const SizedBox(height: 36),
                    _buildCTA(),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'ISAMM · 2025–2026',
                        style: TextStyle(color: _text3.withOpacity(0.6), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // .live-badge
  Widget _buildLiveBadge() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3D2B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _green,
              boxShadow: [BoxShadow(
                color: _green.withOpacity(0.5 * _pulseAnim.value),
                blurRadius: 6, spreadRadius: 1,
              )],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '2 appareils connectés',
            style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    );
  }

  // .intro-title + .intro-sub
  Widget _buildHero() {
    return SlideTransition(
      position: _titleSlide,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 34, fontWeight: FontWeight.w800,
              height: 1.1, letterSpacing: -1.2, color: _text,
            ),
            children: [
              const TextSpan(text: 'Votre ferme,\n'),
              TextSpan(text: 'à portée', style: TextStyle(color: _green)),
              const TextSpan(text: '\nde main.'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Surveillez et contrôlez votre serre intelligente en temps réel depuis votre téléphone.',
          style: TextStyle(color: _text2, fontSize: 13, height: 1.6),
        ),
      ]),
    );
  }

  // .device-cards
  Widget _buildDeviceCards() {
    return SlideTransition(
      position: _cardsSlide,
      child: FadeTransition(
        opacity: _cardsFade,
        child: Row(children: [
          Expanded(child: _deviceCard(
            emoji: '🌿', label: 'Serre', sub: 'Temp · Eau · Hum', color: _green,
            gradColor: const Color(0xFF1A3D2B), onTap: _goToDashboard,
          )),
          const SizedBox(width: 10),
          Expanded(child: _deviceCard(
            emoji: '📷', label: 'Caméra', sub: 'Détection · Photo', color: _amber,
            gradColor: const Color(0xFF3D2A00), onTap: _goToDashboard,
          )),
        ]),
      ),
    );
  }

  Widget _deviceCard({
    required String emoji, required String label, required String sub,
    required Color color, required Color gradColor, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [gradColor, _surface],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: _text3, fontSize: 10)),
        ]),
      ),
    );
  }

  // .feat-grid
  Widget _buildFeatGrid() {
    final feats = [
      _Feat('🌡️', 'Climatisation', 'Auto selon la temp.', _blue),
      _Feat('💧', 'Irrigation', 'Pompe automatique', _green),
      _Feat('🚨', 'Sécurité', 'Alerte immédiate', _red),
      _Feat('📸', 'Photos', 'À la demande', _purple),
    ];
    return SlideTransition(
      position: _cardsSlide,
      child: FadeTransition(
        opacity: _cardsFade,
        child: GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
          childAspectRatio: 2.0,
          children: feats.map((f) => _featItem(f)).toList(),
        ),
      ),
    );
  }

  Widget _featItem(_Feat f) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: f.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(child: Text(f.emoji, style: const TextStyle(fontSize: 14))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(f.title, style: const TextStyle(color: _text, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 1),
          Text(f.sub, style: const TextStyle(color: _text3, fontSize: 9.5, height: 1.3)),
        ])),
      ]),
    );
  }

  // .cta-btn
  Widget _buildCTA() {
    return SlideTransition(
      position: _btnSlide,
      child: GestureDetector(
        onTap: _goToDashboard,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _green.withOpacity(0.20 + 0.12 * _pulseAnim.value),
                  blurRadius: 20 + 8 * _pulseAnim.value,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text(
                'Accéder au tableau de bord',
                style: TextStyle(
                  color: Color(0xFF071a10),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              const Text('→', style: TextStyle(color: Color(0xFF071a10), fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Feat {
  final String emoji, title, sub;
  final Color color;
  const _Feat(this.emoji, this.title, this.sub, this.color);
}