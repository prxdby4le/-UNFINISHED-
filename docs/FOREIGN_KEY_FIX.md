# 🔗 Correção de Foreign Key Constraint

## Problema

Erro ao criar projeto:
```
insert or update on table "projects" violates foreign key constraint "projects_created_by_fkey"
Key is not present in table "profiles"
```

## Causa

O usuário está autenticado, mas seu perfil não existe na tabela `profiles`. A foreign key `created_by` referencia `profiles(id)`, mas o perfil não foi criado.

## Soluções

### Solução 1: Criar Perfil Automaticamente (Recomendada)

O código já foi atualizado para criar o perfil automaticamente antes de criar o projeto. Mas se ainda der erro, execute este SQL para garantir que todos os usuários existentes tenham perfil:

```sql
-- Criar perfis para usuários que não têm
INSERT INTO profiles (id, email, role)
SELECT 
  id,
  email,
  'member'
FROM auth.users
WHERE id NOT IN (SELECT id FROM profiles)
ON CONFLICT (id) DO NOTHING;
```

### Solução 2: Ajustar Foreign Key (Alternativa)

Se preferir, você pode tornar a foreign key mais flexível:

```sql
-- Tornar created_by opcional e permitir NULL
ALTER TABLE projects 
  ALTER COLUMN created_by DROP NOT NULL;

-- Recriar constraint com ON DELETE SET NULL
ALTER TABLE projects 
  DROP CONSTRAINT IF EXISTS projects_created_by_fkey;

ALTER TABLE projects 
  ADD CONSTRAINT projects_created_by_fkey 
  FOREIGN KEY (created_by) 
  REFERENCES profiles(id) 
  ON DELETE SET NULL;
```

### Solução 3: Trigger Automático (Avançada)

Criar um trigger que cria o perfil automaticamente quando um usuário é criado:

```sql
-- Função para criar perfil automaticamente
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (NEW.id, NEW.email, 'member')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger que executa após criar usuário
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

## Verificação

Após aplicar uma das soluções, teste:

1. Faça login
2. Crie um novo projeto
3. Deve funcionar sem erros

## Prevenção

O código já foi atualizado para:
- Verificar se o perfil existe antes de criar projeto
- Criar o perfil automaticamente se não existir
- Tratar erros graciosamente
