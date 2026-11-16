-- =============================================================================
-- PROJETO: Nova Bank - Instituicao de Pagamento S.A. (banco 100% digital)
-- ETAPA:   Modelagem e implementacao do banco de dados
-- ARQUIVO: 01_schema.sql
-- SGBD:    PostgreSQL 17 (Neon)
-- AUTORES: (equipe do projeto)
-- DATA:    novembro/2026
-- =============================================================================
-- Como executar no Neon (Postgres serverless):
--   1) No console do Neon, abra o SQL Editor, cole o conteudo e clique em Run; ou
--   2) Pelo terminal, use a connection string do projeto
--      (Connection Details > Direct connection):
--      psql "postgresql://USUARIO:SENHA@ep-xxxx.regiao.aws.neon.tech/neondb?sslmode=require" -f 01_schema.sql
--
-- Observacoes do Neon:
--   - use a conexao direta (sem -pooler) para executar DDL;
--   - o banco do projeto e o neondb e o schema e o public (nao e preciso criar banco);
--   - os objetos sao criados no banco atual da conexao.

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
