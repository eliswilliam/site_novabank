-- =============================================================================
-- PROJETO: Nova Bank - Instituicao de Pagamento S.A. (banco 100% digital)
-- ETAPA:   Modelagem e implementacao do banco de dados (versao minima)
-- ARQUIVO: 00_nova_bank_completo.sql
-- SGBD:    PostgreSQL 17 (Neon - Postgres serverless)
-- AUTORES: (equipe do projeto)
-- DATA:    novembro/2026
-- =============================================================================
-- Script UNICO: estrutura + dados de exemplo, na ordem correta de execucao.
-- Basta colar tudo no SQL Editor do Neon e clicar em Run (uma unica vez).
-- Como executar no Neon:
--   1) Console do Neon > SQL Editor: cole o arquivo 00_nova_bank_completo.sql e clique em Run; ou
--   2) Pelo terminal, com a connection string do projeto (Connection Details > Direct connection):
--      psql "postgresql://USUARIO:SENHA@ep-xxxx.regiao.aws.neon.tech/neondb?sslmode=require" -f 00_nova_bank_completo.sql
--
-- Observacoes do Neon:
--   - use a conexao direta (sem -pooler) para executar DDL;
--   - o banco do projeto e o neondb e o schema e o public: nao e preciso criar banco;
--   - os objetos sao criados no banco atual da conexao.

-- =============================================================================
-- 1. CRIACAO DAS TABELAS
-- =============================================================================

-- CLIENTE: Cadastro dos clientes (publico jovem) do Nova Bank.
CREATE TABLE cliente (
    id_cliente             SERIAL NOT NULL,
    nome_completo          VARCHAR(120) NOT NULL,
    cpf                    CHAR(11) NOT NULL,
    data_nascimento        DATE NOT NULL,
    email                  VARCHAR(120) NOT NULL,
    telefone               VARCHAR(20) NOT NULL,
    cidade                 VARCHAR(60) NOT NULL,
    uf                     CHAR(2) NOT NULL,
    renda_mensal           DECIMAL(10,2) NOT NULL,
    data_cadastro          DATE NOT NULL DEFAULT CURRENT_DATE,
    status                 VARCHAR(12) NOT NULL DEFAULT 'ativo',
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT uk_cliente_cpf UNIQUE (cpf),
    CONSTRAINT uk_cliente_email UNIQUE (email),
    CONSTRAINT ck_cliente_cpf CHECK (CHAR_LENGTH(cpf) = 11),
    CONSTRAINT ck_cliente_uf CHECK (CHAR_LENGTH(uf) = 2),
    CONSTRAINT ck_cliente_renda_mensal CHECK (renda_mensal >= 0),
    CONSTRAINT ck_cliente_status CHECK (status IN ('ativo','inativo','bloqueado'))
);
COMMENT ON TABLE cliente IS 'Cadastro dos clientes (publico jovem) do Nova Bank.';

-- CONTA: Contas digitais abertas pelos clientes.
CREATE TABLE conta (
    id_conta               SERIAL NOT NULL,
    numero_conta           VARCHAR(10) NOT NULL,
    agencia                VARCHAR(5) NOT NULL DEFAULT '0001',
    tipo_conta             VARCHAR(15) NOT NULL DEFAULT 'pagamento',
    saldo                  DECIMAL(12,2) NOT NULL DEFAULT 0,
    data_abertura          DATE NOT NULL,
    status                 VARCHAR(12) NOT NULL DEFAULT 'ativa',
    id_cliente             INT NOT NULL,
    CONSTRAINT pk_conta PRIMARY KEY (id_conta),
    CONSTRAINT uk_conta_numero_conta UNIQUE (numero_conta),
    CONSTRAINT ck_conta_tipo_conta CHECK (tipo_conta IN ('corrente','poupanca','pagamento')),
    CONSTRAINT ck_conta_saldo CHECK (saldo >= 0),
    CONSTRAINT ck_conta_status CHECK (status IN ('ativa','encerrada','bloqueada')),
    CONSTRAINT fk_conta_cliente_id_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON UPDATE CASCADE ON DELETE RESTRICT
);
COMMENT ON TABLE conta IS 'Contas digitais abertas pelos clientes.';

-- CARTAO: Cartoes de debito, credito e virtuais vinculados as contas.
CREATE TABLE cartao (
    id_cartao              SERIAL NOT NULL,
    numero_mascarado       VARCHAR(19) NOT NULL,
    tipo_cartao            VARCHAR(10) NOT NULL,
    bandeira               VARCHAR(15) NOT NULL,
    limite_total           DECIMAL(10,2) NOT NULL DEFAULT 0,
    limite_disponivel      DECIMAL(10,2) NOT NULL DEFAULT 0,
    data_emissao           DATE NOT NULL,
    data_validade          DATE NOT NULL,
    status                 VARCHAR(12) NOT NULL DEFAULT 'ativo',
    id_conta               INT NOT NULL,
    CONSTRAINT pk_cartao PRIMARY KEY (id_cartao),
    CONSTRAINT ck_cartao_tipo_cartao CHECK (tipo_cartao IN ('debito','credito','virtual')),
    CONSTRAINT ck_cartao_bandeira CHECK (bandeira IN ('Visa','Mastercard','Elo')),
    CONSTRAINT ck_cartao_limite_total CHECK (limite_total >= 0),
    CONSTRAINT ck_cartao_limite_disponivel CHECK (limite_disponivel >= 0 AND limite_disponivel <= limite_total),
    CONSTRAINT ck_cartao_status CHECK (status IN ('ativo','bloqueado','cancelado')),
    CONSTRAINT fk_cartao_conta_id_conta FOREIGN KEY (id_conta)
        REFERENCES conta (id_conta) ON UPDATE CASCADE ON DELETE RESTRICT
);
COMMENT ON TABLE cartao IS 'Cartoes de debito, credito e virtuais vinculados as contas.';

-- EMPRESTIMO: Contratos de emprestimo pessoal jovem.
CREATE TABLE emprestimo (
    id_emprestimo          SERIAL NOT NULL,
    valor_principal        DECIMAL(12,2) NOT NULL,
    taxa_juros_mensal      DECIMAL(5,2) NOT NULL,
    prazo_meses            INT NOT NULL,
    data_contratacao       DATE NOT NULL,
    status                 VARCHAR(12) NOT NULL DEFAULT 'em_analise',
    id_cliente             INT NOT NULL,
    id_conta               INT NOT NULL,
    CONSTRAINT pk_emprestimo PRIMARY KEY (id_emprestimo),
    CONSTRAINT ck_emprestimo_valor_principal CHECK (valor_principal > 0),
    CONSTRAINT ck_emprestimo_taxa_juros_mensal CHECK (taxa_juros_mensal >= 0),
    CONSTRAINT ck_emprestimo_prazo_meses CHECK (prazo_meses BETWEEN 3 AND 36),
    CONSTRAINT ck_emprestimo_status CHECK (status IN ('em_analise','aprovado','ativo','quitado','cancelado')),
    CONSTRAINT fk_emprestimo_cliente_id_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_emprestimo_conta_id_conta FOREIGN KEY (id_conta)
        REFERENCES conta (id_conta) ON UPDATE CASCADE ON DELETE RESTRICT
);
COMMENT ON TABLE emprestimo IS 'Contratos de emprestimo pessoal jovem.';

-- TRANSACAO: Movimentacoes financeiras (Pix, boletos, compras e rendimentos).
CREATE TABLE transacao (
    id_transacao           SERIAL NOT NULL,
    tipo                   VARCHAR(25) NOT NULL,
    valor                  DECIMAL(12,2) NOT NULL,
    data_hora              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descricao              VARCHAR(150),
    status                 VARCHAR(12) NOT NULL DEFAULT 'concluida',
    id_conta_origem        INT,
    id_conta_destino       INT,
    id_cartao              INT,
    CONSTRAINT pk_transacao PRIMARY KEY (id_transacao),
    CONSTRAINT ck_transacao_tipo CHECK (tipo IN ('pix_enviado','pix_recebido','boleto','compra_debito','compra_credito','rendimento','saque','transferencia')),
    CONSTRAINT ck_transacao_valor CHECK (valor > 0),
    CONSTRAINT ck_transacao_status CHECK (status IN ('concluida','pendente','cancelada','estornada')),
    CONSTRAINT ck_transacao_1 CHECK (id_conta_origem IS NOT NULL OR id_conta_destino IS NOT NULL),
    CONSTRAINT ck_transacao_2 CHECK (id_conta_origem IS NULL OR id_conta_destino IS NULL OR id_conta_origem <> id_conta_destino),
    CONSTRAINT fk_transacao_conta_id_conta_origem FOREIGN KEY (id_conta_origem)
        REFERENCES conta (id_conta) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_transacao_conta_id_conta_destino FOREIGN KEY (id_conta_destino)
        REFERENCES conta (id_conta) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_transacao_cartao_id_cartao FOREIGN KEY (id_cartao)
        REFERENCES cartao (id_cartao) ON UPDATE CASCADE ON DELETE RESTRICT
);
COMMENT ON TABLE transacao IS 'Movimentacoes financeiras (Pix, boletos, compras e rendimentos).';

-- =============================================================================
-- 2. INDICES DAS CHAVES ESTRANGEIRAS
-- =============================================================================
CREATE INDEX ix_conta_id_cliente ON conta (id_cliente);
CREATE INDEX ix_cartao_id_conta ON cartao (id_conta);
CREATE INDEX ix_emprestimo_id_cliente ON emprestimo (id_cliente);
CREATE INDEX ix_emprestimo_id_conta ON emprestimo (id_conta);
CREATE INDEX ix_transacao_id_conta_origem ON transacao (id_conta_origem);
CREATE INDEX ix_transacao_id_conta_destino ON transacao (id_conta_destino);
CREATE INDEX ix_transacao_id_cartao ON transacao (id_cartao);

BEGIN;

-- ---------------------------------------------------------------------------
-- CLIENTE (10 registros)
-- ---------------------------------------------------------------------------
INSERT INTO cliente (id_cliente, nome_completo, cpf, data_nascimento, email,
                     telefone, cidade, uf, renda_mensal, data_cadastro,
                     status) VALUES
    (1, 'Ana Beatriz Souza Lima', '12345678901', '2003-04-12', 'ana.lima@email.com', '(11) 98765-4321', 'Sao Paulo', 'SP', 1800.00, '2025-03-10', 'ativo'),
    (2, 'Lucas Ferreira Almeida', '23456789012', '2001-08-25', 'lucas.almeida@email.com', '(21) 99812-3344', 'Rio de Janeiro', 'RJ', 2400.00, '2025-05-22', 'ativo'),
    (3, 'Mariana Costa Oliveira', '34567890123', '2004-01-30', 'mariana.oliveira@email.com', '(81) 98123-7766', 'Recife', 'PE', 1200.00, '2025-09-01', 'ativo'),
    (4, 'Pedro Henrique Santos', '45678901234', '1999-11-05', 'pedro.santos@email.com', '(31) 99123-5544', 'Belo Horizonte', 'MG', 3200.00, '2025-01-15', 'ativo'),
    (5, 'Julia Nascimento Rocha', '56789012345', '2002-06-18', 'julia.rocha@email.com', '(51) 99654-8899', 'Porto Alegre', 'RS', 2100.00, '2025-11-03', 'ativo'),
    (6, 'Gabriel Martins Pereira', '67890123456', '2000-02-14', 'gabriel.pereira@email.com', '(41) 99544-2211', 'Curitiba', 'PR', 2750.00, '2025-07-19', 'ativo'),
    (7, 'Beatriz Almeida Nunes', '78901234567', '2005-09-07', 'beatriz.nunes@email.com', '(71) 98877-6655', 'Salvador', 'BA', 950.00, '2026-02-11', 'ativo'),
    (8, 'Rafael Souza Barbosa', '89012345678', '1998-12-22', 'rafael.barbosa@email.com', '(85) 99321-4455', 'Fortaleza', 'CE', 4100.00, '2025-04-08', 'ativo'),
    (9, 'Camila Ribeiro Dias', '90123456789', '2003-07-03', 'camila.dias@email.com', '(92) 98444-1122', 'Manaus', 'AM', 1600.00, '2026-01-27', 'ativo'),
    (10, 'Thiago Oliveira Castro', '01234567890', '2001-05-19', 'thiago.castro@email.com', '(61) 99700-3322', 'Brasilia', 'DF', 2900.00, '2025-08-30', 'inativo');

-- ---------------------------------------------------------------------------
-- CONTA (12 registros)
-- ---------------------------------------------------------------------------
INSERT INTO conta (id_conta, numero_conta, agencia, tipo_conta, saldo,
                   data_abertura, status, id_cliente) VALUES
    (1, '10001-2', '0001', 'pagamento', 6906.08, '2025-03-10', 'ativa', 1),
    (2, '10002-5', '0001', 'pagamento', 8889.42, '2025-05-22', 'ativa', 2),
    (3, '10003-8', '0001', 'pagamento', 5886.75, '2025-09-01', 'ativa', 3),
    (4, '10004-0', '0001', 'corrente', 11769.34, '2025-01-15', 'ativa', 4),
    (5, '10005-3', '0001', 'poupanca', 1200.00, '2025-02-01', 'ativa', 4),
    (6, '10006-6', '0001', 'pagamento', 9327.46, '2025-11-03', 'ativa', 5),
    (7, '10007-9', '0001', 'pagamento', 9576.17, '2025-07-19', 'ativa', 6),
    (8, '10008-1', '0001', 'pagamento', 4074.76, '2026-02-11', 'ativa', 7),
    (9, '10009-4', '0001', 'corrente', 14739.78, '2025-04-08', 'ativa', 8),
    (10, '10010-7', '0001', 'pagamento', 7127.98, '2026-01-27', 'ativa', 9),
    (11, '10011-0', '0001', 'pagamento', 0.00, '2025-08-30', 'bloqueada', 10),
    (12, '10012-3', '0001', 'poupanca', 2200.00, '2026-03-04', 'ativa', 1);

-- ---------------------------------------------------------------------------
-- CARTAO (14 registros)
-- ---------------------------------------------------------------------------
INSERT INTO cartao (id_cartao, numero_mascarado, tipo_cartao, bandeira,
                    limite_total, limite_disponivel, data_emissao,
                    data_validade, status, id_conta) VALUES
    (1, '**** **** **** 4821', 'debito', 'Visa', 0.00, 0.00, '2025-03-12', '2030-03-31', 'ativo', 1),
    (2, '**** **** **** 7390', 'credito', 'Mastercard', 1500.00, 1037.98, '2025-03-12', '2030-03-31', 'ativo', 1),
    (3, '**** **** **** 1122', 'virtual', 'Visa', 800.00, 800.00, '2026-04-02', '2028-04-30', 'ativo', 1),
    (4, '**** **** **** 5567', 'debito', 'Mastercard', 0.00, 0.00, '2025-05-25', '2030-05-31', 'ativo', 2),
    (5, '**** **** **** 9034', 'credito', 'Visa', 3500.00, 2843.34, '2025-05-25', '2030-05-31', 'ativo', 2),
    (6, '**** **** **** 2288', 'debito', 'Elo', 0.00, 0.00, '2025-09-04', '2030-09-30', 'ativo', 3),
    (7, '**** **** **** 4410', 'debito', 'Visa', 0.00, 0.00, '2025-01-18', '2030-01-31', 'ativo', 4),
    (8, '**** **** **** 6675', 'credito', 'Mastercard', 6000.00, 5055.31, '2025-01-18', '2030-01-31', 'ativo', 4),
    (9, '**** **** **** 3391', 'debito', 'Visa', 0.00, 0.00, '2025-11-06', '2030-11-30', 'ativo', 6),
    (10, '**** **** **** 8812', 'debito', 'Elo', 0.00, 0.00, '2025-07-22', '2030-07-31', 'bloqueado', 7),
    (11, '**** **** **** 7743', 'debito', 'Visa', 0.00, 0.00, '2026-02-14', '2031-02-28', 'ativo', 8),
    (12, '**** **** **** 5508', 'credito', 'Visa', 4500.00, 4040.81, '2025-04-11', '2030-04-30', 'ativo', 9),
    (13, '**** **** **** 1190', 'debito', 'Mastercard', 0.00, 0.00, '2026-01-30', '2031-01-31', 'ativo', 10),
    (14, '**** **** **** 6620', 'debito', 'Visa', 0.00, 0.00, '2026-03-07', '2031-03-31', 'ativo', 12);

-- ---------------------------------------------------------------------------
-- EMPRESTIMO (6 registros)
-- ---------------------------------------------------------------------------
INSERT INTO emprestimo (id_emprestimo, valor_principal, taxa_juros_mensal,
                        prazo_meses, data_contratacao, status, id_cliente,
                        id_conta) VALUES
    (1, 3000.00, 0.99, 12, '2026-06-10', 'ativo', 1, 1),
    (2, 12000.00, 0.99, 18, '2026-03-05', 'ativo', 4, 4),
    (3, 5000.00, 1.29, 18, '2026-08-20', 'ativo', 6, 7),
    (4, 8000.00, 0.99, 12, '2025-11-12', 'quitado', 8, 9),
    (5, 1500.00, 1.49, 6, '2026-10-28', 'em_analise', 3, 3),
    (6, 2500.00, 1.29, 9, '2026-09-02', 'cancelado', 10, 11);

-- ---------------------------------------------------------------------------
-- TRANSACAO (239 registros)
-- ---------------------------------------------------------------------------
INSERT INTO transacao (id_transacao, tipo, valor, data_hora, descricao,
                       status, id_conta_origem, id_conta_destino, id_cartao) VALUES
    (1, 'pix_recebido', 2000.00, '2025-01-15 10:00:00', 'Abertura de conta - deposito inicial', 'concluida', NULL, 4, NULL),
    (2, 'pix_recebido', 1200.00, '2025-02-01 10:00:00', 'Abertura de conta - deposito inicial', 'concluida', NULL, 5, NULL),
    (3, 'pix_recebido', 1500.00, '2025-03-10 10:00:00', 'Abertura de conta - deposito inicial', 'concluida', NULL, 1, NULL),
    (4, 'pix_recebido', 900.00, '2025-04-08 10:00:00', 'Abertura de conta - deposito inicial', 'concluida', NULL, 9, NULL),
    (5, 'pix_recebido', 1500.00, '2025-05-22 10:00:00', 'Abertura de conta - deposito inicial', 'concluida', NULL, 2, NULL),
    (6, 'pix_recebido', 900.00, '2025-07-19 10:00:00', 'Abertura de conta - deposito inicial', 'concluida', NULL, 7, NULL),
    (7, 'pix_recebido', 2500.00, '2025-09-01 10:00:00', 'Abertura de conta - deposito inicial', 'concluida', NULL, 3, NULL),
    (8, 'pix_recebido', 2000.00, '2025-11-03 10:00:00', 'Abertura de conta - deposito inicial', 'concluida', NULL, 6, NULL),
    (9, 'pix_recebido', 2000.00, '2026-01-27 10:00:00', 'Abertura de conta - deposito inicial', 'concluida', NULL, 10, NULL),
    (10, 'pix_recebido', 1500.00, '2026-02-11 10:00:00', 'Abertura de conta - deposito inicial', 'concluida', NULL, 8, NULL),
    (11, 'pix_recebido', 1200.00, '2026-03-04 10:00:00', 'Abertura de conta - deposito inicial', 'concluida', NULL, 12, NULL),
    (12, 'pix_recebido', 1800.00, '2026-07-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 1, NULL),
    (13, 'pix_recebido', 2400.00, '2026-07-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 2, NULL),
    (14, 'pix_recebido', 1200.00, '2026-07-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 3, NULL),
    (15, 'pix_recebido', 3200.00, '2026-07-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 4, NULL),
    (16, 'pix_recebido', 2100.00, '2026-07-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 6, NULL),
    (17, 'pix_recebido', 2750.00, '2026-07-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 7, NULL),
    (18, 'pix_recebido', 950.00, '2026-07-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 8, NULL),
    (19, 'pix_recebido', 4100.00, '2026-07-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 9, NULL),
    (20, 'pix_recebido', 1600.00, '2026-07-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 10, NULL),
    (21, 'compra_credito', 148.42, '2026-07-07 20:15:00', 'E-commerce', 'concluida', 2, NULL, 5),
    (22, 'boleto', 504.00, '2026-07-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 1, NULL, NULL),
    (23, 'boleto', 672.00, '2026-07-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 2, NULL, NULL),
    (24, 'boleto', 336.00, '2026-07-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 3, NULL, NULL),
    (25, 'boleto', 896.00, '2026-07-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 4, NULL, NULL),
    (26, 'boleto', 588.00, '2026-07-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 6, NULL, NULL),
    (27, 'boleto', 770.00, '2026-07-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 7, NULL, NULL),
    (28, 'boleto', 266.00, '2026-07-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 8, NULL, NULL),
    (29, 'boleto', 1148.00, '2026-07-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 9, NULL, NULL),
    (30, 'boleto', 448.00, '2026-07-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 10, NULL, NULL),
    (31, 'compra_debito', 55.57, '2026-07-11 15:03:00', 'Transporte por app', 'concluida', 3, NULL, 6),
    (32, 'compra_debito', 65.54, '2026-07-11 16:01:00', 'Cafe', 'concluida', 9, NULL, NULL),
    (33, 'compra_debito', 148.24, '2026-07-12 15:03:00', 'Supermercado', 'concluida', 4, NULL, 7),
    (34, 'compra_debito', 76.14, '2026-07-12 16:40:00', 'Cinema', 'concluida', 9, NULL, NULL),
    (35, 'compra_debito', 125.04, '2026-07-12 18:48:00', 'Livraria', 'concluida', 10, NULL, 13),
    (36, 'compra_credito', 134.58, '2026-07-12 20:15:00', 'Streaming anual', 'concluida', 1, NULL, 2),
    (37, 'compra_debito', 166.19, '2026-07-13 16:26:00', 'Cinema', 'concluida', 10, NULL, 13),
    (38, 'compra_debito', 29.67, '2026-07-14 20:19:00', 'Supermercado', 'concluida', 2, NULL, 4),
    (39, 'compra_debito', 203.42, '2026-07-16 11:13:00', 'Cinema', 'concluida', 7, NULL, NULL),
    (40, 'compra_debito', 170.49, '2026-07-17 17:09:00', 'Cinema', 'concluida', 7, NULL, NULL),
    (41, 'compra_debito', 94.28, '2026-07-17 22:36:00', 'Supermercado', 'concluida', 2, NULL, 4),
    (42, 'compra_debito', 96.87, '2026-07-17 22:58:00', 'Transporte por app', 'concluida', 6, NULL, 9),
    (43, 'compra_debito', 130.55, '2026-07-18 17:35:00', 'Cafe', 'concluida', 1, NULL, 1),
    (44, 'compra_credito', 69.33, '2026-07-18 20:15:00', 'Curso online', 'concluida', 9, NULL, 12),
    (45, 'compra_debito', 181.11, '2026-07-19 17:08:00', 'Transporte por app', 'concluida', 4, NULL, 7),
    (46, 'compra_debito', 179.50, '2026-07-19 22:02:00', 'Farmacia', 'concluida', 1, NULL, 1),
    (47, 'compra_debito', 137.86, '2026-07-20 17:18:00', 'Cinema', 'concluida', 8, NULL, 11),
    (48, 'compra_credito', 207.79, '2026-07-21 20:15:00', 'Passagem aerea', 'concluida', 4, NULL, 8),
    (49, 'compra_debito', 146.13, '2026-07-23 14:37:00', 'Farmacia', 'concluida', 9, NULL, NULL),
    (50, 'compra_debito', 78.47, '2026-07-23 17:26:00', 'Cafe', 'concluida', 6, NULL, 9),
    (51, 'compra_debito', 134.63, '2026-07-23 17:27:00', 'Cinema', 'concluida', 2, NULL, 4),
    (52, 'compra_debito', 101.37, '2026-07-24 21:07:00', 'Restaurante', 'concluida', 1, NULL, 1),
    (53, 'compra_debito', 145.94, '2026-07-26 13:22:00', 'Farmacia', 'concluida', 8, NULL, 11),
    (54, 'rendimento', 18.81, '2026-07-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 1, NULL),
    (55, 'rendimento', 26.90, '2026-07-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 2, NULL),
    (56, 'rendimento', 27.70, '2026-07-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 3, NULL),
    (57, 'rendimento', 34.87, '2026-07-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 4, NULL),
    (58, 'rendimento', 27.38, '2026-07-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 6, NULL),
    (59, 'rendimento', 18.94, '2026-07-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 7, NULL),
    (60, 'rendimento', 16.03, '2026-07-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 8, NULL),
    (61, 'rendimento', 26.87, '2026-07-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 9, NULL),
    (62, 'rendimento', 23.47, '2026-07-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 10, NULL),
    (63, 'pix_recebido', 1800.00, '2026-08-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 1, NULL),
    (64, 'pix_recebido', 2400.00, '2026-08-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 2, NULL),
    (65, 'pix_recebido', 1200.00, '2026-08-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 3, NULL),
    (66, 'pix_recebido', 3200.00, '2026-08-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 4, NULL),
    (67, 'pix_recebido', 2100.00, '2026-08-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 6, NULL),
    (68, 'pix_recebido', 2750.00, '2026-08-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 7, NULL),
    (69, 'pix_recebido', 950.00, '2026-08-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 8, NULL),
    (70, 'pix_recebido', 4100.00, '2026-08-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 9, NULL),
    (71, 'pix_recebido', 1600.00, '2026-08-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 10, NULL),
    (72, 'compra_credito', 149.59, '2026-08-09 20:15:00', 'Loja de eletronicos', 'concluida', 2, NULL, 5),
    (73, 'boleto', 504.00, '2026-08-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 1, NULL, NULL),
    (74, 'boleto', 672.00, '2026-08-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 2, NULL, NULL),
    (75, 'boleto', 336.00, '2026-08-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 3, NULL, NULL),
    (76, 'boleto', 896.00, '2026-08-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 4, NULL, NULL),
    (77, 'boleto', 588.00, '2026-08-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 6, NULL, NULL),
    (78, 'boleto', 770.00, '2026-08-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 7, NULL, NULL),
    (79, 'boleto', 266.00, '2026-08-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 8, NULL, NULL),
    (80, 'boleto', 1148.00, '2026-08-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 9, NULL, NULL),
    (81, 'boleto', 448.00, '2026-08-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 10, NULL, NULL),
    (82, 'compra_debito', 29.21, '2026-08-11 14:25:00', 'Transporte por app', 'concluida', 1, NULL, 1),
    (83, 'compra_debito', 186.41, '2026-08-12 16:29:00', 'Transporte por app', 'concluida', 7, NULL, NULL),
    (84, 'compra_debito', 139.14, '2026-08-12 20:36:00', 'Livraria', 'concluida', 9, NULL, NULL),
    (85, 'compra_debito', 190.68, '2026-08-14 12:50:00', 'Transporte por app', 'concluida', 7, NULL, NULL),
    (86, 'compra_debito', 164.94, '2026-08-14 20:31:00', 'Supermercado', 'concluida', 9, NULL, NULL),
    (87, 'compra_debito', 38.14, '2026-08-14 22:44:00', 'Transporte por app', 'concluida', 3, NULL, 6),
    (88, 'compra_debito', 177.17, '2026-08-15 21:10:00', 'Livraria', 'concluida', 8, NULL, 11),
    (89, 'compra_debito', 63.04, '2026-08-16 13:15:00', 'Cinema', 'concluida', 1, NULL, 1),
    (90, 'compra_debito', 168.78, '2026-08-18 12:10:00', 'Livraria', 'concluida', 1, NULL, 1),
    (91, 'compra_debito', 141.01, '2026-08-19 22:30:00', 'Supermercado', 'concluida', 6, NULL, 9),
    (92, 'compra_credito', 72.98, '2026-08-20 20:15:00', 'Streaming anual', 'concluida', 1, NULL, 2),
    (93, 'compra_debito', 39.76, '2026-08-22 16:51:00', 'Cinema', 'concluida', 4, NULL, 7),
    (94, 'compra_debito', 54.55, '2026-08-23 13:10:00', 'Livraria', 'concluida', 10, NULL, 13),
    (95, 'compra_debito', 88.21, '2026-08-23 14:15:00', 'Farmacia', 'concluida', 3, NULL, 6),
    (96, 'compra_debito', 193.54, '2026-08-24 20:10:00', 'Farmacia', 'concluida', 3, NULL, 6),
    (97, 'compra_debito', 94.59, '2026-08-25 19:24:00', 'Supermercado', 'concluida', 8, NULL, 11),
    (98, 'compra_debito', 43.75, '2026-08-26 15:15:00', 'Livraria', 'concluida', 10, NULL, 13),
    (99, 'compra_credito', 131.66, '2026-08-26 20:15:00', 'Loja de eletronicos', 'concluida', 9, NULL, 12),
    (100, 'compra_debito', 82.19, '2026-08-27 15:33:00', 'Livraria', 'concluida', 9, NULL, NULL),
    (101, 'compra_debito', 97.78, '2026-08-27 20:37:00', 'Transporte por app', 'concluida', 2, NULL, 4),
    (102, 'compra_credito', 158.50, '2026-08-28 20:15:00', 'E-commerce', 'concluida', 4, NULL, 8),
    (103, 'rendimento', 28.69, '2026-08-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 1, NULL),
    (104, 'rendimento', 41.49, '2026-08-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 2, NULL),
    (105, 'rendimento', 31.43, '2026-08-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 3, NULL),
    (106, 'rendimento', 52.15, '2026-08-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 4, NULL),
    (107, 'rendimento', 40.77, '2026-08-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 6, NULL),
    (108, 'rendimento', 33.72, '2026-08-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 7, NULL),
    (109, 'rendimento', 17.79, '2026-08-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 8, NULL),
    (110, 'rendimento', 47.37, '2026-08-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 9, NULL),
    (111, 'rendimento', 33.19, '2026-08-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 10, NULL),
    (112, 'pix_recebido', 1800.00, '2026-09-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 1, NULL),
    (113, 'pix_recebido', 2400.00, '2026-09-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 2, NULL),
    (114, 'pix_recebido', 1200.00, '2026-09-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 3, NULL),
    (115, 'pix_recebido', 3200.00, '2026-09-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 4, NULL),
    (116, 'pix_recebido', 2100.00, '2026-09-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 6, NULL),
    (117, 'pix_recebido', 2750.00, '2026-09-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 7, NULL),
    (118, 'pix_recebido', 950.00, '2026-09-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 8, NULL),
    (119, 'pix_recebido', 4100.00, '2026-09-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 9, NULL),
    (120, 'pix_recebido', 1600.00, '2026-09-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 10, NULL),
    (121, 'compra_credito', 215.14, '2026-09-09 20:15:00', 'Passagem aerea', 'concluida', 2, NULL, 5),
    (122, 'boleto', 504.00, '2026-09-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 1, NULL, NULL),
    (123, 'boleto', 672.00, '2026-09-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 2, NULL, NULL),
    (124, 'boleto', 336.00, '2026-09-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 3, NULL, NULL),
    (125, 'boleto', 896.00, '2026-09-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 4, NULL, NULL),
    (126, 'boleto', 588.00, '2026-09-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 6, NULL, NULL),
    (127, 'boleto', 770.00, '2026-09-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 7, NULL, NULL),
    (128, 'boleto', 266.00, '2026-09-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 8, NULL, NULL),
    (129, 'boleto', 1148.00, '2026-09-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 9, NULL, NULL),
    (130, 'boleto', 448.00, '2026-09-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 10, NULL, NULL),
    (131, 'compra_debito', 124.21, '2026-09-12 11:54:00', 'Farmacia', 'concluida', 6, NULL, 9),
    (132, 'compra_debito', 68.64, '2026-09-13 20:02:00', 'Transporte por app', 'concluida', 10, NULL, 13),
    (133, 'compra_debito', 154.46, '2026-09-14 11:10:00', 'Cafe', 'concluida', 6, NULL, 9),
    (134, 'compra_debito', 101.62, '2026-09-14 11:42:00', 'Cafe', 'concluida', 7, NULL, NULL),
    (135, 'compra_credito', 88.30, '2026-09-14 20:15:00', 'Curso online', 'concluida', 9, NULL, 12),
    (136, 'pix_enviado', 150.00, '2026-09-15 12:05:00', 'Pix - divisao do aluguel', 'concluida', 1, 3, NULL),
    (137, 'pix_enviado', 75.00, '2026-09-16 18:40:00', 'Pix - reembolso de jantar', 'concluida', 3, 1, NULL),
    (138, 'compra_credito', 166.16, '2026-09-16 20:15:00', 'Curso online', 'concluida', 4, NULL, 8),
    (139, 'compra_debito', 136.12, '2026-09-17 22:06:00', 'Farmacia', 'concluida', 4, NULL, 7),
    (140, 'compra_debito', 198.82, '2026-09-19 19:35:00', 'Farmacia', 'concluida', 8, NULL, 11),
    (141, 'compra_debito', 148.48, '2026-09-21 16:40:00', 'Supermercado', 'concluida', 2, NULL, 4),
    (142, 'compra_debito', 201.61, '2026-09-22 14:12:00', 'Supermercado', 'concluida', 3, NULL, 6),
    (143, 'compra_debito', 144.45, '2026-09-22 18:48:00', 'Livraria', 'concluida', 8, NULL, 11),
    (144, 'compra_debito', 164.05, '2026-09-22 20:02:00', 'Farmacia', 'concluida', 2, NULL, 4),
    (145, 'compra_debito', 44.10, '2026-09-22 20:55:00', 'Cinema', 'concluida', 9, NULL, NULL),
    (146, 'compra_debito', 152.50, '2026-09-23 21:08:00', 'Livraria', 'concluida', 7, NULL, NULL),
    (147, 'compra_debito', 176.78, '2026-09-24 13:40:00', 'Livraria', 'concluida', 1, NULL, 1),
    (148, 'compra_debito', 99.84, '2026-09-24 19:00:00', 'Supermercado', 'concluida', 4, NULL, 7),
    (149, 'compra_debito', 92.78, '2026-09-25 22:18:00', 'Farmacia', 'concluida', 3, NULL, 6),
    (150, 'compra_debito', 99.81, '2026-09-26 13:41:00', 'Cinema', 'concluida', 3, NULL, 6),
    (151, 'compra_debito', 143.74, '2026-09-26 19:44:00', 'Restaurante', 'concluida', 2, NULL, 4),
    (152, 'compra_credito', 110.67, '2026-09-26 20:15:00', 'Passagem aerea', 'concluida', 1, NULL, 2),
    (153, 'compra_debito', 205.24, '2026-09-27 16:19:00', 'Livraria', 'concluida', 4, NULL, 7),
    (154, 'rendimento', 40.92, '2026-09-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 1, NULL),
    (155, 'rendimento', 46.82, '2026-09-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 2, NULL),
    (156, 'rendimento', 35.07, '2026-09-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 3, NULL),
    (157, 'rendimento', 71.06, '2026-09-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 4, NULL),
    (158, 'rendimento', 53.00, '2026-09-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 6, NULL),
    (159, 'rendimento', 47.78, '2026-09-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 7, NULL),
    (160, 'rendimento', 20.41, '2026-09-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 8, NULL),
    (161, 'rendimento', 75.90, '2026-09-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 9, NULL),
    (162, 'rendimento', 45.92, '2026-09-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 10, NULL),
    (163, 'pix_enviado', 320.00, '2026-10-03 09:12:00', 'Pix - ingressos do show', 'concluida', 2, 6, NULL),
    (164, 'pix_recebido', 1800.00, '2026-10-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 1, NULL),
    (165, 'pix_recebido', 2400.00, '2026-10-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 2, NULL),
    (166, 'pix_recebido', 1200.00, '2026-10-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 3, NULL),
    (167, 'pix_recebido', 3200.00, '2026-10-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 4, NULL),
    (168, 'pix_recebido', 2100.00, '2026-10-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 6, NULL),
    (169, 'pix_recebido', 2750.00, '2026-10-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 7, NULL),
    (170, 'pix_recebido', 950.00, '2026-10-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 8, NULL),
    (171, 'pix_recebido', 4100.00, '2026-10-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 9, NULL),
    (172, 'pix_recebido', 1600.00, '2026-10-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 10, NULL),
    (173, 'boleto', 504.00, '2026-10-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 1, NULL, NULL),
    (174, 'boleto', 672.00, '2026-10-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 2, NULL, NULL),
    (175, 'boleto', 336.00, '2026-10-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 3, NULL, NULL),
    (176, 'boleto', 896.00, '2026-10-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 4, NULL, NULL),
    (177, 'boleto', 588.00, '2026-10-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 6, NULL, NULL),
    (178, 'boleto', 770.00, '2026-10-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 7, NULL, NULL),
    (179, 'boleto', 266.00, '2026-10-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 8, NULL, NULL),
    (180, 'boleto', 1148.00, '2026-10-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 9, NULL, NULL),
    (181, 'boleto', 448.00, '2026-10-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 10, NULL, NULL),
    (182, 'compra_debito', 151.28, '2026-10-11 16:23:00', 'Farmacia', 'concluida', 10, NULL, 13),
    (183, 'compra_debito', 105.22, '2026-10-11 21:34:00', 'Supermercado', 'concluida', 3, NULL, 6),
    (184, 'compra_debito', 40.75, '2026-10-12 19:09:00', 'Cinema', 'concluida', 6, NULL, 9),
    (185, 'compra_debito', 140.15, '2026-10-13 12:13:00', 'Farmacia', 'concluida', 7, NULL, NULL),
    (186, 'compra_debito', 121.09, '2026-10-14 17:21:00', 'Cinema', 'concluida', 9, NULL, NULL),
    (187, 'compra_debito', 83.18, '2026-10-14 17:47:00', 'Livraria', 'concluida', 1, NULL, 1),
    (188, 'compra_credito', 143.51, '2026-10-14 20:15:00', 'Loja de eletronicos', 'concluida', 2, NULL, 5),
    (189, 'compra_credito', 169.90, '2026-10-14 20:15:00', 'Streaming anual', 'concluida', 9, NULL, 12),
    (190, 'compra_debito', 153.54, '2026-10-15 12:14:00', 'Transporte por app', 'concluida', 7, NULL, NULL),
    (191, 'compra_debito', 94.89, '2026-10-15 18:39:00', 'Cafe', 'concluida', 6, NULL, 9),
    (192, 'compra_debito', 36.44, '2026-10-15 19:12:00', 'Transporte por app', 'concluida', 2, NULL, 4),
    (193, 'compra_debito', 195.88, '2026-10-18 13:19:00', 'Livraria', 'concluida', 3, NULL, 6),
    (194, 'compra_debito', 158.79, '2026-10-18 20:05:00', 'Cinema', 'concluida', 2, NULL, 4),
    (195, 'compra_debito', 41.41, '2026-10-19 16:33:00', 'Restaurante', 'concluida', 10, NULL, 13),
    (196, 'compra_debito', 136.31, '2026-10-21 15:49:00', 'Cafe', 'concluida', 9, NULL, NULL),
    (197, 'pix_enviado', 200.00, '2026-10-21 16:30:00', 'Pix - presente de aniversario', 'concluida', 9, 4, NULL),
    (198, 'compra_credito', 143.79, '2026-10-21 20:15:00', 'Streaming anual', 'concluida', 1, NULL, 2),
    (199, 'compra_debito', 206.37, '2026-10-22 21:05:00', 'Supermercado', 'concluida', 4, NULL, 7),
    (200, 'compra_debito', 166.39, '2026-10-23 18:35:00', 'Cinema', 'concluida', 1, NULL, 1),
    (201, 'compra_debito', 31.24, '2026-10-24 14:38:00', 'Restaurante', 'concluida', 8, NULL, 11),
    (202, 'pix_enviado', 1000.00, '2026-10-25 11:00:00', 'Pix - aporte na poupanca', 'concluida', 4, 12, NULL),
    (203, 'compra_credito', 210.39, '2026-10-27 20:15:00', 'Streaming anual', 'concluida', 4, NULL, 8),
    (204, 'rendimento', 52.16, '2026-10-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 1, NULL),
    (205, 'rendimento', 64.79, '2026-10-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 2, NULL),
    (206, 'rendimento', 45.72, '2026-10-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 3, NULL),
    (207, 'rendimento', 83.78, '2026-10-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 4, NULL),
    (208, 'rendimento', 56.97, '2026-10-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 6, NULL),
    (209, 'rendimento', 64.54, '2026-10-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 7, NULL),
    (210, 'rendimento', 30.60, '2026-10-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 8, NULL),
    (211, 'rendimento', 105.22, '2026-10-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 9, NULL),
    (212, 'rendimento', 51.20, '2026-10-28 23:59:00', 'Rendimento automatico 100% CDI', 'concluida', NULL, 10, NULL),
    (213, 'pix_recebido', 1800.00, '2026-11-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 1, NULL),
    (214, 'pix_recebido', 2400.00, '2026-11-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 2, NULL),
    (215, 'pix_recebido', 1200.00, '2026-11-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 3, NULL),
    (216, 'pix_recebido', 3200.00, '2026-11-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 4, NULL),
    (217, 'pix_recebido', 2100.00, '2026-11-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 6, NULL),
    (218, 'pix_recebido', 2750.00, '2026-11-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 7, NULL),
    (219, 'pix_recebido', 950.00, '2026-11-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 8, NULL),
    (220, 'pix_recebido', 4100.00, '2026-11-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 9, NULL),
    (221, 'pix_recebido', 1600.00, '2026-11-05 08:30:00', 'Credito de salario/bolsa de estudos', 'concluida', NULL, 10, NULL),
    (222, 'pix_enviado', 90.00, '2026-11-06 20:10:00', 'Pix - rateio da viagem', 'concluida', 7, 2, NULL),
    (223, 'boleto', 504.00, '2026-11-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 1, NULL, NULL),
    (224, 'boleto', 672.00, '2026-11-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 2, NULL, NULL),
    (225, 'boleto', 336.00, '2026-11-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 3, NULL, NULL),
    (226, 'boleto', 896.00, '2026-11-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 4, NULL, NULL),
    (227, 'boleto', 588.00, '2026-11-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 6, NULL, NULL),
    (228, 'boleto', 770.00, '2026-11-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 7, NULL, NULL),
    (229, 'boleto', 266.00, '2026-11-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 8, NULL, NULL),
    (230, 'boleto', 1148.00, '2026-11-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 9, NULL, NULL),
    (231, 'boleto', 448.00, '2026-11-10 09:15:00', 'Pagamento de boleto - aluguel e contas', 'concluida', 10, NULL, NULL),
    (232, 'compra_credito', 201.85, '2026-11-10 20:15:00', 'Passagem aerea', 'concluida', 4, NULL, 8),
    (233, 'compra_debito', 1290.00, '2026-11-11 10:00:00', 'Compra cancelada pelo estabelecimento', 'cancelada', 9, NULL, NULL),
    (234, 'compra_debito', 40.70, '2026-11-11 22:14:00', 'Supermercado', 'concluida', 1, NULL, 1),
    (235, 'compra_debito', 77.41, '2026-11-12 18:21:00', 'Farmacia', 'concluida', 3, NULL, 6),
    (236, 'compra_debito', 175.84, '2026-11-12 19:30:00', 'Cinema', 'concluida', 4, NULL, 7),
    (237, 'compra_debito', 134.94, '2026-11-12 20:06:00', 'Supermercado', 'concluida', 10, NULL, 13),
    (238, 'pix_enviado', 480.00, '2026-11-14 15:20:00', 'Pix - compra de ingresso (aguardando liquidacao)', 'pendente', 2, NULL, NULL),
    (239, 'compra_debito', 192.72, '2026-11-14 18:22:00', 'Supermercado', 'concluida', 2, NULL, 4);

COMMIT;

-- Conferencia das contagens
SELECT 'cliente' AS tabela, COUNT(*) AS registros FROM cliente
UNION ALL
SELECT 'conta' AS tabela, COUNT(*) AS registros FROM conta
UNION ALL
SELECT 'cartao' AS tabela, COUNT(*) AS registros FROM cartao
UNION ALL
SELECT 'emprestimo' AS tabela, COUNT(*) AS registros FROM emprestimo
UNION ALL
SELECT 'transacao' AS tabela, COUNT(*) AS registros FROM transacao
ORDER BY tabela;
