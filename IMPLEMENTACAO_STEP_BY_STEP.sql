-- ====================================================================
-- IMPLEMENTAÇÃO STEP-BY-STEP DA NOVA ESTRUTURA DE VEÍCULOS
-- EXECUÇÃO SEGURA COM BACKUP E TRANSIÇÃO GRADUAL
-- ====================================================================

-- =====================================================
-- PASSO 1: BACKUP COMPLETO (OBRIGATÓRIO!)
-- =====================================================
-- Execute isso PRIMEIRO para ter backup dos dados

CREATE TABLE veiculos_backup AS 
SELECT * FROM veiculos;

-- Verificar backup
SELECT COUNT(*) as total_backup FROM veiculos_backup;
SELECT COUNT(*) as total_original FROM veiculos;
-- Os dois números devem ser iguais!

-- =====================================================
-- PASSO 2: ADICIONAR CAMPO user_id NA TABELA EXISTENTE
-- =====================================================
-- Primeiro, vamos adicionar o campo sem quebrar nada

ALTER TABLE veiculos 
ADD COLUMN user_id UUID;

-- Verificar se foi adicionado
DESCRIBE veiculos; -- ou \d veiculos no psql

-- =====================================================
-- PASSO 3: POPULAR O CAMPO user_id COM DADOS EXISTENTES
-- =====================================================
-- Mapear os dados existentes para o novo campo

UPDATE veiculos 
SET user_id = COALESCE(
    profile_id::uuid, 
    uuid_user::uuid, 
    usuario_id::uuid
)
WHERE user_id IS NULL;

-- Verificar quantos registros foram atualizados
SELECT 
    COUNT(*) as total,
    COUNT(user_id) as com_user_id,
    COUNT(*) - COUNT(user_id) as sem_user_id
FROM veiculos;

-- =====================================================
-- PASSO 4: CRIAR ÍNDICE PARA PERFORMANCE
-- =====================================================
-- Criar índice principal para o novo campo

CREATE INDEX idx_veiculos_user_id ON veiculos(user_id);
CREATE INDEX idx_veiculos_user_status ON veiculos(user_id, status);

-- =====================================================
-- PASSO 5: TESTE COM DADOS REAIS
-- =====================================================
-- Testar se a busca funciona com user_id

-- Exemplo: substitua 'SEU_USER_ID_AQUI' por um ID real
SELECT 
    id, 
    titulo, 
    user_id, 
    profile_id, 
    uuid_user, 
    usuario_id
FROM veiculos 
WHERE user_id = 'SEU_USER_ID_AQUI'
LIMIT 5;

-- Verificar se há dados órfãos (sem user_id)
SELECT 
    id, 
    titulo, 
    profile_id, 
    uuid_user, 
    usuario_id
FROM veiculos 
WHERE user_id IS NULL;

-- =====================================================
-- PASSO 6: (OPCIONAL) LIMPAR DADOS ÓRFÃOS
-- =====================================================
-- Se houver registros sem user_id válido, decidir o que fazer:

-- Opção A: Deletar registros órfãos
-- DELETE FROM veiculos WHERE user_id IS NULL;

-- Opção B: Atribuir a um usuário específico
-- UPDATE veiculos 
-- SET user_id = 'ID_DO_USUARIO_ADMIN' 
-- WHERE user_id IS NULL;

-- =====================================================
-- PASSO 7: TORNAR user_id OBRIGATÓRIO
-- =====================================================
-- Depois que todos os dados estiverem OK

ALTER TABLE veiculos 
ALTER COLUMN user_id SET NOT NULL;

-- =====================================================
-- PASSO 8: ADICIONAR FOREIGN KEY (OPCIONAL)
-- =====================================================
-- Adicionar relacionamento com auth.users

ALTER TABLE veiculos 
ADD CONSTRAINT fk_veiculos_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- =====================================================
-- PASSO 9: CORRIGIR NOME DO CAMPO (BONUS)
-- =====================================================
-- Corrigir "stado_veiculo" para "estado_veiculo"

ALTER TABLE veiculos 
RENAME COLUMN stado_veiculo TO estado_veiculo;

-- =====================================================
-- PASSO 10: VERIFICAÇÃO FINAL
-- =====================================================
-- Verificar se tudo está funcionando

-- 1. Estrutura da tabela
\d veiculos

-- 2. Índices criados
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'veiculos';

-- 3. Teste de consulta por user_id
SELECT 
    COUNT(*) as total_veiculos,
    COUNT(DISTINCT user_id) as usuarios_unicos
FROM veiculos 
WHERE user_id IS NOT NULL;

-- 4. Estatísticas por usuário
SELECT 
    user_id,
    COUNT(*) as total_veiculos,
    COUNT(*) FILTER (WHERE status = 'ativo') as ativos,
    COUNT(*) FILTER (WHERE status = 'vendido') as vendidos
FROM veiculos 
WHERE user_id IS NOT NULL
GROUP BY user_id
ORDER BY total_veiculos DESC
LIMIT 10;

-- =====================================================
-- PASSO 11: (FUTURO) REMOVER CAMPOS ANTIGOS
-- =====================================================
-- DEPOIS que o app estiver funcionando 100% com user_id,
-- você pode remover os campos antigos:

-- ALTER TABLE veiculos DROP COLUMN profile_id;
-- ALTER TABLE veiculos DROP COLUMN uuid_user;
-- ALTER TABLE veiculos DROP COLUMN usuario_id;

-- =====================================================
-- QUERIES DE EXEMPLO PARA O APP
-- =====================================================

-- Buscar veículos de um usuário:
-- SELECT * FROM veiculos WHERE user_id = $1 AND status = 'ativo';

-- Estatísticas do dashboard:
-- SELECT 
--   COUNT(*) as total,
--   COUNT(*) FILTER (WHERE status = 'ativo') as ativos,
--   COUNT(*) FILTER (WHERE status = 'vendido') as vendidos,
--   SUM(preco) FILTER (WHERE status = 'ativo') as valor_estoque
-- FROM veiculos WHERE user_id = $1;

-- =====================================================
-- ROLLBACK SE NECESSÁRIO
-- =====================================================
-- Se algo der errado, você pode voltar ao estado anterior:

-- DROP TABLE veiculos;
-- CREATE TABLE veiculos AS SELECT * FROM veiculos_backup;
-- Mas CUIDADO: você perderá dados criados após o backup!

-- =====================================================
-- SUCESSO! 🎉
-- =====================================================
-- Se chegou até aqui, sua nova estrutura está pronta!
-- O app agora pode usar user_id como campo principal
-- com fallback para os campos antigos durante a transição. 