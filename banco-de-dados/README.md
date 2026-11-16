# Nova Bank — Banco de Dados

Modelagem e implementação do banco de dados do **Nova Bank**, banco 100% digital
para o público jovem. Entrega da etapa *Modelagem e Descrição do Banco de Dados*,
com **5 entidades** e implementação em **PostgreSQL 17 no Neon**.

## Conteúdo

```
banco-de-dados/
├── docs/
│   ├── Modelagem_Banco_de_Dados_NovaBank.docx   documento completo da entrega
│   └── DER_NovaBank.png                         diagrama entidade-relacionamento
├── sql/postgresql/
│   ├── 00_nova_bank_completo.sql                estrutura + dados (arquivo único)
│   ├── 01_schema.sql                            criação das tabelas
│   ├── 02_dados.sql                             dados de exemplo (INSERT)
│   └── 03_consultas.sql                         consultas (SELECT)
├── scripts/                                     geradores usados para produzir os arquivos
└── alternativa-12-tabelas/                      versão ampla do modelo, para consulta
```

## Como executar no Neon

1. Abra o projeto no console do Neon e copie a connection string em
   **Connection Details > Direct connection** (ela termina em `?sslmode=require`).
2. **Opção A — SQL Editor:** abra `sql/postgresql/00_nova_bank_completo.sql`,
   copie todo o conteúdo, cole no editor e clique em **Run**.
3. **Opção B — terminal:**

   ```
   psql "postgresql://USUARIO:SENHA@ep-xxxx.regiao.aws.neon.tech/neondb?sslmode=require" \
        -f sql/postgresql/01_schema.sql
   psql "postgresql://USUARIO:SENHA@ep-xxxx.regiao.aws.neon.tech/neondb?sslmode=require" \
        -f sql/postgresql/02_dados.sql
   psql "postgresql://USUARIO:SENHA@ep-xxxx.regiao.aws.neon.tech/neondb?sslmode=require" \
        -f sql/postgresql/03_consultas.sql
   ```

O banco `neondb` já existe no projeto: não é preciso criar base nem schema, os
objetos são criados no schema `public`. Use sempre a conexão **direta** (sem
`-pooler`) para rodar scripts de criação.

## Modelo

| Tabela | Papel |
|---|---|
| `cliente` | cadastro do titular (CPF, e-mail, renda, situação) |
| `conta` | conta digital do cliente, com saldo e status |
| `cartao` | cartões de débito, crédito e virtuais da conta |
| `emprestimo` | contrato de crédito do cliente, desembolsado na conta |
| `transacao` | movimentações (Pix, boleto, compras, rendimento) |

7 chaves estrangeiras, todas em relacionamentos 1:N. A tabela `transacao` tem duas
FKs para `conta` (origem e destino), o que representa uma transferência interna em
uma única linha.

## Dados de exemplo

10 clientes, 12 contas, 14 cartões, 6 empréstimos e 239 transações — 281 registros.
Os saldos correspondem à soma das transações concluídas; a consulta 6 confere essa
consistência e retorna zero divergências.

## Scripts auxiliares (opcional)

Os arquivos em `scripts/` geram novamente os SQL, o DER e o documento a partir de
uma única definição do modelo (`modelo5.py` + `dados.py`). Exigem Python 3 com
`python-docx` e `Pillow`:

```
python scripts/gerar_sql5.py   # recria sql/postgresql
python scripts/validar5.py     # valida estrutura, dados, consultas e arquivo único
python scripts/der5.py         # recria docs/DER_NovaBank.png
python scripts/doc5.py         # recria o documento .docx
```

## Versão ampla

`alternativa-12-tabelas/` guarda a versão com 12 entidades (parcelas, chaves Pix,
caixinhas, catálogo de serviços, funcionários e atendimentos), caso o professor
peça um modelo maior.
