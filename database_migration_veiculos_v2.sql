-- ==========================================
-- NOVA ESTRUTURA DA TABELA VEICULOS V2.0
-- SOLUÇÃO DEFINITIVA PARA PROBLEMAS DE RELACIONAMENTO
-- ==========================================

-- 1. REMOVER TABELA ANTIGA (FAZER BACKUP ANTES!)
-- DROP TABLE IF EXISTS veiculos_backup;
-- CREATE TABLE veiculos_backup AS SELECT * FROM veiculos; -- BACKUP
-- DROP TABLE IF EXISTS veiculos;

-- 2. CRIAR NOVA TABELA VEICULOS OTIMIZADA
CREATE TABLE veiculos (
    -- ===== IDENTIFICAÇÃO =====
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- ===== RELACIONAMENTO COM USUÁRIO (CAMPO ÚNICO) =====
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    -- Usar APENAS user_id para relacionamento com usuários
    -- Remove confusão entre profile_id, uuid_user, usuario_id
    
    -- ===== DADOS FIPE =====
    codigo_fipe VARCHAR(20),
    marca_id INTEGER,
    marca_nome VARCHAR(100) NOT NULL,
    modelo_id INTEGER,
    modelo_nome VARCHAR(150) NOT NULL,
    ano_fabricacao INTEGER NOT NULL,
    ano_modelo INTEGER NOT NULL,
    
    -- ===== INFORMAÇÕES BÁSICAS =====
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT,
    quilometragem INTEGER DEFAULT 0,
    cor VARCHAR(50),
    combustivel VARCHAR(30) NOT NULL DEFAULT 'Flex',
    cambio VARCHAR(30) NOT NULL DEFAULT 'Manual',
    portas INTEGER DEFAULT 4,
    final_placa VARCHAR(1),
    estado_veiculo VARCHAR(30) DEFAULT 'usado', -- novo, seminovo, usado
    
    -- ===== PREÇO E NEGOCIAÇÃO =====
    preco DECIMAL(12,2) NOT NULL,
    tipo_preco VARCHAR(30) DEFAULT 'a_vista', -- a_vista, financiado, parcelado
    aceita_financiamento BOOLEAN DEFAULT false,
    aceita_troca BOOLEAN DEFAULT false,
    aceita_parcelamento BOOLEAN DEFAULT false,
    parcelas_maximas INTEGER,
    entrada_minima DECIMAL(12,2),
    
    -- ===== STATUS E DESTAQUE =====
    status VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (status IN ('ativo', 'pausado', 'vendido', 'removido')),
    destaque BOOLEAN DEFAULT false,
    verificado BOOLEAN DEFAULT false,
    
    -- ===== MÍDIA =====
    foto_principal TEXT, -- URL da foto principal
    fotos JSONB DEFAULT '[]'::jsonb, -- Array de URLs das fotos
    video TEXT, -- URL do vídeo (opcional)
    
    -- ===== ESTATÍSTICAS =====
    visualizacoes INTEGER DEFAULT 0,
    favoritado INTEGER DEFAULT 0, -- Número de usuários que favoritaram
    
    -- ===== DATAS =====
    vendido_em TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===== ÍNDICES PARA PERFORMANCE =====

-- Índice principal para busca por usuário (MAIS IMPORTANTE)
CREATE INDEX idx_veiculos_user_id ON veiculos(user_id);

-- Índices para status e filtros
CREATE INDEX idx_veiculos_status ON veiculos(status);
CREATE INDEX idx_veiculos_destaque ON veiculos(destaque) WHERE destaque = true;
CREATE INDEX idx_veiculos_status_user ON veiculos(user_id, status);

-- Índices para busca e ordenação
CREATE INDEX idx_veiculos_preco ON veiculos(preco);
CREATE INDEX idx_veiculos_marca_modelo ON veiculos(marca_nome, modelo_nome);
CREATE INDEX idx_veiculos_ano ON veiculos(ano_fabricacao, ano_modelo);
CREATE INDEX idx_veiculos_created_at ON veiculos(created_at DESC);

-- Índice composto para dashboard do vendedor
CREATE INDEX idx_veiculos_user_dashboard ON veiculos(user_id, status, destaque, created_at DESC);

-- ===== TRIGGERS PARA UPDATED_AT AUTOMÁTICO =====
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_veiculos_updated_at
    BEFORE UPDATE ON veiculos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===== POLÍTICAS RLS (ROW LEVEL SECURITY) =====
ALTER TABLE veiculos ENABLE ROW LEVEL SECURITY;

-- Usuários podem ver apenas seus próprios veículos
CREATE POLICY "Usuários podem gerenciar seus próprios veículos" ON veiculos
    FOR ALL USING (auth.uid() = user_id);

-- Política para leitura pública (home, busca, etc.)
CREATE POLICY "Veículos ativos são públicos para leitura" ON veiculos
    FOR SELECT USING (status = 'ativo');

-- ===== COMENTÁRIOS DA TABELA =====
COMMENT ON TABLE veiculos IS 'Tabela otimizada de veículos com relacionamento único por user_id';
COMMENT ON COLUMN veiculos.user_id IS 'ID do usuário proprietário do veículo (auth.users.id)';
COMMENT ON COLUMN veiculos.status IS 'Status do veículo: ativo, pausado, vendido, removido';
COMMENT ON COLUMN veiculos.fotos IS 'Array JSON com URLs das fotos do veículo';
COMMENT ON COLUMN veiculos.destaque IS 'Veículo em destaque na home';

-- ===== MIGRAÇÃO DE DADOS (SE NECESSÁRIO) =====
-- EXECUTE APENAS SE TIVER DADOS NA TABELA ANTIGA
/*
INSERT INTO veiculos (
    user_id, codigo_fipe, marca_nome, modelo_nome, titulo, descricao,
    ano_fabricacao, ano_modelo, quilometragem, preco, cor, combustivel,
    cambio, portas, status, destaque, foto_principal, fotos,
    visualizacoes, favoritado, created_at, updated_at
)
SELECT 
    -- Mapear o campo de usuário correto da tabela antiga
    COALESCE(profile_id::uuid, uuid_user::uuid, usuario_id::uuid) as user_id,
    codigo_fipe, marca_nome, modelo_nome, titulo, descricao,
    ano_fabricacao, ano_modelo, quilometragem, preco, cor, combustivel,
    cambio, portas, status, destaque, foto_principal, 
    COALESCE(fotos, '[]'::jsonb) as fotos,
    COALESCE(visualizacoes, 0), COALESCE(favoritado, 0),
    COALESCE(created_at, NOW()), COALESCE(updated_at, NOW())
FROM veiculos_backup
WHERE COALESCE(profile_id, uuid_user, usuario_id) IS NOT NULL;
*/

-- ===== EXEMPLO DE QUERIES OTIMIZADAS =====

-- Buscar veículos do usuário (SIMPLES E DIRETO)
-- SELECT * FROM veiculos WHERE user_id = $1 AND status = 'ativo';

-- Buscar veículos em destaque
-- SELECT * FROM veiculos WHERE status = 'ativo' AND destaque = true ORDER BY created_at DESC;

-- Estatísticas do dashboard
-- SELECT 
--   COUNT(*) as total,
--   COUNT(*) FILTER (WHERE status = 'ativo') as ativos,
--   COUNT(*) FILTER (WHERE status = 'vendido') as vendidos,
--   SUM(preco) FILTER (WHERE status = 'ativo') as valor_estoque
-- FROM veiculos WHERE user_id = $1;

-- ===== VANTAGENS DA NOVA ESTRUTURA =====
/*
✅ CAMPO ÚNICO para relacionamento (user_id)
✅ FOREIGN KEY correta com auth.users
✅ ÍNDICES otimizados para performance
✅ RLS para segurança automática
✅ TRIGGERS para updated_at automático
✅ JSONB para fotos (flexível e indexável)
✅ CHECKs para validação de dados
✅ COMENTÁRIOS para documentação
✅ QUERIES muito mais simples e rápidas
✅ ZERO ambiguidade nos relacionamentos
*/ 