-- =========================================================
-- CORRIGIR GERAÇÃO AUTOMÁTICA DE ID PARA VEÍCULOS
-- =========================================================

-- 1. Verificar se a extensão uuid-ossp está habilitada
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Alterar a coluna id para ter valor padrão automático
ALTER TABLE veiculos 
ALTER COLUMN id SET DEFAULT uuid_generate_v4();

-- 3. Criar função para garantir que o ID seja sempre gerado
CREATE OR REPLACE FUNCTION ensure_vehicle_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Se o ID não foi fornecido, gerar um novo
    IF NEW.id IS NULL THEN
        NEW.id = uuid_generate_v4();
    END IF;
    
    -- Garantir que created_at e updated_at sejam preenchidos
    IF NEW.created_at IS NULL THEN
        NEW.created_at = NOW();
    END IF;
    
    NEW.updated_at = NOW();
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 4. Criar trigger para executar antes de cada insert/update
DROP TRIGGER IF EXISTS ensure_vehicle_id_trigger ON veiculos;
CREATE TRIGGER ensure_vehicle_id_trigger
    BEFORE INSERT OR UPDATE ON veiculos
    FOR EACH ROW
    EXECUTE FUNCTION ensure_vehicle_id();

-- 5. Atualizar registros existentes que não têm ID
UPDATE veiculos 
SET id = uuid_generate_v4() 
WHERE id IS NULL;

-- 6. Teste de inserção para verificar se funciona
DO $$
DECLARE
    test_id UUID;
BEGIN
    INSERT INTO veiculos (
        user_id, profile_id, titulo, marca_nome, modelo_nome,
        ano_fabricacao, ano_modelo, preco, status, descricao
    ) VALUES (
        '68a144a2-acae-4b1c-8322-9f801e8e86dc',
        '68a144a2-acae-4b1c-8322-9f801e8e86dc',
        'TESTE - BMW X1 2023',
        'BMW',
        'X1',
        2023,
        2023,
        120000,
        'ativo',
        'Veículo de teste para verificar geração de ID'
    ) RETURNING id INTO test_id;
    
    RAISE NOTICE '✅ Teste concluído! ID gerado automaticamente: %', test_id;
    
    -- Remover o registro de teste
    DELETE FROM veiculos WHERE id = test_id;
    RAISE NOTICE '✅ Registro de teste removido!';
END $$;

-- 7. Verificação final
SELECT 
    COUNT(*) as total_veiculos,
    COUNT(CASE WHEN id IS NOT NULL THEN 1 END) as com_id_valido,
    COUNT(CASE WHEN id IS NULL THEN 1 END) as sem_id
FROM veiculos;

-- 8. Mostrar alguns registros para verificar
SELECT 
    id, titulo, marca_nome, created_at, updated_at
FROM veiculos 
ORDER BY created_at DESC 
LIMIT 5;

-- =========================================================
-- SUCESSO!
-- =========================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 ========================================';
    RAISE NOTICE '🎉 CORREÇÃO DE ID CONCLUÍDA!';
    RAISE NOTICE '🎉 ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Extensão uuid-ossp habilitada!';
    RAISE NOTICE '✅ Campo id configurado para gerar UUID automático!';
    RAISE NOTICE '✅ Trigger criado para garantir ID único!';
    RAISE NOTICE '✅ Campos created_at/updated_at automáticos!';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 AGORA CADA VEÍCULO TERÁ SEU PRÓPRIO ID!';
    RAISE NOTICE '📱 Teste o cadastro novamente!';
    RAISE NOTICE '';
END $$; 