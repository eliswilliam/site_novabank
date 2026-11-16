# -*- coding: utf-8 -*-
"""Gera os scripts SQL da versao minima (5 tabelas) para o PostgreSQL/Neon."""

import io
import os
import sys
import unicodedata
from datetime import date, datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import modelo5 as modelo  # noqa: E402
import dados  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PASTA = os.path.join(RAIZ, "sql", "postgresql")

CABECALHO = """-- =============================================================================
-- PROJETO: Nova Bank - Instituicao de Pagamento S.A. (banco 100% digital)
-- ETAPA:   Modelagem e implementacao do banco de dados (versao minima)
-- ARQUIVO: {arquivo}
-- SGBD:    PostgreSQL 17 (Neon - Postgres serverless)
-- AUTORES: (equipe do projeto)
-- DATA:    novembro/2026
-- =============================================================================
{extra}"""

EXTRA = (
    "-- Como executar no Neon:\n"
    "--   1) Console do Neon > SQL Editor: cole o arquivo 00_nova_bank_completo.sql e clique em Run; ou\n"
    "--   2) Pelo terminal, com a connection string do projeto (Connection Details > Direct connection):\n"
    "--      psql \"postgresql://USUARIO:SENHA@ep-xxxx.regiao.aws.neon.tech/neondb?sslmode=require\" -f {arquivo}\n"
    "--\n"
    "-- Observacoes do Neon:\n"
    "--   - use a conexao direta (sem -pooler) para executar DDL;\n"
    "--   - o banco do projeto e o neondb e o schema e o public: nao e preciso criar banco;\n"
    "--   - os objetos sao criados no banco atual da conexao.\n")


def q(s):
    return "'" + str(s).replace("'", "''") + "'"


def sem_acento(texto):
    return "".join(c for c in unicodedata.normalize("NFD", texto)
                   if unicodedata.category(c) != "Mn")


def lit(v):
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    if isinstance(v, datetime):
        return "'" + v.strftime("%Y-%m-%d %H:%M:%S") + "'"
    if isinstance(v, date):
        return "'" + v.strftime("%Y-%m-%d") + "'"
    if isinstance(v, float):
        return f"{v:.2f}"
    if isinstance(v, int):
        return str(v)
    return q(v)


def pk_nome(tabela):
    for a in modelo.POR_NOME[tabela]["attrs"]:
        if a["pk"]:
            return a["n"]
    raise ValueError(tabela)


def ddl_corpo():
    L = ["-- =============================================================================\n"
         "-- 1. CRIACAO DAS TABELAS\n"
         "-- =============================================================================\n"]

    for nome in modelo.ORDEM:
        ent = modelo.POR_NOME[nome]
        L.append(f"\n-- {nome.upper()}: {sem_acento(modelo.DDL_COMMENTS[nome])}\n")
        L.append(f"CREATE TABLE {nome} (\n")
        linhas = []
        for a in ent["attrs"]:
            if a["pk"]:
                decl = f"    {a['n']:<22} SERIAL NOT NULL"
            else:
                decl = f"    {a['n']:<22} {a['t']}"
                if a["nn"]:
                    decl += " NOT NULL"
                if a["d"] is not None:
                    decl += f" DEFAULT {a['d']}"
            linhas.append(decl)
        cons = []
        pk = [a["n"] for a in ent["attrs"] if a["pk"]]
        cons.append(f"    CONSTRAINT pk_{nome} PRIMARY KEY ({', '.join(pk)})")
        for a in ent["attrs"]:
            if a["uq"]:
                cons.append(f"    CONSTRAINT uk_{nome}_{a['n']} UNIQUE ({a['n']})")
        for a in ent["attrs"]:
            if a["ck"]:
                cons.append(f"    CONSTRAINT ck_{nome}_{a['n']} CHECK ({a['ck']})")
        for idx, t in enumerate(ent.get("tchecks", []), start=1):
            cons.append(f"    CONSTRAINT ck_{nome}_{idx} {t}")
        for filha, pai, col, card, verbo in modelo.RELACIONAMENTOS:
            if filha == nome:
                cons.append(
                    f"    CONSTRAINT fk_{nome}_{pai}_{col} FOREIGN KEY ({col})\n"
                    f"        REFERENCES {pai} ({pk_nome(pai)}) ON UPDATE CASCADE ON DELETE RESTRICT")
        L.append(",\n".join(linhas + cons))
        L.append("\n);\n")
        L.append(f"COMMENT ON TABLE {nome} IS {q(sem_acento(modelo.DDL_COMMENTS[nome]))};\n")

    L.append("\n-- =============================================================================\n"
             "-- 2. INDICES DAS CHAVES ESTRANGEIRAS\n"
             "-- =============================================================================\n")
    vistos = set()
    for filha, pai, col, card, verbo in modelo.RELACIONAMENTOS:
        if (filha, col) in vistos:
            continue
        vistos.add((filha, col))
        L.append(f"CREATE INDEX ix_{filha}_{col} ON {filha} ({col});\n")
    return "".join(L)


def linhas_tabela(nome):
    ent = modelo.POR_NOME[nome]
    cols = [a["n"] for a in ent["attrs"]]
    if nome == "cliente":
        rows = dados.CLIENTES
    elif nome == "conta":
        rows = [(c[0], c[1], c[2], c[3], dados.SALDOS[c[0]], c[4], c[5], c[6])
                for c in dados.CONTAS]
    elif nome == "cartao":
        rows = dados.CARTOES
    elif nome == "emprestimo":
        rows = dados.EMPRESTIMOS
    elif nome == "transacao":
        rows = [(t["id"], t["tipo"], t["valor"], t["dt"], t["desc"], t["status"],
                 t["origem"], t["destino"], t["cartao"]) for t in dados.TRANSACOES]
    else:
        rows = []
    return cols, rows


def cabecalho_insert(tabela, cols, limite=78):
    prefixo = f"INSERT INTO {tabela} ("
    recuo = " " * len(prefixo)
    linhas = []
    atual = prefixo
    for i, c in enumerate(cols):
        pedaco = c + ("," if i < len(cols) - 1 else ")")
        sep = "" if atual.endswith("(") else " "
        if len(atual) + len(sep) + len(pedaco) > limite and not atual.endswith("("):
            linhas.append(atual)
            atual = recuo + pedaco
        else:
            atual = atual + sep + pedaco
    linhas.append(atual + " VALUES")
    return "\n".join(linhas)


def dados_corpo():
    L = ["BEGIN;\n"]
    for nome in modelo.ORDEM:
        cols, rows = linhas_tabela(nome)
        L.append("\n-- ---------------------------------------------------------------------------\n")
        L.append(f"-- {nome.upper()} ({len(rows)} registros)\n")
        L.append("-- ---------------------------------------------------------------------------\n")
        L.append(cabecalho_insert(nome, cols) + "\n")
        L.append(",\n".join("    (" + ", ".join(lit(v) for v in r) + ")" for r in rows))
        L.append(";\n")
    L.append("\nCOMMIT;\n\n-- Conferencia das contagens\n")
    for i, nome in enumerate(modelo.ORDEM):
        if i:
            L.append("UNION ALL\n")
        L.append(f"SELECT '{nome}' AS tabela, COUNT(*) AS registros FROM {nome}\n")
    L.append("ORDER BY tabela;\n")
    return "".join(L)


CONSULTAS = [
    ("1. Listagem de clientes com suas contas",
     "Relaciona CLIENTE e CONTA (1:N) e mostra o saldo atual de cada conta.",
     """SELECT c.id_cliente,
       c.nome_completo,
       c.uf,
       co.numero_conta,
       co.tipo_conta,
       co.saldo,
       co.status
FROM cliente c
JOIN conta co ON co.id_cliente = c.id_cliente
ORDER BY c.nome_completo, co.numero_conta;"""),

    ("2. Extrato de uma conta (cliente + conta + transacao)",
     "Junta tres tabelas para montar o extrato de uma conta especifica.",
     """SELECT c.nome_completo,
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
ORDER BY t.data_hora DESC;"""),

    ("3. Gastos por cartao de credito",
     "Agrega as compras de cada cartao, relacionando CARTAO, CONTA, CLIENTE e TRANSACAO.",
     """SELECT c.nome_completo,
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
ORDER BY total_gasto DESC;"""),

    ("4. Emprestimos por cliente e comprometimento da renda",
     "Calcula a parcela estimada (tabela Price) e o peso dela na renda do cliente.",
     """SELECT c.nome_completo,
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
ORDER BY comprometimento_renda DESC;"""),

    ("5. Resumo das transacoes por tipo",
     "Agrupa as movimentacoes concluidas por natureza, com quantidade, total e ticket medio.",
     """SELECT t.tipo,
       COUNT(*)              AS qtd_movimentacoes,
       SUM(t.valor)          AS valor_total,
       ROUND(AVG(t.valor), 2) AS valor_medio
FROM transacao t
WHERE t.status = 'concluida'
GROUP BY t.tipo
ORDER BY valor_total DESC;"""),

    ("6. Conferencia de saldo (integridade dos dados)",
     "Recalcula o saldo de cada conta a partir das transacoes e compara com o saldo gravado.",
     """SELECT co.numero_conta,
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
ORDER BY co.numero_conta;"""),
]

EXTRA_SQL = """WITH movimento AS (
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
ORDER BY data_hora;"""


def consultas_corpo():
    L = []
    for titulo, obj, sql in CONSULTAS:
        L.append(f"\n-- ===========================================================================\n"
                 f"-- {titulo}\n-- {obj}\n"
                 f"-- ===========================================================================\n")
        L.append(sql + "\n")
    L.append("\n-- ===========================================================================\n"
             "-- Consulta extra: CTE + funcao de janela (saldo acumulado do extrato)\n"
             "-- ===========================================================================\n")
    L.append(EXTRA_SQL + "\n")
    return "".join(L)


def arquivo(arquivo_nome, corpo, primeiro=False):
    extra = EXTRA.format(arquivo=arquivo_nome) if primeiro else EXTRA.format(arquivo=arquivo_nome)
    return CABECALHO.format(arquivo=arquivo_nome, extra=extra) + "\n" + corpo


def completo():
    extra = ("-- Script UNICO: estrutura + dados de exemplo, na ordem correta de execucao.\n"
             "-- Basta colar tudo no SQL Editor do Neon e clicar em Run (uma unica vez).\n"
             + EXTRA.format(arquivo="00_nova_bank_completo.sql"))
    return "".join([
        CABECALHO.format(arquivo="00_nova_bank_completo.sql", extra=extra),
        "\n",
        ddl_corpo(),
        "\n",
        dados_corpo(),
    ])


def main():
    os.makedirs(PASTA, exist_ok=True)
    saidas = (
        ("00_nova_bank_completo.sql", completo()),
        ("01_schema.sql", arquivo("01_schema.sql", ddl_corpo())),
        ("02_dados.sql", arquivo("02_dados.sql", dados_corpo())),
        ("03_consultas.sql", arquivo("03_consultas.sql", consultas_corpo())),
    )
    for nome, conteudo in saidas:
        caminho = os.path.join(PASTA, nome)
        with io.open(caminho, "w", encoding="utf-8", newline="\r\n") as f:
            f.write(conteudo)
        print("gerado:", caminho, len(conteudo), "chars")


if __name__ == "__main__":
    main()
