-- =========================================================
-- CORREÇÃO RÁPIDA - ADICIONAR CAMPO user_id FALTANTE
-- Execute isso se a tabela já existir mas sem o campo user_id
-- =========================================================

-- =====================================================
-- OPÇÃO 1: SE A TABELA JÁ EXISTIR (MAIS PROVÁVEL)
-- =====================================================

-- Verificar se a coluna user_id existe
DO $$
BEGIN
    -- Tentar adicionar a coluna user_id se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'veiculos' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE veiculos ADD COLUMN user_id UUID;
        RAISE NOTICE 'Coluna user_id adicionada com sucesso!';
    ELSE
        RAISE NOTICE 'Coluna user_id já existe!';
    END IF;
END $$;

-- Verificar se outras colunas essenciais existem e adicionar se necessário
DO $$
BEGIN
    -- Adicionar profile_id se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'veiculos' AND column_name = 'profile_id'
    ) THEN
        ALTER TABLE veiculos ADD COLUMN profile_id UUID;
        RAISE NOTICE 'Coluna profile_id adicionada!';
    END IF;
    
    -- Adicionar agencia_id se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'veiculos' AND column_name = 'agencia_id'
    ) THEN
        ALTER TABLE veiculos ADD COLUMN agencia_id UUID;
        RAISE NOTICE 'Coluna agencia_id adicionada!';
    END IF;
    
    -- Adicionar uuid_user se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'veiculos' AND column_name = 'uuid_user'
    ) THEN
        ALTER TABLE veiculos ADD COLUMN uuid_user UUID;
        RAISE NOTICE 'Coluna uuid_user adicionada!';
    END IF;
    
    -- Adicionar usuario_id se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'veiculos' AND column_name = 'usuario_id'
    ) THEN
        ALTER TABLE veiculos ADD COLUMN usuario_id UUID;
        RAISE NOTICE 'Coluna usuario_id adicionada!';
    END IF;
END $$;

-- =====================================================
-- CRIAR ÍNDICES SE NÃO EXISTIREM
-- =====================================================

-- Índice para user_id
CREATE INDEX IF NOT EXISTS idx_veiculos_user_id ON veiculos(user_id);

-- Índices para outros campos de usuário
CREATE INDEX IF NOT EXISTS idx_veiculos_profile_id ON veiculos(profile_id);
CREATE INDEX IF NOT EXISTS idx_veiculos_agencia_id ON veiculos(agencia_id);
CREATE INDEX IF NOT EXISTS idx_veiculos_uuid_user ON veiculos(uuid_user);
CREATE INDEX IF NOT EXISTS idx_veiculos_usuario_id ON veiculos(usuario_id);

-- =====================================================
-- CRIAR TRIGGER PARA POPULAR user_id AUTOMATICAMENTE
-- =====================================================

-- Função para garantir que user_id seja sempre populado
CREATE OR REPLACE FUNCTION ensure_user_id_populated()
RETURNS TRIGGER AS $$
BEGIN
    -- Se user_id estiver vazio, tenta popular com outros campos
    IF NEW.user_id IS NULL THEN
        NEW.user_id = COALESCE(
            NEW.profile_id,
            NEW.uuid_user,
            NEW.usuario_id,
            NEW.agencia_id
        );
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Remover trigger anterior se existir e criar novo
DROP TRIGGER IF EXISTS ensure_user_id_on_veiculos ON veiculos;
CREATE TRIGGER ensure_user_id_on_veiculos
    BEFORE INSERT OR UPDATE ON veiculos
    FOR EACH ROW
    EXECUTE FUNCTION ensure_user_id_populated();

-- =====================================================
-- POPULAR user_id NOS REGISTROS EXISTENTES
-- =====================================================

-- Atualizar registros que já existem na tabela
UPDATE veiculos 
SET user_id = COALESCE(
    profile_id,
    uuid_user,
    usuario_id,
    agencia_id
)
WHERE user_id IS NULL;

-- =====================================================
-- VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar estrutura da tabela
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'veiculos' 
  AND column_name IN ('user_id', 'profile_id', 'agencia_id', 'uuid_user', 'usuario_id')
ORDER BY column_name;

-- Contar registros na tabela
SELECT 
    COUNT(*) as total_registros,
    COUNT(user_id) as com_user_id,
    COUNT(profile_id) as com_profile_id,
    COUNT(agencia_id) as com_agencia_id
FROM veiculos;

-- =====================================================
-- AGORA VOCÊ PODE EXECUTAR O INSERT!
-- =====================================================

-- Este INSERT agora funcionará:
INSERT INTO veiculos (
    user_id, profile_id, agencia_id, titulo, marca_nome, modelo_nome, 
    ano_fabricacao, ano_modelo, preco, status, descricao
) VALUES 
(
    '6efc6cdf-e46b-4c46-841d-56bb378d26b2',
    '6efc6cdf-e46b-4c46-841d-56bb378d26b2',
    '6efc6cdf-e46b-4c46-841d-56bb378d26b2',
    'Honda Civic LXR 2020 - Excelente Estado',
    'Honda',
    'Civic',
    2020,
    2020,
    85000.00,
    'ativo',
    'Veículo em excelente estado, revisões em dia, único dono.'
),
(
    '6efc6cdf-e46b-4c46-841d-56bb378d26b2',
    '6efc6cdf-e46b-4c46-841d-56bb378d26b2',
    '6efc6cdf-e46b-4c46-841d-56bb378d26b2',
    'Toyota Corolla XEi 2019 - Muito Conservado',
    'Toyota', 
    'Corolla',
    2019,
    2019,
    75000.00,
    'ativo',
    'Corolla XEi automático, muito bem conservado, IPVA pago.'
);

-- =====================================================
-- SUCESSO! 🎉
-- =====================================================

RAISE NOTICE '✅ CORREÇÃO CONCLUÍDA COM SUCESSO!';
RAISE NOTICE '✅ Campo user_id adicionado e configurado!';
RAISE NOTICE '✅ Triggers automáticos criados!';
RAISE NOTICE '✅ Índices otimizados criados!';
RAISE NOTICE '✅ Agora você pode usar o app normalmente!'; 