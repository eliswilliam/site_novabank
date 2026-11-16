# -*- coding: utf-8 -*-
"""Desenha o DER do Nova Bank em PNG (Pillow)."""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import modelo  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "docs", "DER_NovaBank.png")

SS = 2
LARG = 1460
ALT = 1080
W_CARD = 300
HEAD_H = 36
ROW_H = 21
PAD_B = 8

NAVY = (15, 42, 68)
YELLOW = (245, 183, 0)
TEAL = (14, 116, 144)
TXT = (30, 41, 59)
MUTED = (100, 116, 139)
LINE = (110, 125, 145)
BORDER = (148, 163, 184)
BG = (255, 255, 255)


def fonte(tam, bold=False):
    base = r"C:\Windows\Fonts"
    for n in (("segoeuib.ttf" if bold else "segoeui.ttf"),
              ("arialbd.ttf" if bold else "arial.ttf")):
        caminho = os.path.join(base, n)
        if os.path.exists(caminho):
            return ImageFont.truetype(caminho, int(tam * SS))
    return ImageFont.load_default()


F_TITULO = fonte(23, True)
F_SUB = fonte(11)
F_CARD = fonte(13, True)
F_DOM = fonte(7.5, True)
F_ATTR = fonte(11)
F_ATTR_B = fonte(11, True)
F_TIPO = fonte(9)
F_BADGE = fonte(8, True)
F_REL = fonte(10, True)
F_VERBO = fonte(8.5)
F_LEG = fonte(10)

POS = {
    "cliente": (40, 110),
    "conta": (400, 110),
    "cartao": (760, 110),
    "transacao": (1120, 110),
    "contratacao_servico": (40, 440),
    "emprestimo": (400, 440),
    "chave_pix": (760, 440),
    "funcionario": (1120, 440),
    "servico": (40, 700),
    "parcela": (400, 700),
    "caixinha": (760, 700),
    "atendimento": (1120, 700),
}


def altura(ent):
    return HEAD_H + ROW_H * len(ent["attrs"]) + PAD_B


def caixa(nome):
    x, y = POS[nome]
    return (x, y, x + W_CARD, y + altura(modelo.POR_NOME[nome]))


img = Image.new("RGB", (LARG * SS, ALT * SS), BG)
d = ImageDraw.Draw(img)


def R(x0, y0, x1, y1):
    return [x0 * SS, y0 * SS, x1 * SS, y1 * SS]


def txt(x, y, s, f, fill=TXT, anchor="la"):
    d.text((x * SS, y * SS), s, font=f, fill=fill, anchor=anchor)


def linha(pts, cor=LINE, w=1.5):
    d.line([(x * SS, y * SS) for x, y in pts], fill=cor,
           width=max(1, int(w * SS)), joint="curve")


def badge(x, y, rotulo, cor):
    w, h = 22, 13
    d.rounded_rectangle(R(x, y, x + w, y + h), radius=3 * SS, fill=cor)
    txt(x + w / 2, y + h / 2 - 0.5, rotulo, F_BADGE, (255, 255, 255), anchor="mm")


# --------------------------------------------------------------- relacoes
# pts: caminho ortogonal; (rotulo, x, y) das cardinalidades; verbo opcional
RELS = [
    dict(pts=[(340, 235), (400, 235)], pai=("1", 352, 221), filha=("N", 388, 221)),
    dict(pts=[(700, 200), (760, 200)], pai=("1", 712, 186), filha=("N", 748, 186)),
    dict(pts=[(1060, 220), (1120, 220)], pai=("1", 1072, 206), filha=("N", 1108, 206)),
    dict(pts=[(600, 110), (600, 80), (1240, 80), (1240, 110)],
         pai=("1", 613, 96), filha=("N", 1253, 96), verbo=("movimenta", 930, 69)),
    dict(pts=[(340, 300), (370, 300), (370, 470), (400, 470)],
         pai=("1", 354, 288), filha=("N", 386, 458)),
    dict(pts=[(470, 322), (470, 440)], pai=("1", 483, 336), filha=("N", 483, 426)),
    dict(pts=[(470, 652), (470, 700)], pai=("1", 483, 664), filha=("N", 483, 688)),
    dict(pts=[(540, 322), (540, 412), (910, 412), (910, 440)],
         pai=("1", 553, 336), filha=("N", 923, 428)),
    dict(pts=[(680, 322), (680, 400), (1090, 400), (1090, 800), (1060, 800)],
         pai=("1", 693, 336), filha=("N", 1076, 790), verbo=("cria", 830, 389)),
    dict(pts=[(150, 385), (150, 440)], pai=("1", 163, 397), filha=("N", 163, 428)),
    dict(pts=[(150, 589), (150, 700)], pai=("1", 163, 601), filha=("N", 163, 688)),
    dict(pts=[(40, 330), (22, 330), (22, 945), (1270, 945), (1270, 912)],
         pai=("1", 36, 342), filha=("N", 1256, 926), verbo=("abre", 620, 934)),
    dict(pts=[(1270, 660), (1270, 700)], pai=("1", 1283, 668), filha=("N", 1283, 692)),
]

# linhas primeiro (os cartoes ficam por cima, garantindo que nada invada a caixa)
for r in RELS:
    linha(r["pts"], LINE, 1.5)

# --------------------------------------------------------------- cartoes
for ent in modelo.ENTIDADES:
    x0, y0, x1, y1 = caixa(ent["nome"])
    d.rounded_rectangle(R(x0, y0, x1, y1), radius=7 * SS, fill=(255, 255, 255),
                        outline=BORDER, width=max(1, int(1.2 * SS)))
    d.rounded_rectangle(R(x0, y0, x1, y0 + HEAD_H), radius=7 * SS, fill=NAVY)
    d.rectangle(R(x0, y0 + HEAD_H - 12, x1, y0 + HEAD_H), fill=NAVY)
    d.rectangle(R(x0, y0 + HEAD_H - 3, x1, y0 + HEAD_H), fill=YELLOW)
    txt(x0 + 12, y0 + HEAD_H / 2 - 1, ent["rotulo"], F_CARD, (255, 255, 255), anchor="lm")
    txt(x1 - 10, y0 + HEAD_H / 2 - 1, ent["dominio"].upper(), F_DOM,
        (176, 196, 219), anchor="rm")

    y = y0 + HEAD_H + 6
    for a in ent["attrs"]:
        xa = x0 + 12
        if a["pk"]:
            badge(xa, y + 2, "PK", YELLOW)
            xa += 28
        elif a["fk"]:
            badge(xa, y + 2, "FK", TEAL)
            xa += 28
        txt(xa, y, a["n"], F_ATTR_B if a["pk"] else F_ATTR, TXT)
        if a["pk"]:
            lb = d.textlength(a["n"], font=F_ATTR_B) / SS
            linha([(xa, y + 13.5), (xa + lb, y + 13.5)], NAVY, 1)
        txt(x1 - 12, y, a["t"], F_TIPO, MUTED, anchor="ra")
        y += ROW_H

# --------------------------------------------------------------- rotulos
for r in RELS:
    for rotulo, x, y in (r["pai"], r["filha"]):
        tw = d.textlength(rotulo, font=F_REL) / SS
        d.rectangle(R(x - tw / 2 - 2, y - 7, x + tw / 2 + 2, y + 7), fill=BG)
        txt(x, y - 0.5, rotulo, F_REL, NAVY, anchor="mm")
    if "verbo" in r:
        s, x, y = r["verbo"]
        tw = d.textlength(s, font=F_VERBO) / SS
        d.rectangle(R(x - tw / 2 - 3, y - 6.5, x + tw / 2 + 3, y + 6.5), fill=BG)
        txt(x, y, s, F_VERBO, MUTED, anchor="mm")

# --------------------------------------------------------------- titulo
txt(40, 22, "DER — NOVA BANK", F_TITULO, NAVY)
txt(40, 56, "Diagrama Entidade-Relacionamento do banco de dados digital  ·  "
            "12 entidades  ·  14 chaves estrangeiras  ·  novembro de 2026", F_SUB, MUTED)

# --------------------------------------------------------------- legenda
ly = 966
d.rounded_rectangle(R(40, ly, 760, ly + 96), radius=6 * SS, outline=BORDER,
                    width=max(1, int(1 * SS)))
txt(56, ly + 12, "Legenda", F_CARD, NAVY)
badge(56, ly + 29, "PK", YELLOW)
txt(86, ly + 29, "chave primária (atributo sublinhado)", F_LEG, TXT)
badge(56, ly + 49, "FK", TEAL)
txt(86, ly + 49, "chave estrangeira", F_LEG, TXT)
linha([(330, ly + 22), (380, ly + 22)], LINE, 1.5)
txt(330, ly + 7, "1", F_REL, NAVY)
txt(374, ly + 7, "N", F_REL, NAVY)
txt(392, ly + 15, "relacionamento 1:N (1 = lado pai, N = lado filho)", F_LEG, TXT)
txt(330, ly + 40, "conta → transação: duas FKs (origem e destino)", F_LEG, MUTED)
txt(330, ly + 56, "representadas por uma única linha no diagrama", F_LEG, MUTED)
txt(330, ly + 72, "cardinalidades no padrão 1:N (notação de Peter Chen)", F_LEG, MUTED)

txt(1420, ly + 92, "Nova Bank · Projeto interdisciplinar · 2026", F_LEG, MUTED,
    anchor="ra")

img = img.resize((LARG, ALT), Image.LANCZOS)
os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
img.save(SAIDA, "PNG", dpi=(200, 200))
print("salvo:", SAIDA, img.size)
