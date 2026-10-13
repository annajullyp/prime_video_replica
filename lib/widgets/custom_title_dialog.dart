import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';

/// "Custom • Dialog: Nas opções do título, mostrar capa, nome e ações
/// Favoritar e Assistir mais tarde em um layout próprio. Executar a ação no título correto."
class CustomTitleDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(bool isFavorito) onToggleFavorito;
  final Function(DateTime data, TimeOfDay hora) onDefinirLembrete;
  final VoidCallback onAbrirDetalhes;

  const CustomTitleDialog({
    super.key,
    required this.item,
    required this.onToggleFavorito,
    required this.onDefinirLembrete,
    required this.onAbrirDetalhes,
  });

  @override
  State<CustomTitleDialog> createState() => _CustomTitleDialogState();
}

class _CustomTitleDialogState extends State<CustomTitleDialog> {
  late bool _favorito;
  String? _lembrete;

  @override
  void initState() {
    super.initState();
    _favorito = widget.item['favorito'] == true;
    _lembrete = widget.item['lembrete'] as String?;
  }

  Future<void> _gerenciarFavorito() async {
    if (_favorito) {
      // AlertDialog ao retirar título dos favoritos
      final confirmarRemocao = await showDialog<bool>(
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

      if (!mounted || confirmarRemocao != true) return;
      setState(() => _favorito = false);
      widget.onToggleFavorito(false);
    } else {
      setState(() => _favorito = true);
      widget.onToggleFavorito(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${widget.item['titulo']}" adicionado aos favoritos!',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _escolherDataEHora() async {
    // DatePicker a partir de hoje
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'ESCOLHA O DIA PARA ASSISTIR',
      cancelText: 'CANCELAR',
      confirmText: 'CONTINUAR',
    );

    if (!mounted || dataEscolhida == null) return;

    // TimePicker para escolher horário
    final horaEscolhida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'ESCOLHA O HORÁRIO',
      cancelText: 'CANCELAR',
      confirmText: 'DEFINIR',
    );

    if (!mounted || horaEscolhida == null) return;

    final dataStr =
        '${dataEscolhida.day.toString().padLeft(2, '0')}/${dataEscolhida.month.toString().padLeft(2, '0')}/${dataEscolhida.year}';
    final horaStr =
        '${horaEscolhida.hour.toString().padLeft(2, '0')}:${horaEscolhida.minute.toString().padLeft(2, '0')}';
    final dataFormatada = '$dataStr às $horaStr';

    widget.onDefinirLembrete(dataEscolhida, horaEscolhida);
    widget.item['dataLembrete'] = dataStr;
    widget.item['horaLembrete'] = horaStr;
    widget.item['lembrete'] = dataFormatada;

    setState(() {
      _lembrete = dataFormatada;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lembrete agendado para $dataFormatada'),
          backgroundColor: AppTheme.primeBlueDark,
        ),
      );
    }
  }

  Future<void> _abrirTrailer() async {
    final trailerUrl = widget.item['trailerUrl'] as String?;
    if (trailerUrl == null || trailerUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trailer não disponível no momento.')),
      );
      return;
    }

    final uri = Uri.parse(trailerUrl);
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!abriu) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Não foi possível abrir.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final capaUrl = widget.item['bannerUrl'] ?? widget.item['capaUrl'];
    final titulo = widget.item['titulo'] as String? ?? '';
    final subtitulo = widget.item['subtitulo'] as String? ?? '';
    final sinopse = widget.item['sinopse'] as String? ?? '';

    return Dialog(
      backgroundColor: AppTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagem da capa no topo do diálogo customizado
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: capaUrl != null
                        ? Image.network(
                            capaUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.network(
                              TmdbService.defaultFallbackBanner,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.network(
                            TmdbService.defaultFallbackBanner,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título e subtítulo
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (subtitulo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primeBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Sinopse resumida
                    Text(
                      sinopse,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),

                    if (_lembrete != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.primeBlue.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active,
                              size: 16,
                              color: AppTheme.primeBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lembrete: $_lembrete',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF334155), height: 1),
                    const SizedBox(height: 12),

                    // Ações requeridas pelo PDF
                    Row(
                      children: [
                        // Ação Favoritar
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _gerenciarFavorito,
                            icon: Icon(
                              _favorito ? Icons.check : Icons.add,
                              size: 18,
                              color: _favorito
                                  ? AppTheme.primeBlue
                                  : Colors.white,
                            ),
                            label: Text(
                              _favorito ? 'Favorito' : 'Favoritar',
                              style: TextStyle(
                                fontSize: 13,
                                color: _favorito
                                    ? AppTheme.primeBlue
                                    : Colors.white,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _favorito
                                    ? AppTheme.primeBlue
                                    : const Color(0xFF475569),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Ação Assistir mais tarde (Date Picker & Time Picker)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _escolherDataEHora,
                            icon: const Icon(
                              Icons.schedule,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Mais tarde',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF475569)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Botão Assistir Trailer (url_launcher)
                    ElevatedButton.icon(
                      onPressed: _abrirTrailer,
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('Assistir trailer'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Botão Ver detalhes completos
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onAbrirDetalhes();
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Ver todos os detalhes'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(38),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
