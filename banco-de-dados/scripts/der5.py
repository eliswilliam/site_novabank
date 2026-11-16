# -*- coding: utf-8 -*-
"""Desenha o DER da versao minima (5 entidades) do Nova Bank."""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import modelo5 as modelo  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "docs", "DER_NovaBank.png")

SS = 2
LARG = 1120
ALT = 820
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
F_LEG = fonte(10)

POS = {
    "cliente": (40, 110),
    "conta": (400, 110),
    "cartao": (760, 110),
    "emprestimo": (400, 430),
    "transacao": (760, 430),
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
    d.line([(x * SS, y * SS) for x, y in pts], fill=cor, width=max(1, int(w * SS)), joint="curve")


def badge(x, y, rotulo, cor):
    w, h = 22, 13
    d.rounded_rectangle(R(x, y, x + w, y + h), radius=3 * SS, fill=cor)
    txt(x + w / 2, y + h / 2 - 0.5, rotulo, F_BADGE, (255, 255, 255), anchor="mm")


RELS = [
    dict(pts=[(340, 235), (400, 235)], pai=("1", 352, 221), filha=("N", 388, 221)),
    dict(pts=[(700, 200), (760, 200)], pai=("1", 712, 186), filha=("N", 748, 186)),
    dict(pts=[(470, 322), (470, 430)], pai=("1", 483, 336), filha=("N", 483, 416)),
    dict(pts=[(340, 300), (370, 300), (370, 490), (400, 490)],
         pai=("1", 354, 288), filha=("N", 386, 478)),
    dict(pts=[(900, 364), (900, 430)], pai=("1", 913, 376), filha=("N", 913, 418)),
    dict(pts=[(620, 322), (620, 380), (830, 380), (830, 430)],
         pai=("1", 633, 336), filha=("N", 843, 418), verbo=("movimenta", 710, 369)),
]

for r in RELS:
    linha(r["pts"], LINE, 1.5)

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

for r in RELS:
    for rotulo, x, y in (r["pai"], r["filha"]):
        tw = d.textlength(rotulo, font=F_REL) / SS
        d.rectangle(R(x - tw / 2 - 2, y - 7, x + tw / 2 + 2, y + 7), fill=BG)
        txt(x, y - 0.5, rotulo, F_REL, NAVY, anchor="mm")
    if "verbo" in r:
        s, x, y = r["verbo"]
        tw = d.textlength(s, font=F_VERBO) / SS if "F_VERBO" in globals() else \
            d.textlength(s, font=F_SUB) / SS
        d.rectangle(R(x - tw / 2 - 3, y - 6.5, x + tw / 2 + 3, y + 6.5), fill=BG)
        txt(x, y, s, F_SUB, MUTED, anchor="mm")

txt(40, 22, "DER — NOVA BANK", F_TITULO, NAVY)
txt(40, 56, "Diagrama Entidade-Relacionamento · versão mínima  ·  5 entidades  ·  "
            "7 chaves estrangeiras  ·  novembro de 2026", F_SUB, MUTED)

ly = 700
d.rounded_rectangle(R(40, ly, 760, ly + 92), radius=6 * SS, outline=BORDER,
                    width=max(1, int(1 * SS)))
txt(56, ly + 12, "Legenda", F_CARD, NAVY)
badge(56, ly + 30, "PK", YELLOW)
txt(86, ly + 30, "chave primária (atributo sublinhado)", F_LEG, TXT)
badge(56, ly + 50, "FK", TEAL)
txt(86, ly + 50, "chave estrangeira", F_LEG, TXT)
linha([(330, ly + 22), (380, ly + 22)], LINE, 1.5)
txt(330, ly + 7, "1", F_REL, NAVY)
txt(374, ly + 7, "N", F_REL, NAVY)
txt(392, ly + 15, "relacionamento 1:N (1 = lado pai, N = lado filho)", F_LEG, TXT)
txt(330, ly + 42, "conta → transação: duas FKs (origem e destino)", F_LEG, MUTED)
txt(330, ly + 58, "representadas por uma única linha no diagrama", F_LEG, MUTED)
txt(330, ly + 74, "cardinalidades no padrão 1:N (notação de Peter Chen)", F_LEG, MUTED)

img = img.resize((LARG, ALT), Image.LANCZOS)
os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
img.save(SAIDA, "PNG", dpi=(220, 220))
print("salvo:", SAIDA, img.size)
