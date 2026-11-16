-- =============================================================================
-- PROJETO: Nova Bank - Instituicao de Pagamento S.A. (banco 100% digital)
-- ETAPA:   Modelagem e implementacao do banco de dados
-- ARQUIVO: 03_consultas.sql
-- SGBD:    MySQL 8.0 ou superior
-- AUTORES: (equipe do projeto)
-- DATA:    novembro/2026
-- =============================================================================
-- Consultas de demonstracao (SELECT), com comentarios de objetivo.

USE nova_bank;

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
-- Agrega as compras de cada cartao de credito, relacionando CARTAO, CONTA, CLIENTE e TRANSACAO.
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
-- 4. Situacao das parcelas de cada emprestimo
-- Mostra, por contrato, quantas parcelas foram pagas e quantas seguem em aberto.
-- ===========================================================================
SELECT e.id_emprestimo,
       c.nome_completo,
       e.valor_principal,
       e.taxa_juros_mensal,
       e.prazo_meses,
       e.status                       AS status_contrato,
       COUNT(p.id_parcela)            AS qtd_parcelas,
       SUM(CASE WHEN p.status = 'paga' THEN 1 ELSE 0 END) AS parcelas_pagas,
       SUM(CASE WHEN p.status IN ('aberta','atrasada') THEN 1 ELSE 0 END) AS parcelas_em_aberto,
       SUM(CASE WHEN p.status = 'paga' THEN p.valor_parcela ELSE 0 END)   AS total_pago
FROM emprestimo e
JOIN cliente c       ON c.id_cliente = e.id_cliente
LEFT JOIN parcela p  ON p.id_emprestimo = e.id_emprestimo
GROUP BY e.id_emprestimo, c.nome_completo, e.valor_principal,
         e.taxa_juros_mensal, e.prazo_meses, e.status
ORDER BY e.id_emprestimo;

-- ===========================================================================
-- 5. Parcelas vencidas e ainda nao pagas
-- Consulta de inadimplencia: usa data de vencimento e status da parcela.
-- ===========================================================================
SELECT c.nome_completo,
       e.id_emprestimo,
       p.numero_parcela,
       p.valor_parcela,
       p.data_vencimento,
       p.status
FROM parcela p
JOIN emprestimo e   ON e.id_emprestimo = p.id_emprestimo
JOIN cliente c      ON c.id_cliente = e.id_cliente
WHERE p.status <> 'paga'
  AND p.data_vencimento < CURRENT_DATE
ORDER BY p.data_vencimento;

-- ===========================================================================
-- 6. Servicos mais contratados
-- Percorre a tabela associativa CONTRATACAO_SERVICO (relacionamento N:N).
-- ===========================================================================
SELECT s.nome_servico,
       s.categoria,
       COUNT(cs.id_contratacao) AS total_contratacoes
FROM servico s
LEFT JOIN contratacao_servico cs
       ON cs.id_servico = s.id_servico
      AND cs.status = 'ativa'
GROUP BY s.id_servico, s.nome_servico, s.categoria
ORDER BY total_contratacoes DESC, s.nome_servico;

-- ===========================================================================
-- 7. Progresso das caixinhas
-- Calcula o percentual atingido de cada meta financeira.
-- ===========================================================================
SELECT c.nome_completo,
       cx.nome_objetivo,
       cx.valor_meta,
       cx.saldo_atual,
       ROUND(cx.saldo_atual * 100.0 / cx.valor_meta, 1) AS percentual_meta,
       cx.status
FROM caixinha cx
JOIN conta co   ON co.id_conta = cx.id_conta
JOIN cliente c  ON c.id_cliente = co.id_cliente
ORDER BY percentual_meta DESC;

-- ===========================================================================
-- 8. Conferencia de saldo (integridade dos dados)
-- Recalcula o saldo de cada conta a partir das transacoes concluidas e compara com o saldo gravado.
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
