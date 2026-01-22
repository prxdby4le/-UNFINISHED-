# 🎵 Central de Gravadora - Trashtalk Records

Aplicativo Flutter para gestão de demos, versões de áudio e feedback para coletivo musical.

## 📋 Stack Tecnológica

- **Frontend**: Flutter (Android, iOS, Desktop)
- **Backend/Auth**: Supabase (Free Tier)
- **Storage**: Cloudflare R2 (custo zero de egress)
- **Áudio**: Lossless (WAV/FLAC) com Gapless Playback

## 📚 Bibliotecas Principais

- `just_audio` - Motor de áudio e gapless playback
- `just_audio_background` - Reprodução em segundo plano
- `supabase_flutter` - Banco de dados, auth e buckets
- `path_provider` - Cache local de arquivos
- `cached_network_image` - Cache de imagens (opcional)

## 🚀 Roadmap de Implementação

### Fase 1: Setup Inicial (Semana 1)
- [ ] Configuração do projeto Flutter
- [ ] Integração com Supabase
- [ ] Configuração do Cloudflare R2
- [ ] Setup de autenticação

### Fase 2: Core Features (Semanas 2-3)
- [ ] Sistema de login
- [ ] CRUD de projetos/pastas
- [ ] Upload de versões de áudio
- [ ] Listagem de versões por data

### Fase 3: Player de Áudio (Semana 4)
- [ ] Player com just_audio
- [ ] Gapless playback
- [ ] Reprodução em segundo plano
- [ ] Cache inteligente

### Fase 4: Feedback e UI (Semanas 5-6)
- [ ] Sistema de feedback/comentários
- [ ] UI/UX polida
- [ ] Testes e otimizações

## 📁 Estrutura do Projeto

```
lib/
├── main.dart
├── core/
│   ├── config/
│   │   ├── supabase_config.dart
│   │   └── r2_config.dart
│   ├── cache/
│   │   └── audio_cache_manager.dart
│   └── constants/
├── data/
│   ├── models/
│   │   ├── project.dart
│   │   ├── audio_version.dart
│   │   └── user_profile.dart
│   ├── repositories/
│   │   ├── project_repository.dart
│   │   ├── audio_repository.dart
│   │   └── auth_repository.dart
│   └── services/
│       ├── supabase_service.dart
│       └── r2_service.dart
├── presentation/
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── projects_screen.dart
│   │   ├── project_detail_screen.dart
│   │   └── player_screen.dart
│   ├── widgets/
│   │   ├── audio_player_widget.dart
│   │   └── version_list_item.dart
│   └── providers/
│       ├── audio_player_provider.dart
│       └── project_provider.dart
└── utils/
    └── audio_utils.dart
```

## 🔧 Configuração

Veja os arquivos de documentação:
- `docs/DATABASE_SCHEMA.md` - Modelagem de dados
- `docs/R2_SETUP.md` - Configuração Cloudflare R2
- `docs/CACHE_STRATEGY.md` - Estratégia de cache
- `docs/GAPLESS_PLAYBACK.md` - Implementação gapless
