import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prime_video_replica/main.dart';
import 'package:prime_video_replica/screens/detalhes_page.dart';
import 'package:prime_video_replica/services/tmdb_service.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('Verifica renderização da tela principal do Prime Video', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const PrimeVideoReplicaApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Elementos do cabeçalho
    expect(find.text('prime'), findsWidgets);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Fileiras da página inicial
    expect(find.text('Continuar assistindo'), findsOneWidget);
    expect(find.text('Filmes infantis e para toda a família'), findsOneWidget);
    expect(find.text('Ao vivo'), findsOneWidget);
    expect(find.text('Filmes de drama'), findsOneWidget);
  });

  testWidgets('Verifica catálogo com os 4 títulos solicitados nos destaques', (WidgetTester tester) async {
    final catalogo = TmdbService.obterCatalogoInicial();
    final destaques = catalogo.where((item) => item['secao'] == 'destaque').toList();

    // Valida os 4 títulos exigidos pelo usuário
    final titulosDestaque = destaques.map((e) => e['titulo']).toList();
    expect(titulosDestaque, contains('Um Amor Diferente do Seu'));
    expect(titulosDestaque, contains('Devoradores de Estrelas'));
    expect(titulosDestaque, contains('Elle'));
    expect(titulosDestaque, contains('Homem-Aranha: Um Novo Dia'));
  });

  testWidgets('Verifica tela de detalhes com passagem de parâmetros', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final itemTeste = {
      'id': 634649,
      'tipo': 'movie',
      'titulo': 'Homem-Aranha: Um Novo Dia',
      'subtitulo': 'Ação / Marvel',
      'sinopse': 'Peter Parker protege as ruas de Nova York.',
      'capaUrl': 'https://image.tmdb.org/t/p/w500/8c4a8kE7PizaGQQnditMmI1xbRp.jpg',
      'bannerUrl': 'https://image.tmdb.org/t/p/w780/14QbnygCuTO0vl7CAFmPf1fgZfV.jpg',
      'trailerUrl': 'https://www.youtube.com/watch?v=JfVOs4VSpmA',
      'classificacao': '12',
      'favorito': false,
      'lembrete': null,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: DetalhesPage(item: itemTeste),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Valida exibição dos dados recebidos por parâmetro
    expect(find.text('Homem-Aranha: Um Novo Dia'), findsOneWidget);
    expect(find.text('Assistir trailer'), findsOneWidget);
    expect(find.text('Minha lista'), findsOneWidget);
    expect(find.text('Mais tarde'), findsOneWidget);
    expect(find.text('Sinopse'), findsOneWidget);
  });
}
