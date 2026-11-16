-- =============================================================================
-- PROJETO: Nova Bank - Instituicao de Pagamento S.A. (banco 100% digital)
-- ETAPA:   Modelagem e implementacao do banco de dados (versao minima)
-- ARQUIVO: 01_schema.sql
-- SGBD:    PostgreSQL 17 (Neon - Postgres serverless)
-- AUTORES: (equipe do projeto)
-- DATA:    novembro/2026
-- =============================================================================
-- Como executar no Neon:
--   1) Console do Neon > SQL Editor: cole o arquivo 00_nova_bank_completo.sql e clique em Run; ou
--   2) Pelo terminal, com a connection string do projeto (Connection Details > Direct connection):
--      psql "postgresql://USUARIO:SENHA@ep-xxxx.regiao.aws.neon.tech/neondb?sslmode=require" -f 01_schema.sql
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
