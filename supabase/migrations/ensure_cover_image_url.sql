-- Migration: Garantir que a tabela projects tem o campo cover_image_url
-- Execute este script no Supabase SQL Editor se o campo não existir

-- Verificar se a coluna existe, se não existir, criar
DO $$ 
BEGIN
  -- Verificar se a coluna cover_image_url existe
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'projects' 
    AND column_name = 'cover_image_url'
  ) THEN
    -- Adicionar a coluna se não existir
    ALTER TABLE projects 
    ADD COLUMN cover_image_url TEXT;
    
    RAISE NOTICE 'Coluna cover_image_url adicionada à tabela projects';
  ELSE
    RAISE NOTICE 'Coluna cover_image_url já existe na tabela projects';
  END IF;
END $$;

-- Verificar estrutura atual da tabela
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'projects'
ORDER BY ordinal_position;
