-- =========================================================
-- SOLUÇÃO RÁPIDA - ADICIONAR CAMPO user_id
-- =========================================================

-- Adicionar o campo user_id que está faltando
ALTER TABLE veiculos ADD COLUMN IF NOT EXISTS user_id UUID;

-- Adicionar o campo agencia_id que também será necessário
ALTER TABLE veiculos ADD COLUMN IF NOT EXISTS agencia_id UUID;

-- Popular o user_id com dados existentes
UPDATE veiculos 
SET user_id = COALESCE(profile_id, uuid_user, usuario_id)
WHERE user_id IS NULL;

-- Popular o agencia_id também
UPDATE veiculos 
SET agencia_id = COALESCE(profile_id, uuid_user, usuario_id)
WHERE agencia_id IS NULL;

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_veiculos_user_id ON veiculos(user_id);
CREATE INDEX IF NOT EXISTS idx_veiculos_agencia_id ON veiculos(agencia_id);

-- Inserir dados de teste para funcionamento imediato
INSERT INTO veiculos (
    user_id, profile_id, uuid_user, usuario_id, agencia_id,
    titulo, marca_nome, modelo_nome, 
    ano_fabricacao, ano_modelo, preco, status, descricao,
    combustivel, cambio, cor, portas, quilometragem
) VALUES 
(
    '68a144a2-acae-4b1c-8322-9f801e8e86dc',
    '68a144a2-acae-4b1c-8322-9f801e8e86dc',
    '68a144a2-acae-4b1c-8322-9f801e8e86dc',
    '68a144a2-acae-4b1c-8322-9f801e8e86dc',
    '68a144a2-acae-4b1c-8322-9f801e8e86dc',
    'Honda Civic LXR 2020 - Excelente Estado',
    'Honda',
    'Civic',
    2020,
    2020,
    85000,
    'ativo',
    'Veículo em excelente estado, revisões em dia, único dono.',
    'Flex',
    'Automático',
    'Branco',
    4,
    15000
),
(
    '68a144a2-acae-4b1c-8322-9f801e8e86dc',
    '68a144a2-acae-4b1c-8322-9f801e8e86dc',
    '68a144a2-acae-4b1c-8322-9f801e8e86dc',
    '68a144a2-acae-4b1c-8322-9f801e8e86dc',
    '68a144a2-acae-4b1c-8322-9f801e8e86dc',
    'Toyota Corolla XEi 2019 - Muito Conservado',
    'Toyota',
    'Corolla',
    2019,
    2019,
    75000,
    'ativo',
    'Corolla XEi automático, muito bem conservado, IPVA pago.',
    'Flex',
    'Automático',
    'Prata',
    4,
    25000
);

-- Verificar se funcionou
SELECT 
    COUNT(*) as total_registros,
    COUNT(user_id) as com_user_id,
    COUNT(agencia_id) as com_agencia_id
FROM veiculos;

-- Mostrar dados inseridos
SELECT id, titulo, marca_nome, user_id FROM veiculos 
WHERE user_id = '68a144a2-acae-4b1c-8322-9f801e8e86dc'; 