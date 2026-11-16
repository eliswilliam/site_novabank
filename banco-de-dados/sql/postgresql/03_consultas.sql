-- =============================================================================
-- PROJETO: Nova Bank - Instituicao de Pagamento S.A. (banco 100% digital)
-- ETAPA:   Modelagem e implementacao do banco de dados (versao minima)
-- ARQUIVO: 03_consultas.sql
-- SGBD:    PostgreSQL 17 (Neon - Postgres serverless)
-- AUTORES: (equipe do projeto)
-- DATA:    novembro/2026
-- =============================================================================
-- Como executar no Neon:
--   1) Console do Neon > SQL Editor: cole o arquivo 00_nova_bank_completo.sql e clique em Run; ou
--   2) Pelo terminal, com a connection string do projeto (Connection Details > Direct connection):
--      psql "postgresql://USUARIO:SENHA@ep-xxxx.regiao.aws.neon.tech/neondb?sslmode=require" -f 03_consultas.sql
--
-- Observacoes do Neon:
--   - use a conexao direta (sem -pooler) para executar DDL;
--   - o banco do projeto e o neondb e o schema e o public: nao e preciso criar banco;
--   - os objetos sao criados no banco atual da conexao.


-- ===========================================================================
-- 1. Listagem de clientes com suas contas
-- Relaciona CLIENTE e CONTA (1:N) e mostra o saldo atual de cada conta.
-- ===========================================================================
SELECT c.id_cliente,
       c.nome_completo,
       c.uf,
       co.numero_conta,
       co.tipo_conta,
       co.saldo,
       co.status
FROM cliente c
JOIN conta co ON co.id_cliente = c.id_cliente
ORDER BY c.nome_completo, co.numero_conta;

-- ===========================================================================
-- 2. Extrato de uma conta (cliente + conta + transacao)
-- Junta tres tabelas para montar o extrato de uma conta especifica.
-- ===========================================================================
SELECT c.nome_completo,
       co.numero_conta,
       t.data_hora,
       t.tipo,
       t.valor,
       t.descricao,
       t.status
FROM transacao t
JOIN conta co   ON co.id_conta = t.id_conta_origem
JOIN cliente c  ON c.id_cliente = co.id_cliente
WHERE co.numero_conta = '10001-2'
ORDER BY t.data_hora DESC;

-- ===========================================================================
-- 3. Gastos por cartao de credito
-- Agrega as compras de cada cartao, relacionando CARTAO, CONTA, CLIENTE e TRANSACAO.
-- ===========================================================================
SELECT c.nome_completo,
       ca.numero_mascarado,
       ca.bandeira,
       COUNT(t.id_transacao)        AS qtd_compras,
       SUM(t.valor)                 AS total_gasto,
       ca.limite_total,
       ca.limite_disponivel
FROM cartao ca
JOIN conta co        ON co.id_conta = ca.id_conta
JOIN cliente c       ON c.id_cliente = co.id_cliente
LEFT JOIN transacao t ON t.id_cartao = ca.id_cartao
                     AND t.tipo = 'compra_credito'
                     AND t.status = 'concluida'
WHERE ca.tipo_cartao = 'credito'
GROUP BY c.nome_completo, ca.id_cartao, ca.numero_mascarado, ca.bandeira,
         ca.limite_total, ca.limite_disponivel
ORDER BY total_gasto DESC;

-- ===========================================================================
-- 4. Emprestimos por cliente e comprometimento da renda
-- Calcula a parcela estimada (tabela Price) e o peso dela na renda do cliente.
-- ===========================================================================
SELECT c.nome_completo,
       c.renda_mensal,
       e.valor_principal,
       e.taxa_juros_mensal,
       e.prazo_meses,
       ROUND(e.valor_principal * (e.taxa_juros_mensal / 100.0)
             / (1 - POWER(1 + e.taxa_juros_mensal / 100.0, -e.prazo_meses)), 2) AS parcela_estimada,
       ROUND(100.0 * (e.valor_principal * (e.taxa_juros_mensal / 100.0)
             / (1 - POWER(1 + e.taxa_juros_mensal / 100.0, -e.prazo_meses)))
             / c.renda_mensal, 1) AS comprometimento_renda,
       e.status
FROM emprestimo e
JOIN cliente c ON c.id_cliente = e.id_cliente
ORDER BY comprometimento_renda DESC;

-- ===========================================================================
-- 5. Resumo das transacoes por tipo
-- Agrupa as movimentacoes concluidas por natureza, com quantidade, total e ticket medio.
-- ===========================================================================
SELECT t.tipo,
       COUNT(*)              AS qtd_movimentacoes,
       SUM(t.valor)          AS valor_total,
       ROUND(AVG(t.valor), 2) AS valor_medio
FROM transacao t
WHERE t.status = 'concluida'
GROUP BY t.tipo
ORDER BY valor_total DESC;

-- ===========================================================================
-- 6. Conferencia de saldo (integridade dos dados)
-- Recalcula o saldo de cada conta a partir das transacoes e compara com o saldo gravado.
-- ===========================================================================
SELECT co.numero_conta,
       co.saldo                                   AS saldo_gravado,
       COALESCE(SUM(CASE WHEN t.id_conta_destino = co.id_conta THEN t.valor ELSE 0 END), 0)
     - COALESCE(SUM(CASE WHEN t.id_conta_origem  = co.id_conta THEN t.valor ELSE 0 END), 0)
                                                  AS saldo_calculado
FROM conta co
LEFT JOIN transacao t
       ON (t.id_conta_origem = co.id_conta OR t.id_conta_destino = co.id_conta)
      AND t.status = 'concluida'
      AND t.tipo <> 'compra_credito'
GROUP BY co.id_conta, co.numero_conta, co.saldo
ORDER BY co.numero_conta;

-- ===========================================================================
-- Consulta extra: CTE + funcao de janela (saldo acumulado do extrato)
-- ===========================================================================
WITH movimento AS (
    SELECT t.data_hora,
           t.tipo,
           CASE WHEN t.id_conta_destino = co.id_conta THEN  t.valor
                WHEN t.id_conta_origem  = co.id_conta THEN -t.valor
                ELSE 0 END AS efeito
    FROM transacao t
    JOIN conta co ON co.id_conta IN (t.id_conta_origem, t.id_conta_destino)
    WHERE co.numero_conta = '10001-2'
      AND t.status = 'concluida'
      AND t.tipo <> 'compra_credito'
)
SELECT data_hora,
       tipo,
       efeito,
       SUM(efeito) OVER (ORDER BY data_hora, tipo) AS saldo_acumulado
FROM movimento
ORDER BY data_hora;
