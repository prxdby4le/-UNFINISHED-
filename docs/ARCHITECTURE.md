# 🏗️ Arquitetura do Projeto

## Visão Geral

O aplicativo segue uma arquitetura em camadas (Layered Architecture) com separação clara de responsabilidades.

## Estrutura de Camadas

```
┌─────────────────────────────────────┐
│   Presentation Layer (UI/Widgets)   │
│   - Screens                         │
│   - Widgets                         │
│   - Providers (State Management)    │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   Domain Layer (Business Logic)      │
│   - Models                          │
│   - Repositories (Interfaces)       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   Data Layer                         │
│   - Repositories (Implementação)     │
│   - Services (Supabase, R2)          │
│   - Cache Manager                    │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   Infrastructure Layer               │
│   - Supabase Client                 │
│   - Cloudflare R2                   │
│   - Local Storage (Cache)           │
└─────────────────────────────────────┘
```

## Fluxo de Dados

### 1. Autenticação
```
User Input → AuthRepository → Supabase Auth → Session → Provider → UI Update
```

### 2. Upload de Áudio
```
User Selects File → AudioRepository → R2 Service (via Proxy) → 
Supabase DB (metadata) → Provider → UI Update
```

### 3. Reprodução de Áudio
```
User Plays Track → AudioPlayerProvider → CacheManager (check) → 
Download if needed → just_audio → AudioPlayer → UI Update
```

## Componentes Principais

### 1. AudioPlayerProvider
- Gerencia estado do player
- Coordena cache e download
- Implementa gapless playback
- Mantém sincronização com UI

### 2. AudioCacheManager
- Gerencia cache local de arquivos
- Implementa LRU (Least Recently Used)
- Controla tamanho máximo do cache
- Otimiza downloads

### 3. Repositories
- Abstraem acesso a dados
- Implementam lógica de negócio
- Gerenciam cache e sincronização

### 4. Services
- SupabaseService: Comunicação com Supabase
- R2Service: Upload/download via proxy
- AuthService: Autenticação

## Padrões de Design

### 1. Repository Pattern
Abstrai a fonte de dados (Supabase, Cache, etc.)

```dart
abstract class ProjectRepository {
  Future<List<Project>> getProjects();
  Future<Project> createProject(Project project);
  Future<void> deleteProject(String id);
}

class SupabaseProjectRepository implements ProjectRepository {
  // Implementação usando Supabase
}
```

### 2. Provider Pattern (State Management)
Gerencia estado da aplicação de forma reativa

```dart
class ProjectProvider extends ChangeNotifier {
  List<Project> _projects = [];
  // ... lógica de estado
}
```

### 3. Singleton Pattern
Para serviços globais (CacheManager, Supabase Client)

```dart
class AudioCacheManager {
  static final AudioCacheManager _instance = AudioCacheManager._internal();
  factory AudioCacheManager() => _instance;
}
```

## Segurança

### 1. Row Level Security (RLS)
- Todas as tabelas têm RLS habilitado
- Apenas usuários autenticados podem acessar
- Políticas específicas por operação (SELECT, INSERT, UPDATE, DELETE)

### 2. Autenticação
- PKCE flow para segurança
- Tokens JWT gerenciados pelo Supabase
- Refresh automático de tokens

### 3. Storage
- Arquivos privados (não públicos)
- Acesso apenas via autenticação
- Validação de tipos de arquivo

## Performance

### 1. Cache Strategy
- Cache local para arquivos frequentemente acessados
- LRU para gerenciar espaço
- Pré-carregamento inteligente

### 2. Lazy Loading
- Carregar dados sob demanda
- Paginação de listas grandes
- Preparação lazy de tracks no player

### 3. Otimizações
- Índices no banco de dados
- Queries otimizadas
- Redução de rebuilds desnecessários

## Escalabilidade

### 1. Horizontal Scaling
- Supabase escala automaticamente
- R2 suporta alta carga
- Edge Functions distribuídas

### 2. Vertical Scaling
- Cache local reduz carga no servidor
- Compressão de dados quando possível
- Otimização de queries

## Testabilidade

### 1. Separação de Responsabilidades
- Lógica de negócio isolada
- Dependências injetáveis
- Interfaces para mock

### 2. Testes
- Unit tests para repositories
- Integration tests para services
- Widget tests para UI

## Manutenibilidade

### 1. Código Limpo
- Nomes descritivos
- Funções pequenas e focadas
- Documentação inline

### 2. Estrutura Modular
- Módulos independentes
- Baixo acoplamento
- Alta coesão

## Próximos Passos

1. Implementar testes unitários
2. Adicionar logging estruturado
3. Implementar analytics
4. Adicionar monitoramento de erros (Sentry)
