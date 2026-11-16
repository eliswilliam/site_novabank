-- =============================================================================
-- PROJETO: Nova Bank - Instituicao de Pagamento S.A. (banco 100% digital)
-- ETAPA:   Modelagem e implementacao do banco de dados
-- ARQUIVO: 00_nova_bank_completo.sql
-- SGBD:    PostgreSQL 17 (Neon)
-- AUTORES: (equipe do projeto)
-- DATA:    novembro/2026
-- =============================================================================
-- Script UNICO: estrutura + dados de exemplo, na ordem correta de execucao.
-- Basta colar tudo no SQL Editor do Neon e clicar em Run (uma unica vez).
-- Como executar no Neon (Postgres serverless):
--   1) No console do Neon, abra o SQL Editor, cole o conteudo e clique em Run; ou
--   2) Pelo terminal, use a connection string do projeto
--      (Connection Details > Direct connection):
--      psql "postgresql://USUARIO:SENHA@ep-xxxx.regiao.aws.neon.tech/neondb?sslmode=require" -f 00_nova_bank_completo.sql
--
-- Observacoes do Neon:
--   - use a conexao direta (sem -pooler) para executar DDL;
--   - o banco do projeto e o neondb e o schema e o public (nao e preciso criar banco);
--   - os objetos sao criados no banco atual da conexao.


-- =============================================================================
-- PARTE 1 - ESTRUTURA (tabelas, chaves estrangeiras e indices)
-- =============================================================================
-- Remocao das tabelas na ordem inversa das dependencias
DROP TABLE IF EXISTS atendimento CASCADE;
DROP TABLE IF EXISTS transacao CASCADE;
DROP TABLE IF EXISTS contratacao_servico CASCADE;
DROP TABLE IF EXISTS parcela CASCADE;
DROP TABLE IF EXISTS emprestimo CASCADE;
DROP TABLE IF EXISTS caixinha CASCADE;
DROP TABLE IF EXISTS chave_pix CASCADE;
DROP TABLE IF EXISTS cartao CASCADE;
DROP TABLE IF EXISTS conta CASCADE;
DROP TABLE IF EXISTS servico CASCADE;
DROP TABLE IF EXISTS funcionario CASCADE;
DROP TABLE IF EXISTS cliente CASCADE;

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

-- FUNCIONARIO: Colaboradores que compoem a estrutura organizacional do banco.
CREATE TABLE funcionario (
    id_funcionario         SERIAL NOT NULL,
    nome                   VARCHAR(120) NOT NULL,
    cargo                  VARCHAR(60) NOT NULL,
    departamento           VARCHAR(30) NOT NULL,
    email_corporativo      VARCHAR(120) NOT NULL,
    salario                DECIMAL(10,2) NOT NULL,
    data_admissao          DATE NOT NULL,
    status                 VARCHAR(12) NOT NULL DEFAULT 'ativo',
    CONSTRAINT pk_funcionario PRIMARY KEY (id_funcionario),
    CONSTRAINT uk_funcionario_email_corporativo UNIQUE (email_corporativo),
    CONSTRAINT ck_funcionario_departamento CHECK (departamento IN ('Diretoria','Tecnologia','Financeiro','CX','Compliance')),
    CONSTRAINT ck_funcionario_salario CHECK (salario > 0),
    CONSTRAINT ck_funcionario_status CHECK (status IN ('ativo','afastado','desligado'))
);
COMMENT ON TABLE funcionario IS 'Colaboradores que compoem a estrutura organizacional do banco.';

-- SERVICO: Catalogo de servicos financeiros oferecidos pelo banco.
CREATE TABLE servico (
    id_servico             SERIAL NOT NULL,
    nome_servico           VARCHAR(60) NOT NULL,
    categoria              VARCHAR(20) NOT NULL,
    descricao              VARCHAR(200),
    tarifa                 DECIMAL(8,2) NOT NULL DEFAULT 0,
    ativo                  BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_servico PRIMARY KEY (id_servico),
    CONSTRAINT uk_servico_nome_servico UNIQUE (nome_servico),
    CONSTRAINT ck_servico_categoria CHECK (categoria IN ('conta','cartao','pix','pagamento','credito','investimento')),
    CONSTRAINT ck_servico_tarifa CHECK (tarifa >= 0)
);
COMMENT ON TABLE servico IS 'Catalogo de servicos financeiros oferecidos pelo banco.';

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

-- CHAVE_PIX: Chaves Pix registradas por conta.
CREATE TABLE chave_pix (
    id_chave               SERIAL NOT NULL,
    tipo_chave             VARCHAR(10) NOT NULL,
    valor_chave            VARCHAR(100) NOT NULL,
    data_cadastro          DATE NOT NULL,
    ativa                  BOOLEAN NOT NULL DEFAULT TRUE,
    id_conta               INT NOT NULL,
    CONSTRAINT pk_chave_pix PRIMARY KEY (id_chave),
    CONSTRAINT uk_chave_pix_valor_chave UNIQUE (valor_chave),
    CONSTRAINT ck_chave_pix_tipo_chave CHECK (tipo_chave IN ('cpf','email','telefone','aleatoria')),
    CONSTRAINT fk_chave_pix_conta_id_conta FOREIGN KEY (id_conta)
        REFERENCES conta (id_conta) ON UPDATE CASCADE ON DELETE RESTRICT
);
COMMENT ON TABLE chave_pix IS 'Chaves Pix registradas por conta.';

-- CAIXINHA: Caixinhas de objetivos com rendimento automatico.
CREATE TABLE caixinha (
    id_caixinha            SERIAL NOT NULL,
    nome_objetivo          VARCHAR(60) NOT NULL,
    valor_meta             DECIMAL(10,2) NOT NULL,
    saldo_atual            DECIMAL(12,2) NOT NULL DEFAULT 0,
    data_criacao           DATE NOT NULL,
    data_prevista          DATE,
    status                 VARCHAR(12) NOT NULL DEFAULT 'ativa',
    id_conta               INT NOT NULL,
    CONSTRAINT pk_caixinha PRIMARY KEY (id_caixinha),
    CONSTRAINT ck_caixinha_valor_meta CHECK (valor_meta > 0),
    CONSTRAINT ck_caixinha_saldo_atual CHECK (saldo_atual >= 0),
    CONSTRAINT ck_caixinha_status CHECK (status IN ('ativa','concluida','cancelada')),
    CONSTRAINT fk_caixinha_conta_id_conta FOREIGN KEY (id_conta)
        REFERENCES conta (id_conta) ON UPDATE CASCADE ON DELETE RESTRICT
);
COMMENT ON TABLE caixinha IS 'Caixinhas de objetivos com rendimento automatico.';

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

-- PARCELA: Parcelas geradas a partir de cada contrato de emprestimo.
CREATE TABLE parcela (
    id_parcela             SERIAL NOT NULL,
    numero_parcela         INT NOT NULL,
    valor_parcela          DECIMAL(10,2) NOT NULL,
    data_vencimento        DATE NOT NULL,
    data_pagamento         DATE,
    status                 VARCHAR(12) NOT NULL DEFAULT 'aberta',
    id_emprestimo          INT NOT NULL,
    CONSTRAINT pk_parcela PRIMARY KEY (id_parcela),
    CONSTRAINT ck_parcela_numero_parcela CHECK (numero_parcela > 0),
    CONSTRAINT ck_parcela_valor_parcela CHECK (valor_parcela > 0),
    CONSTRAINT ck_parcela_status CHECK (status IN ('aberta','paga','atrasada','cancelada')),
    CONSTRAINT uk_parcela_contrato UNIQUE (id_emprestimo, numero_parcela),
    CONSTRAINT fk_parcela_emprestimo_id_emprestimo FOREIGN KEY (id_emprestimo)
        REFERENCES emprestimo (id_emprestimo) ON UPDATE CASCADE ON DELETE RESTRICT
);
COMMENT ON TABLE parcela IS 'Parcelas geradas a partir de cada contrato de emprestimo.';

-- CONTRATACAO_SERVICO: Tabela associativa entre cliente e servico (relacionamento N:N).
CREATE TABLE contratacao_servico (
    id_contratacao         SERIAL NOT NULL,
    data_contratacao       DATE NOT NULL,
    status                 VARCHAR(12) NOT NULL DEFAULT 'ativa',
    id_cliente             INT NOT NULL,
    id_servico             INT NOT NULL,
    CONSTRAINT pk_contratacao_servico PRIMARY KEY (id_contratacao),
    CONSTRAINT ck_contratacao_servico_status CHECK (status IN ('ativa','encerrada','suspensa')),
    CONSTRAINT uk_contratacao_cliente_servico UNIQUE (id_cliente, id_servico),
    CONSTRAINT fk_contratacao_servico_cliente_id_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_contratacao_servico_servico_id_servico FOREIGN KEY (id_servico)
        REFERENCES servico (id_servico) ON UPDATE CASCADE ON DELETE RESTRICT
);
COMMENT ON TABLE contratacao_servico IS 'Tabela associativa entre cliente e servico (relacionamento N:N).';

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

-- ATENDIMENTO: Tickets de atendimento abertos pelos clientes.
CREATE TABLE atendimento (
    id_atendimento         SERIAL NOT NULL,
    canal                  VARCHAR(15) NOT NULL,
    assunto                VARCHAR(120) NOT NULL,
    data_abertura          TIMESTAMP NOT NULL,
    data_encerramento      TIMESTAMP,
    status                 VARCHAR(15) NOT NULL DEFAULT 'aberto',
    id_cliente             INT NOT NULL,
    id_funcionario         INT NOT NULL,
    CONSTRAINT pk_atendimento PRIMARY KEY (id_atendimento),
    CONSTRAINT ck_atendimento_canal CHECK (canal IN ('app','chat','telefone','email','ouvidoria')),
    CONSTRAINT ck_atendimento_status CHECK (status IN ('aberto','em_andamento','resolvido')),
    CONSTRAINT ck_atendimento_1 CHECK (data_encerramento IS NULL OR data_encerramento >= data_abertura),
    CONSTRAINT fk_atendimento_cliente_id_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_atendimento_funcionario_id_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario) ON UPDATE CASCADE ON DELETE RESTRICT
);
COMMENT ON TABLE atendimento IS 'Tickets de atendimento abertos pelos clientes.';

-- =============================================================================
-- 2. INDICES AUXILIARES (o PostgreSQL nao cria indice automaticamente para FK)
-- =============================================================================
CREATE INDEX ix_conta_id_cliente ON conta (id_cliente);
CREATE INDEX ix_cartao_id_conta ON cartao (id_conta);
CREATE INDEX ix_chave_pix_id_conta ON chave_pix (id_conta);
CREATE INDEX ix_caixinha_id_conta ON caixinha (id_conta);
CREATE INDEX ix_emprestimo_id_cliente ON emprestimo (id_cliente);
CREATE INDEX ix_emprestimo_id_conta ON emprestimo (id_conta);
CREATE INDEX ix_parcela_id_emprestimo ON parcela (id_emprestimo);
CREATE INDEX ix_transacao_id_conta_origem ON transacao (id_conta_origem);
CREATE INDEX ix_transacao_id_conta_destino ON transacao (id_conta_destino);
CREATE INDEX ix_transacao_id_cartao ON transacao (id_cartao);
CREATE INDEX ix_contratacao_servico_id_cliente ON contratacao_servico (id_cliente);
CREATE INDEX ix_contratacao_servico_id_servico ON contratacao_servico (id_servico);
CREATE INDEX ix_atendimento_id_cliente ON atendimento (id_cliente);
CREATE INDEX ix_atendimento_id_funcionario ON atendimento (id_funcionario);

-- =============================================================================
-- FIM DO SCRIPT ESTRUTURAL
-- =============================================================================

-- =============================================================================
-- PARTE 2 - DADOS DE EXEMPLO
-- =============================================================================
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
-- FUNCIONARIO (6 registros)
-- ---------------------------------------------------------------------------
INSERT INTO funcionario (id_funcionario, nome, cargo, departamento,
                         email_corporativo, salario, data_admissao, status) VALUES
    (1, 'Ana Paula Ribeiro', 'Diretora Executiva (CEO)', 'Diretoria', 'ana.ribeiro@novabank.com.br', 28000.00, '2024-02-01', 'ativo'),
    (2, 'Bruno Carvalho Mendes', 'Engenheiro de Software Senior', 'Tecnologia', 'bruno.mendes@novabank.com.br', 14500.00, '2024-04-15', 'ativo'),
    (3, 'Carla Menezes Farias', 'Analista de Credito', 'Financeiro', 'carla.farias@novabank.com.br', 7800.00, '2024-08-05', 'ativo'),
    (4, 'Diego Ramos Teixeira', 'Especialista em CX', 'CX', 'diego.teixeira@novabank.com.br', 6900.00, '2025-01-20', 'ativo'),
    (5, 'Elisa Fontes Barros', 'Analista de Compliance', 'Compliance', 'elisa.barros@novabank.com.br', 9200.00, '2024-06-10', 'ativo'),
    (6, 'Felipe Andrade Luz', 'Gerente de Atendimento', 'CX', 'felipe.luz@novabank.com.br', 8300.00, '2025-03-03', 'ativo');

-- ---------------------------------------------------------------------------
-- SERVICO (6 registros)
-- ---------------------------------------------------------------------------
INSERT INTO servico (id_servico, nome_servico, categoria, descricao, tarifa,
                     ativo) VALUES
    (1, 'Conta Digital Gratuita', 'conta', 'Conta sem mensalidade com rendimento automatico de 100% do CDI', 0.00, TRUE),
    (2, 'Cartao Virtual e Fisico', 'cartao', 'Cartao de debito e credito sem anuidade, com virtuais temporarios', 0.00, TRUE),
    (3, 'Pix e Transferencias 24/7', 'pix', 'Transferencias instantaneas gratuitas para qualquer banco', 0.00, TRUE),
    (4, 'Pagamento de Boletos', 'pagamento', 'Pagamento e agendamento de boletos pelo aplicativo', 0.00, TRUE),
    (5, 'Emprestimo Pessoal Jovem', 'credito', 'Credito pessoal a partir de 0,99% ao mes, com simulacao no app', 0.00, TRUE),
    (6, 'Caixinhas com Rendimento', 'investimento', 'Reservas por objetivo com rendimento diario automatico', 0.00, TRUE);

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
-- CHAVE_PIX (10 registros)
-- ---------------------------------------------------------------------------
INSERT INTO chave_pix (id_chave, tipo_chave, valor_chave, data_cadastro,
                       ativa, id_conta) VALUES
    (1, 'cpf', '12345678901', '2025-03-10', TRUE, 1),
    (2, 'email', 'ana.lima@email.com', '2025-03-10', TRUE, 1),
    (3, 'telefone', '+5521987654321', '2025-05-22', TRUE, 2),
    (4, 'cpf', '23456789012', '2025-05-22', TRUE, 2),
    (5, 'aleatoria', 'a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d', '2025-09-01', TRUE, 3),
    (6, 'email', 'pedro.santos@email.com', '2025-01-15', TRUE, 4),
    (7, 'telefone', '+5541995442211', '2025-07-19', TRUE, 7),
    (8, 'email', 'rafael.barbosa@email.com', '2025-04-08', TRUE, 9),
    (9, 'cpf', '90123456789', '2026-01-27', TRUE, 10),
    (10, 'aleatoria', 'f7e8d9c0-b1a2-4c3d-8e9f-0a1b2c3d4e5f', '2025-11-03', FALSE, 6);

-- ---------------------------------------------------------------------------
-- CAIXINHA (8 registros)
-- ---------------------------------------------------------------------------
INSERT INTO caixinha (id_caixinha, nome_objetivo, valor_meta, saldo_atual,
                      data_criacao, data_prevista, status, id_conta) VALUES
    (1, 'Viagem para o Chile', 6000.00, 2450.00, '2026-01-10', '2027-01-15', 'ativa', 1),
    (2, 'Reserva de Emergencia', 5000.00, 1800.00, '2025-06-02', '2027-06-30', 'ativa', 1),
    (3, 'Curso de Ingles', 3000.00, 3000.00, '2025-05-12', '2026-08-31', 'concluida', 2),
    (4, 'Notebook Novo', 4500.00, 900.00, '2026-02-18', '2027-02-28', 'ativa', 3),
    (5, 'Entrada do Apartamento', 20000.00, 7200.00, '2025-02-10', '2028-12-31', 'ativa', 4),
    (6, 'Intercambio na Irlanda', 8000.00, 1200.00, '2026-04-05', '2027-09-30', 'ativa', 6),
    (7, 'Moto Usada', 12000.00, 3500.00, '2025-09-15', '2027-03-31', 'ativa', 9),
    (8, 'Fundo de Estudos', 2500.00, 650.00, '2026-06-20', '2027-06-30', 'ativa', 10);

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
-- PARCELA (60 registros)
-- ---------------------------------------------------------------------------
INSERT INTO parcela (id_parcela, numero_parcela, valor_parcela,
                     data_vencimento, data_pagamento, status, id_emprestimo) VALUES
    (1, 1, 266.38, '2026-06-10', '2026-06-10', 'paga', 1),
    (2, 2, 266.38, '2026-07-10', '2026-07-10', 'paga', 1),
    (3, 3, 266.38, '2026-08-10', '2026-08-10', 'paga', 1),
    (4, 4, 266.38, '2026-09-10', '2026-09-10', 'paga', 1),
    (5, 5, 266.38, '2026-10-10', '2026-10-10', 'paga', 1),
    (6, 6, 266.38, '2026-11-10', NULL, 'atrasada', 1),
    (7, 7, 266.38, '2026-12-10', NULL, 'aberta', 1),
    (8, 8, 266.38, '2027-01-10', NULL, 'aberta', 1),
    (9, 9, 266.38, '2027-02-10', NULL, 'aberta', 1),
    (10, 10, 266.38, '2027-03-10', NULL, 'aberta', 1),
    (11, 11, 266.38, '2027-04-10', NULL, 'aberta', 1),
    (12, 12, 266.38, '2027-05-10', NULL, 'aberta', 1),
    (13, 1, 731.12, '2026-03-05', '2026-03-05', 'paga', 2),
    (14, 2, 731.12, '2026-04-05', '2026-04-05', 'paga', 2),
    (15, 3, 731.12, '2026-05-05', '2026-05-05', 'paga', 2),
    (16, 4, 731.12, '2026-06-05', '2026-06-05', 'paga', 2),
    (17, 5, 731.12, '2026-07-05', '2026-07-05', 'paga', 2),
    (18, 6, 731.12, '2026-08-05', '2026-08-05', 'paga', 2),
    (19, 7, 731.12, '2026-09-05', '2026-09-05', 'paga', 2),
    (20, 8, 731.12, '2026-10-05', '2026-10-05', 'paga', 2),
    (21, 9, 731.12, '2026-11-05', NULL, 'atrasada', 2),
    (22, 10, 731.12, '2026-12-05', NULL, 'aberta', 2),
    (23, 11, 731.12, '2027-01-05', NULL, 'aberta', 2),
    (24, 12, 731.12, '2027-02-05', NULL, 'aberta', 2),
    (25, 13, 731.12, '2027-03-05', NULL, 'aberta', 2),
    (26, 14, 731.12, '2027-04-05', NULL, 'aberta', 2),
    (27, 15, 731.12, '2027-05-05', NULL, 'aberta', 2),
    (28, 16, 731.12, '2027-06-05', NULL, 'aberta', 2),
    (29, 17, 731.12, '2027-07-05', NULL, 'aberta', 2),
    (30, 18, 731.12, '2027-08-05', NULL, 'aberta', 2),
    (31, 1, 313.05, '2026-08-20', '2026-08-20', 'paga', 3),
    (32, 2, 313.05, '2026-09-20', '2026-09-20', 'paga', 3),
    (33, 3, 313.05, '2026-10-20', NULL, 'atrasada', 3),
    (34, 4, 313.05, '2026-11-20', NULL, 'aberta', 3),
    (35, 5, 313.05, '2026-12-20', NULL, 'aberta', 3),
    (36, 6, 313.05, '2027-01-20', NULL, 'aberta', 3),
    (37, 7, 313.05, '2027-02-20', NULL, 'aberta', 3),
    (38, 8, 313.05, '2027-03-20', NULL, 'aberta', 3),
    (39, 9, 313.05, '2027-04-20', NULL, 'aberta', 3),
    (40, 10, 313.05, '2027-05-20', NULL, 'aberta', 3),
    (41, 11, 313.05, '2027-06-20', NULL, 'aberta', 3),
    (42, 12, 313.05, '2027-07-20', NULL, 'aberta', 3),
    (43, 13, 313.05, '2027-08-20', NULL, 'aberta', 3),
    (44, 14, 313.05, '2027-09-20', NULL, 'aberta', 3),
    (45, 15, 313.05, '2027-10-20', NULL, 'aberta', 3),
    (46, 16, 313.05, '2027-11-20', NULL, 'aberta', 3),
    (47, 17, 313.05, '2027-12-20', NULL, 'aberta', 3),
    (48, 18, 313.05, '2028-01-20', NULL, 'aberta', 3),
    (49, 1, 710.34, '2025-11-12', '2025-11-12', 'paga', 4),
    (50, 2, 710.34, '2025-12-12', '2025-12-12', 'paga', 4),
    (51, 3, 710.34, '2026-01-12', '2026-01-12', 'paga', 4),
    (52, 4, 710.34, '2026-02-12', '2026-02-12', 'paga', 4),
    (53, 5, 710.34, '2026-03-12', '2026-03-12', 'paga', 4),
    (54, 6, 710.34, '2026-04-12', '2026-04-12', 'paga', 4),
    (55, 7, 710.34, '2026-05-12', '2026-05-12', 'paga', 4),
    (56, 8, 710.34, '2026-06-12', '2026-06-12', 'paga', 4),
    (57, 9, 710.34, '2026-07-12', '2026-07-12', 'paga', 4),
    (58, 10, 710.34, '2026-08-12', '2026-08-12', 'paga', 4),
    (59, 11, 710.34, '2026-09-12', '2026-09-12', 'paga', 4),
    (60, 12, 710.34, '2026-10-12', '2026-10-12', 'paga', 4);

-- ---------------------------------------------------------------------------
-- CONTRATACAO_SERVICO (37 registros)
-- ---------------------------------------------------------------------------
INSERT INTO contratacao_servico (id_contratacao, data_contratacao, status,
                                 id_cliente, id_servico) VALUES
    (1, '2025-03-21', 'ativa', 1, 1),
    (2, '2025-04-01', 'ativa', 1, 2),
    (3, '2025-04-12', 'ativa', 1, 3),
    (4, '2025-04-23', 'ativa', 1, 4),
    (5, '2025-05-15', 'ativa', 1, 6),
    (6, '2025-06-02', 'ativa', 2, 1),
    (7, '2025-06-13', 'ativa', 2, 2),
    (8, '2025-06-24', 'ativa', 2, 3),
    (9, '2025-07-27', 'ativa', 2, 6),
    (10, '2025-09-12', 'ativa', 3, 1),
    (11, '2025-10-04', 'ativa', 3, 3),
    (12, '2025-01-26', 'ativa', 4, 1),
    (13, '2025-02-06', 'ativa', 4, 2),
    (14, '2025-02-17', 'ativa', 4, 3),
    (15, '2025-02-28', 'ativa', 4, 4),
    (16, '2025-03-11', 'ativa', 4, 5),
    (17, '2025-03-22', 'ativa', 4, 6),
    (18, '2025-11-14', 'ativa', 5, 1),
    (19, '2025-12-06', 'ativa', 5, 3),
    (20, '2026-01-08', 'ativa', 5, 6),
    (21, '2025-07-30', 'ativa', 6, 1),
    (22, '2025-08-10', 'ativa', 6, 2),
    (23, '2025-08-21', 'ativa', 6, 3),
    (24, '2025-09-12', 'ativa', 6, 5),
    (25, '2026-02-22', 'ativa', 7, 1),
    (26, '2026-03-16', 'ativa', 7, 3),
    (27, '2025-04-19', 'ativa', 8, 1),
    (28, '2025-04-30', 'ativa', 8, 2),
    (29, '2025-05-11', 'ativa', 8, 3),
    (30, '2025-05-22', 'ativa', 8, 4),
    (31, '2025-06-02', 'ativa', 8, 5),
    (32, '2025-06-13', 'ativa', 8, 6),
    (33, '2026-02-07', 'ativa', 9, 1),
    (34, '2026-03-01', 'ativa', 9, 3),
    (35, '2026-04-03', 'ativa', 9, 6),
    (36, '2025-09-10', 'ativa', 10, 1),
    (37, '2025-10-02', 'ativa', 10, 3);

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

-- ---------------------------------------------------------------------------
-- ATENDIMENTO (9 registros)
-- ---------------------------------------------------------------------------
INSERT INTO atendimento (id_atendimento, canal, assunto, data_abertura,
                         data_encerramento, status, id_cliente,
                         id_funcionario) VALUES
    (1, 'chat', 'Duvida sobre limite do cartao de credito', '2026-09-03 10:12:00', '2026-09-03 10:41:00', 'resolvido', 1, 4),
    (2, 'app', 'Segunda via de comprovante de Pix', '2026-09-18 14:05:00', '2026-09-18 14:22:00', 'resolvido', 3, 4),
    (3, 'telefone', 'Cartao bloqueado apos tentativa de compra', '2026-10-02 09:30:00', '2026-10-02 10:15:00', 'resolvido', 6, 6),
    (4, 'email', 'Solicitacao de antecipacao de parcelas', '2026-10-14 16:40:00', '2026-10-15 11:05:00', 'resolvido', 4, 3),
    (5, 'ouvidoria', 'Discordancia sobre juros do emprestimo', '2026-10-27 08:55:00', NULL, 'em_andamento', 8, 1),
    (6, 'chat', 'Como criar uma caixinha de viagem', '2026-11-04 19:10:00', '2026-11-04 19:25:00', 'resolvido', 9, 4),
    (7, 'app', 'Problema no reconhecimento facial', '2026-11-09 07:45:00', NULL, 'aberto', 7, 2),
    (8, 'telefone', 'Pedido de desbloqueio da conta', '2026-11-12 13:20:00', NULL, 'em_andamento', 10, 5),
    (9, 'chat', 'Duvida sobre rendimento das caixinhas', '2026-11-15 21:05:00', '2026-11-15 21:18:00', 'resolvido', 5, 6);

COMMIT;

-- Conferencia das contagens
SELECT 'cliente' AS tabela, COUNT(*) AS registros FROM cliente
UNION ALL
SELECT 'funcionario' AS tabela, COUNT(*) AS registros FROM funcionario
UNION ALL
SELECT 'servico' AS tabela, COUNT(*) AS registros FROM servico
UNION ALL
SELECT 'conta' AS tabela, COUNT(*) AS registros FROM conta
UNION ALL
SELECT 'cartao' AS tabela, COUNT(*) AS registros FROM cartao
UNION ALL
SELECT 'chave_pix' AS tabela, COUNT(*) AS registros FROM chave_pix
UNION ALL
SELECT 'caixinha' AS tabela, COUNT(*) AS registros FROM caixinha
UNION ALL
SELECT 'emprestimo' AS tabela, COUNT(*) AS registros FROM emprestimo
UNION ALL
SELECT 'parcela' AS tabela, COUNT(*) AS registros FROM parcela
UNION ALL
SELECT 'contratacao_servico' AS tabela, COUNT(*) AS registros FROM contratacao_servico
UNION ALL
SELECT 'transacao' AS tabela, COUNT(*) AS registros FROM transacao
UNION ALL
SELECT 'atendimento' AS tabela, COUNT(*) AS registros FROM atendimento
ORDER BY tabela;
