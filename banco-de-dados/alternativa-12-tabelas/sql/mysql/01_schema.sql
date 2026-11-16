-- =============================================================================
-- PROJETO: Nova Bank - Instituicao de Pagamento S.A. (banco 100% digital)
-- ETAPA:   Modelagem e implementacao do banco de dados
-- ARQUIVO: 01_schema.sql
-- SGBD:    MySQL 8.0 ou superior
-- AUTORES: (equipe do projeto)
-- DATA:    novembro/2026
-- =============================================================================
-- Como executar: abra no MySQL Workbench e execute o script inteiro,
-- ou rode no terminal: mysql -u root -p < 01_schema.sql

CREATE DATABASE IF NOT EXISTS nova_bank
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_general_ci;

USE nova_bank;

-- Remocao das tabelas na ordem inversa das dependencias
DROP TABLE IF EXISTS atendimento;
DROP TABLE IF EXISTS transacao;
DROP TABLE IF EXISTS contratacao_servico;
DROP TABLE IF EXISTS parcela;
DROP TABLE IF EXISTS emprestimo;
DROP TABLE IF EXISTS caixinha;
DROP TABLE IF EXISTS chave_pix;
DROP TABLE IF EXISTS cartao;
DROP TABLE IF EXISTS conta;
DROP TABLE IF EXISTS servico;
DROP TABLE IF EXISTS funcionario;
DROP TABLE IF EXISTS cliente;

-- =============================================================================
-- 1. CRIACAO DAS TABELAS
-- =============================================================================

-- CLIENTE: Cadastro dos clientes (publico jovem) do Nova Bank.
CREATE TABLE cliente (
    id_cliente             INT NOT NULL AUTO_INCREMENT,
    nome_completo          VARCHAR(120) NOT NULL,
    cpf                    CHAR(11) NOT NULL,
    data_nascimento        DATE NOT NULL,
    email                  VARCHAR(120) NOT NULL,
    telefone               VARCHAR(20) NOT NULL,
    cidade                 VARCHAR(60) NOT NULL,
    uf                     CHAR(2) NOT NULL,
    renda_mensal           DECIMAL(10,2) NOT NULL,
    data_cadastro          DATE NOT NULL DEFAULT (CURRENT_DATE),
    status                 VARCHAR(12) NOT NULL DEFAULT 'ativo',
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT uk_cliente_cpf UNIQUE (cpf),
    CONSTRAINT uk_cliente_email UNIQUE (email),
    CONSTRAINT ck_cliente_cpf CHECK (CHAR_LENGTH(cpf) = 11),
    CONSTRAINT ck_cliente_uf CHECK (CHAR_LENGTH(uf) = 2),
    CONSTRAINT ck_cliente_renda_mensal CHECK (renda_mensal >= 0),
    CONSTRAINT ck_cliente_status CHECK (status IN ('ativo','inativo','bloqueado'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Cadastro dos clientes (publico jovem) do Nova Bank.';

-- FUNCIONARIO: Colaboradores que compoem a estrutura organizacional do banco.
CREATE TABLE funcionario (
    id_funcionario         INT NOT NULL AUTO_INCREMENT,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Colaboradores que compoem a estrutura organizacional do banco.';

-- SERVICO: Catalogo de servicos financeiros oferecidos pelo banco.
CREATE TABLE servico (
    id_servico             INT NOT NULL AUTO_INCREMENT,
    nome_servico           VARCHAR(60) NOT NULL,
    categoria              VARCHAR(20) NOT NULL,
    descricao              VARCHAR(200),
    tarifa                 DECIMAL(8,2) NOT NULL DEFAULT 0,
    ativo                  BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_servico PRIMARY KEY (id_servico),
    CONSTRAINT uk_servico_nome_servico UNIQUE (nome_servico),
    CONSTRAINT ck_servico_categoria CHECK (categoria IN ('conta','cartao','pix','pagamento','credito','investimento')),
    CONSTRAINT ck_servico_tarifa CHECK (tarifa >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Catalogo de servicos financeiros oferecidos pelo banco.';

-- CONTA: Contas digitais abertas pelos clientes.
CREATE TABLE conta (
    id_conta               INT NOT NULL AUTO_INCREMENT,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Contas digitais abertas pelos clientes.';

-- CARTAO: Cartoes de debito, credito e virtuais vinculados as contas.
CREATE TABLE cartao (
    id_cartao              INT NOT NULL AUTO_INCREMENT,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Cartoes de debito, credito e virtuais vinculados as contas.';

-- CHAVE_PIX: Chaves Pix registradas por conta.
CREATE TABLE chave_pix (
    id_chave               INT NOT NULL AUTO_INCREMENT,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Chaves Pix registradas por conta.';

-- CAIXINHA: Caixinhas de objetivos com rendimento automatico.
CREATE TABLE caixinha (
    id_caixinha            INT NOT NULL AUTO_INCREMENT,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Caixinhas de objetivos com rendimento automatico.';

-- EMPRESTIMO: Contratos de emprestimo pessoal jovem.
CREATE TABLE emprestimo (
    id_emprestimo          INT NOT NULL AUTO_INCREMENT,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Contratos de emprestimo pessoal jovem.';

-- PARCELA: Parcelas geradas a partir de cada contrato de emprestimo.
CREATE TABLE parcela (
    id_parcela             INT NOT NULL AUTO_INCREMENT,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Parcelas geradas a partir de cada contrato de emprestimo.';

-- CONTRATACAO_SERVICO: Tabela associativa entre cliente e servico (relacionamento N:N).
CREATE TABLE contratacao_servico (
    id_contratacao         INT NOT NULL AUTO_INCREMENT,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tabela associativa entre cliente e servico (relacionamento N:N).';

-- TRANSACAO: Movimentacoes financeiras (Pix, boletos, compras e rendimentos).
CREATE TABLE transacao (
    id_transacao           INT NOT NULL AUTO_INCREMENT,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Movimentacoes financeiras (Pix, boletos, compras e rendimentos).';

-- ATENDIMENTO: Tickets de atendimento abertos pelos clientes.
CREATE TABLE atendimento (
    id_atendimento         INT NOT NULL AUTO_INCREMENT,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tickets de atendimento abertos pelos clientes.';

-- =============================================================================
-- 2. INDICES AUXILIARES
-- =============================================================================
CREATE INDEX ix_transacao_id_conta_origem ON transacao (id_conta_origem);
CREATE INDEX ix_transacao_id_conta_destino ON transacao (id_conta_destino);
CREATE INDEX ix_transacao_id_cartao ON transacao (id_cartao);

-- =============================================================================
-- FIM DO SCRIPT ESTRUTURAL
-- =============================================================================
