# 🗺️ Roadmap de Implementação Detalhado

## Fase 1: Setup e Infraestrutura (Semana 1)

### 1.1 Configuração do Projeto Flutter
- [x] Criar estrutura de pastas
- [x] Configurar `pubspec.yaml` com dependências
- [ ] Configurar variáveis de ambiente (`.env`)
- [ ] Setup de linting e formatação
- [ ] Configurar builds para Android/iOS/Desktop

### 1.2 Configuração Supabase
- [ ] Criar projeto no Supabase
- [ ] Executar scripts SQL de criação de tabelas (`docs/DATABASE_SCHEMA.md`)
- [ ] Configurar Row Level Security (RLS)
- [ ] Criar bucket de storage (se usar Supabase Storage como cache)
- [ ] Testar conexão do Flutter com Supabase

### 1.3 Configuração Cloudflare R2
- [ ] Criar bucket no R2
- [ ] Gerar API tokens
- [ ] Configurar CORS
- [ ] Criar Edge Function no Supabase para proxy R2
- [ ] Testar upload/download via proxy

### 1.4 Autenticação
- [ ] Implementar tela de login
- [ ] Integrar Supabase Auth
- [ ] Implementar logout
- [ ] Gerenciar sessão persistente

**Entregáveis**: Projeto configurado, autenticação funcionando, R2 acessível via proxy

---

## Fase 2: Core Features - Projetos e Versões (Semanas 2-3)

### 2.1 Gestão de Projetos
- [ ] Tela de listagem de projetos
- [ ] Criar novo projeto
- [ ] Editar projeto existente
- [ ] Deletar projeto (com confirmação)
- [ ] Buscar/filtrar projetos
- [ ] Visualizar detalhes do projeto

### 2.2 Upload de Versões de Áudio
- [ ] Selecionar arquivo (WAV/FLAC)
- [ ] Upload para R2 via proxy
- [ ] Extrair metadados (duração, tamanho)
- [ ] Criar registro na tabela `audio_versions`
- [ ] Mostrar progresso de upload
- [ ] Tratamento de erros

### 2.3 Listagem de Versões
- [ ] Listar versões por projeto
- [ ] Ordenar por data de upload (mais recente primeiro)
- [ ] Mostrar informações (nome, data, tamanho, duração)
- [ ] Indicar versão master
- [ ] Filtros (por formato, data, etc)

**Entregáveis**: CRUD completo de projetos e versões, upload funcionando

---

## Fase 3: Player de Áudio (Semana 4)

### 3.1 Player Básico
- [ ] Widget de player
- [ ] Controles (play, pause, stop)
- [ ] Barra de progresso
- [ ] Exibir tempo atual/total
- [ ] Integração com `just_audio`

### 3.2 Gapless Playback
- [ ] Implementar `ConcatenatingAudioSource`
- [ ] Configurar `useLazyPreparation: true`
- [ ] Testar transições sem pausas
- [ ] Navegação entre tracks (anterior/próximo)

### 3.3 Background Playback
- [ ] Configurar `just_audio_background`
- [ ] Notificação de controle (Android/iOS)
- [ ] Testar com app minimizado
- [ ] Manter estado do player

### 3.4 Integração com Cache
- [ ] Usar `AudioCacheManager` no player
- [ ] Baixar arquivo antes de reproduzir (se necessário)
- [ ] Mostrar progresso de download
- [ ] Reproduzir do cache local quando disponível

**Entregáveis**: Player funcional com gapless e background playback

---

## Fase 4: Sistema de Feedback (Semana 5)

### 4.1 Comentários em Versões
- [ ] Adicionar comentário
- [ ] Listar comentários
- [ ] Editar próprio comentário
- [ ] Deletar próprio comentário
- [ ] Timestamp no áudio (opcional)

### 4.2 UI de Feedback
- [ ] Widget de comentários
- [ ] Formulário de novo comentário
- [ ] Exibir autor e data
- [ ] Marcação de timestamps (se implementado)

**Entregáveis**: Sistema de feedback completo

---

## Fase 5: Cache e Otimizações (Semana 6)

### 5.1 Cache Inteligente
- [ ] Implementar `AudioCacheManager` completo
- [ ] LRU (Least Recently Used) cleanup
- [ ] Limite de tamanho de cache
- [ ] Pré-cache do próximo track
- [ ] Cache apenas em Wi-Fi (opcional)

### 5.2 Otimizações de Performance
- [ ] Lazy loading de listas
- [ ] Paginação de projetos/versões
- [ ] Otimizar queries do Supabase
- [ ] Reduzir rebuilds desnecessários

### 5.3 UX/UI Polida
- [ ] Loading states
- [ ] Error handling amigável
- [ ] Animações suaves
- [ ] Feedback visual (toasts, snackbars)
- [ ] Tema escuro/claro

**Entregáveis**: App otimizado, cache funcionando, UX polida

---

## Fase 6: Testes e Deploy (Semana 7)

### 6.1 Testes
- [ ] Testes unitários (repositories, models)
- [ ] Testes de integração (auth, upload)
- [ ] Testes de UI (widgets principais)
- [ ] Testes de player (gapless, background)

### 6.2 Deploy
- [ ] Build Android (APK/AAB)
- [ ] Build iOS (se aplicável)
- [ ] Build Desktop (opcional)
- [ ] Testes em dispositivos reais
- [ ] Documentação final

**Entregáveis**: App testado e pronto para distribuição

---

## Checklist de Dependências Externas

- [ ] Conta Supabase criada e configurada
- [ ] Conta Cloudflare com R2 ativado
- [ ] Domínio configurado (opcional, para produção)
- [ ] Certificados de assinatura (Android/iOS)
- [ ] Testes em dispositivos físicos

---

## Notas de Implementação

### Prioridades
1. **Crítico**: Auth, Upload, Player básico
2. **Importante**: Gapless, Cache, Feedback
3. **Desejável**: UI polida, Otimizações, Testes

### Decisões Técnicas Pendentes
- [ ] Escolher state management (Provider vs Riverpod)
- [ ] Definir limite máximo de tamanho de arquivo
- [ ] Política de retenção de cache
- [ ] Estratégia de backup/restore

### Riscos e Mitigações
- **Risco**: Arquivos muito grandes causam timeout
  - **Mitigação**: Chunked upload, retry logic
- **Risco**: Cache consome muito espaço
  - **Mitigação**: Limite de tamanho, cleanup automático
- **Risco**: Gapless não funciona perfeitamente
  - **Mitigação**: Testar com diferentes formatos, fallback para MP3

---

## Métricas de Sucesso

- ✅ Upload de arquivo WAV 100MB em < 5 minutos (Wi-Fi)
- ✅ Gapless playback sem pausas audíveis
- ✅ Player funciona em background por > 30 minutos
- ✅ Cache reduz consumo de dados em > 80%
- ✅ App responsivo (< 2s para carregar listas)
