# Tabela user_library

Execute este SQL no Supabase Dashboard para criar a tabela de biblioteca do usuário.

## SQL

```sql
-- Criar tabela user_library
CREATE TABLE IF NOT EXISTS user_library (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Evitar duplicatas
  UNIQUE(user_id, project_id)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_user_library_user_id ON user_library(user_id);
CREATE INDEX IF NOT EXISTS idx_user_library_project_id ON user_library(project_id);

-- Habilitar RLS
ALTER TABLE user_library ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
-- Usuários só podem ver seus próprios itens na biblioteca
CREATE POLICY "Usuários podem ver sua própria biblioteca"
  ON user_library FOR SELECT
  USING (user_id = auth.uid());

-- Usuários podem adicionar à sua própria biblioteca
CREATE POLICY "Usuários podem adicionar à sua biblioteca"
  ON user_library FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Usuários podem remover da sua própria biblioteca
CREATE POLICY "Usuários podem remover da sua biblioteca"
  ON user_library FOR DELETE
  USING (user_id = auth.uid());
```

## Verificação

Após executar o SQL, a tabela deve aparecer no Supabase Dashboard em:
- Database → Tables → user_library

## Uso no App

O botão "Save to library" na tela de detalhes do projeto usa esta tabela para:
- Verificar se o projeto está salvo
- Adicionar/remover projetos da biblioteca pessoal
