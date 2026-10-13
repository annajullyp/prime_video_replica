import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';
import 'prime_header.dart';

/// Carrossel de Destaques principais do Amazon Prime Video
/// Atende ao pedido explícito do usuário de exibir os 4 títulos solicitados:
/// 1. 'Um Amor Diferente do Seu'
/// 2. 'Interestelar'
/// 3. 'Elle'
/// 4. 'Homem-Aranha: Um Novo Dia'
class PrimeFeaturedCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onTap;
  final Function(Map<String, dynamic>)? onLongPress;

  const PrimeFeaturedCarousel({
    super.key,
    required this.items,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<PrimeFeaturedCarousel> createState() => _PrimeFeaturedCarouselState();
}

class _PrimeFeaturedCarouselState extends State<PrimeFeaturedCarousel> {
  late PageController _pageController;
  int _paginaAtual = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _irParaAnterior() {
    if (_paginaAtual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        widget.items.length - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _irParaProximo() {
    if (_paginaAtual < widget.items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primeBlue),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 10.5,
      child: Stack(
        children: [
          // Visualizador de Páginas com gesto de deslize
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() => _paginaAtual = index);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _buildSlide(item);
            },
          ),

          // Seta de navegação esquerda (<) do print
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _irParaAnterior,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          // Seta de navegação direita (>) do print
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _irParaProximo,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          // Indicadores de pontinhos (dots) no centro inferior
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (index) {
                final ativo = _paginaAtual == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: ativo ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: ativo
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> item) {
    final bannerUrl = item['bannerUrl'] as String?;
    final titulo = item['titulo'] as String? ?? '';
    final classificacao = item['classificacao'] as String? ?? '14';

    return GestureDetector(
      onTap: () => widget.onTap(item),
      onLongPress: () => widget.onLongPress?.call(item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem de fundo com fallback gracioso
          if (bannerUrl != null && bannerUrl.isNotEmpty)
            Image.network(
              bannerUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPlaceholder(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _buildPlaceholder(loading: true);
              },
            )
          else
            _buildPlaceholder(),

          // Gradientes para garantir legibilidade dos textos e estilo Prime
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  AppTheme.background.withValues(alpha: 0.7),
                  AppTheme.background,
                ],
                stops: const [0.0, 0.45, 0.8, 1.0],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppTheme.background.withValues(alpha: 0.75),
                  Colors.transparent,
                  AppTheme.background.withValues(alpha: 0.3),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Detalhes do print no destaque (prime com sorriso, título, "Incluído no Prime", selo A16)
          Positioned(
            left: 20,
            bottom: 26,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selo prime azul
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'prime',
                          style: TextStyle(
                            color: AppTheme.primeBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        CustomPaint(
                          size: const Size(36, 4),
                          painter: PrimeSmilePainter(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Título em destaque
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Indicador de "✓ Incluído no Prime" e Classificação indicativa
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppTheme.primeBlue,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Incluído no Prime',
                      style: TextStyle(
                        color: AppTheme.primeBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Badge de classificação etária
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            classificacao.startsWith('A') ||
                                classificacao == '18'
                            ? AppTheme.ratingA16
                            : const Color(0xFFEAB308),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        classificacao,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder({bool loading = false}) {
    if (loading) {
      return Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primeBlue,
            strokeWidth: 2,
          ),
        ),
      );
    }
    return Image.network(
      TmdbService.defaultFallbackBanner,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Icon(
            Icons.movie_creation_outlined,
            size: 48,
            color: Colors.white24,
          ),
        ),
      ),
    );
  }
}
