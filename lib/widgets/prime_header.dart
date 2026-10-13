import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Cabeçalho estilizado no padrão Amazon Prime Video
/// Contém o botão de Menu dropdown, o logotipo central com o sorriso do Prime,
/// e os botões de busca e perfil de usuário.
class PrimeHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onProfilePressed;
  final String? categoriaAtiva;
  final VoidCallback? onLimparFiltro;

  const PrimeHeader({
    super.key,
    required this.onMenuPressed,
    required this.onSearchPressed,
    required this.onProfilePressed,
    this.categoriaAtiva,
    this.onLimparFiltro,
  });

  @override
  Size get preferredSize => Size.fromHeight(categoriaAtiva != null ? 100 : 64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFF1E293B),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Row(
                children: [
                  // Menu com seta conforme o print ("Menu ⌵")
                  InkWell(
                    onTap: onMenuPressed,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                      child: Row(
                        children: const [
                          Text(
                            'Menu',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: AppTheme.textPrimary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Marca central "prime video" com o clássico sorriso
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'prime',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'video',
                            style: TextStyle(
                              color: AppTheme.primeBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      // Arco/Sorriso característico do Prime
                      CustomPaint(
                        size: const Size(42, 6),
                        painter: PrimeSmilePainter(),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Botão de Busca
                  IconButton(
                    onPressed: onSearchPressed,
                    icon: const Icon(
                      Icons.search,
                      color: AppTheme.textPrimary,
                      size: 22,
                    ),
                    tooltip: 'Buscar títulos',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),

                  const SizedBox(width: 6),

                  // Avatar de Perfil
                  GestureDetector(
                    onTap: onProfilePressed,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2563EB),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Faixa de categoria ativa (quando filtrado pelo SimpleDialog)
            if (categoriaAtiva != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppTheme.surfaceLight.withValues(alpha: 0.8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      size: 16,
                      color: AppTheme.primeBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Categoria: $categoriaAtiva',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (onLimparFiltro != null)
                      GestureDetector(
                        onTap: onLimparFiltro,
                        child: const Row(
                          children: [
                            Text(
                              'Mostrar tudo',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primeBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.close, size: 14, color: AppTheme.primeBlue),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Desenho vetorial do sorriso característico sob a palavra Prime
class PrimeSmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primeBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(2, 1);
    path.quadraticBezierTo(size.width * 0.5, size.height + 1, size.width - 2, 1);
    canvas.drawPath(path, paint);

    // Pequena seta na ponta direita
    final arrowPaint = Paint()
      ..color = AppTheme.primeBlue
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    arrowPath.moveTo(size.width - 3, 0);
    arrowPath.lineTo(size.width + 2, 2);
    arrowPath.lineTo(size.width - 1, 5);
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
