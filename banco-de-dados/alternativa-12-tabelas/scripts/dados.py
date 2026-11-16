# -*- coding: utf-8 -*-
"""Geracao deterministica dos dados de exemplo do Nova Bank."""

import random
from datetime import date, datetime, timedelta

RND = random.Random(20261116)
HOJE = datetime(2026, 11, 16, 23, 59)


# --------------------------------------------------------------------------
# CLIENTES
# --------------------------------------------------------------------------
CLIENTES = [
    (1, "Ana Beatriz Souza Lima", "12345678901", date(2003, 4, 12), "ana.lima@email.com",
     "(11) 98765-4321", "Sao Paulo", "SP", 1800.00, date(2025, 3, 10), "ativo"),
    (2, "Lucas Ferreira Almeida", "23456789012", date(2001, 8, 25), "lucas.almeida@email.com",
     "(21) 99812-3344", "Rio de Janeiro", "RJ", 2400.00, date(2025, 5, 22), "ativo"),
    (3, "Mariana Costa Oliveira", "34567890123", date(2004, 1, 30), "mariana.oliveira@email.com",
     "(81) 98123-7766", "Recife", "PE", 1200.00, date(2025, 9, 1), "ativo"),
    (4, "Pedro Henrique Santos", "45678901234", date(1999, 11, 5), "pedro.santos@email.com",
     "(31) 99123-5544", "Belo Horizonte", "MG", 3200.00, date(2025, 1, 15), "ativo"),
    (5, "Julia Nascimento Rocha", "56789012345", date(2002, 6, 18), "julia.rocha@email.com",
     "(51) 99654-8899", "Porto Alegre", "RS", 2100.00, date(2025, 11, 3), "ativo"),
    (6, "Gabriel Martins Pereira", "67890123456", date(2000, 2, 14), "gabriel.pereira@email.com",
     "(41) 99544-2211", "Curitiba", "PR", 2750.00, date(2025, 7, 19), "ativo"),
    (7, "Beatriz Almeida Nunes", "78901234567", date(2005, 9, 7), "beatriz.nunes@email.com",
     "(71) 98877-6655", "Salvador", "BA", 950.00, date(2026, 2, 11), "ativo"),
    (8, "Rafael Souza Barbosa", "89012345678", date(1998, 12, 22), "rafael.barbosa@email.com",
     "(85) 99321-4455", "Fortaleza", "CE", 4100.00, date(2025, 4, 8), "ativo"),
    (9, "Camila Ribeiro Dias", "90123456789", date(2003, 7, 3), "camila.dias@email.com",
     "(92) 98444-1122", "Manaus", "AM", 1600.00, date(2026, 1, 27), "ativo"),
    (10, "Thiago Oliveira Castro", "01234567890", date(2001, 5, 19), "thiago.castro@email.com",
     "(61) 99700-3322", "Brasilia", "DF", 2900.00, date(2025, 8, 30), "inativo"),
]

# --------------------------------------------------------------------------
# CONTAS
# --------------------------------------------------------------------------
CONTAS = [
    (1, "10001-2", "0001", "pagamento", date(2025, 3, 10), "ativa", 1),
    (2, "10002-5", "0001", "pagamento", date(2025, 5, 22), "ativa", 2),
    (3, "10003-8", "0001", "pagamento", date(2025, 9, 1), "ativa", 3),
    (4, "10004-0", "0001", "corrente", date(2025, 1, 15), "ativa", 4),
    (5, "10005-3", "0001", "poupanca", date(2025, 2, 1), "ativa", 4),
    (6, "10006-6", "0001", "pagamento", date(2025, 11, 3), "ativa", 5),
    (7, "10007-9", "0001", "pagamento", date(2025, 7, 19), "ativa", 6),
    (8, "10008-1", "0001", "pagamento", date(2026, 2, 11), "ativa", 7),
    (9, "10009-4", "0001", "corrente", date(2025, 4, 8), "ativa", 8),
    (10, "10010-7", "0001", "pagamento", date(2026, 1, 27), "ativa", 9),
    (11, "10011-0", "0001", "pagamento", date(2025, 8, 30), "bloqueada", 10),
    (12, "10012-3", "0001", "poupanca", date(2026, 3, 4), "ativa", 1),
]

# --------------------------------------------------------------------------
# CARTOES  (id, numero_mascarado, tipo, bandeira, limite_total, limite_disp,
#           emissao, validade, status, id_conta)
# --------------------------------------------------------------------------
CARTOES = [
    (1, "**** **** **** 4821", "debito", "Visa", 0.00, 0.00, date(2025, 3, 12), date(2030, 3, 31), "ativo", 1),
    (2, "**** **** **** 7390", "credito", "Mastercard", 1500.00, 1210.10, date(2025, 3, 12), date(2030, 3, 31), "ativo", 1),
    (3, "**** **** **** 1122", "virtual", "Visa", 800.00, 800.00, date(2026, 4, 2), date(2028, 4, 30), "ativo", 1),
    (4, "**** **** **** 5567", "debito", "Mastercard", 0.00, 0.00, date(2025, 5, 25), date(2030, 5, 31), "ativo", 2),
    (5, "**** **** **** 9034", "credito", "Visa", 3500.00, 2860.40, date(2025, 5, 25), date(2030, 5, 31), "ativo", 2),
    (6, "**** **** **** 2288", "debito", "Elo", 0.00, 0.00, date(2025, 9, 4), date(2030, 9, 30), "ativo", 3),
    (7, "**** **** **** 4410", "debito", "Visa", 0.00, 0.00, date(2025, 1, 18), date(2030, 1, 31), "ativo", 4),
    (8, "**** **** **** 6675", "credito", "Mastercard", 6000.00, 5180.00, date(2025, 1, 18), date(2030, 1, 31), "ativo", 4),
    (9, "**** **** **** 3391", "debito", "Visa", 0.00, 0.00, date(2025, 11, 6), date(2030, 11, 30), "ativo", 6),
    (10, "**** **** **** 8812", "debito", "Elo", 0.00, 0.00, date(2025, 7, 22), date(2030, 7, 31), "bloqueado", 7),
    (11, "**** **** **** 7743", "debito", "Visa", 0.00, 0.00, date(2026, 2, 14), date(2031, 2, 28), "ativo", 8),
    (12, "**** **** **** 5508", "credito", "Visa", 4500.00, 4020.00, date(2025, 4, 11), date(2030, 4, 30), "ativo", 9),
    (13, "**** **** **** 1190", "debito", "Mastercard", 0.00, 0.00, date(2026, 1, 30), date(2031, 1, 31), "ativo", 10),
    (14, "**** **** **** 6620", "debito", "Visa", 0.00, 0.00, date(2026, 3, 7), date(2031, 3, 31), "ativo", 12),
]

# --------------------------------------------------------------------------
# CHAVES PIX
# --------------------------------------------------------------------------
CHAVES_PIX = [
    (1, "cpf", "12345678901", date(2025, 3, 10), True, 1),
    (2, "email", "ana.lima@email.com", date(2025, 3, 10), True, 1),
    (3, "telefone", "+5521987654321", date(2025, 5, 22), True, 2),
    (4, "cpf", "23456789012", date(2025, 5, 22), True, 2),
    (5, "aleatoria", "a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d", date(2025, 9, 1), True, 3),
    (6, "email", "pedro.santos@email.com", date(2025, 1, 15), True, 4),
    (7, "telefone", "+5541995442211", date(2025, 7, 19), True, 7),
    (8, "email", "rafael.barbosa@email.com", date(2025, 4, 8), True, 9),
    (9, "cpf", "90123456789", date(2026, 1, 27), True, 10),
    (10, "aleatoria", "f7e8d9c0-b1a2-4c3d-8e9f-0a1b2c3d4e5f", date(2025, 11, 3), False, 6),
]

# --------------------------------------------------------------------------
# SERVICOS
# --------------------------------------------------------------------------
SERVICOS = [
    (1, "Conta Digital Gratuita", "conta", "Conta sem mensalidade com rendimento automatico de 100% do CDI", 0.00, True),
    (2, "Cartao Virtual e Fisico", "cartao", "Cartao de debito e credito sem anuidade, com virtuais temporarios", 0.00, True),
    (3, "Pix e Transferencias 24/7", "pix", "Transferencias instantaneas gratuitas para qualquer banco", 0.00, True),
    (4, "Pagamento de Boletos", "pagamento", "Pagamento e agendamento de boletos pelo aplicativo", 0.00, True),
    (5, "Emprestimo Pessoal Jovem", "credito", "Credito pessoal a partir de 0,99% ao mes, com simulacao no app", 0.00, True),
    (6, "Caixinhas com Rendimento", "investimento", "Reservas por objetivo com rendimento diario automatico", 0.00, True),
]

# --------------------------------------------------------------------------
# FUNCIONARIOS
# --------------------------------------------------------------------------
FUNCIONARIOS = [
    (1, "Ana Paula Ribeiro", "Diretora Executiva (CEO)", "Diretoria", "ana.ribeiro@novabank.com.br", 28000.00, date(2024, 2, 1)),
    (2, "Bruno Carvalho Mendes", "Engenheiro de Software Senior", "Tecnologia", "bruno.mendes@novabank.com.br", 14500.00, date(2024, 4, 15)),
    (3, "Carla Menezes Farias", "Analista de Credito", "Financeiro", "carla.farias@novabank.com.br", 7800.00, date(2024, 8, 5)),
    (4, "Diego Ramos Teixeira", "Especialista em CX", "CX", "diego.teixeira@novabank.com.br", 6900.00, date(2025, 1, 20)),
    (5, "Elisa Fontes Barros", "Analista de Compliance", "Compliance", "elisa.barros@novabank.com.br", 9200.00, date(2024, 6, 10)),
    (6, "Felipe Andrade Luz", "Gerente de Atendimento", "CX", "felipe.luz@novabank.com.br", 8300.00, date(2025, 3, 3)),
]

# --------------------------------------------------------------------------
# EMPRESTIMOS
# --------------------------------------------------------------------------
EMPRESTIMOS = [
    (1, 3000.00, 0.99, 12, date(2026, 6, 10), "ativo", 1, 1),
    (2, 12000.00, 0.99, 18, date(2026, 3, 5), "ativo", 4, 4),
    (3, 5000.00, 1.29, 18, date(2026, 8, 20), "ativo", 6, 7),
    (4, 8000.00, 0.99, 12, date(2025, 11, 12), "quitado", 8, 9),
    (5, 1500.00, 1.49, 6, date(2026, 10, 28), "em_analise", 3, 3),
    (6, 2500.00, 1.29, 9, date(2026, 9, 2), "cancelado", 10, 11),
]

CAIXINHAS = [
    (1, "Viagem para o Chile", 6000.00, 2450.00, date(2026, 1, 10), date(2027, 1, 15), "ativa", 1),
    (2, "Reserva de Emergencia", 5000.00, 1800.00, date(2025, 6, 2), date(2027, 6, 30), "ativa", 1),
    (3, "Curso de Ingles", 3000.00, 3000.00, date(2025, 5, 12), date(2026, 8, 31), "concluida", 2),
    (4, "Notebook Novo", 4500.00, 900.00, date(2026, 2, 18), date(2027, 2, 28), "ativa", 3),
    (5, "Entrada do Apartamento", 20000.00, 7200.00, date(2025, 2, 10), date(2028, 12, 31), "ativa", 4),
    (6, "Intercambio na Irlanda", 8000.00, 1200.00, date(2026, 4, 5), date(2027, 9, 30), "ativa", 6),
    (7, "Moto Usada", 12000.00, 3500.00, date(2025, 9, 15), date(2027, 3, 31), "ativa", 9),
    (8, "Fundo de Estudos", 2500.00, 650.00, date(2026, 6, 20), date(2027, 6, 30), "ativa", 10),
]

# --------------------------------------------------------------------------
# CONTRATACOES DE SERVICO (cliente, servico)
# --------------------------------------------------------------------------
CONTRATACOES = [
    (1, 1), (1, 2), (1, 3), (1, 4), (1, 6),
    (2, 1), (2, 2), (2, 3), (2, 6),
    (3, 1), (3, 3),
    (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6),
    (5, 1), (5, 3), (5, 6),
    (6, 1), (6, 2), (6, 3), (6, 5),
    (7, 1), (7, 3),
    (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6),
    (9, 1), (9, 3), (9, 6),
    (10, 1), (10, 3),
]

# --------------------------------------------------------------------------
# ATENDIMENTOS
# --------------------------------------------------------------------------
ATENDIMENTOS = [
    (1, "chat", "Duvida sobre limite do cartao de credito", datetime(2026, 9, 3, 10, 12), datetime(2026, 9, 3, 10, 41), "resolvido", 1, 4),
    (2, "app", "Segunda via de comprovante de Pix", datetime(2026, 9, 18, 14, 5), datetime(2026, 9, 18, 14, 22), "resolvido", 3, 4),
    (3, "telefone", "Cartao bloqueado apos tentativa de compra", datetime(2026, 10, 2, 9, 30), datetime(2026, 10, 2, 10, 15), "resolvido", 6, 6),
    (4, "email", "Solicitacao de antecipacao de parcelas", datetime(2026, 10, 14, 16, 40), datetime(2026, 10, 15, 11, 5), "resolvido", 4, 3),
    (5, "ouvidoria", "Discordancia sobre juros do emprestimo", datetime(2026, 10, 27, 8, 55), None, "em_andamento", 8, 1),
    (6, "chat", "Como criar uma caixinha de viagem", datetime(2026, 11, 4, 19, 10), datetime(2026, 11, 4, 19, 25), "resolvido", 9, 4),
    (7, "app", "Problema no reconhecimento facial", datetime(2026, 11, 9, 7, 45), None, "aberto", 7, 2),
    (8, "telefone", "Pedido de desbloqueio da conta", datetime(2026, 11, 12, 13, 20), None, "em_andamento", 10, 5),
    (9, "chat", "Duvida sobre rendimento das caixinhas", datetime(2026, 11, 15, 21, 5), datetime(2026, 11, 15, 21, 18), "resolvido", 5, 6),
]


# --------------------------------------------------------------------------
# LEDGER DE TRANSACOES
# --------------------------------------------------------------------------
def pmt(principal, taxa_pct, n):
    i = taxa_pct / 100.0
    if i == 0:
        return round(principal / n, 2)
    fator = i / (1 - (1 + i) ** (-n))
    return round(principal * fator, 2)


def gerar():
    saldos = {c[0]: 0.0 for c in CONTAS}
    limite = {c[0]: c[4] for c in CARTOES}
    transacoes = []
    cartao_debito = {}
    cartao_credito = {}
    for c in CARTOES:
        cid, _, tipo, _, _, _, _, _, status, conta = c
        if status != "ativo":
            continue
        if tipo == "debito":
            cartao_debito.setdefault(conta, cid)
        elif tipo == "credito":
            cartao_credito[conta] = cid

    def add(origem, destino, tipo, valor, dt, desc, cartao=None, status="concluida"):
        """Registra uma movimentacao. Compra no credito nao afeta o saldo da conta,
        apenas o limite do cartao."""
        valor = round(valor, 2)
        if dt > HOJE:
            return False
        if status == "concluida" and tipo != "compra_credito" and origem:
            if saldos[origem] - valor < 0:
                return False
        transacoes.append({
            "tipo": tipo, "valor": valor, "dt": dt, "desc": desc,
            "status": status, "origem": origem, "destino": destino, "cartao": cartao,
        })
        if status != "concluida" or tipo == "compra_credito":
            return True
        if origem:
            saldos[origem] = round(saldos[origem] - valor, 2)
        if destino:
            saldos[destino] = round(saldos[destino] + valor, 2)
        return True

    # Deposito inicial de cada conta
    for c in CONTAS:
        cid, _, _, tipo, abertura, status, cli = c
        if status != "ativa":
            continue
        valor = 1200.00 if tipo == "poupanca" else RND.choice([900.00, 1500.00, 2000.00, 2500.00])
        add(None, cid, "pix_recebido", valor,
            datetime(abertura.year, abertura.month, abertura.day, 10, 0),
            "Abertura de conta - deposito inicial")

    # Ciclo mensal das contas de movimento: salario, contas, compras, rendimento
    for c in CONTAS:
        cid, _, _, tipo, abertura, status, cli = c
        if status != "ativa" or tipo == "poupanca":
            continue
        renda = CLIENTES[cli - 1][8]
        entrada = max(renda, 950.00)
        inicio = max(abertura, date(2026, 7, 1))
        mes = date(inicio.year, inicio.month, 1)
        while mes <= date(2026, 11, 1):
            dia_pg = 5
            if date(mes.year, mes.month, dia_pg) < inicio:
                mes = date(mes.year + (mes.month == 12), (mes.month % 12) + 1, 1)
                continue
            add(None, cid, "pix_recebido", entrada,
                datetime(mes.year, mes.month, dia_pg, 8, 30),
                "Credito de salario/bolsa de estudos")
            add(cid, None, "boleto", round(entrada * 0.28, 2),
                datetime(mes.year, mes.month, 10, 9, 15),
                "Pagamento de boleto - aluguel e contas")
            for _ in range(RND.randint(1, 3)):
                dia = RND.randint(11, 27)
                valor = round(RND.uniform(28, 210), 2)
                add(cid, None, "compra_debito", valor,
                    datetime(mes.year, mes.month, dia, RND.randint(11, 22), RND.randint(0, 59)),
                    RND.choice(["Supermercado", "Farmacia", "Cafe", "Transporte por app",
                                "Livraria", "Cinema", "Restaurante"]),
                    cartao=cartao_debito.get(cid))
            if cid in cartao_credito:
                cartao = cartao_credito[cid]
                for _ in range(1):
                    valor = round(RND.uniform(60, 220), 2)
                    if limite[cartao] - valor < 0:
                        continue
                    limite[cartao] = round(limite[cartao] - valor, 2)
                    add(cid, None, "compra_credito", valor,
                        datetime(mes.year, mes.month, RND.randint(6, 28), 20, 15),
                        RND.choice(["E-commerce", "Streaming anual", "Curso online",
                                    "Passagem aerea", "Loja de eletronicos"]),
                        cartao=cartao)
            if saldos[cid] > 0:
                rend = round(saldos[cid] * RND.uniform(0.0075, 0.0092), 2)
                add(None, cid, "rendimento", rend,
                    datetime(mes.year, mes.month, 28, 23, 59),
                    "Rendimento automatico 100% CDI")
            mes = date(mes.year + (mes.month == 12), (mes.month % 12) + 1, 1)

    # Transferencias Pix internas: uma linha com conta de origem e de destino,
    # movimentando as duas contas ao mesmo tempo.
    transferencias = [
        (1, 3, 150.00, datetime(2026, 9, 15, 12, 5), "Pix - divisao do aluguel"),
        (3, 1, 75.00, datetime(2026, 9, 16, 18, 40), "Pix - reembolso de jantar"),
        (2, 6, 320.00, datetime(2026, 10, 3, 9, 12), "Pix - ingressos do show"),
        (9, 4, 200.00, datetime(2026, 10, 21, 16, 30), "Pix - presente de aniversario"),
        (4, 12, 1000.00, datetime(2026, 10, 25, 11, 0), "Pix - aporte na poupanca"),
        (7, 2, 90.00, datetime(2026, 11, 6, 20, 10), "Pix - rateio da viagem"),
    ]
    for origem, destino, valor, dt, desc in transferencias:
        add(origem, destino, "pix_enviado", valor, dt, desc)

    # Movimentacoes com outros status (nao afetam o saldo)
    add(2, None, "pix_enviado", 480.00, datetime(2026, 11, 14, 15, 20),
        "Pix - compra de ingresso (aguardando liquidacao)", status="pendente")
    add(9, None, "compra_debito", 1290.00, datetime(2026, 11, 11, 10, 0),
        "Compra cancelada pelo estabelecimento", status="cancelada",
        cartao=cartao_debito.get(9))

    transacoes.sort(key=lambda t: t["dt"])
    for i, t in enumerate(transacoes, start=1):
        t["id"] = i

    # Limite disponivel = limite total - compras no credito concluidas
    gasto = {}
    for t in transacoes:
        if t["tipo"] == "compra_credito" and t["status"] == "concluida":
            gasto[t["cartao"]] = round(gasto.get(t["cartao"], 0) + t["valor"], 2)
    for i, c in enumerate(CARTOES):
        cid, total = c[0], c[4]
        disp = round(total - gasto.get(cid, 0), 2)
        assert disp >= 0, f"limite estourado no cartao {cid}: {disp}"
        CARTOES[i] = c[:5] + (disp,) + c[6:]
    return transacoes, saldos, limite


# --------------------------------------------------------------------------
# PARCELAS
# --------------------------------------------------------------------------
def gerar_parcelas():
    parcelas = []
    pid = 1
    # (id_emprestimo, pagas, vencidas_nao_pagas?) -> status derivado
    config = {
        1: {"pagas": 5, "venc_base": date(2026, 6, 10)},
        2: {"pagas": 8, "venc_base": date(2026, 3, 5)},
        3: {"pagas": 2, "venc_base": date(2026, 8, 20)},
        4: {"pagas": 12, "venc_base": date(2025, 11, 12)},
    }
    hoje = date(2026, 11, 16)
    for e in EMPRESTIMOS:
        eid, principal, taxa, prazo = e[0], e[1], e[2], e[3]
        if eid not in config:
            continue
        cfg = config[eid]
        valor = pmt(principal, taxa, prazo)
        for k in range(1, prazo + 1):
            venc = date(cfg["venc_base"].year + (cfg["venc_base"].month - 1 + k - 1) // 12,
                        (cfg["venc_base"].month - 1 + k - 1) % 12 + 1,
                        cfg["venc_base"].day)
            if k <= cfg["pagas"]:
                status = "paga"
                pagto = venc
            elif venc < hoje:
                status = "atrasada"
                pagto = None
            else:
                status = "aberta"
                pagto = None
            parcelas.append((pid, k, valor, venc, pagto, status, eid))
            pid += 1
    return parcelas


TRANSACOES, SALDOS, LIMITES = gerar()
PARCELAS = gerar_parcelas()
