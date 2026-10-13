import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_page.dart';
import 'screens/detalhes_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PrimeVideoReplicaApp());
}

/// Aplicação Réplica do Amazon Prime Video
/// Desenvolvida para a Atividade Prática Integradora do IFRO Campus Ariquemes
class PrimeVideoReplicaApp extends StatelessWidget {
  const PrimeVideoReplicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prime Video IFRO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomePage(),
      
      // Rota nomeada com onGenerateRoute conforme Opção B (Página 6 do PDF)
      onGenerateRoute: (settings) {
        if (settings.name == '/detalhes') {
          final item = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => DetalhesPage(item: item),
          );
        }
        return null;
      },
    );
  }
}
