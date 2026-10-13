import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Diálogo do tipo SimpleDialog com SimpleDialogOption conforme página 7 do PDF:
/// "SimpleDialog: No Menu ou Navegar, escolher uma das categorias já existentes
/// no catálogo. Use SimpleDialogOption. Resultado esperado: Mostrar a categoria ativa
/// e os itens correspondentes."
class SimpleCategoryDialog extends StatelessWidget {
  final String? categoriaSelecionada;
  final Function(String? categoria) onSelecionarCategoria;
  final VoidCallback onAbrirSobre;
  final VoidCallback onConfigurarToken;

  const SimpleCategoryDialog({
    super.key,
    required this.categoriaSelecionada,
    required this.onSelecionarCategoria,
    required this.onAbrirSobre,
    required this.onConfigurarToken,
  });

  static const List<Map<String, dynamic>> categorias = [
    {
      'id': null,
      'nome': 'Todos os títulos',
      'icone': Icons.apps,
      'descricao': 'Exibir o catálogo completo e todas as fileiras',
    },
    {
      'id': 'assistir_mais_tarde',
      'nome': 'Assistir Mais Tarde',
      'icone': Icons.schedule,
      'descricao': 'Títulos com lembrete agendado (data e horário)',
    },
    {
      'id': 'continuar_assistindo',
      'nome': 'Continuar assistindo',
      'icone': Icons.play_circle_outline,
      'descricao': 'Títulos em andamento',
    },
    {
      'id': 'infantil_familia',
      'nome': 'Filmes infantis e para toda a família',
      'icone': Icons.child_care,
      'descricao': 'Animações e diversão para todas as idades',
    },
    {
      'id': 'ao_vivo',
      'nome': 'Ao vivo',
      'icone': Icons.live_tv,
      'descricao': 'Transmissões esportivas e canais de notícias',
    },
    {
      'id': 'drama',
      'nome': 'Filmes de drama',
      'icone': Icons.theater_comedy,
      'descricao': 'Obras aclamadas e premiadas pela crítica',
    },
    {
      'id': 'favoritos',
      'nome': 'Meus Favoritos',
      'icone': Icons.favorite,
      'descricao': 'Títulos salvos na sua lista pessoal',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: AppTheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      title: Row(
        children: const [
          Icon(Icons.category_outlined, color: AppTheme.primeBlue, size: 22),
          SizedBox(width: 10),
          Text(
            'Navegar por Categoria',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      children: [
        ...categorias.map((cat) {
          final id = cat['id'] as String?;
          final nome = cat['nome'] as String;
          final icone = cat['icone'] as IconData;
          final descricao = cat['descricao'] as String;
          final selecionada = categoriaSelecionada == id;

          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              onSelecionarCategoria(id);
            },
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selecionada ? AppTheme.primeBlue.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: selecionada
                    ? Border.all(color: AppTheme.primeBlue.withValues(alpha: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icone,
                    size: 20,
                    color: selecionada ? AppTheme.primeBlue : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selecionada ? FontWeight.bold : FontWeight.w500,
                            color: selecionada ? AppTheme.primeBlue : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          descricao,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selecionada)
                    const Icon(Icons.check, size: 18, color: AppTheme.primeBlue),
                ],
              ),
            ),
          );
        }),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Divider(color: Color(0xFF334155), height: 1),
        ),

        // Opção do Menu: Configurar Token TMDB
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            onConfigurarToken();
          },
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: const [
              Icon(Icons.key, size: 20, color: Color(0xFF10B981)),
              SizedBox(width: 12),
              Text(
                'Configurar Token TMDB',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),

        // Opção do Menu: Sobre o Aplicativo (showAboutDialog)
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            onAbrirSobre();
          },
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: const [
              Icon(Icons.info_outline, size: 20, color: AppTheme.primeBlue),
              SizedBox(width: 12),
              Text(
                'Sobre o Aplicativo (Créditos)',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
