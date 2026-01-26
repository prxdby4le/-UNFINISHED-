# 🎯 Passo a Passo: O Que Falta Implementar

## 📊 Visão Geral Rápida

| Funcionalidade | Status | Prioridade | Tempo Estimado |
|---------------|--------|------------|----------------|
| Sistema de Feedback | ❌ Não implementado | 🔴 Alta | 1-2 semanas |
| Cache Inteligente | ⚠️ Parcial | 🔴 Alta | 1 semana |
| UI/UX Polida | ⚠️ Básico | 🟡 Média | 1 semana |
| Otimizações | ⚠️ Básico | 🟡 Média | 1 semana |
| Editar/Deletar | ⚠️ Parcial | 🟡 Média | 3-5 dias |
| Testes | ❌ Não implementado | 🟢 Baixa | 2 semanas |

---

## 🔴 PRIORIDADE 1: Sistema de Feedback/Comentários

### Por que é importante?
- É uma funcionalidade **core** do projeto
- Permite colaboração entre membros do coletivo
- Tabela já existe no banco de dados

### Passo a Passo Detalhado

#### 1. Criar Model de Feedback
**Arquivo**: `lib/data/models/feedback.dart`

```dart
class Feedback {
  final String id;
  final String audioVersionId;
  final String? authorId;
  final String content;
  final int? timestampSeconds; // Timestamp no áudio (opcional)
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Construtor, fromJson, toJson, etc.
}
```

**Tempo**: 30 minutos

---

#### 2. Criar FeedbackRepository
**Arquivo**: `lib/data/repositories/feedback_repository.dart`

**Métodos necessários**:
- `getFeedbackByVersion(String versionId)` - Lista comentários de uma versão
- `createFeedback(...)` - Cria novo comentário
- `updateFeedback(String id, String content)` - Atualiza comentário próprio
- `deleteFeedback(String id)` - Deleta comentário próprio

**Tempo**: 2-3 horas

---

#### 3. Criar Widget de Lista de Comentários
**Arquivo**: `lib/presentation/widgets/feedback_list_widget.dart`

**Funcionalidades**:
- Lista de comentários com autor e data
- Indicador de timestamp (se houver)
- Botão para editar/deletar próprio comentário
- Loading state
- Empty state (quando não há comentários)

**Tempo**: 4-5 horas

---

#### 4. Criar Widget de Formulário de Comentário
**Arquivo**: `lib/presentation/widgets/feedback_form_widget.dart`

**Funcionalidades**:
- Campo de texto para comentário
- Campo opcional para timestamp (em segundos)
- Botão de enviar
- Validação
- Loading state durante envio

**Tempo**: 2-3 horas

---

#### 5. Integrar na UI
**Onde integrar**:
- Opção 1: Modal na tela de detalhes do projeto
- Opção 2: Seção na tela de detalhes do projeto
- Opção 3: Tela separada acessível pelo player

**Arquivo**: Modificar `project_detail_screen.dart` ou criar nova tela

**Tempo**: 3-4 horas

---

#### 6. Adicionar Botão de Acesso
- Adicionar botão "Comentários" na lista de versões
- Ou ícone de comentário ao lado de cada versão

**Tempo**: 1 hora

---

**TOTAL**: ~15-20 horas (2-3 dias de trabalho)

---

## 🔴 PRIORIDADE 2: Cache Inteligente Completo

### Por que é importante?
- Reduz consumo de dados móveis
- Melhora experiência (gapless mais suave)
- Permite reprodução offline

### Passo a Passo Detalhado

#### 1. Completar AudioCacheManager
**Arquivo**: `lib/core/cache/audio_cache_manager.dart`

**O que falta**:
- [ ] Implementar LRU cleanup (deletar arquivos menos usados)
- [ ] Verificar limite de tamanho (500MB)
- [ ] Verificar espaço disponível antes de baixar
- [ ] Método para limpar cache manualmente
- [ ] Método para obter tamanho do cache

**Tempo**: 4-5 horas

---

#### 2. Integrar Cache com Player
**Arquivo**: `lib/presentation/providers/audio_player_provider.dart`

**Modificações**:
- Verificar se arquivo está em cache antes de usar URL assinada
- Se não estiver, baixar para cache e usar arquivo local
- Mostrar progresso de download quando necessário

**Tempo**: 3-4 horas

---

#### 3. Implementar Pré-cache
**Arquivo**: `lib/presentation/providers/audio_player_provider.dart`

**Funcionalidade**:
- Quando uma música está tocando, baixar a próxima em background
- Usar `currentIndexStream` para detectar mudança de track

**Tempo**: 2-3 horas

---

#### 4. Verificação de Wi-Fi
**Arquivo**: `lib/core/cache/audio_cache_manager.dart`

**Funcionalidade**:
- Verificar se está conectado via Wi-Fi
- Só fazer cache se for Wi-Fi (opcional, configurável)

**Tempo**: 1-2 horas

---

#### 5. UI de Gerenciamento de Cache
**Arquivo**: `lib/presentation/screens/cache_settings_screen.dart`

**Funcionalidades**:
- Mostrar tamanho atual do cache
- Botão para limpar cache
- Toggle para cache apenas em Wi-Fi
- Lista de arquivos em cache (opcional)

**Tempo**: 3-4 horas

---

**TOTAL**: ~13-18 horas (2 dias de trabalho)

---

## 🟡 PRIORIDADE 3: UI/UX Polida

### Passo a Passo Detalhado

#### 1. Criar Widgets de Estado Reutilizáveis
**Arquivos**:
- `lib/presentation/widgets/loading_widget.dart`
- `lib/presentation/widgets/error_widget.dart`
- `lib/presentation/widgets/empty_state_widget.dart`

**Tempo**: 2-3 horas

---

#### 2. Adicionar Empty States
**Onde**:
- Lista de projetos (quando vazia)
- Lista de versões (quando vazia)
- Lista de comentários (quando vazia)

**Tempo**: 2-3 horas

---

#### 3. Melhorar Mensagens de Erro
**Onde**: Todas as telas

**Melhorias**:
- Mensagens mais específicas
- Botões de ação (tentar novamente, etc)
- Ícones visuais

**Tempo**: 3-4 horas

---

#### 4. Adicionar Animações
**Onde**:
- Transições entre telas
- Aparição de itens em listas
- Loading states

**Tempo**: 4-5 horas

---

#### 5. Implementar Pull-to-Refresh
**Onde**:
- Lista de projetos
- Lista de versões

**Tempo**: 2 horas

---

#### 6. Adicionar Skeleton Loaders
**Onde**:
- Lista de projetos (durante carregamento)
- Lista de versões (durante carregamento)

**Tempo**: 3-4 horas

---

**TOTAL**: ~16-21 horas (2-3 dias de trabalho)

---

## 🟡 PRIORIDADE 4: Funcionalidades de Edição/Deleção

### Passo a Passo Detalhado

#### 1. Editar Projeto
**Arquivo**: `lib/presentation/screens/edit_project_screen.dart`

**Funcionalidades**:
- Editar nome
- Editar descrição
- Trocar capa
- Salvar alterações

**Tempo**: 3-4 horas

---

#### 2. Editar Versão
**Arquivo**: Modal ou tela separada

**Funcionalidades**:
- Editar nome
- Editar descrição
- Marcar/desmarcar como master
- Salvar alterações

**Tempo**: 2-3 horas

---

#### 3. Deletar Versão
**Arquivo**: Modificar `project_detail_screen.dart`

**Funcionalidades**:
- Botão de deletar
- Dialog de confirmação
- Deletar do R2 também (via Edge Function)

**Tempo**: 2-3 horas

---

#### 4. Arquivar Projeto
**Arquivo**: Modificar `projects_screen.dart`

**Funcionalidades**:
- Botão "Arquivar"
- Filtro para mostrar/ocultar arquivados
- Desarquivar

**Tempo**: 2-3 horas

---

**TOTAL**: ~9-13 horas (1-2 dias de trabalho)

---

## 🟡 PRIORIDADE 5: Otimizações de Performance

### Passo a Passo Detalhado

#### 1. Implementar Paginação
**Arquivos**: 
- `lib/data/repositories/project_repository.dart`
- `lib/data/repositories/audio_repository.dart`

**Funcionalidade**:
- Carregar 20 itens por vez
- Load more ao chegar no fim da lista

**Tempo**: 4-5 horas

---

#### 2. Otimizar Queries
**Arquivos**: Todos os repositories

**Melhorias**:
- Usar `.select()` específico (não `*`)
- Adicionar índices no banco (se necessário)
- Evitar queries aninhadas desnecessárias

**Tempo**: 2-3 horas

---

#### 3. Adicionar Debounce em Buscas
**Arquivo**: `lib/presentation/screens/projects_screen.dart`

**Funcionalidade**:
- Aguardar 500ms após parar de digitar antes de buscar

**Tempo**: 1 hora

---

#### 4. Reduzir Rebuilds
**Onde**: Todas as telas

**Melhorias**:
- Usar `const` onde possível
- Separar widgets que mudam frequentemente
- Usar `Consumer` específico do Provider

**Tempo**: 3-4 horas

---

**TOTAL**: ~10-13 horas (1-2 dias de trabalho)

---

## 📅 Cronograma Sugerido

### Semana 1-2: Sistema de Feedback
- Dia 1-2: Model e Repository
- Dia 3-4: Widgets de UI
- Dia 5: Integração e testes

### Semana 3: Cache Inteligente
- Dia 1-2: Completar AudioCacheManager
- Dia 3: Integração com player
- Dia 4: Pré-cache e Wi-Fi check
- Dia 5: UI de gerenciamento

### Semana 4: UI/UX Polida
- Dia 1: Widgets de estado
- Dia 2: Empty states e mensagens de erro
- Dia 3: Animações
- Dia 4: Pull-to-refresh e skeleton loaders

### Semana 5: Funcionalidades Adicionais
- Dia 1-2: Editar projeto e versão
- Dia 3: Deletar versão
- Dia 4: Arquivar projeto

### Semana 6: Otimizações
- Dia 1-2: Paginação
- Dia 3: Otimizar queries
- Dia 4: Debounce e reduzir rebuilds

---

## 🎯 Resumo por Prioridade

### 🔴 Crítico (2-3 semanas)
1. Sistema de Feedback
2. Cache Inteligente

### 🟡 Importante (2-3 semanas)
3. UI/UX Polida
4. Editar/Deletar
5. Otimizações

### 🟢 Desejável (2+ semanas)
6. Testes
7. Deploy mobile
8. Documentação adicional

---

## 💡 Dicas de Implementação

1. **Comece pelo Feedback**: É a funcionalidade mais visível e importante
2. **Teste incrementalmente**: Não espere terminar tudo para testar
3. **Reutilize código**: Crie widgets reutilizáveis desde o início
4. **Documente enquanto implementa**: Facilita manutenção futura
5. **Priorize UX**: Funcionalidades que melhoram a experiência do usuário

---

## 📝 Notas Finais

- O projeto está **70% completo** funcionalmente
- As funcionalidades faltantes são principalmente **melhorias** e **features avançadas**
- Com foco, é possível completar as prioridades altas em **4-6 semanas**
- O sistema de feedback é a única funcionalidade **core** que está faltando
