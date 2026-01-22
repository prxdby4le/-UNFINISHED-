# 📊 Modelagem de Dados - Supabase

## Visão Geral

O banco de dados utiliza PostgreSQL do Supabase com Row Level Security (RLS) para garantir que apenas membros do coletivo tenham acesso aos dados.

## Tabelas

### 1. `profiles` - Perfis de Usuário

Armazena informações dos membros do coletivo.

```sql
-- Tabela de perfis (extensão da auth.users do Supabase)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member', 'guest')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Usuários podem ver todos os perfis do coletivo
CREATE POLICY "Coletivo pode ver perfis"
  ON profiles FOR SELECT
  USING (true);

-- Usuários podem criar seu próprio perfil (importante para signup)
CREATE POLICY "Usuários podem criar próprio perfil"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Usuários podem atualizar apenas seu próprio perfil
CREATE POLICY "Usuários podem atualizar próprio perfil"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);
```

### 2. `projects` - Pastas de Projeto

Representa as "pastas" de projeto onde as versões de áudio são organizadas.

```sql
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  cover_image_url TEXT,
  -- Referência para profiles, mas permite NULL caso o perfil não exista ainda
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_archived BOOLEAN DEFAULT FALSE
);

-- NOTA: Se você já criou a tabela sem ON DELETE SET NULL, execute:
-- ALTER TABLE projects ALTER COLUMN created_by DROP NOT NULL;
-- ALTER TABLE projects DROP CONSTRAINT IF EXISTS projects_created_by_fkey;
-- ALTER TABLE projects ADD CONSTRAINT projects_created_by_fkey 
--   FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;

-- Índices
CREATE INDEX idx_projects_created_at ON projects(created_at DESC);
CREATE INDEX idx_projects_created_by ON projects(created_by);

-- RLS Policies
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Todos os membros autenticados podem ver projetos
CREATE POLICY "Membros podem ver projetos"
  ON projects FOR SELECT
  USING (auth.role() = 'authenticated');

-- Apenas membros podem criar projetos
CREATE POLICY "Membros podem criar projetos"
  ON projects FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Apenas criador ou admin pode atualizar/deletar
CREATE POLICY "Criador pode atualizar projeto"
  ON projects FOR UPDATE
  USING (created_by = auth.uid() OR 
         EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Criador pode deletar projeto"
  ON projects FOR DELETE
  USING (created_by = auth.uid() OR 
         EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
```

### 3. `audio_versions` - Versões de Áudio

Armazena metadados das versões de áudio (Mix 1, Mix Final, Master V2, etc).

```sql
CREATE TABLE audio_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL, -- Ex: "Mix 1", "Mix Final", "Master V2"
  description TEXT,
  file_url TEXT NOT NULL, -- URL do arquivo no R2 via Supabase Storage
  file_size BIGINT, -- Tamanho em bytes
  duration_seconds INTEGER, -- Duração em segundos
  format TEXT CHECK (format IN ('WAV', 'FLAC', 'MP3')), -- Formato do arquivo
  uploaded_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_master BOOLEAN DEFAULT FALSE -- Marca versão master
);

-- Índices
CREATE INDEX idx_audio_versions_project_id ON audio_versions(project_id);
CREATE INDEX idx_audio_versions_created_at ON audio_versions(created_at DESC);
CREATE INDEX idx_audio_versions_project_created ON audio_versions(project_id, created_at DESC);

-- RLS Policies
ALTER TABLE audio_versions ENABLE ROW LEVEL SECURITY;

-- Membros podem ver versões
CREATE POLICY "Membros podem ver versões"
  ON audio_versions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM projects 
      WHERE projects.id = audio_versions.project_id
    )
  );

-- Membros podem criar versões
CREATE POLICY "Membros podem criar versões"
  ON audio_versions FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Uploader ou admin pode atualizar/deletar
CREATE POLICY "Uploader pode atualizar versão"
  ON audio_versions FOR UPDATE
  USING (
    uploaded_by = auth.uid() OR 
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Uploader pode deletar versão"
  ON audio_versions FOR DELETE
  USING (
    uploaded_by = auth.uid() OR 
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4. `feedback` - Sistema de Feedback

Permite comentários e feedback sobre versões de áudio.

```sql
CREATE TABLE feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  audio_version_id UUID REFERENCES audio_versions(id) ON DELETE CASCADE NOT NULL,
  author_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  timestamp_seconds INTEGER, -- Timestamp no áudio (opcional)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_feedback_audio_version ON feedback(audio_version_id);
CREATE INDEX idx_feedback_created_at ON feedback(created_at DESC);

-- RLS Policies
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Membros podem ver feedback
CREATE POLICY "Membros podem ver feedback"
  ON feedback FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM audio_versions av
      JOIN projects p ON p.id = av.project_id
      WHERE av.id = feedback.audio_version_id
    )
  );

-- Membros podem criar feedback
CREATE POLICY "Membros podem criar feedback"
  ON feedback FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Autor pode atualizar/deletar próprio feedback
CREATE POLICY "Autor pode atualizar feedback"
  ON feedback FOR UPDATE
  USING (author_id = auth.uid());

CREATE POLICY "Autor pode deletar feedback"
  ON feedback FOR DELETE
  USING (author_id = auth.uid());
```

## Funções Úteis

### Função para atualizar `updated_at` automaticamente

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em todas as tabelas
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_audio_versions_updated_at BEFORE UPDATE ON audio_versions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_feedback_updated_at BEFORE UPDATE ON feedback
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Storage Buckets (Supabase Storage)

### Bucket: `audio-files`

Armazena os arquivos de áudio. Os arquivos são referenciados na tabela `audio_versions` através do campo `file_url`.

```sql
-- Criar bucket (via Supabase Dashboard ou API)
-- Nome: audio-files
-- Público: false (privado)
-- File size limit: 500MB (ajustar conforme necessário)
-- Allowed MIME types: audio/wav, audio/flac, audio/mpeg
```

### Políticas RLS para Storage

```sql
-- Membros autenticados podem fazer upload
CREATE POLICY "Membros podem fazer upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'audio-files' AND
    auth.role() = 'authenticated'
  );

-- Membros autenticados podem baixar
CREATE POLICY "Membros podem baixar"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'audio-files' AND
    auth.role() = 'authenticated'
  );

-- Apenas uploader ou admin pode deletar
CREATE POLICY "Uploader pode deletar arquivo"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'audio-files' AND
    (owner = auth.uid() OR 
     EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'))
  );
```

## Views Úteis

### View: Versões com informações do projeto

```sql
CREATE VIEW audio_versions_with_project AS
SELECT 
  av.*,
  p.name as project_name,
  p.description as project_description,
  p.cover_image_url as project_cover,
  up.full_name as uploader_name,
  up.email as uploader_email
FROM audio_versions av
JOIN projects p ON p.id = av.project_id
LEFT JOIN profiles up ON up.id = av.uploaded_by
ORDER BY av.created_at DESC;
```

## Notas Importantes

1. **Segurança**: Todas as tabelas usam RLS para garantir acesso apenas a membros autenticados
2. **Cascata**: Deletar um projeto deleta todas as versões e feedback associados
3. **Auditoria**: Campos `created_at` e `updated_at` rastreiam mudanças
4. **Performance**: Índices criados nas colunas mais consultadas
5. **Escalabilidade**: Estrutura preparada para crescimento do coletivo
