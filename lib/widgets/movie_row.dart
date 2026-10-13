import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';

/// Fileira horizontal de títulos no padrão Amazon Prime Video
/// Implementa ListView.builder horizontal delimitado por SizedBox, conforme página 4 do PDF.
class MovieRow extends StatelessWidget {
  final String tituloSecao;
  final bool temVejaMais;
  final VoidCallback? onVejaMais;
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onItemTap;
  final Function(Map<String, dynamic>) onItemLongPress;
  final double cardWidth;
  final double cardHeight;
  final bool isLiveRow;

  const MovieRow({
    super.key,
    required this.tituloSecao,
    this.temVejaMais = false,
    this.onVejaMais,
    required this.items,
    required this.onItemTap,
    required this.onItemLongPress,
    this.cardWidth = 145,
    this.cardHeight = 90,
    this.isLiveRow = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Altura total incluindo textos de canais abaixo caso seja a fileira Ao Vivo
    final double alturaContainer = isLiveRow ? cardHeight + 34 : cardHeight + 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da fileira
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                tituloSecao,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              if (temVejaMais)
                GestureDetector(
                  onTap: onVejaMais,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Veja mais',
                        style: TextStyle(
                          color: AppTheme.primeBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        color: AppTheme.primeBlue,
                        size: 16,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Lista horizontal conforme especificado no PDF (ListView.builder com SizedBox)
        SizedBox(
          height: alturaContainer,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildCard(context, item);
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> item) {
    final capaUrl = item['bannerUrl'] ?? item['capaUrl'];
    final badge = item['badge'] as String? ?? 'prime';
    final tag = item['tag'] as String?;
    final progresso = (item['progresso'] as num?)?.toDouble();
    final isLive = item['isLive'] == true;
    final canalNome = item['canalNome'] as String?;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cartaz clicável
          GestureDetector(
            onTap: () => onItemTap(item),
            onLongPress: () => onItemLongPress(item),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  // Capa / Imagem da obra
                  Container(
                    width: cardWidth,
                    height: cardHeight,
                    color: AppTheme.surfaceLight,
                    child: capaUrl != null && (capaUrl as String).isNotEmpty
                        ? Image.network(
                            capaUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildPlaceholder(),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return _buildPlaceholder(loading: true);
                            },
                          )
                        : _buildPlaceholder(),
                  ),

                  // Gradiente sutil inferior no card
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Tag especial (ex: "EM ALTA", "MAIS CURTIDO")
                  if (tag != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                  // Tag "AO VIVO" vermelha no topo direito (conforme print)
                  if (isLive)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.liveRed,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'AO VIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                  // Selo do canal / Prime no canto inferior direito (conforme print)
                  Positioned(
                    bottom: progresso != null ? 7 : 4,
                    right: 6,
                    child: _buildBadge(badge),
                  ),

                  // Barra de progresso para a seção "Continuar assistindo"
                  if (progresso != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 3,
                        color: AppTheme.progressBackground,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progresso.clamp(0.0, 1.0),
                          child: Container(
                            color: AppTheme.primeBlue,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Título do canal na fileira "Ao vivo"
          if (isLiveRow && canalNome != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 2.0),
              child: Text(
                canalNome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String badge) {
    if (badge == 'canais globo') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.trip_origin, size: 9, color: Colors.white),
            SizedBox(width: 3),
            Text(
              'canais globo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Badge Prime
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'prime',
        style: TextStyle(
          color: AppTheme.primeBlue,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildPlaceholder({bool loading = false}) {
    if (loading) {
      return Container(
        color: AppTheme.surfaceLight,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primeBlue,
            ),
          ),
        ),
      );
    }
    return Image.network(
      TmdbService.defaultFallbackPoster,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppTheme.surfaceLight,
        child: const Center(
          child: Icon(Icons.movie, size: 24, color: Colors.white24),
        ),
      ),
    );
  }
}
