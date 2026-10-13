import 'dart:convert';

import 'package:http/http.dart' as http;

/// Serviço responsável pela integração com a API do TMDB (The Movie Database)
/// Conforme especificado na página 5 do PDF da atividade.
class TmdbService {
  /// Token de leitura do TMDB configurável via linha de comando:
  /// flutter run --dart-define=TMDB_TOKEN=SEU_TOKEN
  static const String envToken = String.fromEnvironment(
    'TMDB_TOKEN',
    defaultValue: '',
  );

  /// Permite também a definição dinâmica em tempo de execução via diálogo/configuração
  static String runtimeToken = '';

  static String get activeToken =>
      runtimeToken.isNotEmpty ? runtimeToken : envToken;

  /// Imagens padrão garantidas da API TMDB para fallback resiliente
  static const String defaultFallbackPoster =
      'https://image.tmdb.org/t/p/w500/iKgdhgBPi1cCRRqsUgaxUDRuFP6.jpg';
  static const String defaultFallbackBanner =
      'https://image.tmdb.org/t/p/w780/moUjiEzpJVNZc7hyNRBbLPt0CPX.jpg';

  /// Método oficial requerido pelo roteiro (página 5 do PDF):
  /// Consulta /3/{tipo}/{id} com language: pt-BR e Authorization Bearer
  static Future<Map<String, dynamic>?> buscarTituloApi(
    String tipo,
    int id,
  ) async {
    final token = activeToken;
    if (token.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.https('api.themoviedb.org', '/3/$tipo/$id', {
        'language': 'pt-BR',
      });

      final resposta = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);
        final poster = dados['poster_path'];
        final fundo = dados['backdrop_path'];

        return {
          'id': dados['id'],
          'tipo': tipo,
          'titulo': dados['title'] ?? dados['name'],
          'sinopse': dados['overview'] ?? '',
          'capaUrl': poster == null
              ? null
              : 'https://image.tmdb.org/t/p/w500$poster',
          'bannerUrl': fundo == null
              ? null
              : 'https://image.tmdb.org/t/p/w780$fundo',
        };
      }
    } catch (e) {
      // Falha na rede ou token inválido - o catálogo local manterá o app funcional
    }
    return null;
  }

  /// Catálogo inicial com semente fiel ao PDF e imagens 100% verificadas da API TMDB.
  /// Inclui os 4 destaques: 'Um Amor Diferente do Seu' (Dorama de 2026),
  /// 'Interestelar', 'Elle' e 'Homem-Aranha: Um Novo Dia'.
  static List<Map<String, dynamic>> obterCatalogoInicial() {
    return [
      // ==========================================
      // DESTAQUES PRINCIPAIS (Carrossel do Topo)
      // ==========================================
      {
        'id': 314939,
        'tipo': 'tv',
        'titulo': 'Um Amor Diferente do Seu',
        'subtitulo': 'Dorama Coreano • K-Drama (2026)',
        'ano': '2026',
        'elenco': 'Seo Kang-joon, Ahn Eun-jin, Lee Joo-ahn, Jo A-ram',
        'sinopse': 'Dorama romântico coreano lançado em 2026 no Prime Video. Namgoong Ho e Lee Mi-do estão juntos há dez anos desde os tempos de escola. Prestes a decidir o futuro da relação, eles enfrentam o desgaste da rotina, incertezas profissionais e sentimentos inesperados que colocam o amor e a convivência à prova.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/iKgdhgBPi1cCRRqsUgaxUDRuFP6.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/moUjiEzpJVNZc7hyNRBbLPt0CPX.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=zp62ID0bbQM',
        'secao': 'destaque',
        'classificacao': '14',
        'inPrime': true,
        'badge': 'prime',
        'favorito': false,
        'lembrete': '12/10/2026 às 21:00',
        'dataLembrete': '12/10/2026',
        'horaLembrete': '21:00',
      },
      {
        'id': 1184918,
        'tipo': 'movie',
        'titulo': 'Interestelar',
        'subtitulo': 'Ficção Científica / Espaço',
        'ano': '2026',
        'sinopse': 'Uma ameaça cósmica sem precedentes passa a devorar a radiação das estrelas mais próximas do Sistema Solar. Um grupo isolado de cientistas parte numa jornada interestelar desesperada para tentar salvar o futuro da Terra.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/xJHokMbljvjADYdit5fK5VQsXEG.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=zSWdZVtXT7E',
        'secao': 'destaque',
        'classificacao': '14',
        'inPrime': true,
        'badge': 'prime',
        'favorito': false,
        'lembrete': '15/10/2026 às 19:30',
        'dataLembrete': '15/10/2026',
        'horaLembrete': '19:30',
      },
      {
        'id': 337674,
        'tipo': 'movie',
        'titulo': 'Elle',
        'subtitulo': 'Suspense Psicológico / Drama',
        'ano': '2016',
        'sinopse': 'Michèle é diretora executiva de uma empresa de sucesso de videogames. Quando é violentamente atacada por um homem mascarado em sua casa, ela se recusa a ser intimidada e inicia um jogo perigoso de gato e rato para descobrir a identidade do agressor.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/z446adpGUVXXPxrLpKBGnYBcofk.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/5VApPDSRlONQV2gXugyz1yj7qZm.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=aG_XF0k4Cqo',
        'secao': 'destaque',
        'classificacao': '18',
        'inPrime': true,
        'badge': 'prime',
        'favorito': false,
        'lembrete': null,
      },
      {
        'id': 634649,
        'tipo': 'movie',
        'titulo': 'Homem-Aranha: Um Novo Dia',
        'subtitulo': 'Ação / Aventura / Marvel',
        'ano': '2021',
        'sinopse': 'Após os sacrifícios que redefiniram sua existência, Peter Parker tenta reconstruir sua identidade anônima nas ruas de Nova York. Um novo amanhecer traz desafios inéditos que colocarão sua coragem à prova.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/8c4a8kE7PizaGQQnditMmI1xbRp.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/14QbnygCuTO0vl7CAFmPf1fgZfV.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=JfVOs4VSpmA',
        'secao': 'destaque',
        'classificacao': '12',
        'inPrime': true,
        'badge': 'prime',
        'favorito': false,
        'lembrete': null,
      },

      // ==========================================
      // CONTINUAR ASSISTINDO (Página 2 do Print)
      // ==========================================
      {
        'id': 337674,
        'tipo': 'movie',
        'titulo': 'Elle',
        'subtitulo': 'Filme • Suspense',
        'sinopse': 'Michèle é diretora de uma empresa de videogames e enfrenta um agressor misterioso em sua vida privada.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/z446adpGUVXXPxrLpKBGnYBcofk.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/5VApPDSRlONQV2gXugyz1yj7qZm.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=gM96ne-XiH0', // <- URL corrigida aqui
        'secao': 'continuar_assistindo',
        'badge': 'prime',
        'progresso': 0.72,
        'classificacao': '18',
        'favorito': false,
        'lembrete': null,
      },
      {
        'id': 71446,
        'tipo': 'tv',
        'titulo': 'La Casa de Papel',
        'subtitulo': 'Série de Drama e Mistério',
        'sinopse': 'Segredos de família, patrimônio e disputas intensas em uma vila histórica cercada de mistérios.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/reEMJA1uzscCbkpeRJeTT2bjqUp.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/xGexTKCJDkl12dTW4YCBDXWb1AD.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=1o2V0zkXV4c',
        'secao': 'continuar_assistindo',
        'badge': 'canais globo',
        'progresso': 0.45,
        'classificacao': '14',
        'favorito': false,
        'lembrete': null,
      },
      {
        'id': 76479,
        'tipo': 'tv',
        'titulo': 'The Boys',
        'subtitulo': 'Ação • Super-heróis',
        'sinopse': 'Um grupo de vigilantes luta contra super-heróis corruptos que abusam de seus poderes sob os cuidados de uma megacorporação.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/in1R2dDc421JxsoRWaIIAqVI2KE.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/bq28ajZaoMyzEIm6REelqyqtEDZ.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=tcrNsIaQkb4',
        'secao': 'continuar_assistindo',
        'badge': 'prime',
        'progresso': 0.88,
        'classificacao': '18',
        'favorito': false,
        'lembrete': null,
      },

      // ==========================================
      // FILMES INFANTIS E PARA TODA A FAMÍLIA
      // ==========================================
      {
        'id': 65334,
        'tipo': 'movie',
        'titulo': 'Miraculous World: Paris',
        'subtitulo': 'Animação / Aventura',
        'sinopse': 'Ladybug e Cat Noir encaram uma missão especial na Cidade Luz para deter novos vilões de dimensões paralelas.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/acrtAy8gmxcsEvrDP09MpMSCeDZ.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/lH22EnM0ofC7GsVGU8dAA2RXV1c.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=B59NoiERDOU',
        'secao': 'infantil_familia',
        'badge': 'canais globo',
        'classificacao': 'L',
        'favorito': false,
        'lembrete': null,
      },
      {
        'id': 277834,
        'tipo': 'movie',
        'titulo': 'Moana',
        'subtitulo': 'Infantil • Fantasia',
        'sinopse': 'Uma jovem corajosa procura ir além dos limites para descobrir o que está errado com as ilhas.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/4JeejGugONWpJkbnvL12hVoYEDa.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/qLVNZFHYUR6Li64He67SWl6BHQe.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=62b9PPVfacg',
        'secao': 'infantil_familia',
        'badge': 'canais globo',
        'classificacao': 'L',
        'favorito': false,
        'lembrete': null,
      },
      {
        'id': 315162,
        'tipo': 'movie',
        'titulo': 'Gato de Botas 2: O Último Pedido',
        'subtitulo': 'Animação • Comédia',
        'sinopse': 'O Gato de Botas descobre que gastou oito de suas nove vidas e embarca numa jornada épica para encontrar a lendária Estrela dos Desejos.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/kuf6dutpsT0vSVehic3EZIqkOBt.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/jr8tSoJGj33XLgFBy6lmZhpGQNu.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=sLk94T-hS78',
        'secao': 'infantil_familia',
        'badge': 'prime',
        'classificacao': 'L',
        'favorito': false,
        'lembrete': null,
      },
      {
        'id': 502356,
        'tipo': 'movie',
        'titulo': 'Super Mario Bros. O Filme',
        'subtitulo': 'Família • Aventura',
        'sinopse': 'Dois irmãos encanadores do Brooklyn são transportados para um labirinto misterioso no Reino dos Cogumelos.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/qNBAXBIQlnOThrVvA6mA2B5ggV6.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/9n2tJBplPbgR2ca05hS5CKXwP2c.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=cDNkh5WybZo',
        'secao': 'infantil_familia',
        'badge': 'prime',
        'classificacao': 'L',
        'favorito': false,
        'lembrete': null,
      },

      // ==========================================
      // AO VIVO (Página 2 do Print)
      // ==========================================
      {
        'id': 15621,
        'tipo': 'tv',
        'titulo': 'GloboNews Mais',
        'canalNome': 'Globonews',
        'subtitulo': 'Notícias e debates em tempo real',
        'sinopse': 'Cobertura completa dos principais fatos do Brasil e do mundo com análises aprofundadas dos maiores comentaristas.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/pOC3DmU47X98Sv5vaPnmgjG30eY.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/oNNdRpSQSdRIaWnSFejhw1qk51K.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=Yf1lT0qYmQk',
        'secao': 'ao_vivo',
        'isLive': true,
        'badge': 'canais globo',
        'classificacao': 'L',
        'favorito': false,
        'lembrete': null,
      },
      {
        'id': 90282,
        'tipo': 'tv',
        'titulo': 'CNN 360°',
        'canalNome': 'CNN Brasil',
        'subtitulo': 'Jornalismo 24 horas',
        'sinopse': 'Informações ao vivo com o panorama político e econômico, com credibilidade e dinamismo internacional.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/y9x2R87yt2U616736NJrP0d56dt.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/uMsTtNaUEWOE2q64m8zthBIMgen.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=vV76VqZ6yOQ',
        'secao': 'ao_vivo',
        'isLive': true,
        'badge': 'prime',
        'classificacao': 'L',
        'favorito': false,
        'lembrete': null,
      },

      // ==========================================
      // FILMES DE DRAMA (Página 2 do Print)
      // ==========================================
      {
        'id': 872585,
        'tipo': 'movie',
        'titulo': 'Oppenheimer',
        'tag': 'EM ALTA',
        'subtitulo': 'Drama Biográfico / História',
        'sinopse': 'A história do físico J. Robert Oppenheimer e seu papel fundamental no Projeto Manhattan e no desenvolvimento da bomba atômica.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/rLb2cwF3Pazuxaj0sRXQ037tGI1.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=uYPbbksJxIg',
        'secao': 'drama',
        'badge': 'prime',
        'classificacao': '16',
        'favorito': false,
        'lembrete': null,
      },
      {
        'id': 840430,
        'tipo': 'movie',
        'titulo': 'Os Rejeitados',
        'tag': 'MAIS CURTIDO',
        'subtitulo': 'Comédia Dramática',
        'sinopse': 'Um instrutor rabugento em uma escola preparatória da Nova Inglaterra é obrigado a permanecer no campus durante o recesso de fim de ano.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/VHSzNBTwxV8vh7wylo7O9CLdac.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/A99WMiz0ASpH9coOFrxSEuwTWx0.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=AhKLpJmHhIg',
        'secao': 'drama',
        'badge': 'prime',
        'classificacao': '14',
        'favorito': false,
        'lembrete': null,
      },
      {
        'id': 496243,
        'tipo': 'movie',
        'titulo': 'Parasita',
        'tag': 'EM ALTA',
        'subtitulo': 'Suspense / Drama',
        'sinopse': 'Toda a família de Ki-taek está desempregada, vivendo num porão sujo. Uma oportunidade inesperada muda drasticamente sua realidade.',
        'capaUrl':
            'https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg',
        'bannerUrl':
            'https://image.tmdb.org/t/p/w780/hiKmpZMGZsrkA3cdce8a7Dpos1j.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=m4jfE-TxC24',
        'secao': 'drama',
        'badge': 'prime',
        'classificacao': '16',
        'favorito': false,
        'lembrete': null,
      },
    ];
  }
}
