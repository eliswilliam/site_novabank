# -*- coding: utf-8 -*-
"""Gera os scripts SQL (MySQL 8 e PostgreSQL 17) a partir do modelo e dos dados."""

import io
import os
import sys
import unicodedata
from datetime import date, datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import modelo
import dados

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PASTA = os.path.join(RAIZ, "sql")


def q(s):
    return "'" + str(s).replace("'", "''") + "'"


def sem_acento(texto):
    """Mantem os scripts SQL em ASCII puro, evitando problemas de encoding."""
    return "".join(c for c in unicodedata.normalize("NFD", texto)
                   if unicodedata.category(c) != "Mn")


def dimensao_dias(n):
    from datetime import timedelta
    return timedelta(days=n)


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


def col_names(ent):
    return [a["n"] for a in ent["attrs"]]


def pk_nome(tabela):
    for a in modelo.POR_NOME[tabela]["attrs"]:
        if a["pk"]:
            return a["n"]
    raise ValueError(tabela)


CABECALHO = """-- =============================================================================
-- PROJETO: Nova Bank - Instituicao de Pagamento S.A. (banco 100% digital)
-- ETAPA:   Modelagem e implementacao do banco de dados
-- ARQUIVO: {arquivo}
-- SGBD:    {sgbd}
-- AUTORES: (equipe do projeto)
-- DATA:    novembro/2026
-- =============================================================================
{extra}
"""


def ddl_mysql(_dialeto=None):
    L = []
    L.append(CABECALHO.format(
        arquivo="01_schema.sql", sgbd="MySQL 8.0 ou superior",
        extra="-- Como executar: abra no MySQL Workbench e execute o script inteiro,\n"
              "-- ou rode no terminal: mysql -u root -p < 01_schema.sql\n"))
    L.append("CREATE DATABASE IF NOT EXISTS nova_bank\n"
             "    DEFAULT CHARACTER SET utf8mb4\n"
             "    DEFAULT COLLATE utf8mb4_general_ci;\n\n"
             "USE nova_bank;\n\n")
    L.append("-- Remocao das tabelas na ordem inversa das dependencias\n")
    for nome in reversed(modelo.ORDEM):
        L.append(f"DROP TABLE IF EXISTS {nome};\n")
    L.append("\n-- =============================================================================\n"
             "-- 1. CRIACAO DAS TABELAS\n"
             "-- =============================================================================\n")

    for nome in modelo.ORDEM:
        ent = modelo.POR_NOME[nome]
        L.append(f"\n-- {nome.upper()}: {sem_acento(modelo.DDL_COMMENTS[nome])}\n")
        L.append(f"CREATE TABLE {nome} (\n")
        linhas = []
        for a in ent["attrs"]:
            tipo = a["t"]
            if a["pk"]:
                tipo = "INT"
                decl = f"    {a['n']:<22} INT NOT NULL AUTO_INCREMENT"
            else:
                decl = f"    {a['n']:<22} {tipo}"
                if a["nn"]:
                    decl += " NOT NULL"
                if a["d"] is not None:
                    valor = a["d"]
                    if valor == "CURRENT_DATE":
                        valor = "(CURRENT_DATE)"
                    decl += f" DEFAULT {valor}"
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
        for t in ent.get("tchecks", []):
            idx = ent["tchecks"].index(t) + 1
            cons.append(f"    CONSTRAINT ck_{nome}_{idx} {t}")
        for t, cols, uk in modelo.UNICAS_COMPOSTAS:
            if t == nome:
                cons.append(f"    CONSTRAINT {uk} UNIQUE ({', '.join(cols)})")
        for filha, pai, col, card, verbo in modelo.RELACIONAMENTOS:
            if filha == nome:
                cons.append(
                    f"    CONSTRAINT fk_{nome}_{pai}_{col} FOREIGN KEY ({col})\n"
                    f"        REFERENCES {pai} ({pk_nome(pai)}) ON UPDATE CASCADE ON DELETE RESTRICT")
        L.append(",\n".join(linhas + cons))
        L.append(f"\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT={q(sem_acento(modelo.DDL_COMMENTS[nome]))};\n")

    L.append("""
-- =============================================================================
-- 2. INDICES AUXILIARES
-- =============================================================================
""")
    for filha, pai, col, card, verbo in modelo.RELACIONAMENTOS:
        if filha == "transacao":
            L.append(f"CREATE INDEX ix_{filha}_{col} ON {filha} ({col});\n")
    L.append("""
-- =============================================================================
-- FIM DO SCRIPT ESTRUTURAL
-- =============================================================================
""")
    return "".join(L)


def extra_pg(arquivo):
    return ("-- Como executar no Neon (Postgres serverless):\n"
            "--   1) No console do Neon, abra o SQL Editor, cole o conteudo e clique em Run; ou\n"
            "--   2) Pelo terminal, use a connection string do projeto\n"
            "--      (Connection Details > Direct connection):\n"
            f"--      psql \"postgresql://USUARIO:SENHA@ep-xxxx.regiao.aws.neon.tech/neondb?sslmode=require\" -f {arquivo}\n"
            "--\n"
            "-- Observacoes do Neon:\n"
            "--   - use a conexao direta (sem -pooler) para executar DDL;\n"
            "--   - o banco do projeto e o neondb e o schema e o public (nao e preciso criar banco);\n"
            "--   - os objetos sao criados no banco atual da conexao.\n")


def ddl_pg_corpo():
    L = []
    L.append("-- Remocao das tabelas na ordem inversa das dependencias\n")
    for nome in reversed(modelo.ORDEM):
        L.append(f"DROP TABLE IF EXISTS {nome} CASCADE;\n")
    L.append("\n-- =============================================================================\n"
             "-- 1. CRIACAO DAS TABELAS\n"
             "-- =============================================================================\n")

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
        for t, cols, uk in modelo.UNICAS_COMPOSTAS:
            if t == nome:
                cons.append(f"    CONSTRAINT {uk} UNIQUE ({', '.join(cols)})")
        for filha, pai, col, card, verbo in modelo.RELACIONAMENTOS:
            if filha == nome:
                cons.append(
                    f"    CONSTRAINT fk_{nome}_{pai}_{col} FOREIGN KEY ({col})\n"
                    f"        REFERENCES {pai} ({pk_nome(pai)}) ON UPDATE CASCADE ON DELETE RESTRICT")
        L.append(",\n".join(linhas + cons))
        L.append("\n);\n")
        L.append(f"COMMENT ON TABLE {nome} IS {q(sem_acento(modelo.DDL_COMMENTS[nome]))};\n")

    L.append("""
-- =============================================================================
-- 2. INDICES AUXILIARES (o PostgreSQL nao cria indice automaticamente para FK)
-- =============================================================================
""")
    vistos = set()
    for filha, pai, col, card, verbo in modelo.RELACIONAMENTOS:
        chave = (filha, col)
        if chave in vistos:
            continue
        vistos.add(chave)
        L.append(f"CREATE INDEX ix_{filha}_{col} ON {filha} ({col});\n")
    L.append("""
-- =============================================================================
-- FIM DO SCRIPT ESTRUTURAL
-- =============================================================================
""")
    return "".join(L)


def ddl_pg(_dialeto=None):
    return (CABECALHO.format(arquivo="01_schema.sql",
                             sgbd="PostgreSQL 17 (Neon)",
                             extra=extra_pg("01_schema.sql"))
            + ddl_pg_corpo())


def linhas_tabela(nome):
    ent = modelo.POR_NOME[nome]
    cols = col_names(ent)
    if nome == "cliente":
        rows = dados.CLIENTES
    elif nome == "funcionario":
        rows = [tuple(f) + ("ativo",) for f in dados.FUNCIONARIOS]
    elif nome == "servico":
        rows = dados.SERVICOS
    elif nome == "conta":
        rows = [(c[0], c[1], c[2], c[3], dados.SALDOS[c[0]], c[4], c[5], c[6])
                for c in dados.CONTAS]
    elif nome == "cartao":
        rows = dados.CARTOES
    elif nome == "chave_pix":
        rows = dados.CHAVES_PIX
    elif nome == "caixinha":
        rows = dados.CAIXINHAS
    elif nome == "emprestimo":
        rows = dados.EMPRESTIMOS
    elif nome == "parcela":
        rows = dados.PARCELAS
    elif nome == "contratacao_servico":
        rows = []
        for i, (cli, srv) in enumerate(dados.CONTRATACOES, start=1):
            base = dados.CLIENTES[cli - 1][9]
            rows.append((i, base + dimensao_dias(srv * 11), "ativa", cli, srv))
    elif nome == "transacao":
        rows = [(t["id"], t["tipo"], t["valor"], t["dt"], t["desc"], t["status"],
                 t["origem"], t["destino"], t["cartao"]) for t in dados.TRANSACOES]
    elif nome == "atendimento":
        rows = dados.ATENDIMENTOS
    else:
        rows = []
    return cols, rows


def cabecalho_insert(tabela, cols, limite=78):
    """Quebra a lista de colunas em varias linhas para manter o script legivel."""
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


def inserts(dialeto):
    L = []
    L.append(CABECALHO.format(
        arquivo="02_dados.sql",
        sgbd="MySQL 8.0 ou superior" if dialeto == "mysql" else "PostgreSQL 17 (Neon)",
        extra=("-- Insercao dos dados de exemplo na ordem das dependencias (pai -> filho).\n"
               if dialeto == "mysql" else extra_pg("02_dados.sql"))))
    if dialeto == "mysql":
        L.append("USE nova_bank;\n\nSTART TRANSACTION;\n")
    else:
        L.append("BEGIN;\n")

    total = {}
    for nome in modelo.ORDEM:
        cols, rows = linhas_tabela(nome)
        total[nome] = len(rows)
        L.append(f"\n-- ---------------------------------------------------------------------------\n")
        L.append(f"-- {nome.upper()} ({len(rows)} registros)\n")
        L.append(f"-- ---------------------------------------------------------------------------\n")
        if not rows:
            L.append("-- (sem registros de exemplo)\n")
            continue
        cab = cabecalho_insert(nome, cols) + "\n"
        blocos = []
        for r in rows:
            blocos.append("    (" + ", ".join(lit(v) for v in r) + ")")
        L.append(cab)
        L.append(",\n".join(blocos))
        L.append(";\n")

    L.append("\nCOMMIT;\n\n-- Conferencia das contagens\n")
    for nome in modelo.ORDEM:
        L.append(f"SELECT '{nome}' AS tabela, COUNT(*) AS registros FROM {nome}\n"
                 if dialeto == "mysql" else
                 f"SELECT '{nome}' AS tabela, COUNT(*) AS registros FROM {nome}\n")
        if nome != modelo.ORDEM[-1]:
            L.append("UNION ALL\n")
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
     "Agrega as compras de cada cartao de credito, relacionando CARTAO, CONTA, CLIENTE e TRANSACAO.",
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

    ("4. Situacao das parcelas de cada emprestimo",
     "Mostra, por contrato, quantas parcelas foram pagas e quantas seguem em aberto.",
     """SELECT e.id_emprestimo,
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
ORDER BY e.id_emprestimo;"""),

    ("5. Parcelas vencidas e ainda nao pagas",
     "Consulta de inadimplencia: usa data de vencimento e status da parcela.",
     """SELECT c.nome_completo,
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
ORDER BY p.data_vencimento;"""),

    ("6. Servicos mais contratados",
     "Percorre a tabela associativa CONTRATACAO_SERVICO (relacionamento N:N).",
     """SELECT s.nome_servico,
       s.categoria,
       COUNT(cs.id_contratacao) AS total_contratacoes
FROM servico s
LEFT JOIN contratacao_servico cs
       ON cs.id_servico = s.id_servico
      AND cs.status = 'ativa'
GROUP BY s.id_servico, s.nome_servico, s.categoria
ORDER BY total_contratacoes DESC, s.nome_servico;"""),

    ("7. Progresso das caixinhas",
     "Calcula o percentual atingido de cada meta financeira.",
     """SELECT c.nome_completo,
       cx.nome_objetivo,
       cx.valor_meta,
       cx.saldo_atual,
       ROUND(cx.saldo_atual * 100.0 / cx.valor_meta, 1) AS percentual_meta,
       cx.status
FROM caixinha cx
JOIN conta co   ON co.id_conta = cx.id_conta
JOIN cliente c  ON c.id_cliente = co.id_cliente
ORDER BY percentual_meta DESC;"""),

    ("8. Conferencia de saldo (integridade dos dados)",
     "Recalcula o saldo de cada conta a partir das transacoes concluidas e compara com o saldo gravado.",
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


def consultas(dialeto):
    L = []
    L.append(CABECALHO.format(
        arquivo="03_consultas.sql",
        sgbd="MySQL 8.0 ou superior" if dialeto == "mysql" else "PostgreSQL 17 (Neon)",
        extra=("-- Consultas de demonstracao (SELECT), com comentarios de objetivo.\n"
               if dialeto == "mysql" else extra_pg("03_consultas.sql"))))
    if dialeto == "mysql":
        L.append("USE nova_bank;\n")
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


def completo():
    """Arquivo unico (estrutura + dados) para colar no SQL Editor do Neon."""
    schema = ddl_pg()
    dados = inserts("postgresql")
    corpo_schema = "-- Remocao" + schema.split("-- Remocao", 1)[1]
    corpo_dados = "BEGIN;" + dados.split("BEGIN;", 1)[1]
    extra = ("-- Script UNICO: estrutura + dados de exemplo, na ordem correta de execucao.\n"
             "-- Basta colar tudo no SQL Editor do Neon e clicar em Run (uma unica vez).\n"
             + extra_pg("00_nova_bank_completo.sql"))
    return "".join([
        CABECALHO.format(arquivo="00_nova_bank_completo.sql",
                         sgbd="PostgreSQL 17 (Neon)", extra=extra),
        "\n-- =============================================================================\n"
        "-- PARTE 1 - ESTRUTURA (tabelas, chaves estrangeiras e indices)\n"
        "-- =============================================================================\n",
        corpo_schema,
        "\n-- =============================================================================\n"
        "-- PARTE 2 - DADOS DE EXEMPLO\n"
        "-- =============================================================================\n",
        corpo_dados,
    ])


def main():
    for dialeto, pasta, ddl, ins, con in (
        ("mysql", "mysql", ddl_mysql, inserts, consultas),
        ("postgresql", "postgresql", ddl_pg, inserts, consultas),
    ):
        destino = os.path.join(PASTA, pasta)
        os.makedirs(destino, exist_ok=True)
        for arquivo, conteudo in (("01_schema.sql", ddl(dialeto)),
                                  ("02_dados.sql", ins(dialeto)),
                                  ("03_consultas.sql", con(dialeto))):
            caminho = os.path.join(destino, arquivo)
            with io.open(caminho, "w", encoding="utf-8", newline="\r\n") as f:
                f.write(conteudo)
            print("gerado:", caminho, len(conteudo), "chars")

    caminho = os.path.join(PASTA, "postgresql", "00_nova_bank_completo.sql")
    with io.open(caminho, "w", encoding="utf-8", newline="\r\n") as f:
        f.write(completo())
    print("gerado:", caminho)


if __name__ == "__main__":
    main()
