# 🚀 Guia de Início Rápido

## Passo 1: Configuração do Supabase

1. Crie uma conta no [Supabase](https://supabase.com)
2. Crie um novo projeto
3. Anote a URL e a chave anônima (anon key)
4. Execute os scripts SQL em `docs/DATABASE_SCHEMA.md` no SQL Editor do Supabase

## Passo 2: Configuração do Cloudflare R2

1. Crie uma conta no [Cloudflare](https://cloudflare.com)
2. Ative o R2 no dashboard
3. Crie um bucket chamado `trashtalk-audio-files`
4. Gere um API Token com permissões de leitura/escrita
5. Anote: Account ID, Access Key ID, Secret Access Key

## Passo 3: Configurar Edge Function no Supabase

1. No Supabase Dashboard, vá em Edge Functions
2. Crie uma nova função chamada `r2-proxy`
3. Copie o código de `docs/R2_SETUP.md` (Opção 1)
4. Configure as variáveis de ambiente:
   - `R2_ACCOUNT_ID`
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`

## Passo 4: Configurar o Projeto Flutter

1. Edite `lib/core/config/supabase_config.dart`:
   ```dart
   static const String supabaseUrl = 'SUA_URL_AQUI';
   static const String supabaseAnonKey = 'SUA_CHAVE_AQUI';
   ```

2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. Execute o app:
   ```bash
   flutter run
   ```

## Passo 5: Testar Upload

1. Faça login no app
2. Crie um projeto
3. Faça upload de um arquivo WAV/FLAC
4. Verifique se o arquivo aparece no Cloudflare R2

## Próximos Passos

Siga o roadmap em `docs/ROADMAP.md` para implementar as funcionalidades restantes.

## Troubleshooting

### Erro de autenticação
- Verifique se as credenciais do Supabase estão corretas
- Confirme que o RLS está configurado corretamente

### Erro ao fazer upload
- Verifique se a Edge Function está deployada
- Confirme as variáveis de ambiente do R2
- Verifique os logs da Edge Function no Supabase

### Player não toca
- Verifique permissões de áudio no dispositivo
- Confirme que o arquivo foi baixado corretamente
- Teste com arquivo local primeiro
