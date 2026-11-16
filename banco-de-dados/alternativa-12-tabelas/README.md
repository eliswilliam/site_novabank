# Nova Bank — Banco de Dados

Modelagem e implementação do banco de dados do **Nova Bank**, banco 100% digital
criado para o público jovem (conta digital, cartões, Pix, boletos, empréstimo e
caixinhas). Entrega da etapa *Modelagem e Descrição do Banco de Dados*.

## Conteúdo

```
banco-de-dados/
├── docs/
│   ├── Modelagem_Banco_de_Dados_NovaBank.docx   documento completo da entrega
│   └── DER_NovaBank.png                         diagrama entidade-relacionamento
├── sql/
│   ├── mysql/          scripts para MySQL 8 (recomendado)
│   │   ├── 01_schema.sql
│   │   ├── 02_dados.sql
│   │   └── 03_consultas.sql
│   └── postgresql/     mesmos scripts para PostgreSQL 17
└── scripts/            geradores em Python usados para produzir SQL, DER e DOCX
```

## Como executar (MySQL 8)

1. Abra o MySQL Workbench e conecte-se ao servidor.
2. Abra `sql/mysql/01_schema.sql` e execute o script inteiro (ícone do raio).
3. Execute `sql/mysql/02_dados.sql`.
4. Execute `sql/mysql/03_consultas.sql`.

Pelo terminal: `mysql -u root -p < sql/mysql/01_schema.sql`

## Como executar (PostgreSQL 17)

```
createdb nova_bank
psql -d nova_bank -f sql/postgresql/01_schema.sql
psql -d nova_bank -f sql/postgresql/02_dados.sql
psql -d nova_bank -f sql/postgresql/03_consultas.sql
```

## Modelo em resumo

12 tabelas, 14 chaves estrangeiras, relacionamentos 1:N e um N:N resolvido por
tabela associativa:

| Domínio | Tabelas |
|---|---|
| Cadastro | `cliente` |
| Núcleo bancário | `conta`, `cartao`, `chave_pix`, `caixinha`, `transacao` |
| Crédito | `emprestimo`, `parcela` |
| Catálogo | `servico`, `contratacao_servico` |
| Relacionamento | `funcionario`, `atendimento` |

## Dados de exemplo

10 clientes, 12 contas, 14 cartões, 239 transações, 60 parcelas e 37 adesões a
serviços (417 registros). Os saldos das contas correspondem à soma das
transações concluídas — a consulta 8 do documento confere essa consistência.

## Scripts auxiliares (opcional)

Os arquivos em `scripts/` geram novamente os scripts SQL, o DER e o documento a
partir de uma única definição do modelo (`modelo.py` + `dados.py`). Exigem
Python 3 com `python-docx` e `Pillow`. Ordem de execução:

```
python scripts/gerar_sql.py     # recria sql/mysql e sql/postgresql
python scripts/validar.py       # valida estrutura, dados e consultas
python scripts/der.py           # recria docs/DER_NovaBank.png
python scripts/doc.py           # recria o documento .docx
```
