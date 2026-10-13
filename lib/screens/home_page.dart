import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';
import '../widgets/prime_header.dart';
import '../widgets/prime_featured_carousel.dart';
import '../widgets/movie_row.dart';
import '../widgets/custom_title_dialog.dart';
import '../widgets/simple_category_dialog.dart';
import 'detalhes_page.dart';

/// Tela principal da réplica do Amazon Prime Video
/// Conforme especificado nas páginas 1 a 8 do PDF da Atividade Integradora (IFRO)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Núcleo da consulta TMDB conforme trecho exato da Página 5 do PDF:
  static const token = String.fromEnvironment('TMDB_TOKEN');
  final List<Map<String, dynamic>> catalogo = [];

  bool _carregandoApi = false;
  String? _categoriaAtiva;

  @override
  void initState() {
    super.initState();
    _inicializarCatalogo();
  }

  /// Inicializa o catálogo com os títulos requeridos e tenta sincronizar via TMDB HTTP GET
  void _inicializarCatalogo() {
    final seed = TmdbService.obterCatalogoInicial();

    // Preserva favoritos e lembretes já definidos pelo usuário (ex.: ao puxar para atualizar)
    final estadoUsuario = <String, Map<String, dynamic>>{
      for (final item in catalogo)
        '${item['tipo']}/${item['id']}': {
          'favorito': item['favorito'],
          'lembrete': item['lembrete'],
          'dataLembrete': item['dataLembrete'],
          'horaLembrete': item['horaLembrete'],
        },
    };

    catalogo.clear();
    catalogo.addAll(seed);

    for (final item in catalogo) {
      final salvo = estadoUsuario['${item['tipo']}/${item['id']}'];
      if (salvo != null) item.addAll(salvo);
    }

    // Se houver token do ambiente ou se o usuário configurar em tempo de execução, carrega via API
    if (token.isNotEmpty || TmdbService.activeToken.isNotEmpty) {
      _carregarTitulosDaApi();
    }
  }

  /// Função de carregamento requerida pela Página 5 do PDF:
  /// "Inicie as chamadas em initState ou em uma função de carregamento, uma vez por obra."
  Future<void> carregarTitulo(String tipo, int id) async {
    final tokenAtivo = TmdbService.activeToken;
    if (tokenAtivo.isEmpty) return;

    try {
      final uri = Uri.https('api.themoviedb.org', '/3/$tipo/$id', {
        'language': 'pt-BR',
      });
      final resposta = await http
          .get(uri, headers: {'Authorization': 'Bearer $tokenAtivo'})
          .timeout(const Duration(seconds: 5));

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);
        final poster = dados['poster_path'];
        final fundo = dados['backdrop_path'];
        if (!mounted) return;

        // Atualiza a obra correspondente no catálogo com os dados oficiais da API
        final index = catalogo.indexWhere(
          (item) => item['id'] == id && item['tipo'] == tipo,
        );
        if (index != -1) {
          setState(() {
            catalogo[index]['titulo'] =
                dados['title'] ?? dados['name'] ?? catalogo[index]['titulo'];
            catalogo[index]['sinopse'] =
                dados['overview'] ?? catalogo[index]['sinopse'];
            if (poster != null) {
              catalogo[index]['capaUrl'] =
                  'https://image.tmdb.org/t/p/w500$poster';
            }
            if (fundo != null) {
              catalogo[index]['bannerUrl'] =
                  'https://image.tmdb.org/t/p/w780$fundo';
            }
          });
        }
      }
    } catch (_) {
      // Em caso de falha de conexão ou timeout, mantém os dados pré-carregados
    }
  }

  Future<void> _carregarTitulosDaApi() async {
    setState(() => _carregandoApi = true);
    for (final item in List<Map<String, dynamic>>.from(catalogo)) {
      final id = item['id'];
      final tipo = item['tipo'] as String?;
      if (id is int && tipo != null && (tipo == 'movie' || tipo == 'tv')) {
        await carregarTitulo(tipo, id);
      }
    }
    if (mounted) {
      setState(() => _carregandoApi = false);
    }
  }

  /// Copia o lembrete de uma obra para as demais entradas do catálogo com o mesmo id/tipo
  /// (ex.: "Elle" aparece nos destaques e em "Continuar assistindo").
  void _sincronizarLembrete(Map<String, dynamic> origem) {
    for (final outro in catalogo) {
      if (identical(outro, origem)) continue;
      if (outro['id'] == origem['id'] && outro['tipo'] == origem['tipo']) {
        outro['lembrete'] = origem['lembrete'];
        outro['dataLembrete'] = origem['dataLembrete'];
        outro['horaLembrete'] = origem['horaLembrete'];
      }
    }
  }

  /// Converte "dd/mm/aaaa às hh:mm" em DateTime (usado para ordenar a lista)
  DateTime? _dataDoLembrete(String? texto) {
    if (texto == null) return null;
    final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4}) às (\d{2}):(\d{2})$')
        .firstMatch(texto);
    if (m == null) return null;
    return DateTime(
      int.parse(m[3]!),
      int.parse(m[2]!),
      int.parse(m[1]!),
      int.parse(m[4]!),
      int.parse(m[5]!),
    );
  }

  /// Títulos com lembrete definido (sem repetições), do mais próximo ao mais distante
  List<Map<String, dynamic>> _titulosParaAssistirMaisTarde() {
    final vistos = <String>{};
    final lista = <Map<String, dynamic>>[];
    for (final item in catalogo) {
      final lembrete = item['lembrete'];
      if (lembrete is! String || lembrete.isEmpty) continue;
      if (!vistos.add('${item['tipo']}/${item['id']}')) continue;
      lista.add(item);
    }
    lista.sort((a, b) {
      final da = _dataDoLembrete(a['lembrete'] as String?);
      final db = _dataDoLembrete(b['lembrete'] as String?);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return lista;
  }

  /// Navegação para Detalhes com passagem de parâmetros (Página 6 do PDF)
  void _abrirDetalhes(Map<String, dynamic> item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalhesPage(item: item)),
    );
    // Atualiza o estado da tela principal ao retornar (favoritos, lembretes, etc.)
    if (mounted) {
      _sincronizarLembrete(item);
      setState(() {});
    }
  }

  /// Exibe o Custom Dialog (Página 7 do PDF)
  void _abrirCustomDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => CustomTitleDialog(
        item: item,
        onToggleFavorito: (fav) {
          setState(() {
            item['favorito'] = fav;
          });
        },
        onDefinirLembrete: (data, hora) {
          final dataStr =
              '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
          final horaStr =
              '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
          setState(() {
            item['dataLembrete'] = dataStr;
            item['horaLembrete'] = horaStr;
            item['lembrete'] = '$dataStr às $horaStr';
            _sincronizarLembrete(item);
          });
        },
        onAbrirDetalhes: () => _abrirDetalhes(item),
      ),
    );
  }

  /// Exibe o SimpleDialog de Categorias e Menu (Página 7 do PDF)
  void _abrirMenuCategorias() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleCategoryDialog(
        categoriaSelecionada: _categoriaAtiva,
        onSelecionarCategoria: (categoriaId) {
          setState(() {
            _categoriaAtiva = categoriaId;
          });
        },
        onAbrirSobre: _abrirSobreDialog,
        onConfigurarToken: _abrirConfigurarTokenDialog,
      ),
    );
  }

  /// Exibe o showAboutDialog com dados acadêmicos e TMDB (Página 7 e 8 do PDF)
  void _abrirSobreDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Amazon Prime Video (Réplica)',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.movie_creation,
          color: AppTheme.primeBlue,
          size: 36,
        ),
      ),
      applicationLegalese: 'Réplica acadêmica para estudo de Flutter\nIFRO - Campus Ariquemes | ADS\nProf. Me. Andrey Alencar Quadros\nEstudante: Programação Mobile',
      children: [
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(Icons.verified, size: 16, color: AppTheme.primeBlue),
                  SizedBox(width: 6),
                  Text(
                    'Aviso de atribuição da TMDB',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Recursos avaliados: Passagem de parâmetros, HTTP GET (TMDB), 6 Dialogs (Custom, SimpleDialog, AlertDialog, AboutDialog, DatePicker, TimePicker) e url_launcher.',
          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  /// Diálogo para configurar Token TMDB em tempo de execução
  void _abrirConfigurarTokenDialog() {
    final textController = TextEditingController(text: TmdbService.activeToken);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: AppTheme.primeBlue, size: 22),
            SizedBox(width: 8),
            Text('Token da API TMDB'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insira seu API Read Access Token do TMDB para consultar dados em tempo real ou execute com:\nflutter run --dart-define=TMDB_TOKEN=SEU_TOKEN',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Cole seu Bearer Token aqui...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.white30),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 12, color: Colors.white),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              TmdbService.runtimeToken = textController.text.trim();
              if (TmdbService.runtimeToken.isNotEmpty) {
                _carregarTitulosDaApi();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Token TMDB atualizado! Recarregando obras...',
                    ),
                  ),
                );
              }
            },
            child: const Text('Salvar e Sincronizar'),
          ),
        ],
      ),
    );
  }

  /// Diálogo interativo de busca de títulos
  void _abrirDialogoBusca() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String busca = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final resultados = busca.isEmpty
                ? <Map<String, dynamic>>[]
                : catalogo
                      .where(
                        (item) => (item['titulo'] as String? ?? '')
                            .toLowerCase()
                            .contains(busca.toLowerCase()),
                      )
                      .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.primeBlue,
                      ),
                      hintText: 'Buscar filmes, séries ou programas...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() => busca = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (busca.isNotEmpty && resultados.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Nenhum título encontrado.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  if (resultados.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: resultados.length,
                        itemBuilder: (context, idx) {
                          final res = resultados[idx];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: res['capaUrl'] != null
                                  ? Image.network(
                                      res['capaUrl'],
                                      width: 40,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 40,
                                      height: 60,
                                      color: AppTheme.surfaceLight,
                                    ),
                            ),
                            title: Text(
                              res['titulo'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              res['subtitulo'] ?? '',
                              style: const TextStyle(
                                color: AppTheme.primeBlue,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _abrirDetalhes(res);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Lista vertical "Assistir mais tarde": cada título mostra a data e o horário agendados;
  /// ao tocar, abre a tela de detalhes (que também exibe o lembrete).
  Widget _buildListaAssistirMaisTarde(List<Map<String, dynamic>> itens) {
    if (itens.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'Nenhum título agendado ainda.\nUse a opção "Mais tarde" em qualquer obra para agendar!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(
              'Assistir mais tarde',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final item in itens) _buildCardAssistirMaisTarde(item),
        ],
      ),
    );
  }

  Widget _buildCardAssistirMaisTarde(Map<String, dynamic> item) {
    final imagem = (item['bannerUrl'] ?? item['capaUrl']) as String?;
    final titulo = item['titulo'] as String? ?? 'Sem título';
    final lembrete = item['lembrete'] as String? ?? '';

    Widget placeholder() => Container(
      color: AppTheme.surfaceLight,
      child: const Icon(Icons.movie, color: Colors.white24),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _abrirDetalhes(item),
          onLongPress: () => _abrirCustomDialog(item),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 120,
                    height: 68,
                    child: imagem != null && imagem.isNotEmpty
                        ? Image.network(
                            imagem,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => placeholder(),
                          )
                        : placeholder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.alarm_on,
                            size: 14,
                            color: AppTheme.primeBlue,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              lembrete,
                              style: const TextStyle(
                                color: AppTheme.primeBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Destaques principais (4 títulos solicitados pelo usuário)
    final destaques = catalogo
        .where((item) => item['secao'] == 'destaque')
        .toList();

    // 2. Fileira "Continuar assistindo"
    final continuarAssistindo = catalogo
        .where((item) => item['secao'] == 'continuar_assistindo')
        .toList();

    // 3. Fileira "Filmes infantis e para toda a família"
    final infantilFamilia = catalogo
        .where((item) => item['secao'] == 'infantil_familia')
        .toList();

    // 4. Fileira "Ao vivo"
    final aoVivo = catalogo
        .where((item) => item['secao'] == 'ao_vivo')
        .toList();

    // 5. Fileira "Filmes de drama"
    final drama = catalogo.where((item) => item['secao'] == 'drama').toList();

    // Filtro por categoria caso o usuário tenha selecionado no SimpleDialog
    final bool filtrarContinuar =
        _categoriaAtiva == null || _categoriaAtiva == 'continuar_assistindo';
    final bool filtrarInfantil =
        _categoriaAtiva == null || _categoriaAtiva == 'infantil_familia';
    final bool filtrarAoVivo =
        _categoriaAtiva == null || _categoriaAtiva == 'ao_vivo';
    final bool filtrarDrama =
        _categoriaAtiva == null || _categoriaAtiva == 'drama';
    final bool filtrarFavoritos = _categoriaAtiva == 'favoritos';
    final bool filtrarMaisTarde = _categoriaAtiva == 'assistir_mais_tarde';

    final favoritos = catalogo
        .where((item) => item['favorito'] == true)
        .toList();
    final maisTarde = _titulosParaAssistirMaisTarde();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PrimeHeader(
        onMenuPressed: _abrirMenuCategorias,
        onSearchPressed: _abrirDialogoBusca,
        onProfilePressed: _abrirSobreDialog,
        categoriaAtiva: _categoriaAtiva != null
            ? (_categoriaAtiva == 'assistir_mais_tarde'
                  ? 'Assistir mais tarde'
                  : _categoriaAtiva == 'continuar_assistindo'
                  ? 'Continuar assistindo'
                  : _categoriaAtiva == 'infantil_familia'
                  ? 'Infantis e Família'
                  : _categoriaAtiva == 'ao_vivo'
                  ? 'Ao vivo'
                  : _categoriaAtiva == 'drama'
                  ? 'Drama'
                  : 'Meus Favoritos')
            : null,
        onLimparFiltro: () => setState(() => _categoriaAtiva = null),
      ),
      body: Center(
        // Centraliza e mantém proporções harmônicas semelhantes ao print mobile (958 × 1808)
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: RefreshIndicator(
            color: AppTheme.primeBlue,
            backgroundColor: AppTheme.surface,
            onRefresh: () async {
              _inicializarCatalogo();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de sincronização com API TMDB (se ativo)
                  if (_carregandoApi)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: AppTheme.primeBlueDark,
                      child: const Center(
                        child: Text(
                          'Sincronizando capas via API TMDB...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // CARROSSEL DE DESTAQUE PRINCIPAL
                  // Exibe exatamente os 4 títulos pedidos:
                  // 'Um Amor Diferente do Seu', 'Interestelar', 'Elle', 'Homem-Aranha: Um Novo Dia'
                  if (_categoriaAtiva == null)
                    PrimeFeaturedCarousel(
                      items: destaques,
                      onTap: _abrirDetalhes,
                      onLongPress: _abrirCustomDialog,
                    ),

                  const SizedBox(height: 8),

                  // LISTA "ASSISTIR MAIS TARDE" (títulos com data e horário agendados)
                  if (filtrarMaisTarde) _buildListaAssistirMaisTarde(maisTarde),

                  // FILEIRA DE FAVORITOS (Se filtrado por Favoritos)
                  if (filtrarFavoritos)
                    if (favoritos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'Nenhum título favoritado ainda.\nToque em qualquer obra para favoritar!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                      )
                    else
                      MovieRow(
                        tituloSecao: 'Meus Favoritos',
                        items: favoritos,
                        onItemTap: _abrirDetalhes,
                        onItemLongPress: _abrirCustomDialog,
                      ),

                  // FILEIRA 1: CONTINUAR ASSISTINDO (Print da Página 2)
                  if (filtrarContinuar && !filtrarFavoritos)
                    MovieRow(
                      tituloSecao: 'Continuar assistindo',
                      items: continuarAssistindo,
                      cardWidth: 145,
                      cardHeight: 88,
                      onItemTap: _abrirDetalhes,
                      onItemLongPress: _abrirCustomDialog,
                    ),

                  // FILEIRA 2: FILMES INFANTIS E PARA TODA A FAMÍLIA (Print da Página 2)
                  if (filtrarInfantil && !filtrarFavoritos)
                    MovieRow(
                      tituloSecao: 'Filmes infantis e para toda a família',
                      temVejaMais: true,
                      onVejaMais: () =>
                          setState(() => _categoriaAtiva = 'infantil_familia'),
                      items: infantilFamilia,
                      cardWidth: 145,
                      cardHeight: 88,
                      onItemTap: _abrirDetalhes,
                      onItemLongPress: _abrirCustomDialog,
                    ),

                  // FILEIRA 3: AO VIVO (Print da Página 2)
                  if (filtrarAoVivo && !filtrarFavoritos)
                    MovieRow(
                      tituloSecao: 'Ao vivo',
                      items: aoVivo,
                      cardWidth: 145,
                      cardHeight: 88,
                      isLiveRow: true,
                      onItemTap: _abrirDetalhes,
                      onItemLongPress: _abrirCustomDialog,
                    ),

                  // FILEIRA 4: FILMES DE DRAMA (Print da Página 2)
                  if (filtrarDrama && !filtrarFavoritos)
                    MovieRow(
                      tituloSecao: 'Filmes de drama',
                      temVejaMais: true,
                      onVejaMais: () =>
                          setState(() => _categoriaAtiva = 'drama'),
                      items: drama,
                      cardWidth: 145,
                      cardHeight: 88,
                      onItemTap: _abrirDetalhes,
                      onItemLongPress: _abrirCustomDialog,
                    ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
