# ✅ Verificação e Correção do Campo cover_image_url

## Problema

Ao tentar alterar a capa do projeto, pode ocorrer erro se o campo `cover_image_url` não existir na tabela `projects`.

## Solução

### 1. Verificar se o campo existe

Execute no **Supabase SQL Editor**:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'projects'
AND column_name = 'cover_image_url';
```

### 2. Se o campo não existir, criar

Execute no **Supabase SQL Editor**:

```sql
ALTER TABLE projects 
ADD COLUMN cover_image_url TEXT;
```

### 3. Script Completo (Automático)

Execute o arquivo `supabase/migrations/ensure_cover_image_url.sql` no Supabase SQL Editor. Ele verifica e cria o campo automaticamente se necessário.

## Estrutura Esperada

A tabela `projects` deve ter:

```sql
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  cover_image_url TEXT,  -- ✅ Este campo deve existir
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_archived BOOLEAN DEFAULT FALSE
);
```

## Correção do Código

O código já foi corrigido para:
- ✅ Usar `bytes` no web (não `path`)
- ✅ Usar `path` em mobile/desktop
- ✅ Suportar ambos os ambientes corretamente

## Teste

1. Tente alterar a capa de um projeto
2. Se funcionar, o campo existe e está configurado corretamente
3. Se der erro de campo não encontrado, execute o script SQL acima
