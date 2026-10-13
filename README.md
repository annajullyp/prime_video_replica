# Réplica Educacional - Amazon Prime Video (Flutter)
 
## Opção escolhida
 
**A - Amazon Prime Video**
 
## Como configurar o token TMDB
 
**Método 1: linha de comando**
 
```bash
flutter run --dart-define=TMDB_TOKEN=SEU_TOKEN_AQUI
```
 
**Método 2: dentro do aplicativo**
 
1. Toque no botão **Menu ⌵** no topo da tela.
2. Selecione **"Configurar Token TMDB"**.
3. Cole o token e toque em **"Salvar e Sincronizar"**.
Sem token (ou sem internet), o app usa o catálogo local embutido.
 
## Dependências
 
- Flutter SDK `>=3.44.0` / Dart `^3.13.1`
- `http` ^1.6.0
- `url_launcher` ^6.3.3
- `cupertino_icons` ^1.0.8
- `flutter_lints` ^6.0.0 (desenvolvimento)

## Tamanho de tela testado
 
Tela de celular padrão, aproximadamente 390 x 844 (Iphone 13), compatível com o print mobile da atividade.
 
## Substituições de títulos
 
- **"Casas"** foi substituído por **"La Casa de Papel"**;
- **"Nina: A Heroína dos Sete Mares"** foi substituído por **"Moana"**;
- **"Um Dia"** foi substituído por **"Oppenheimer"**;
- **"O Drama"** foi substituído por **"Os Rejeitados"**.

 ## Explicação de conteúdos
 
- **GET/JSON:** em `lib/screens/home_page.dart`, método `carregarTitulo` (chamado uma vez por obra por `_carregarTitulosDaApi`). Ele faz `http.get` em `https://api.themoviedb.org/3/{tipo}/{id}` e converte a resposta com `jsonDecode`, usando `title`/`name`, `overview`, `poster_path` e `backdrop_path` para atualizar o catálogo. `TmdbService.buscarTituloApi` (`lib/services/tmdb_service.dart`) é uma versão equivalente da mesma consulta.
- **Parâmetros enviados:** na URL, o `tipo` (`movie` ou `tv`), o `id` da obra e a query `language=pt-BR`; no cabeçalho, `Authorization: Bearer <token>`. Na navegação, o mapa completo da obra é passado ao construtor `DetalhesPage(item: item)` por `Navigator.push`.
- **Retorno dos dialogs:**
  - `AlertDialog` (remover favorito): `showDialog<bool>` com `Navigator.pop(ctx, true/false)`; só remove se o resultado for `true`.
  - `showDatePicker` e `showTimePicker`: retornam `DateTime?` e `TimeOfDay?` (`null` = cancelou); os dois valores são formatados como `dd/mm/aaaa às hh:mm` e salvos em `item['lembrete']`.
  - `SimpleDialog` e Custom Dialog: devolvem a escolha por callbacks (`onSelecionarCategoria`, `onToggleFavorito`, `onDefinirLembrete`), que atualizam o estado com `setState`.
  - `AboutDialog`: apenas informativo, sem valor de retorno.

## Uso de IA

O Antigravity IDE desenvolveu este projeto, auxiliando no desenvolvimento, manutenção e correção do código. 

O Claude ajudou a corrigir a lista "Assistir mais tarde", trocar o título do destaque e reescrever este README. O código foi conferido com `flutter analyze` e `flutter test`.
 
*This product uses the TMDB API but is not endorsed or certified by TMDB.*
