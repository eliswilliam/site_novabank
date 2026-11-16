# -*- coding: utf-8 -*-
"""Valida a versao minima (5 tabelas): estrutura, dados, consultas e arquivo unico."""

import io
import json
import os
import re
import sqlite3
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)

import gerar_sql5 as g  # noqa: E402

SQL_DIR = os.path.join(os.path.dirname(AQUI), "sql", "postgresql")


def traduzir(sql):
    """Traducao mecanica PostgreSQL -> SQLite, so para conferir a logica."""
    sql = re.sub(r"COMMENT ON TABLE \w+ IS '.*';", "", sql)
    sql = sql.replace(" CASCADE;", ";")
    sql = re.sub(r"\bSERIAL NOT NULL\b", "INTEGER NOT NULL", sql)
    sql = re.sub(r"\b(VARCHAR|CHAR)\(\d+\)", "TEXT", sql)
    sql = re.sub(r"\bDECIMAL\(\d+,\d+\)", "NUMERIC", sql)
    sql = re.sub(r"\bBOOLEAN\b", "INTEGER", sql)
    sql = re.sub(r"\bTIMESTAMP\b", "TEXT", sql)
    sql = re.sub(r"\bDATE\b", "TEXT", sql)
    return sql


def conectar():
    con = sqlite3.connect(":memory:")
    con.execute("PRAGMA foreign_keys = ON")
    con.create_function("CHAR_LENGTH", 1, lambda s: len(s) if s is not None else None)
    con.create_function("POWER", 2, lambda a, b: a ** b)
    return con


def consulta_dict(cur):
    cols = [d[0] for d in cur.description]
    return {"colunas": cols, "linhas": [list(r) for r in cur.fetchall()]}


def main():
    con = conectar()
    cur = con.cursor()

    schema = io.open(os.path.join(SQL_DIR, "01_schema.sql"), encoding="utf-8").read()
    cur.executescript(traduzir(schema))
    tabelas = [r[0] for r in cur.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    print("schema ok:", len(tabelas), "tabelas ->", ", ".join(sorted(tabelas)))

    cur.executescript(io.open(os.path.join(SQL_DIR, "02_dados.sql"), encoding="utf-8").read())
    print("dados ok:", {t: cur.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0] for t in tabelas})

    resultados = {}
    for titulo, _obj, sql in g.CONSULTAS:
        resultados[titulo] = consulta_dict(cur.execute(sql))
        print(f"{titulo}: {len(resultados[titulo]['linhas'])} linhas")

    resultados["7. Extrato com saldo acumulado (CTE + window function)"] = \
        consulta_dict(cur.execute(g.EXTRA_SQL))

    chave = "6. Conferencia de saldo (integridade dos dados)"
    div = [l for l in resultados[chave]["linhas"] if round(l[1], 2) != round(l[2], 2)]
    print("divergencias de saldo:", div)
    print("fk_check:", cur.execute("PRAGMA foreign_key_check").fetchall())

    con2 = conectar()
    con2.executescript(traduzir(
        io.open(os.path.join(SQL_DIR, "00_nova_bank_completo.sql"), encoding="utf-8").read()))
    print("arquivo unico ok:", con2.execute("SELECT COUNT(*) FROM transacao").fetchone()[0],
          "transacoes")

    destino = os.path.join(AQUI, "resultados5.json")
    with io.open(destino, "w", encoding="utf-8") as f:
        json.dump(resultados, f, ensure_ascii=False, indent=1, default=str)
    print("resultados salvos em", destino)


if __name__ == "__main__":
    main()
