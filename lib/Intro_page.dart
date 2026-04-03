import 'dart:math';
import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _rotateCtrl;

  late Animation<double> _fadeAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _rotateAnim;
  late Animation<Offset> _titleSlide;
  late Animation<Offset> _subtitleSlide;
  late Animation<Offset> _cardsSlide;
  late Animation<Offset> _btnSlide;
  late Animation<double> _cardsFade;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _floatAnim = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _rotateAnim = CurvedAnimation(parent: _rotateCtrl, curve: Curves.linear);

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)));

    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideCtrl,
                curve:
                    const Interval(0.1, 0.6, curve: Curves.easeOutCubic)));

    _cardsSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideCtrl,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)));

    _cardsFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _slideCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut)));

    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideCtrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic)));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 900),
        pageBuilder: (_, animation, __) => const DashboardPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06100A),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    _buildTopBadge(),
                    const SizedBox(height: 28),
                    _buildLogo(),
                    const SizedBox(height: 28),
                    _buildTitle(),
                    const SizedBox(height: 18),
                    _buildSubtitle(),
                    const SizedBox(height: 36),
                    _buildAnimalBand(),
                    const SizedBox(height: 36),
                    _buildFeatureCards(),
                    const SizedBox(height: 36),
                    _buildStatsRow(),
                    const SizedBox(height: 40),
                    _buildCTAButton(),
                    const SizedBox(height: 28),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fond animé organique ─────────────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) {
        return CustomPaint(
          painter: _FarmBackgroundPainter(_floatAnim.value),
          size: Size.infinite,
        );
      },
    );
  }

  // ── Badge haut "LIVE" ─────────────────────────────────────
  Widget _buildTopBadge() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A1A),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: const Color(0xFF4CAF50)
                    .withOpacity(0.3 + 0.2 * _pulseAnim.value)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50)
                          .withOpacity(0.7 * _pulseAnim.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SURVEILLANCE EN DIRECT',
                style: TextStyle(
                  color: Color(0xFF66BB6A),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Logo ferme ────────────────────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -8 * _floatAnim.value),
        child: child,
      ),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Anneau extérieur tournant
              AnimatedBuilder(
                animation: _rotateAnim,
                builder: (_, __) => Transform.rotate(
                  angle: _rotateAnim.value * 2 * pi,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.transparent,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _DashedCirclePainter(
                          color: const Color(0xFF4CAF50).withOpacity(0.25)),
                    ),
                  ),
                ),
              ),
              // Cercle principal
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF2E5E1E), Color(0xFF0F2A0A)],
                    center: Alignment(-0.3, -0.3),
                  ),
                  border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32)
                          .withOpacity(0.3 + 0.15 * _pulseAnim.value),
                      blurRadius: 30 + 12 * _pulseAnim.value,
                      spreadRadius: 2 + 4 * _pulseAnim.value,
                    ),
                    const BoxShadow(
                      color: Color(0xFF000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🏡', style: TextStyle(fontSize: 50)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Titre ─────────────────────────────────────────────────
  Widget _buildTitle() {
    return SlideTransition(
      position: _titleSlide,
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFA5D6A7),
                Color(0xFF4CAF50),
                Color(0xFF81C784)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'Ferme Intelligente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.05,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 30,
                  height: 1,
                  color: const Color(0xFF4CAF50).withOpacity(0.4)),
              const SizedBox(width: 10),
              Text(
                'AGRICULTURE & ÉLEVAGE CONNECTÉS',
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFF4CAF50).withOpacity(0.7),
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                  width: 30,
                  height: 1,
                  color: const Color(0xFF4CAF50).withOpacity(0.4)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sous-titre ────────────────────────────────────────────
  Widget _buildSubtitle() {
    return SlideTransition(
      position: _subtitleSlide,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1F0D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.18), width: 1),
        ),
        child: Text(
          'Gérez vos cultures, votre bétail, l\'irrigation et le stockage '
          'depuis un seul tableau de bord intelligent, partout et à tout moment.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.62),
            height: 1.75,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  // ── Bande animaux ─────────────────────────────────────────
  Widget _buildAnimalBand() {
    final animals = [
      _AnimalItem('🐄', 'Bovins', '48'),
      _AnimalItem('🐑', 'Ovins', '120'),
      _AnimalItem('🐓', 'Volailles', '340'),
      _AnimalItem('🐖', 'Porcins', '72'),
    ];

    return FadeTransition(
      opacity: _cardsFade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('🐾', 'CHEPTEL ACTIF'),
          const SizedBox(height: 12),
          Row(
            children: animals
                .map((a) => Expanded(child: _buildAnimalChip(a)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalChip(_AnimalItem a) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D200D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF2E5E1E).withOpacity(0.6), width: 1),
      ),
      child: Column(
        children: [
          Text(a.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            a.count,
            style: const TextStyle(
              color: Color(0xFF81C784),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            a.name,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Cartes fonctionnalités ────────────────────────────────
  Widget _buildFeatureCards() {
    final features = [
      _FeatureItem(
        emoji: '🌾',
        title: 'Cultures & Récoltes',
        desc: 'Suivi des parcelles, semis et alertes de récolte par saison',
        color: const Color(0xFF66BB6A),
      ),
      _FeatureItem(
        emoji: '🐄',
        title: 'Élevage & Bétail',
        desc: 'Santé animale, alimentation et suivi du troupeau en direct',
        color: const Color(0xFFFFB300),
      ),
      _FeatureItem(
        emoji: '💧',
        title: 'Irrigation & Eau',
        desc: 'Arrosage automatique selon humidité du sol et météo locale',
        color: const Color(0xFF29B6F6),
      ),
      _FeatureItem(
        emoji: '🌡️',
        title: 'Climat & Environnement',
        desc: 'Température, vent et conditions optimales pour la ferme',
        color: const Color(0xFFFF7043),
      ),
    ];

    return SlideTransition(
      position: _cardsSlide,
      child: FadeTransition(
        opacity: _cardsFade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('⚙️', 'MODULES DE GESTION'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.98,
              ),
              itemCount: features.length,
              itemBuilder: (_, i) => _buildFeatureCard(features[i], i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + index * 120),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1A0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: item.color.withOpacity(0.22), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icône avec accent coloré
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                    border:
                        Border.all(color: item.color.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(item.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    )),
                const SizedBox(height: 5),
                Text(item.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      height: 1.45,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    return FadeTransition(
      opacity: _cardsFade,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1A0A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.04),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('12', 'Parcelles', '🌿'),
            _divider(),
            _statItem('580', 'Animaux', '🐾'),
            _divider(),
            _statItem('+32%', 'Rendement', '📈'),
            _divider(),
            _statItem('24/7', 'Monitoring', '🔍'),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String emoji, String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.45),
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _statItem(String value, String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
              color: Color(0xFF81C784),
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }

  Widget _divider() => Container(
      width: 1, height: 44, color: Colors.white.withOpacity(0.07));

  // ── Bouton CTA ────────────────────────────────────────────
  Widget _buildCTAButton() {
    return SlideTransition(
      position: _btnSlide,
      child: Column(
        children: [
          GestureDetector(
            onTap: _goToDashboard,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) {
                return Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF4CAF50)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(
                            0.28 + 0.16 * _pulseAnim.value),
                        blurRadius: 24 + 10 * _pulseAnim.value,
                        offset: const Offset(0, 8),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Effet brillant
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.agriculture_rounded,
                                color: Colors.white, size: 22),
                            SizedBox(width: 12),
                            Text(
                              'Accéder au Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.09)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Cultures · Bétail · Irrigation · Stockage',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────
  Widget _buildFooter() {
    return Text(
      'Gérez votre ferme intelligemment — partout, tout le temps',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withOpacity(0.18),
        fontSize: 11,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────
class _FeatureItem {
  final String emoji, title, desc;
  final Color color;
  const _FeatureItem(
      {required this.emoji,
      required this.title,
      required this.desc,
      required this.color});
}

class _AnimalItem {
  final String emoji, name, count;
  const _AnimalItem(this.emoji, this.name, this.count);
}

// ── Fond organique ────────────────────────────────────────────
class _FarmBackgroundPainter extends CustomPainter {
  final double t;
  _FarmBackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Fond de base
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF06100A));

    // Cercles lumineux
    final circles = [
      _Circle(0.12, 0.08, 180, const Color(0xFF1B4D1B), 0.20),
      _Circle(0.88, 0.22, 140, const Color(0xFF2E7D32), 0.13),
      _Circle(0.5, 0.50, 220, const Color(0xFF163916), 0.11),
      _Circle(0.08, 0.78, 110, const Color(0xFF4CAF50), 0.07),
      _Circle(0.92, 0.82, 150, const Color(0xFF1B5E20), 0.09),
      _Circle(0.75, 0.60, 100, const Color(0xFF33691E), 0.08),
    ];

    for (final c in circles) {
      final dy = sin(t * pi + c.phase) * 12;
      canvas.drawCircle(
        Offset(size.width * c.x, size.height * c.y + dy),
        c.radius,
        Paint()
          ..color = c.color.withOpacity(c.opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70),
      );
    }

    // Grille fine
    final gridPaint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.028)
      ..strokeWidth = 0.8;
    const spacing = 38.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Points décoratifs aux intersections
    final dotPaint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.06);
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_FarmBackgroundPainter old) => old.t != t;
}

// ── Cercle en pointillés ─────────────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    const dashCount = 24;
    const dashAngle = 2 * pi / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final endAngle = startAngle + dashAngle * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

class _Circle {
  final double x, y, radius, opacity;
  final double phase;
  final Color color;
  const _Circle(this.x, this.y, this.radius, this.color, this.opacity,
      [this.phase = 0]);
}