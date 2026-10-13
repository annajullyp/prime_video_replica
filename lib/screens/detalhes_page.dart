import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_title_dialog.dart';

/// Tela de Detalhes do Título conforme páginas 6, 7 e 8 do PDF.
/// Recebe o mapa carregado com id, tipo, título, sinopse e URLs das imagens.
class DetalhesPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const DetalhesPage({super.key, required this.item});

  @override
  State<DetalhesPage> createState() => _DetalhesPageState();
}

class _DetalhesPageState extends State<DetalhesPage> {
  late bool _favorito;
  String? _lembrete;

  @override
  void initState() {
    super.initState();
    _favorito = widget.item['favorito'] == true;
    _lembrete = widget.item['lembrete'] as String?;
  }

  /// Ação Assistir trailer requerida na página 8 do PDF com url_launcher
  Future<void> abrirTrailer() async {
    final trailer = widget.item['trailerUrl'] as String?;
    if (trailer == null || trailer.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trailer não disponível no momento.')),
      );
      return;
    }

    try {
      final uri = Uri.parse(trailer);
      final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!abriu) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Não foi possível abrir.')));
    }
  }

  /// Gerenciamento de favoritos com AlertDialog conforme página 7 do PDF
  Future<void> alternarFavorito() async {
    if (_favorito) {
      // AlertDialog ao retirar título dos favoritos
      final remover = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remover dos favoritos?'),
          content: Text(
            'Deseja retirar "${widget.item['titulo']}" da sua lista?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.liveRed),
              child: const Text('Remover'),
            ),
          ],
        ),
      );

      if (!mounted || remover != true) return;
      setState(() {
        _favorito = false;
        widget.item['favorito'] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${widget.item['titulo']}" removido dos favoritos.'),
          ),
        );
      }
    } else {
      setState(() {
        _favorito = true;
        widget.item['favorito'] = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${widget.item['titulo']}" adicionado aos favoritos!',
            ),
            backgroundColor: AppTheme.primeBlueDark,
          ),
        );
      }
    }
  }

  /// Assistir mais tarde com DatePicker e TimePicker conforme página 7 do PDF
  Future<void> agendarAssistirMaisTarde() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'ESCOLHA A DATA PARA ASSISTIR',
      cancelText: 'CANCELAR',
      confirmText: 'PRÓXIMO',
    );

    if (!mounted || dataEscolhida == null) return;

    final horaEscolhida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'ESCOLHA O HORÁRIO',
      cancelText: 'CANCELAR',
      confirmText: 'DEFINIR',
    );

    if (!mounted || horaEscolhida == null) return;

    final dataFormatada =
        '${dataEscolhida.day.toString().padLeft(2, '0')}/${dataEscolhida.month.toString().padLeft(2, '0')}/${dataEscolhida.year} às ${horaEscolhida.hour.toString().padLeft(2, '0')}:${horaEscolhida.minute.toString().padLeft(2, '0')}';

    setState(() {
      _lembrete = dataFormatada;
      widget.item['lembrete'] = dataFormatada;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lembrete salvo para $dataFormatada'),
          backgroundColor: AppTheme.primeBlueDark,
        ),
      );
    }
  }

  /// Abre o Custom Dialog diretamente a partir dos detalhes
  void _abrirCustomDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CustomTitleDialog(
        item: widget.item,
        onToggleFavorito: (fav) {
          setState(() {
            _favorito = fav;
            widget.item['favorito'] = fav;
          });
        },
        onDefinirLembrete: (data, hora) {
          final dataFormatada =
              '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
          setState(() {
            _lembrete = dataFormatada;
            widget.item['lembrete'] = dataFormatada;
          });
        },
        onAbrirDetalhes: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final titulo = item['titulo'] as String? ?? 'Sem título';
    final subtitulo = item['subtitulo'] as String? ?? '';
    final sinopse = (item['sinopse'] as String?)?.isNotEmpty == true
        ? item['sinopse'] as String
        : 'Sinopse não informada pelo serviço de metadados.';
    final bannerUrl = item['bannerUrl'] as String?;
    final capaUrl = item['capaUrl'] as String?;
    final imagemDestaque = bannerUrl ?? capaUrl;
    final classificacao = item['classificacao'] as String? ?? '14';
    final tipo = item['tipo'] == 'tv' ? 'Série' : 'Filme';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // AppBar expansível com a imagem do título
          SliverAppBar(
            expandedHeight: 260.0,
            pinned: true,
            backgroundColor: AppTheme.background,
            leading: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  tooltip: 'Mais opções',
                  onPressed: _abrirCustomDialog,
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imagemDestaque != null && imagemDestaque.isNotEmpty)
                    Image.network(
                      imagemDestaque,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppTheme.surfaceLight,
                        child: const Icon(
                          Icons.movie,
                          size: 64,
                          color: Colors.white24,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.surfaceLight,
                      child: const Icon(
                        Icons.movie,
                        size: 64,
                        color: Colors.white24,
                      ),
                    ),

                  // Gradiente inferior para mesclar com o corpo da página
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          AppTheme.background.withValues(alpha: 0.8),
                          AppTheme.background,
                        ],
                        stops: const [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                  ),

                  // Ícone de reprodução flutuante
                  Center(
                    child: GestureDetector(
                      onTap: abrirTrailer,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 2),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo e metadados do título
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selo Prime
                  Row(
                    children: [
                      const Text(
                        'prime',
                        style: TextStyle(
                          color: AppTheme.primeBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '• Incluído na sua assinatura',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Título principal
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),

                  if (subtitulo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: AppTheme.primeBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Metadados (Tipo, Classificação, Qualidade)
                  Row(
                    children: [
                      // Badge de classificação
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              classificacao.startsWith('A') ||
                                  classificacao == '18'
                              ? AppTheme.ratingA16
                              : const Color(0xFFEAB308),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          classificacao,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        tipo,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.textMuted),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'UHD',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.textMuted),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'HDR',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Botão principal: Assistir trailer com url_launcher (Página 8)
                  ElevatedButton.icon(
                    onPressed: abrirTrailer,
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text(
                      'Assistir trailer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primeBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Linha de ações secundárias (Favoritar, Assistir mais tarde, Opções)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Botão Favoritar
                      _buildAcaoIcone(
                        icone: _favorito ? Icons.check : Icons.add,
                        rotulo: _favorito ? 'Na lista' : 'Minha lista',
                        ativo: _favorito,
                        onTap: alternarFavorito,
                      ),

                      // Botão Assistir mais tarde (Date Picker + Time Picker)
                      _buildAcaoIcone(
                        icone: Icons.schedule,
                        rotulo: 'Mais tarde',
                        ativo: _lembrete != null,
                        onTap: agendarAssistirMaisTarde,
                      ),

                      // Botão de Opções / Custom Dialog
                      _buildAcaoIcone(
                        icone: Icons.dashboard_customize_outlined,
                        rotulo: 'Opções',
                        ativo: false,
                        onTap: _abrirCustomDialog,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Banner de lembrete ativo (conforme requisito da página 7)
                  if (_lembrete != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primeBlue.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.alarm_on,
                            color: AppTheme.primeBlue,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lembrete programado',
                                  style: TextStyle(
                                    color: AppTheme.primeBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Assistir em: $_lembrete',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                            tooltip: 'Remover lembrete',
                            onPressed: () {
                              setState(() {
                                _lembrete = null;
                                widget.item['lembrete'] = null;
                                widget.item['dataLembrete'] = null;
                                widget.item['horaLembrete'] = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  const Divider(color: Color(0xFF1E293B)),
                  const SizedBox(height: 8),

                  // Sinopse da obra
                  const Text(
                    'Sinopse',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sinopse,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Detalhes adicionais no estilo Prime Video
                  _buildLinhaInfo(
                    'Idiomas de áudio',
                    'Português (Brasil), Inglês',
                  ),
                  _buildLinhaInfo(
                    'Legendas',
                    'Português (Brasil) [CC], Inglês',
                  ),
                  _buildLinhaInfo('ID da obra (TMDB)', '${item['id']}'),
                  _buildLinhaInfo('Tipo de mídia', tipo),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcaoIcone({
    required IconData icone,
    required String rotulo,
    required bool ativo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ativo
                    ? AppTheme.primeBlue.withValues(alpha: 0.2)
                    : AppTheme.surfaceLight,
                border: Border.all(
                  color: ativo ? AppTheme.primeBlue : Colors.transparent,
                ),
              ),
              child: Icon(
                icone,
                color: ativo ? AppTheme.primeBlue : Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              rotulo,
              style: TextStyle(
                color: ativo ? AppTheme.primeBlue : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
