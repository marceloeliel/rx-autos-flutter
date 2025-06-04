-- =========================================================
-- SOLUÇÃO FINAL - BASEADA NA ESTRUTURA REAL
-- Sua tabela já tem quase tudo, só vou adicionar o que falta
-- =========================================================

-- 1. Adicionar apenas os campos que realmente faltam
ALTER TABLE veiculos ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE veiculos ADD COLUMN IF NOT EXISTS agencia_id UUID;

-- 2. Popular user_id com dados dos campos existentes
UPDATE veiculos 
SET user_id = COALESCE(profile_id, uuid_user, usuario_id)
WHERE user_id IS NULL;

-- 3. Popular agencia_id também (para compatibilidade)
UPDATE veiculos 
SET agencia_id = COALESCE(profile_id, uuid_user, usuario_id)
WHERE agencia_id IS NULL;

-- 4. Corrigir o campo com erro de digitação (BONUS)
ALTER TABLE veiculos RENAME COLUMN stado_veiculo TO estado_veiculo;

-- 5. Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_veiculos_user_id ON veiculos(user_id);
CREATE INDEX IF NOT EXISTS idx_veiculos_agencia_id ON veiculos(agencia_id);
CREATE INDEX IF NOT EXISTS idx_veiculos_profile_id ON veiculos(profile_id);

-- 6. Inserir dados de teste para o usuário atual
INSERT INTO veiculos (
    user_id, profile_id, uuid_user, usuario_id, agencia_id,
    titulo, marca_nome, modelo_nome, 
    ano_fabricacao, ano_modelo, preco, status, descricao,
    combustivel, cambio, cor, portas, quilometragem,
    aceita_financiamento, aceita_troca, aceita_parcelamento,
    destaque, estado_veiculo
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
    85000.00,
    'ativo',
    'Veículo em excelente estado, revisões em dia, único dono.',
    'Flex',
    'Automático',
    'Branco',
    4,
    15000,
    true,
    false,
    true,
    false,
    'Seminovo'
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
    75000.00,
    'ativo',
    'Corolla XEi automático, muito bem conservado, IPVA pago.',
    'Flex',
    'Automático',
    'Prata',
    4,
    25000,
    true,
    true,
    false,
    true,
    'Usado'
);

-- 7. Verificação final
SELECT 
    COUNT(*) as total_veiculos,
    COUNT(user_id) as com_user_id,
    COUNT(agencia_id) as com_agencia_id,
    COUNT(profile_id) as com_profile_id
FROM veiculos;

-- 8. Mostrar dados do usuário
SELECT 
    id, titulo, marca_nome, modelo_nome, user_id, profile_id
FROM veiculos 
WHERE user_id = '68a144a2-acae-4b1c-8322-9f801e8e86dc'
ORDER BY created_at DESC; 