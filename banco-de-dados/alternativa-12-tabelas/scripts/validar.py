# -*- coding: utf-8 -*-
"""Valida a logica do script (estrutura, dados e consultas) num motor SQL local.

O script PostgreSQL e traduzido mecanicamente para SQLite (motor embutido no
Python), o que permite conferir chaves, CHECKs, inserts e o resultado de cada
consulta sem depender de um servidor instalado.
"""

import io
import json
import os
import re
import sqlite3
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
sys.path.insert(0, AQUI)

import gerar_sql  # noqa: E402  (reutiliza as consultas)

SQL_DIR = os.path.join(RAIZ, "sql", "postgresql")


def traduzir(sql):
    sql = re.sub(r"COMMENT ON TABLE \w+ IS '.*';", "", sql)
    sql = sql.replace(" CASCADE;", ";")
    sql = re.sub(r"\bSERIAL NOT NULL\b", "INTEGER NOT NULL", sql)
    sql = re.sub(r"\b(VARCHAR|CHAR)\(\d+\)", "TEXT", sql)
    sql = re.sub(r"\bDECIMAL\(\d+,\d+\)", "NUMERIC", sql)
    sql = re.sub(r"\bBOOLEAN\b", "INTEGER", sql)
    sql = re.sub(r"\bTIMESTAMP\b", "TEXT", sql)
    sql = re.sub(r"\bDATE\b", "TEXT", sql)
    sql = sql.replace("DEFAULT TRUE", "DEFAULT 1")
    return sql


def consulta_dict(cur):
    cols = [d[0] for d in cur.description]
    return {"colunas": cols, "linhas": [list(r) for r in cur.fetchall()]}


def main():
    con = sqlite3.connect(":memory:")
    con.execute("PRAGMA foreign_keys = ON")
    con.create_function("CHAR_LENGTH", 1, lambda s: len(s) if s is not None else None)
    cur = con.cursor()

    schema = io.open(os.path.join(SQL_DIR, "01_schema.sql"), encoding="utf-8").read()
    cur.executescript(traduzir(schema))
    print("schema ok:", len(
        [r for r in cur.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]),
        "tabelas")

    dados_sql = io.open(os.path.join(SQL_DIR, "02_dados.sql"), encoding="utf-8").read()
    cur.executescript(dados_sql)
    print("dados ok:", {t: cur.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
                        for t in ("cliente", "conta", "cartao", "transacao", "parcela")})

    resultados = {}
    for titulo, _obj, sql in gerar_sql.CONSULTAS:
        resultados[titulo] = consulta_dict(cur.execute(sql))
        print(f"{titulo}: {len(resultados[titulo]['linhas'])} linhas")

    extra = gerar_sql.EXTRA_SQL
    resultados["9. Extrato com saldo acumulado (CTE + window function)"] = \
        consulta_dict(cur.execute(extra))

    # Conferencia: saldo gravado x saldo calculado
    chave = "8. Conferencia de saldo (integridade dos dados)"
    divergencias = [l for l in resultados[chave]["linhas"] if round(l[1], 2) != round(l[2], 2)]
    print("divergencias de saldo:", divergencias)

    # Integridade referencial (o SQLite nao valida FK retroativamente, entao checa)
    fks = cur.execute("PRAGMA foreign_key_check").fetchall()
    print("fk_check:", fks)

    # Confere tambem o arquivo unico usado no Neon
    con2 = sqlite3.connect(":memory:")
    con2.execute("PRAGMA foreign_keys = ON")
    con2.create_function("CHAR_LENGTH", 1, lambda s: len(s) if s is not None else None)
    completo = io.open(os.path.join(SQL_DIR, "00_nova_bank_completo.sql"), encoding="utf-8").read()
    con2.executescript(traduzir(completo))
    print("arquivo unico (Neon) ok:", con2.execute(
        "SELECT COUNT(*) FROM transacao").fetchone()[0], "transacoes")

    destino = os.path.join(AQUI, "resultados.json")
    with io.open(destino, "w", encoding="utf-8") as f:
        json.dump(resultados, f, ensure_ascii=False, indent=1, default=str)
    print("resultados salvos em", destino)


if __name__ == "__main__":
    main()
