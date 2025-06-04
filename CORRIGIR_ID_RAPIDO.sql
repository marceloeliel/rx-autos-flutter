-- CORRIGIR GERAÇÃO AUTOMÁTICA DE ID

-- 1. Habilitar extensão UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Configurar campo id para gerar UUID automaticamente
ALTER TABLE veiculos ALTER COLUMN id SET DEFAULT uuid_generate_v4();

-- 3. Corrigir registros sem ID
UPDATE veiculos SET id = uuid_generate_v4() WHERE id IS NULL;

-- 4. Teste rápido
INSERT INTO veiculos (user_id, titulo, marca_nome, modelo_nome, preco, status) 
VALUES (
    '68a144a2-acae-4b1c-8322-9f801e8e86dc',
    'TESTE ID AUTOMÁTICO',
    'Toyota',
    'Corolla',
    50000,
    'ativo'
) RETURNING id; 