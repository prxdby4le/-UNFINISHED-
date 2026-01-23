# Tabela de Biblioteca (Favoritos)

Execute este SQL no Supabase Dashboard para criar a tabela de biblioteca:

```sql
-- Tabela para salvar projetos na biblioteca do usuário
CREATE TABLE IF NOT EXISTS user_library (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Garantir que cada usuário só pode salvar um projeto uma vez
  UNIQUE(user_id, project_id)
);

-- Índices para performance
CREATE INDEX idx_user_library_user_id ON user_library(user_id);
CREATE INDEX idx_user_library_project_id ON user_library(project_id);

-- RLS Policies
ALTER TABLE user_library ENABLE ROW LEVEL SECURITY;

-- Usuários só podem ver sua própria biblioteca
CREATE POLICY "Usuários podem ver sua biblioteca"
  ON user_library FOR SELECT
  USING (user_id = auth.uid());

-- Usuários só podem adicionar à sua própria biblioteca
CREATE POLICY "Usuários podem adicionar à biblioteca"
  ON user_library FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Usuários só podem remover da sua própria biblioteca
CREATE POLICY "Usuários podem remover da biblioteca"
  ON user_library FOR DELETE
  USING (user_id = auth.uid());
```
