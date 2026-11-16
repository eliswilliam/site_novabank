# -*- coding: utf-8 -*-
"""Monta o documento Word da entrega (pt-BR) a partir do modelo e dos resultados."""

import io
import json
import os
import re
import sys

from docx import Document
from docx.enum.section import WD_ORIENT, WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
sys.path.insert(0, AQUI)

import modelo  # noqa: E402
import dados  # noqa: E402
import gerar_sql  # noqa: E402

NAVY = RGBColor(0x0F, 0x2A, 0x44)
NAVY_HEX = "0F2A44"
GRAY = RGBColor(0x64, 0x74, 0x8B)
DARK = RGBColor(0x1E, 0x29, 0x3B)
YELLOW = RGBColor(0xB4, 0x86, 0x00)

DOCS = os.path.join(RAIZ, "docs")
SQL = os.path.join(RAIZ, "sql")
RES = json.load(io.open(os.path.join(AQUI, "resultados.json"), encoding="utf-8"))
SAIDA = os.path.join(DOCS, "Modelagem_Banco_de_Dados_NovaBank.docx")

doc = Document()


# --------------------------------------------------------------------------
# utilidades OOXML
# --------------------------------------------------------------------------
def shade(cell, hexcor):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), hexcor)
    tcPr.append(shd)


def para_shade(p, hexcor):
    pPr = p._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), hexcor)
    pPr.append(shd)


def para_border(p, lado="bottom", cor=NAVY_HEX, sz=8, espaco=4):
    pPr = p._p.get_or_add_pPr()
    pBdr = pPr.find(qn("w:pBdr"))
    if pBdr is None:
        pBdr = OxmlElement("w:pBdr")
        pPr.append(pBdr)
    el = OxmlElement(f"w:{lado}")
    el.set(qn("w:val"), "single")
    el.set(qn("w:sz"), str(sz))
    el.set(qn("w:space"), str(espaco))
    el.set(qn("w:color"), cor)
    pBdr.append(el)


def table_borders(table, cor="D6DEE8", sz=4):
    tbl = table._tbl
    tblPr = tbl.tblPr
    borders = OxmlElement("w:tblBorders")
    for lado in ("top", "left", "bottom", "right", "insideH", "insideV"):
        el = OxmlElement(f"w:{lado}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), str(sz))
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), cor)
        borders.append(el)
    tblPr.append(borders)


def repetir_cabecalho(row):
    trPr = row._tr.get_or_add_trPr()
    el = OxmlElement("w:tblHeader")
    el.set(qn("w:val"), "true")
    trPr.append(el)


def sem_quebra_linha(table):
    tblPr = table._tbl.tblPr
    el = OxmlElement("w:cantSplit")
    tblPr.append(el)


def larguras(table, cms):
    table.autofit = False
    tblPr = table._tbl.tblPr
    layout = OxmlElement("w:tblLayout")
    layout.set(qn("w:type"), "fixed")
    tblPr.append(layout)
    for linha in table.rows:
        for i, c in enumerate(linha.cells):
            if i < len(cms):
                c.width = Cm(cms[i])
    for i, col in enumerate(table.columns):
        if i < len(cms):
            col.width = Cm(cms[i])


# --------------------------------------------------------------------------
# utilidades de conteudo
# --------------------------------------------------------------------------
def p(texto="", size=10.5, bold=False, italic=False, cor=DARK, align=None,
      antes=0, depois=6, spacing=1.15, keep=False):
    par = doc.add_paragraph()
    run = par.add_run(texto)
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = cor
    run.font.name = "Calibri"
    pf = par.paragraph_format
    pf.space_before = Pt(antes)
    pf.space_after = Pt(depois)
    pf.line_spacing = spacing
    pf.keep_with_next = keep
    if align is not None:
        par.alignment = align
    return par


def h1(texto):
    doc.add_page_break()
    par = doc.add_paragraph()
    run = par.add_run(texto)
    run.font.size = Pt(17)
    run.font.bold = True
    run.font.color.rgb = NAVY
    run.font.name = "Calibri"
    par.paragraph_format.space_before = Pt(0)
    par.paragraph_format.space_after = Pt(12)
    par.paragraph_format.keep_with_next = True
    para_border(par, "bottom", "F5B700", 12, 6)
    return par


def h2(texto):
    par = doc.add_paragraph()
    run = par.add_run(texto)
    run.font.size = Pt(12.5)
    run.font.bold = True
    run.font.color.rgb = NAVY
    par.paragraph_format.space_before = Pt(14)
    par.paragraph_format.space_after = Pt(6)
    par.paragraph_format.keep_with_next = True
    return par


def h3(texto):
    par = doc.add_paragraph()
    run = par.add_run(texto)
    run.font.size = Pt(11)
    run.font.bold = True
    run.font.color.rgb = NAVY
    par.paragraph_format.space_before = Pt(10)
    par.paragraph_format.space_after = Pt(4)
    par.paragraph_format.keep_with_next = True
    return par


def bullet(texto, size=10.5, marcador="•"):
    par = doc.add_paragraph()
    run = par.add_run(f"{marcador}  ")
    run.font.size = Pt(size)
    run.font.color.rgb = RGBColor(0xB4, 0x86, 0x00)
    run.font.bold = True
    r2 = par.add_run(texto)
    r2.font.size = Pt(size)
    r2.font.color.rgb = DARK
    pf = par.paragraph_format
    pf.left_indent = Cm(0.6)
    pf.first_line_indent = Cm(-0.45)
    pf.space_before = Pt(0)
    pf.space_after = Pt(3)
    pf.line_spacing = 1.1
    return par


def legenda(texto):
    par = doc.add_paragraph()
    run = par.add_run(texto)
    run.font.size = Pt(8.5)
    run.font.italic = True
    run.font.color.rgb = GRAY
    par.alignment = WD_ALIGN_PARAGRAPH.CENTER
    par.paragraph_format.space_before = Pt(2)
    par.paragraph_format.space_after = Pt(12)
    return par


def codigo(bloco, size=8.0):
    linhas = bloco.strip("\n").split("\n")
    for i, l in enumerate(linhas):
        par = doc.add_paragraph()
        run = par.add_run(l if l else " ")
        run.font.size = Pt(size)
        run.font.name = "Consolas"
        run.font.color.rgb = RGBColor(0x1A, 0x2B, 0x40)
        pf = par.paragraph_format
        pf.space_before = Pt(0)
        pf.space_after = Pt(0)
        pf.line_spacing = 1.0
        pf.left_indent = Cm(0.25)
        pf.keep_with_next = i < len(linhas) - 1
        para_shade(par, "F3F6FA")
    p("", size=4, depois=6)


def tabela(cabecalhos, linhas, cms, size=8.8, align_center=None, header_size=8.8):
    t = doc.add_table(rows=1, cols=len(cabecalhos))
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    table_borders(t)
    hdr = t.rows[0]
    repetir_cabecalho(hdr)
    for i, h in enumerate(cabecalhos):
        c = hdr.cells[i]
        c.text = ""
        par = c.paragraphs[0]
        run = par.add_run(str(h))
        run.font.size = Pt(header_size)
        run.font.bold = True
        run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
        par.paragraph_format.space_before = Pt(2)
        par.paragraph_format.space_after = Pt(2)
        shade(c, NAVY_HEX)
    for k, linha in enumerate(linhas):
        row = t.add_row()
        for i, valor in enumerate(linha):
            c = row.cells[i]
            c.text = ""
            par = c.paragraphs[0]
            run = par.add_run(str(valor))
            run.font.size = Pt(size)
            run.font.color.rgb = DARK
            par.paragraph_format.space_before = Pt(1.5)
            par.paragraph_format.space_after = Pt(1.5)
            par.paragraph_format.line_spacing = 1.0
            if align_center and i in align_center:
                par.alignment = WD_ALIGN_PARAGRAPH.CENTER
            if k % 2 == 1:
                shade(c, "F5F8FB")
    larguras(t, cms)
    p("", size=4, depois=8)
    return t


ROTULOS = {
    "id_cliente": "ID cliente", "id_conta": "ID conta", "id_emprestimo": "ID contrato",
    "id_cartao": "ID cartão", "id_funcionario": "ID funcionário",
    "id_atendimento": "ID atendimento", "id_transacao": "ID transação",
    "nome_completo": "Nome completo", "numero_conta": "Número da conta",
    "tipo_conta": "Tipo de conta", "data_hora": "Data / hora", "descricao": "Descrição",
    "qtd_compras": "Qtd. compras", "total_gasto": "Total gasto",
    "limite_total": "Limite total", "limite_disponivel": "Limite disponível",
    "numero_mascarado": "Cartão", "qtd_parcelas": "Qtd. parcelas",
    "parcelas_pagas": "Pagas", "parcelas_em_aberto": "Em aberto",
    "total_pago": "Total pago", "taxa_juros_mensal": "Juros (% a.m.)",
    "prazo_meses": "Prazo (meses)", "status_contrato": "Status do contrato",
    "valor_principal": "Valor principal", "numero_parcela": "Parcela",
    "valor_parcela": "Valor da parcela", "data_vencimento": "Vencimento",
    "nome_servico": "Serviço", "total_contratacoes": "Contratações",
    "nome_objetivo": "Objetivo", "valor_meta": "Meta", "saldo_atual": "Saldo atual",
    "percentual_meta": "% da meta", "saldo_gravado": "Saldo gravado",
    "saldo_calculado": "Saldo calculado", "efeito": "Efeito",
    "saldo_acumulado": "Saldo acumulado", "data_cadastro": "Data de cadastro",
    "data_abertura": "Data de abertura", "data_encerramento": "Encerramento",
    "nome_servico": "Serviço", "total_contratacoes": "Contratações",
}

CAMPOS_DINHEIRO = {
    "valor", "saldo", "limite_total", "limite_disponivel", "valor_principal",
    "valor_parcela", "valor_meta", "saldo_atual", "total_pago", "total_gasto",
    "saldo_gravado", "saldo_calculado", "efeito", "saldo_acumulado",
}


def rotulo_col(col):
    return ROTULOS.get(col, col.replace("_", " ")[:1].upper() + col.replace("_", " ")[1:])


def fmt_moeda(v):
    n = float(v)
    s = f"{abs(n):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return ("-R$ " if n < 0 else "R$ ") + s


def fmt_num(v, dec=2):
    return f"{float(v):,.{dec}f}".replace(".", ",")


def eh_dinheiro(col):
    return col in CAMPOS_DINHEIRO


def fmt_celula(valor, col):
    if valor is None:
        return "—"
    if isinstance(valor, (int, float)) and not isinstance(valor, bool):
        if "percentual" in col.lower():
            return fmt_num(valor, 1) + "%"
        if "taxa" in col.lower():
            return fmt_num(valor) + "%"
        if eh_dinheiro(col):
            return fmt_moeda(valor)
        if float(valor).is_integer():
            return str(int(valor))
        return fmt_num(valor)
    s = str(valor)
    if re.match(r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}", s):
        d, h = s.split(" ")
        ano, mes, dia = d.split("-")
        return f"{dia}/{mes}/{ano} {h[:5]}"
    if re.match(r"^\d{4}-\d{2}-\d{2}$", s):
        ano, mes, dia = s.split("-")
        return f"{dia}/{mes}/{ano}"
    return s


def resultado(titulo_consulta, max_linhas=None):
    r = RES[titulo_consulta]
    cols = r["colunas"]
    linhas = r["linhas"]
    mostra = linhas[:max_linhas] if max_linhas else linhas
    cms_full = 16.4
    formatadas = [[fmt_celula(v, c) for v, c in zip(l, cols)] for l in mostra]
    pesos = []
    for j, c in enumerate(cols):
        maior = max([len(rotulo_col(c)) * 0.9] + [len(l[j]) for l in formatadas])
        pesos.append(min(max(maior, 6), 24))
    soma = sum(pesos)
    n = len(cols)
    # largura minima de 1,0 cm por coluna, distribuindo o restante por peso
    minimo = 1.0
    restante = cms_full - minimo * n
    if restante <= 0:
        cms = [cms_full / n] * n
    else:
        extra = [max(0.0, cms_full * w / soma - minimo) for w in pesos]
        s2 = sum(extra) or 1.0
        cms = [minimo + restante * e / s2 for e in extra]
    tamanho = 8.2 if n <= 6 else 7.7
    tabela([rotulo_col(c) for c in cols],
           formatadas,
           cms, size=tamanho, align_center=set(range(n)), header_size=tamanho)
    if max_linhas and len(linhas) > max_linhas:
        legenda(f"Resultado completo: {len(linhas)} linhas (exibidas as {max_linhas} primeiras).")
    elif len(linhas) == 1:
        legenda("1 linha retornada.")
    else:
        legenda(f"{len(linhas)} linhas retornadas.")


# --------------------------------------------------------------------------
# estilos gerais
# --------------------------------------------------------------------------
sec = doc.sections[0]
sec.page_width = Cm(21)
sec.page_height = Cm(29.7)
sec.top_margin = Cm(2.2)
sec.bottom_margin = Cm(2.0)
sec.left_margin = Cm(2.3)
sec.right_margin = Cm(2.3)

estilo = doc.styles["Normal"]
estilo.font.name = "Calibri"
estilo.font.size = Pt(10.5)


def rodape():
    ft = doc.sections[0].footer
    par = ft.paragraphs[0]
    par.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = par.add_run("Nova Bank · Modelagem e Implementação do Banco de Dados · ")
    run.font.size = Pt(8)
    run.font.color.rgb = GRAY
    fld = OxmlElement("w:fldSimple")
    fld.set(qn("w:instr"), "PAGE")
    r = OxmlElement("w:r")
    rPr = OxmlElement("w:rPr")
    sz = OxmlElement("w:sz")
    sz.set(qn("w:val"), "16")
    rPr.append(sz)
    r.append(rPr)
    t = OxmlElement("w:t")
    t.text = "1"
    r.append(t)
    fld.append(r)
    par._p.append(fld)


rodape()

# --------------------------------------------------------------------------
# CAPA
# --------------------------------------------------------------------------
p("", size=10, depois=30)
logo = os.path.join(os.path.dirname(RAIZ), "assets", "logo_256.png")
if os.path.exists(logo):
    par = doc.add_paragraph()
    par.alignment = WD_ALIGN_PARAGRAPH.CENTER
    par.add_run().add_picture(logo, width=Cm(3.2))
    par.paragraph_format.space_after = Pt(18)

par = doc.add_paragraph()
par.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = par.add_run("NOVA BANK")
run.font.size = Pt(30)
run.font.bold = True
run.font.color.rgb = NAVY
par.paragraph_format.space_after = Pt(0)

par = doc.add_paragraph()
par.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = par.add_run("Instituição de Pagamento S.A. · banco digital")
run.font.size = Pt(11)
run.font.color.rgb = GRAY
par.paragraph_format.space_after = Pt(26)

for linha_titulo in ("MODELAGEM E IMPLEMENTAÇÃO", "DO BANCO DE DADOS"):
    par = doc.add_paragraph()
    par.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = par.add_run(linha_titulo)
    run.font.size = Pt(20)
    run.font.bold = True
    run.font.color.rgb = NAVY
    run.font.name = "Calibri"
    par.paragraph_format.line_spacing = 1.2
    par.paragraph_format.space_before = Pt(0)
    par.paragraph_format.space_after = Pt(0)
doc.paragraphs[-1].paragraph_format.space_after = Pt(10)

p("Modelo Entidade-Relacionamento, scripts SQL, dados de exemplo e consultas",
  size=11, italic=True, cor=GRAY, align=WD_ALIGN_PARAGRAPH.CENTER, depois=40)

for rotulo, valor in (
    ("Curso", "Análise e Desenvolvimento de Sistemas"),
    ("Disciplinas", "Modelagem de Banco de Dados · Desenvolvimento em Banco de Dados"),
    ("Professor(a)", "____________________________________________"),
    ("Integrantes", "____________________________________________"),
    ("", "____________________________________________"),
    ("", "____________________________________________"),
    ("Entrega", "Novembro de 2026"),
):
    if rotulo:
        par = doc.add_paragraph()
        par.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r1 = par.add_run(f"{rotulo}: ")
        r1.font.size = Pt(10)
        r1.font.bold = True
        r1.font.color.rgb = NAVY
        r2 = par.add_run(valor)
        r2.font.size = Pt(10)
        r2.font.color.rgb = DARK
    else:
        p(valor, size=10, align=WD_ALIGN_PARAGRAPH.CENTER, depois=2)
    par.paragraph_format.space_after = Pt(4)

# --------------------------------------------------------------------------
# SUMARIO
# --------------------------------------------------------------------------
h1("Sumário")
itens = [
    ("1", "Contexto da empresa e do banco de dados"),
    ("2", "Funcionalidade escolhida e justificativa"),
    ("3", "Modelo conceitual (DER)"),
    ("3.1", "Notação e critérios de modelagem"),
    ("3.2", "Domínios do modelo"),
    ("3.3", "Diagrama Entidade-Relacionamento"),
    ("3.4", "Entidades e atributos"),
    ("3.5", "Relacionamentos e cardinalidades"),
    ("3.6", "Decisões de modelagem"),
    ("4", "Dicionário de dados"),
    ("5", "Implementação SQL"),
    ("6", "Dados de exemplo"),
    ("7", "Consultas SQL e resultados"),
    ("8", "Como executar e conferência da entrega"),
]
for num, titulo in itens:
    par = doc.add_paragraph()
    recuo = 0 if len(num) <= 1 else 0.8
    r1 = par.add_run(f"{num}   ")
    r1.font.size = Pt(10.5)
    r1.font.bold = len(num) <= 1
    r1.font.color.rgb = NAVY
    r2 = par.add_run(titulo)
    r2.font.size = Pt(10.5)
    r2.font.bold = len(num) <= 1
    r2.font.color.rgb = NAVY if len(num) <= 1 else DARK
    pf = par.paragraph_format
    pf.left_indent = Cm(recuo)
    pf.space_before = Pt(2 if len(num) <= 1 else 0)
    pf.space_after = Pt(2)

p("", size=6, depois=10)
p("Os scripts SQL completos acompanham esta entrega nas pastas "
  "banco-de-dados/sql/mysql e banco-de-dados/sql/postgresql, e o diagrama "
  "também está disponível em banco-de-dados/docs/DER_NovaBank.png.",
  size=9, italic=True, cor=GRAY)

# --------------------------------------------------------------------------
# 1. CONTEXTO
# --------------------------------------------------------------------------
h1("1. Contexto da empresa e do banco de dados")

p("O Nova Bank é um banco 100% digital criado para o público jovem — estudantes, "
  "universitários e jovens profissionais que estão começando a vida financeira. "
  "O modelo de negócio dispensa agências físicas: a abertura de conta, a emissão "
  "de cartões, as transferências, os pagamentos e a contratação de crédito "
  "acontecem integralmente pelo aplicativo, em poucos minutos e sem burocracia.")

p("O portfólio da empresa, apresentado no site institucional, é composto por seis "
  "produtos principais: conta digital gratuita com rendimento automático de 100% do "
  "CDI; cartão de débito, crédito e virtual sem anuidade; Pix e transferências 24/7; "
  "pagamento e agendamento de boletos; empréstimo pessoal jovem com taxa a partir de "
  "0,99% ao mês; e caixinhas de objetivos com rendimento diário. A estrutura "
  "organizacional é enxuta e dividida em quatro diretorias — Tecnologia, Financeira, "
  "CX & Atendimento e Compliance & Jurídico — subordinadas à Diretoria Executiva.")

p("Como não existem agências, praticamente todo o relacionamento com o cliente "
  "gera registros digitais: o cadastro, a abertura de conta, cada cartão emitido, "
  "cada chave Pix registrada, cada movimentação financeira, cada contrato de crédito "
  "com suas parcelas, cada meta de poupança e cada ticket de atendimento. Sem um "
  "banco de dados organizado, esses registros ficariam dispersos e seria impossível "
  "responder a perguntas simples do negócio, como “qual é o saldo desta conta?”, "
  "“quanto este cliente já pagou do empréstimo?” ou “quais parcelas estão em atraso?”.")

h2("1.1 Objetivo do banco de dados")
p("O banco de dados Nova Bank tem por objetivo ser a fonte única de informação "
  "(single source of truth) das operações da empresa, garantindo quatro propriedades:")
bullet("consistência: o saldo de uma conta precisa refletir exatamente as "
       "movimentações registradas;")
bullet("integridade referencial: nenhuma transação, parcela ou cartão pode existir "
       "sem a conta, o contrato ou o cliente correspondente;")
bullet("rastreabilidade: toda operação financeira guarda data, hora, tipo, valor e "
       "situação, permitindo auditoria e conciliação;")
bullet("apoio à decisão: a estrutura permite consultas agregadas (gastos por cartão, "
       "inadimplência, adesão aos serviços) que orientam as áreas de negócio.")

h2("1.2 Escopo desta etapa")
p("Conforme o enunciado, esta etapa é independente das demais disciplinas: o banco "
  "de dados representa as informações da empresa, mas não é integrado ao site nem ao "
  "programa desenvolvido em lógica de programação. Estão no escopo: o modelo "
  "conceitual (DER), o dicionário de dados, os scripts de criação (DDL), a carga de "
  "dados de exemplo (INSERT) e as consultas de demonstração (SELECT). Estão fora do "
  "escopo: autenticação, criptografia, políticas de backup e integração com o "
  "aplicativo.")

# --------------------------------------------------------------------------
# 2. FUNCIONALIDADE
# --------------------------------------------------------------------------
h1("2. Funcionalidade escolhida e justificativa")

p("Entre as funcionalidades possíveis (conta digital, cartões, crédito, atendimento, "
  "catálogo de serviços), a equipe escolheu modelar o núcleo de conta digital e "
  "movimentações financeiras, com os módulos de crédito e de relacionamento "
  "conectados a ele. Em outras palavras, o banco de dados cobre o caminho completo "
  "do dinheiro dentro da instituição: o cliente é cadastrado, abre uma conta, recebe "
  "cartões e chaves Pix, movimenta o saldo por Pix, boleto ou compra, contrata "
  "empréstimo (que gera parcelas), organiza reservas em caixinhas e é atendido por "
  "um colaborador quando precisa de suporte.")

p("A escolha se justifica por quatro motivos:")
bullet("é a funcionalidade central do negócio — sem conta e sem movimentação não "
       "existe banco digital, e todos os demais produtos dependem dessa base;")
bullet("exercita os três tipos clássicos de relacionamento vistos em sala: 1:N "
       "(cliente possui contas), N:N resolvido por tabela associativa (cliente "
       "contrata serviços) e um relacionamento da entidade com ela mesma (conta de "
       "origem e conta de destino de uma transferência interna);")
bullet("permite consultas realmente relevantes para a gestão: extrato, gastos por "
       "cartão, situação das parcelas, inadimplência, progresso das metas e "
       "conferência de saldo;")
bullet("mantém aderência total ao site institucional já desenvolvido pelo grupo, "
       "que descreve exatamente esses produtos e serviços.")

# --------------------------------------------------------------------------
# 3. MODELO CONCEITUAL
# --------------------------------------------------------------------------
h1("3. Modelo conceitual (DER)")

h2("3.1 Notação e critérios de modelagem")
p("O modelo foi construído na notação entidade-relacionamento e implementado no "
  "modelo relacional. Cada entidade do DER corresponde a uma tabela; cada atributo, "
  "a uma coluna; cada relacionamento 1:N é implementado por uma chave estrangeira "
  "na tabela do lado N (filho), que aponta para a chave primária do lado 1 (pai).")
bullet("Chaves primárias simples e sem significado de negócio (surrogate keys), do "
       "tipo INT com auto incremento, para evitar que mudanças de CPF, e-mail ou "
       "número de conta afetem os relacionamentos.")
bullet("Chaves estrangeiras com ON UPDATE CASCADE e ON DELETE RESTRICT: um cliente "
       "não pode ser excluído enquanto tiver contas, e uma conta não pode ser "
       "excluída enquanto tiver transações.")
bullet("Relacionamento N:N entre cliente e serviço resolvido pela tabela associativa "
       "contratacao_servico, com chave única composta (id_cliente, id_servico).")
bullet("Restrições CHECK para domínios fechados (status, tipo de conta, bandeira, "
       "canal de atendimento) e para regras numéricas (valor maior que zero, saldo "
       "não negativo, limite disponível menor ou igual ao limite total).")
bullet("O número do cartão é armazenado de forma mascarada (**** **** **** 4821), "
       "em atenção à LGPD.")

h2("3.2 Domínios do modelo")
p("As doze tabelas foram organizadas em cinco domínios, o que facilita a leitura do "
  "diagrama e a evolução futura do sistema.")
tabela(["Domínio", "Entidades", "Papel no negócio"],
       [["Cadastro", "cliente", "Dados cadastrais, renda e situação do titular"],
        ["Núcleo bancário", "conta, cartao, chave_pix, caixinha, transacao",
         "Saldo, meios de pagamento, chaves Pix, reservas e movimentações"],
        ["Crédito", "emprestimo, parcela", "Contratação do empréstimo e cobrança das parcelas"],
        ["Catálogo", "servico, contratacao_servico", "Produtos oferecidos e adesão do cliente (N:N)"],
        ["Relacionamento", "funcionario, atendimento", "Estrutura organizacional e tickets de suporte"]],
       [3.0, 6.6, 6.8], size=9)

h2("3.3 Diagrama Entidade-Relacionamento")
p("O diagrama abaixo apresenta as 12 entidades, seus atributos, as chaves primárias "
  "(PK), as chaves estrangeiras (FK) e as cardinalidades dos 14 relacionamentos. "
  "Cada entidade traz no cabeçalho o domínio a que pertence.", depois=4)

# --- pagina paisagem com o DER
nova = doc.add_section(WD_SECTION.NEW_PAGE)
nova.orientation = WD_ORIENT.LANDSCAPE
nova.page_width = Cm(29.7)
nova.page_height = Cm(21)
nova.top_margin = Cm(1.4)
nova.bottom_margin = Cm(1.4)
nova.left_margin = Cm(1.5)
nova.right_margin = Cm(1.5)

par = doc.add_paragraph()
par.alignment = WD_ALIGN_PARAGRAPH.CENTER
der = os.path.join(DOCS, "DER_NovaBank.png")
par.add_run().add_picture(der, width=Cm(23.4))
par.paragraph_format.space_after = Pt(4)
legenda("Figura 1 — Diagrama Entidade-Relacionamento do banco de dados Nova Bank "
        "(12 entidades e 14 chaves estrangeiras).")

# --- volta ao retrato
volta = doc.add_section(WD_SECTION.NEW_PAGE)
volta.orientation = WD_ORIENT.PORTRAIT
volta.page_width = Cm(21)
volta.page_height = Cm(29.7)
volta.top_margin = Cm(2.2)
volta.bottom_margin = Cm(2.0)
volta.left_margin = Cm(2.3)
volta.right_margin = Cm(2.3)

h2("3.4 Entidades e atributos")
linhas_ent = []
for ent in modelo.ENTIDADES:
    pk = ", ".join(a["n"] for a in ent["attrs"] if a["pk"])
    fks = ", ".join(a["n"] for a in ent["attrs"] if a["fk"])
    linhas_ent.append([ent["rotulo"].lower(), modelo.DDL_COMMENTS[ent["nome"]],
                       pk, fks or "—", str(len(ent["attrs"]))])
tabela(["Entidade", "Descrição", "Chave primária", "Chaves estrangeiras", "Atrib."],
       linhas_ent, [3.0, 6.4, 2.7, 3.3, 1.0], size=8.2,
       align_center={4})

h2("3.5 Relacionamentos e cardinalidades")
p("A tabela a seguir descreve cada relacionamento do diagrama. A cardinalidade é "
  "sempre 1:N (um para muitos), lida do lado pai para o lado filho.")
linhas_rel = []
for filha, pai, col, card, verbo in modelo.RELACIONAMENTOS:
    ent = modelo.POR_NOME[filha]
    obrig = "obrigatória" if any(a["n"] == col and a["nn"] for a in ent["attrs"]) \
        else "opcional"
    linhas_rel.append([pai, filha, col, card, obrig])
tabela(["Entidade pai (1)", "Entidade filha (N)", "Atributo FK", "Cardinalidade",
        "Participação no lado N"],
       linhas_rel, [3.3, 3.9, 3.6, 2.4, 3.2], size=8.6, align_center={3, 4})
legenda("Quadro 1 — Relacionamentos do modelo e respectivas chaves estrangeiras.")

h2("3.6 Decisões de modelagem")
p("Algumas decisões merecem destaque, pois explicam por que o modelo tem a forma "
  "apresentada:")
bullet("Saldo armazenado na conta. O saldo é mantido na tabela conta (e não calculado "
       "a cada consulta) por desempenho, mas a consulta 8 do capítulo 7 recalcula o "
       "valor a partir das transações e compara com o saldo gravado, funcionando como "
       "teste de integridade.")
bullet("Compra no crédito não altera o saldo. Uma compra no cartão de crédito afeta "
       "apenas o limite disponível do cartão; por isso, a transação registra o cartão "
       "utilizado e a consulta de conferência de saldo ignora esse tipo.")
bullet("Transferência interna em uma única linha. A tabela transacao possui duas "
       "chaves estrangeiras para conta (origem e destino); quando as duas estão "
       "preenchidas, a movimentação debita uma conta e credita a outra ao mesmo tempo.")
bullet("Valor sempre positivo. O sinal da operação é dado pelo campo tipo (pix_enviado, "
       "pix_recebido, boleto, compra_debito, compra_credito, rendimento), o que "
       "facilita agregações e somas.")
bullet("Parcelas identificadas pelo contrato e pelo número. A chave única composta "
       "(id_emprestimo, numero_parcela) impede duplicidade de parcelas no mesmo contrato.")
bullet("Catálogo separado da adesão. O serviço é um produto do catálogo; a contratação "
       "é o vínculo entre cliente e serviço, com data e status próprios.")

# --------------------------------------------------------------------------
# 4. DICIONARIO
# --------------------------------------------------------------------------
h1("4. Dicionário de dados")
p("O dicionário apresenta, para cada tabela, os campos, os tipos de dados, as "
  "restrições aplicadas e a descrição do significado do atributo no negócio. "
  "PK indica chave primária, FK indica chave estrangeira e NN indica NOT NULL.")

for i, ent in enumerate(modelo.ENTIDADES, start=1):
    h3(f"4.{i} {ent['rotulo'].lower()} — {modelo.DDL_COMMENTS[ent['nome']]}")
    linhas = []
    for a in ent["attrs"]:
        rest = []
        if a["pk"]:
            rest.append("PK")
        if a["fk"]:
            rest.append(f"FK → {a['fk'][0]}")
        if a["nn"] and not a["pk"]:
            rest.append("NN")
        if a["uq"]:
            rest.append("UNIQUE")
        if a["d"] is not None:
            rest.append(f"default {a['d']}")
        if a["ck"]:
            rest.append("CHECK")
        linhas.append([a["n"], a["t"], ", ".join(rest) or "—", a["desc"]])
    tabela(["Campo", "Tipo", "Restrições", "Descrição"], linhas,
           [3.6, 3.0, 3.6, 6.2], size=8.2)

# --------------------------------------------------------------------------
# 5. IMPLEMENTACAO
# --------------------------------------------------------------------------
h1("5. Implementação SQL")

h2("5.1 Organização dos scripts")
p("A implementação adota o PostgreSQL 17 hospedado no Neon (Postgres serverless). "
  "Os scripts ficam na pasta sql/postgresql e podem ser executados de duas formas: pelo "
  "SQL Editor do console do Neon, colando o arquivo único, ou pelo terminal, usando a "
  "connection string do projeto. A pasta sql/mysql traz uma variante opcional do mesmo "
  "modelo, para quem preferir rodar localmente no MySQL Workbench.")
tabela(["Arquivo (pasta postgresql)", "Conteúdo", "Recursos demonstrados"],
       [["00_nova_bank_completo.sql", "Estrutura + dados em um único script",
         "Atalho para o SQL Editor do Neon"],
        ["01_schema.sql", "Criação das 12 tabelas",
         "CREATE TABLE, PK, FK, UNIQUE, CHECK, DEFAULT, índices"],
        ["02_dados.sql", "Carga de dados de exemplo",
         "INSERT com múltiplas linhas, respeitando a ordem das FKs"],
        ["03_consultas.sql", "Consultas de demonstração",
         "SELECT com JOIN, GROUP BY, LEFT JOIN, CTE e window function"]],
       [4.6, 5.8, 6.0], size=8.6)

p("O Neon exige três cuidados simples: a conexão usa SSL (sslmode=require), o banco do "
  "projeto já existe e se chama neondb, e os objetos são criados no schema public. Para "
  "executar scripts de criação (DDL), use a conexão direta do projeto — a opção "
  "“Direct connection” em Connection Details — e não a conexão agrupada (pooler).",
  size=10)

h2("5.2 Tipos de dados utilizados")
tabela(["Tipo", "Uso no modelo", "Justificativa"],
       [["INT / SERIAL", "Chaves primárias e estrangeiras",
         "Identificadores compactos, com auto incremento"],
        ["VARCHAR(n)", "Nomes, e-mails, descrições, números mascarados",
         "Texto de tamanho variável e limitado"],
        ["CHAR(n)", "CPF (11), UF (2)", "Tamanho fixo, com CHECK de comprimento"],
        ["DECIMAL(p,s)", "Valores monetários, taxas e limites",
         "Precisão exata — evita erros de arredondamento do ponto flutuante"],
        ["DATE", "Datas de nascimento, abertura, vencimento, pagamento",
         "Data sem hora"],
        ["TIMESTAMP", "Data e hora de transações e atendimentos",
         "Permite ordenar o extrato e medir o tempo de atendimento"],
        ["BOOLEAN", "Indicadores (ativo, ativa)",
         "Representa estados verdadeiro/falso"]],
       [3.2, 6.6, 6.6], size=8.6)

h2("5.3 Restrições de integridade")
p("Além das chaves primárias e estrangeiras, o script cria restrições de unicidade e "
  "de domínio que impedem o cadastro de dados inconsistentes.")
bullet("UNIQUE em cpf e email (cliente), numero_conta (conta), valor_chave (chave_pix), "
       "email_corporativo (funcionario), nome_servico (servico) e nas chaves compostas "
       "de parcela e contratacao_servico.")
bullet("CHECK de domínio: status, tipo_conta, tipo_cartao, bandeira, categoria, "
       "tipo_chave, canal, departamento e tipo de transação aceitam apenas valores "
       "previstos no negócio.")
bullet("CHECK numérico: valor > 0, saldo >= 0, limite_disponivel <= limite_total, "
       "prazo_meses entre 3 e 36, renda_mensal >= 0.")
bullet("CHECK de coerência: uma transação precisa ter conta de origem ou de destino; "
       "origem e destino não podem ser a mesma conta; o encerramento de um atendimento "
       "não pode ser anterior à sua abertura.")

h2("5.4 Trecho do script de criação")
schema_txt = io.open(os.path.join(SQL, "postgresql", "01_schema.sql"), encoding="utf-8").read()
bloco = schema_txt.split("CREATE TABLE conta (", 1)[1].split("\n);", 1)[0]
codigo("CREATE TABLE conta (" + bloco + "\n);")

h2("5.5 Índices")
p("No PostgreSQL os índices das colunas de chave estrangeira não são criados "
  "automaticamente; por isso o script cria explicitamente um índice para cada FK, o "
  "que acelera as junções mais frequentes do banco: extrato por conta, parcelas por "
  "contrato, transações por cartão e atendimentos por cliente.")

# --------------------------------------------------------------------------
# 6. DADOS
# --------------------------------------------------------------------------
h1("6. Dados de exemplo")
p("A carga de dados foi construída para que o banco funcione como um pequeno recorte "
  "real da operação, com dez clientes, doze contas, quatorze cartões, duzentas e "
  "trinta e nove transações e sessenta parcelas distribuídas em quatro contratos.")

h2("6.1 Volumetria")
contagens = [("cliente", len(dados.CLIENTES)), ("conta", len(dados.CONTAS)),
             ("cartao", len(dados.CARTOES)), ("chave_pix", len(dados.CHAVES_PIX)),
             ("caixinha", len(dados.CAIXINHAS)), ("emprestimo", len(dados.EMPRESTIMOS)),
             ("parcela", len(dados.PARCELAS)), ("servico", len(dados.SERVICOS)),
             ("contratacao_servico", len(dados.CONTRATACOES)),
             ("transacao", len(dados.TRANSACOES)),
             ("funcionario", len(dados.FUNCIONARIOS)),
             ("atendimento", len(dados.ATENDIMENTOS))]
total = sum(v for _, v in contagens)
tabela(["Tabela", "Registros", "Conteúdo dos dados de exemplo"],
       [[n, str(v), d] for (n, v), d in zip(contagens, [
           "Titulares com CPF, e-mail, cidade, renda e situação",
           "Contas de pagamento, corrente e poupança, com saldo",
           "Cartões de débito, crédito e virtuais, com limites",
           "Chaves Pix do tipo CPF, e-mail, telefone e aleatória",
           "Metas de viagem, curso, reserva e entrada de imóvel",
           "Contratos ativos, quitado, em análise e cancelado",
           "Parcelas pagas, abertas e atrasadas",
           "Seis produtos do catálogo (conta, cartão, Pix, boleto, crédito, caixinha)",
           "Adesões de clientes aos serviços (relacionamento N:N)",
           "Pix, boletos, compras, rendimentos e transferências internas",
           "Colaboradores das diretorias da empresa",
           "Tickets de chat, app, telefone, e-mail e ouvidoria"])] +
       [["Total", str(total), "Registros carregados pelos scripts de INSERT"]],
       [3.6, 2.0, 10.8], size=8.6, align_center={1})

h2("6.2 Regras seguidas na geração dos dados")
p("Os dados não foram digitados ao acaso: eles obedecem a regras que garantem "
  "coerência entre tabelas.")
bullet("Saldo = soma das transações concluídas de cada conta (entradas menos saídas), "
       "o que faz a consulta de conferência retornar zero divergências.")
bullet("Cada transferência interna gera uma única linha, com conta de origem e conta "
       "de destino, movimentando as duas contas.")
bullet("O valor das parcelas foi calculado pela fórmula de amortização (PMT) com a "
       "taxa e o prazo do contrato — por exemplo, R$ 3.000,00 em 12 meses a 0,99% ao "
       "mês resultam em parcelas de R$ 266,38.")
bullet("O limite disponível de cada cartão é o limite total menos as compras no "
       "crédito já realizadas.")
bullet("As datas vão até 14/11/2026, de modo que existem parcelas vencidas e não "
       "pagas para demonstrar a consulta de inadimplência.")

h2("6.3 Amostra do script de inserção")
ins = io.open(os.path.join(SQL, "mysql", "02_dados.sql"), encoding="utf-8").read()
amostra = []
for tbl in ("conta", "chave_pix"):
    i = ins.index(f"INSERT INTO {tbl}")
    amostra.append(ins[i:].split(";", 1)[0] + ";")
codigo("\n\n".join(amostra))

# --------------------------------------------------------------------------
# 7. CONSULTAS
# --------------------------------------------------------------------------
h1("7. Consultas SQL e resultados")
p("As consultas abaixo foram executadas sobre os dados de exemplo e são apresentadas "
  "com o resultado obtido. Todas demonstram o relacionamento entre tabelas, conforme "
  "exigido no enunciado.")

TITULOS_DOC = {
    "2. Extrato de uma conta (cliente + conta + transacao)":
        "Extrato de uma conta (cliente + conta + transação)",
    "3. Gastos por cartao de credito": "Gastos por cartão de crédito",
    "4. Situacao das parcelas de cada emprestimo":
        "Situação das parcelas de cada empréstimo",
    "5. Parcelas vencidas e ainda nao pagas": "Parcelas vencidas e ainda não pagas",
    "6. Servicos mais contratados": "Serviços mais contratados",
    "8. Conferencia de saldo (integridade dos dados)":
        "Conferência de saldo (integridade dos dados)",
}

consultas_doc = [
    ("1. Listagem de clientes com suas contas",
     "Objetivo: listar cada cliente e as contas que ele possui, com tipo e saldo.",
     "Mostra o relacionamento 1:N entre cliente e conta por meio de JOIN.",
     None),
    ("2. Extrato de uma conta (cliente + conta + transacao)",
     "Objetivo: montar o extrato da conta 10001-2, da cliente Ana Beatriz.",
     "Junta três tabelas e ordena as movimentações da mais recente para a mais antiga.",
     10),
    ("3. Gastos por cartao de credito",
     "Objetivo: total gasto em cada cartão de crédito, com limite total e disponível.",
     "Combina quatro tabelas, LEFT JOIN e agregações para mostrar o consumo do limite.",
     None),
    ("4. Situacao das parcelas de cada emprestimo",
     "Objetivo: para cada contrato, quantas parcelas foram pagas e quantas seguem em aberto.",
     "Usa LEFT JOIN com agregação condicional (CASE WHEN) e cobre também contratos sem parcelas.",
     None),
    ("5. Parcelas vencidas e ainda nao pagas",
     "Objetivo: identificar a inadimplência atual da carteira de crédito.",
     "Compara a data de vencimento com a data atual e retorna cliente, contrato e parcela.",
     None),
    ("6. Servicos mais contratados",
     "Objetivo: medir a adesão de cada produto do catálogo.",
     "Percorre a tabela associativa contratacao_servico, que resolve o relacionamento N:N.",
     None),
    ("7. Progresso das caixinhas",
     "Objetivo: acompanhar o percentual atingido de cada meta financeira.",
     "Calcula o percentual em tempo de consulta e ordena da meta mais próxima à mais distante.",
     8),
    ("8. Conferencia de saldo (integridade dos dados)",
     "Objetivo: provar que o saldo gravado corresponde à soma das transações.",
     "Recalcula o saldo com CASE WHEN dentro de SUM e compara com a coluna saldo.",
     None),
]

for i, (chave, objetivo, demonstra, limite) in enumerate(consultas_doc, start=1):
    h2(f"7.{i} {TITULOS_DOC.get(chave, chave.split('. ', 1)[1])}")
    p(objetivo, size=10, depois=2)
    sql_txt = next(s for t, o, s in gerar_sql.CONSULTAS if t == chave)
    codigo(sql_txt)
    resultado(chave, limite)
    p(demonstra, size=9, italic=True, cor=GRAY)

# extras
h2("7.9 Consulta com CTE e função de janela")
p("Como complemento, o arquivo 03_consultas.sql traz uma consulta que usa Common Table "
  "Expression (WITH) e função de janela para calcular o saldo acumulado do extrato, "
  "mostrando a evolução do saldo movimento a movimento.", size=10, depois=4)
codigo(gerar_sql.EXTRA_SQL)
resultado("9. Extrato com saldo acumulado (CTE + window function)", 8)
legenda("O saldo acumulado da última linha (R$ 6.906,08) é igual ao saldo gravado na "
        "conta 10001-2, confirmando a consistência entre transações e saldo.")

# --------------------------------------------------------------------------
# 8. EXECUCAO
# --------------------------------------------------------------------------
h1("8. Como executar e conferência da entrega")

h2("8.1 Neon — PostgreSQL serverless (ambiente adotado)")
p("O banco é executado em um projeto do Neon, com PostgreSQL 17. O caminho mais "
  "rápido é usar o SQL Editor do próprio console; a alternativa é conectar pelo "
  "terminal com a connection string do projeto.", size=10)
bullet("No console do Neon, abra o projeto e copie a connection string em "
       "Connection Details > Direct connection (ela termina com ?sslmode=require).")
bullet("Opção A — SQL Editor: abra o arquivo sql/postgresql/00_nova_bank_completo.sql, "
       "cole o conteúdo e clique em Run. Estrutura e dados são criados de uma vez.")
bullet("Opção B — terminal: psql \"postgresql://usuario:senha@ep-xxxx.regiao.aws.neon.tech/neondb?sslmode=require\" -f 01_schema.sql, "
       "depois 02_dados.sql e 03_consultas.sql.")
bullet("Confira em Tables, no menu lateral do Neon: as 12 tabelas devem aparecer no "
       "schema public.")
p("O banco neondb já existe no projeto, então não é preciso criar base nem schema: o "
  "script apenas cria as tabelas no schema public da conexão atual. Como o Neon usa "
  "SSL obrigatório, qualquer cliente (psql, DBeaver, pgAdmin) precisa da opção "
  "sslmode=require na connection string.", size=10)

h2("8.2 MySQL 8 (variante local, opcional)")
bullet("Abra o MySQL Workbench e conecte-se ao servidor local.")
bullet("Abra o arquivo sql/mysql/01_schema.sql e execute o script inteiro (ícone de raio).")
bullet("Execute em seguida 02_dados.sql e depois 03_consultas.sql.")
p("Nesta variante o script cria o banco nova_bank; no PostgreSQL/Neon não há "
  "CREATE DATABASE, porque o banco já é fornecido pela plataforma.", size=10)

h2("8.3 Conferência dos itens exigidos")
tabela(["Exigência do enunciado", "Como foi atendida"],
       [["Mínimo de 5 entidades", "12 tabelas: cliente, conta, cartao, chave_pix, caixinha, transacao, emprestimo, parcela, servico, contratacao_servico, funcionario e atendimento"],
        ["Atributos de cada entidade", "Dicionário de dados (capítulo 4) e diagrama (figura 1)"],
        ["Chaves primárias", "Uma PK por tabela, identificada no DER e no dicionário"],
        ["Chaves estrangeiras", "14 FKs, listadas no quadro 1 e implementadas com ON UPDATE CASCADE"],
        ["Relacionamentos e cardinalidades", "Quadro 1 e figura 1 (1:N em todos os relacionamentos)"],
        ["Entidades no contexto da empresa", "Todos os produtos do site (conta, cartão, Pix, boleto, crédito, caixinha) e a estrutura organizacional"],
        ["Criação das tabelas em SQL", "sql/postgresql (Neon), com variante MySQL em sql/mysql"],
        ["Tipos de dados apropriados", "Seção 5.2"],
        ["Inserção de dados (INSERT)", f"02_dados.sql, com {total} registros"],
        ["Consultas (SELECT) — mínimo 3", "03_consultas.sql, com 9 consultas comentadas"],
        ["Explicação do contexto", "Capítulos 1 e 2"],
        ["Diagrama claro e organizado", "Figura 1, em página inteira no formato paisagem"]],
       [5.4, 11.0], size=8.6)

p("Todos os arquivos estão organizados na pasta banco-de-dados:", depois=4)
tabela(["Pasta / arquivo", "Descrição"],
       [["sql/postgresql/00_nova_bank_completo.sql", "Estrutura + dados em um único script (Neon)"],
        ["sql/postgresql/01_schema.sql", "Criação das tabelas (PostgreSQL 17 / Neon)"],
        ["sql/postgresql/02_dados.sql", "Inserção dos dados de exemplo (Neon)"],
        ["sql/postgresql/03_consultas.sql", "Consultas de demonstração (Neon)"],
        ["sql/mysql/01_schema.sql", "Criação das tabelas (variante MySQL 8)"],
        ["sql/mysql/02_dados.sql", "Inserção dos dados de exemplo (variante MySQL 8)"],
        ["sql/mysql/03_consultas.sql", "Consultas de demonstração (variante MySQL 8)"],
        ["docs/DER_NovaBank.png", "Diagrama Entidade-Relacionamento em imagem"],
        ["docs/Modelagem_Banco_de_Dados_NovaBank.docx", "Este documento"]],
       [7.4, 9.0], size=8.8)

os.makedirs(DOCS, exist_ok=True)
doc.save(SAIDA)
print("salvo:", SAIDA)
