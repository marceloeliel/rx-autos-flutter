-- =========================================================
-- CRIAÇÃO INICIAL DA TABELA VEÍCULOS NO SUPABASE
-- Execute isso PRIMEIRO se a tabela não existir
-- =========================================================

-- =====================================================
-- PASSO 1: CRIAR TABELA VEÍCULOS INICIAL
-- =====================================================
-- Esta é a estrutura inicial baseada no que o código espera

CREATE TABLE IF NOT EXISTS veiculos (
    -- ===== IDENTIFICAÇÃO =====
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- ===== RELACIONAMENTO (estrutura atual + nova) =====
    profile_id UUID, -- Campo atual usado pelo app
    uuid_user UUID,  -- Campo alternativo atual
    usuario_id UUID, -- Campo alternativo atual
    agencia_id UUID, -- Campo usado no add_vehicle_screen
    user_id UUID,    -- NOVO CAMPO principal
    
    -- ===== DADOS FIPE =====
    codigo_fipe VARCHAR(20),
    marca_id INTEGER,
    marca_nome VARCHAR(100) NOT NULL,
    modelo_id INTEGER,
    modelo_nome VARCHAR(150) NOT NULL,
    ano_fabricacao INTEGER NOT NULL DEFAULT 0,
    ano_modelo INTEGER NOT NULL DEFAULT 0,
    
    -- ===== INFORMAÇÕES BÁSICAS =====
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT,
    quilometragem INTEGER DEFAULT 0,
    cor VARCHAR(50),
    combustivel VARCHAR(30) NOT NULL DEFAULT 'Flex',
    cambio VARCHAR(30) NOT NULL DEFAULT 'Manual',
    portas INTEGER DEFAULT 4,
    final_placa VARCHAR(1),
    estado_veiculo VARCHAR(30) DEFAULT 'usado',
    
    -- ===== PREÇO E NEGOCIAÇÃO =====
    preco DECIMAL(12,2) NOT NULL DEFAULT 0,
    tipo_preco VARCHAR(30) DEFAULT 'a_vista',
    aceita_financiamento BOOLEAN DEFAULT false,
    aceita_troca BOOLEAN DEFAULT false,
    aceita_parcelamento BOOLEAN DEFAULT false,
    parcelas_maximas INTEGER,
    entrada_minima DECIMAL(12,2),
    
    -- ===== STATUS E DESTAQUE =====
    status VARCHAR(20) NOT NULL DEFAULT 'ativo' 
        CHECK (status IN ('ativo', 'pausado', 'vendido', 'removido')),
    destaque BOOLEAN DEFAULT false,
    verificado BOOLEAN DEFAULT false,
    
    -- ===== MÍDIA =====
    foto_principal TEXT,
    fotos JSONB DEFAULT '[]'::jsonb,
    video TEXT,
    
    -- ===== ESTATÍSTICAS =====
    visualizacoes INTEGER DEFAULT 0,
    favoritado INTEGER DEFAULT 0,
    
    -- ===== DATAS =====
    vendido_em TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- PASSO 2: CRIAR ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índice principal para user_id (nova estrutura)
CREATE INDEX IF NOT EXISTS idx_veiculos_user_id ON veiculos(user_id);

-- Índices para compatibilidade com estrutura atual
CREATE INDEX IF NOT EXISTS idx_veiculos_profile_id ON veiculos(profile_id);
CREATE INDEX IF NOT EXISTS idx_veiculos_uuid_user ON veiculos(uuid_user);
CREATE INDEX IF NOT EXISTS idx_veiculos_usuario_id ON veiculos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_veiculos_agencia_id ON veiculos(agencia_id);

-- Índices para status e filtros
CREATE INDEX IF NOT EXISTS idx_veiculos_status ON veiculos(status);
CREATE INDEX IF NOT EXISTS idx_veiculos_destaque ON veiculos(destaque) WHERE destaque = true;
CREATE INDEX IF NOT EXISTS idx_veiculos_user_status ON veiculos(user_id, status);

-- Índices para busca e ordenação
CREATE INDEX IF NOT EXISTS idx_veiculos_preco ON veiculos(preco);
CREATE INDEX IF NOT EXISTS idx_veiculos_marca_modelo ON veiculos(marca_nome, modelo_nome);
CREATE INDEX IF NOT EXISTS idx_veiculos_created_at ON veiculos(created_at DESC);

-- =====================================================
-- PASSO 3: TRIGGER PARA UPDATED_AT AUTOMÁTICO
-- =====================================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger na tabela veiculos
DROP TRIGGER IF EXISTS update_veiculos_updated_at ON veiculos;
CREATE TRIGGER update_veiculos_updated_at
    BEFORE UPDATE ON veiculos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- PASSO 4: TRIGGER PARA POPULAR user_id AUTOMATICAMENTE
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
    
    -- Garantir que pelo menos um campo de usuário está preenchido
    IF NEW.user_id IS NULL AND NEW.profile_id IS NULL AND NEW.uuid_user IS NULL AND NEW.usuario_id IS NULL AND NEW.agencia_id IS NULL THEN
        RAISE EXCEPTION 'Pelo menos um campo de usuário deve ser preenchido (user_id, profile_id, uuid_user, usuario_id, agencia_id)';
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para INSERT e UPDATE
DROP TRIGGER IF EXISTS ensure_user_id_on_veiculos ON veiculos;
CREATE TRIGGER ensure_user_id_on_veiculos
    BEFORE INSERT OR UPDATE ON veiculos
    FOR EACH ROW
    EXECUTE FUNCTION ensure_user_id_populated();

-- =====================================================
-- PASSO 5: RLS (ROW LEVEL SECURITY) OPCIONAL
-- =====================================================

-- Habilitar RLS se quiser controle de acesso por linha
-- ALTER TABLE veiculos ENABLE ROW LEVEL SECURITY;

-- Política para usuários verem apenas seus próprios veículos
-- CREATE POLICY "Usuários podem gerenciar seus próprios veículos" ON veiculos
--     FOR ALL USING (
--         auth.uid()::text = user_id::text OR 
--         auth.uid()::text = profile_id::text OR 
--         auth.uid()::text = uuid_user::text OR 
--         auth.uid()::text = usuario_id::text OR
--         auth.uid()::text = agencia_id::text
--     );

-- =====================================================
-- PASSO 6: INSERIR DADOS DE TESTE (OPCIONAL)
-- =====================================================

-- Inserir alguns veículos de teste para validar
-- DESCOMENTE se quiser dados de exemplo

/*
INSERT INTO veiculos (
    user_id, profile_id, titulo, marca_nome, modelo_nome, 
    ano_fabricacao, ano_modelo, preco, status, descricao
) VALUES 
(
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
    'Toyota Corolla XEi 2019 - Muito Conservado',
    'Toyota', 
    'Corolla',
    2019,
    2019,
    75000.00,
    'ativo',
    'Corolla XEi automático, muito bem conservado, IPVA pago.'
),
(
    '6efc6cdf-e46b-4c46-841d-56bb378d26b2',
    '6efc6cdf-e46b-4c46-841d-56bb378d26b2',
    'Volkswagen Jetta TSI 2021 - Seminovo',
    'Volkswagen',
    'Jetta',
    2021,
    2021,
    95000.00,
    'vendido',
    'Jetta TSI turbo, baixa quilometragem, na garantia.'
);
*/

-- =====================================================
-- PASSO 7: VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar se a tabela foi criada corretamente
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'veiculos' 
ORDER BY ordinal_position;

-- Verificar índices criados
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'veiculos';

-- =====================================================
-- SUCESSO! 🎉
-- =====================================================

-- COMENTÁRIOS FINAIS:
-- ✅ Tabela veiculos criada com compatibilidade total
-- ✅ Índices otimizados para todas as estratégias de busca
-- ✅ Triggers automáticos para updated_at e user_id
-- ✅ Estrutura pronta para nova arquitetura
-- ✅ Compatibilidade 100% com código atual

-- PRÓXIMOS PASSOS:
-- 1. Execute este script no Supabase
-- 2. Teste criando um veículo no app
-- 3. Verifique o dashboard
-- 4. Celebre! 🚀 