# -*- coding: utf-8 -*-
"""Modelo minimo do Nova Bank: 5 entidades, 7 chaves estrangeiras."""


def A(nome, tipo, desc, nn=False, pk=False, fk=None, uq=False, d=None, ck=None):
    return {"n": nome, "t": tipo, "desc": desc, "nn": nn, "pk": pk,
            "fk": fk, "uq": uq, "d": d, "ck": ck}


ENTIDADES = [
    {
        "nome": "cliente", "rotulo": "CLIENTE", "dominio": "Cadastro",
        "attrs": [
            A("id_cliente", "INT", "Identificador único do cliente", nn=True, pk=True),
            A("nome_completo", "VARCHAR(120)", "Nome civil completo do titular", nn=True),
            A("cpf", "CHAR(11)", "CPF do cliente, somente os 11 dígitos", nn=True, uq=True,
              ck="CHAR_LENGTH(cpf) = 11"),
            A("data_nascimento", "DATE", "Data de nascimento (público jovem)", nn=True),
            A("email", "VARCHAR(120)", "E-mail utilizado para acesso ao aplicativo", nn=True, uq=True),
            A("telefone", "VARCHAR(20)", "Telefone celular para contato", nn=True),
            A("cidade", "VARCHAR(60)", "Cidade de residência", nn=True),
            A("uf", "CHAR(2)", "Sigla do estado (ex.: SP, RJ)", nn=True, ck="CHAR_LENGTH(uf) = 2"),
            A("renda_mensal", "DECIMAL(10,2)", "Renda mensal declarada, em reais", nn=True,
              ck="renda_mensal >= 0"),
            A("data_cadastro", "DATE", "Data de abertura do cadastro", nn=True, d="CURRENT_DATE"),
            A("status", "VARCHAR(12)", "Situação cadastral do cliente", nn=True, d="'ativo'",
              ck="status IN ('ativo','inativo','bloqueado')"),
        ],
    },
    {
        "nome": "conta", "rotulo": "CONTA", "dominio": "Núcleo bancário",
        "attrs": [
            A("id_conta", "INT", "Identificador único da conta", nn=True, pk=True),
            A("numero_conta", "VARCHAR(10)", "Número da conta, com dígito verificador", nn=True, uq=True),
            A("agencia", "VARCHAR(5)", "Código da agência digital", nn=True, d="'0001'"),
            A("tipo_conta", "VARCHAR(15)", "Tipo de conta aberta", nn=True, d="'pagamento'",
              ck="tipo_conta IN ('corrente','poupanca','pagamento')"),
            A("saldo", "DECIMAL(12,2)", "Saldo disponível, em reais", nn=True, d="0",
              ck="saldo >= 0"),
            A("data_abertura", "DATE", "Data de abertura da conta", nn=True),
            A("status", "VARCHAR(12)", "Situação da conta", nn=True, d="'ativa'",
              ck="status IN ('ativa','encerrada','bloqueada')"),
            A("id_cliente", "INT", "Cliente titular da conta", nn=True,
              fk=("cliente", "id_cliente")),
        ],
    },
    {
        "nome": "cartao", "rotulo": "CARTAO", "dominio": "Núcleo bancário",
        "attrs": [
            A("id_cartao", "INT", "Identificador único do cartão", nn=True, pk=True),
            A("numero_mascarado", "VARCHAR(19)", "Número do cartão mascarado (LGPD)", nn=True),
            A("tipo_cartao", "VARCHAR(10)", "Débito, crédito ou virtual", nn=True,
              ck="tipo_cartao IN ('debito','credito','virtual')"),
            A("bandeira", "VARCHAR(15)", "Bandeira do cartão", nn=True,
              ck="bandeira IN ('Visa','Mastercard','Elo')"),
            A("limite_total", "DECIMAL(10,2)", "Limite total aprovado", nn=True, d="0",
              ck="limite_total >= 0"),
            A("limite_disponivel", "DECIMAL(10,2)", "Limite ainda disponível para compras", nn=True, d="0",
              ck="limite_disponivel >= 0 AND limite_disponivel <= limite_total"),
            A("data_emissao", "DATE", "Data de emissão do cartão", nn=True),
            A("data_validade", "DATE", "Data de validade do cartão", nn=True),
            A("status", "VARCHAR(12)", "Situação do cartão", nn=True, d="'ativo'",
              ck="status IN ('ativo','bloqueado','cancelado')"),
            A("id_conta", "INT", "Conta à qual o cartão está vinculado", nn=True,
              fk=("conta", "id_conta")),
        ],
    },
    {
        "nome": "emprestimo", "rotulo": "EMPRESTIMO", "dominio": "Crédito",
        "attrs": [
            A("id_emprestimo", "INT", "Identificador único do contrato", nn=True, pk=True),
            A("valor_principal", "DECIMAL(12,2)", "Valor liberado ao cliente", nn=True,
              ck="valor_principal > 0"),
            A("taxa_juros_mensal", "DECIMAL(5,2)", "Taxa de juros mensal, em porcentagem", nn=True,
              ck="taxa_juros_mensal >= 0"),
            A("prazo_meses", "INT", "Prazo total do contrato, em meses", nn=True,
              ck="prazo_meses BETWEEN 3 AND 36"),
            A("data_contratacao", "DATE", "Data de assinatura do contrato", nn=True),
            A("status", "VARCHAR(12)", "Etapa atual do contrato", nn=True, d="'em_analise'",
              ck="status IN ('em_analise','aprovado','ativo','quitado','cancelado')"),
            A("id_cliente", "INT", "Cliente tomador do crédito", nn=True,
              fk=("cliente", "id_cliente")),
            A("id_conta", "INT", "Conta que recebe o desembolso", nn=True,
              fk=("conta", "id_conta")),
        ],
    },
    {
        "nome": "transacao", "rotulo": "TRANSACAO", "dominio": "Núcleo bancário",
        "attrs": [
            A("id_transacao", "INT", "Identificador único da movimentação", nn=True, pk=True),
            A("tipo", "VARCHAR(25)", "Natureza da movimentação", nn=True,
              ck="tipo IN ('pix_enviado','pix_recebido','boleto','compra_debito','compra_credito','rendimento','saque','transferencia')"),
            A("valor", "DECIMAL(12,2)", "Valor da movimentação, sempre positivo", nn=True, ck="valor > 0"),
            A("data_hora", "TIMESTAMP", "Data e hora da movimentação", nn=True,
              d="CURRENT_TIMESTAMP"),
            A("descricao", "VARCHAR(150)", "Histórico apresentado no extrato", nn=False),
            A("status", "VARCHAR(12)", "Situação da movimentação", nn=True, d="'concluida'",
              ck="status IN ('concluida','pendente','cancelada','estornada')"),
            A("id_conta_origem", "INT", "Conta debitada (nulo em entradas externas)", nn=False,
              fk=("conta", "id_conta")),
            A("id_conta_destino", "INT", "Conta creditada (nulo em saídas externas)", nn=False,
              fk=("conta", "id_conta")),
            A("id_cartao", "INT", "Cartão utilizado na compra, quando aplicável", nn=False,
              fk=("cartao", "id_cartao")),
        ],
        "tchecks": [
            "CHECK (id_conta_origem IS NOT NULL OR id_conta_destino IS NOT NULL)",
            "CHECK (id_conta_origem IS NULL OR id_conta_destino IS NULL OR id_conta_origem <> id_conta_destino)",
        ],
    },
]

ORDEM = ["cliente", "conta", "cartao", "emprestimo", "transacao"]

POR_NOME = {e["nome"]: e for e in ENTIDADES}

# (tabela_filha, tabela_pai, atributo_fk, cardinalidade, verbo)
RELACIONAMENTOS = [
    ("conta", "cliente", "id_cliente", "1:N", "possui"),
    ("cartao", "conta", "id_conta", "1:N", "emite"),
    ("emprestimo", "cliente", "id_cliente", "1:N", "contrata"),
    ("emprestimo", "conta", "id_conta", "1:N", "credita"),
    ("transacao", "conta", "id_conta_origem", "1:N", "debita"),
    ("transacao", "conta", "id_conta_destino", "1:N", "credita"),
    ("transacao", "cartao", "id_cartao", "1:N", "movimenta"),
]

UNICAS_COMPOSTAS = []

DDL_COMMENTS = {
    "cliente": "Cadastro dos clientes (público jovem) do Nova Bank.",
    "conta": "Contas digitais abertas pelos clientes.",
    "cartao": "Cartões de débito, crédito e virtuais vinculados às contas.",
    "emprestimo": "Contratos de empréstimo pessoal jovem.",
    "transacao": "Movimentações financeiras (Pix, boletos, compras e rendimentos).",
}
