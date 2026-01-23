# 🔒 Isolamento de Dados por Usuário

## Problema

As políticas RLS originais permitiam que todos os usuários autenticados vissem todos os projetos. Isso causava vazamento de dados entre contas.

## Solução

Atualizar as políticas RLS para isolar dados por usuário.

## SQL para Executar no Supabase

Execute este SQL no **SQL Editor** do Supabase Dashboard:

```sql
-- ===============================================
-- ATUALIZAR POLÍTICAS RLS PARA ISOLAMENTO POR USUÁRIO
-- ===============================================

-- 1. PROJETOS - Remover políticas antigas
DROP POLICY IF EXISTS "Membros podem ver projetos" ON projects;
DROP POLICY IF EXISTS "Membros podem criar projetos" ON projects;
DROP POLICY IF EXISTS "Criador pode atualizar projeto" ON projects;
DROP POLICY IF EXISTS "Criador pode deletar projeto" ON projects;

-- 2. PROJETOS - Criar novas políticas com isolamento
-- Usuários só podem ver SEUS PRÓPRIOS projetos
CREATE POLICY "Usuários podem ver seus projetos"
  ON projects FOR SELECT
  USING (created_by = auth.uid());

-- Usuários podem criar projetos (vinculado ao seu ID)
CREATE POLICY "Usuários podem criar projetos"
  ON projects FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated' AND
    created_by = auth.uid()
  );

-- Usuários só podem atualizar SEUS PRÓPRIOS projetos
CREATE POLICY "Usuários podem atualizar seus projetos"
  ON projects FOR UPDATE
  USING (created_by = auth.uid());

-- Usuários só podem deletar SEUS PRÓPRIOS projetos
CREATE POLICY "Usuários podem deletar seus projetos"
  ON projects FOR DELETE
  USING (created_by = auth.uid());

-- ===============================================
-- 3. AUDIO_VERSIONS - Atualizar para seguir projetos
-- ===============================================

DROP POLICY IF EXISTS "Membros podem ver versões" ON audio_versions;
DROP POLICY IF EXISTS "Membros podem criar versões" ON audio_versions;
DROP POLICY IF EXISTS "Uploader pode atualizar versão" ON audio_versions;
DROP POLICY IF EXISTS "Uploader pode deletar versão" ON audio_versions;

-- Usuários só podem ver versões de SEUS PRÓPRIOS projetos
CREATE POLICY "Usuários podem ver versões de seus projetos"
  ON audio_versions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM projects 
      WHERE projects.id = audio_versions.project_id
      AND projects.created_by = auth.uid()
    )
  );

-- Usuários só podem criar versões em SEUS PRÓPRIOS projetos
CREATE POLICY "Usuários podem criar versões em seus projetos"
  ON audio_versions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM projects 
      WHERE projects.id = audio_versions.project_id
      AND projects.created_by = auth.uid()
    )
  );

-- Usuários podem atualizar versões de seus projetos
CREATE POLICY "Usuários podem atualizar versões de seus projetos"
  ON audio_versions FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM projects 
      WHERE projects.id = audio_versions.project_id
      AND projects.created_by = auth.uid()
    )
  );

-- Usuários podem deletar versões de seus projetos
CREATE POLICY "Usuários podem deletar versões de seus projetos"
  ON audio_versions FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM projects 
      WHERE projects.id = audio_versions.project_id
      AND projects.created_by = auth.uid()
    )
  );

-- ===============================================
-- 4. FEEDBACK - Atualizar para seguir projetos
-- ===============================================

DROP POLICY IF EXISTS "Membros podem ver feedback" ON feedback;
DROP POLICY IF EXISTS "Membros podem criar feedback" ON feedback;
DROP POLICY IF EXISTS "Autor pode atualizar feedback" ON feedback;
DROP POLICY IF EXISTS "Autor pode deletar feedback" ON feedback;

-- Usuários só podem ver feedback de versões de SEUS projetos
CREATE POLICY "Usuários podem ver feedback de seus projetos"
  ON feedback FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM audio_versions av
      JOIN projects p ON p.id = av.project_id
      WHERE av.id = feedback.audio_version_id
      AND p.created_by = auth.uid()
    )
  );

-- Usuários podem criar feedback em versões de seus projetos
CREATE POLICY "Usuários podem criar feedback em seus projetos"
  ON feedback FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM audio_versions av
      JOIN projects p ON p.id = av.project_id
      WHERE av.id = feedback.audio_version_id
      AND p.created_by = auth.uid()
    )
  );

-- Autor pode atualizar/deletar próprio feedback
CREATE POLICY "Autor pode atualizar feedback"
  ON feedback FOR UPDATE
  USING (author_id = auth.uid());

CREATE POLICY "Autor pode deletar feedback"
  ON feedback FOR DELETE
  USING (author_id = auth.uid());
```

## Verificação

Após executar o SQL, teste:

1. Crie um projeto com a Conta A
2. Faça logout e login com a Conta B
3. A Conta B NÃO deve ver o projeto da Conta A

## Notas

- O código Flutter também foi atualizado para filtrar por `created_by = user.id`
- Isso garante dupla proteção (cliente + servidor)
- Se quiser modo coletivo (todos veem tudo), use as políticas originais em `DATABASE_SCHEMA.md`
