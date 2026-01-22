# 🔒 Correção de Políticas RLS (Row Level Security)

## Problema

Erro ao criar perfil: `new row violates row-level security policy for table "profiles"`

Isso acontece porque a política RLS não permite que novos usuários criem seu próprio perfil durante o signup.

## Solução

Execute este SQL no Supabase SQL Editor para corrigir as políticas:

```sql
-- Remover política antiga se existir
DROP POLICY IF EXISTS "Usuários podem criar próprio perfil" ON profiles;

-- Criar política que permite usuário criar seu próprio perfil
CREATE POLICY "Usuários podem criar próprio perfil"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Também garantir que usuários podem ver seu próprio perfil
DROP POLICY IF EXISTS "Usuários podem ver próprio perfil" ON profiles;

CREATE POLICY "Usuários podem ver próprio perfil"
  ON profiles FOR SELECT
  USING (auth.uid() = id OR true); -- Permite ver todos (coletivo)
```

## Alternativa: Desabilitar Confirmação de Email

Se você não quiser exigir confirmação de email (útil para desenvolvimento):

1. Vá em **Supabase Dashboard > Authentication > Settings**
2. Desabilite **"Enable email confirmations"**
3. Salve as alterações

## Verificação

Após executar o SQL, teste criar uma nova conta. O perfil deve ser criado automaticamente sem erros.
