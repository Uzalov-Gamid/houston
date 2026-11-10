#!/usr/bin/env python3
# Макет «nvim в стиле Claude Code» + варианты prompt — в цветах Obsidian.
# Ничего не меняет. Запуск: python3 ~/.config/palette/test/nvim-preview.py
# Окно терминала — пошире (≥ 110 колонок).

P = {
    "paper": "#f8f1e3", "cream": "#f1ead8", "linen": "#e6dcc6", "sand": "#d6c8ab", "dune": "#c9b99c",
    "ink": "#2a1f1b", "espresso": "#3b2c26", "night": "#1c1513", "stone": "#6e6155", "slate": "#56616b",
    "ash": "#8f8276", "ember": "#b4541b", "flame": "#e08a4c", "peach": "#f0c9a0", "rust": "#b0381a",
    "mustard": "#765500", "gold": "#8c6a12", "brass": "#c49a3a", "butter": "#f2dc8f", "emerald": "#1f6b5c",
    "pine": "#134b40", "glow": "#7daea3", "mint": "#cfe3d6", "olive": "#5d6a1c", "navy": "#1e3a5f",
    "blue": "#24578f", "sky": "#2f64a0", "mist": "#c9dbe8", "tan": "#87562f",
    "sel": "#f1d4b9", "cardfg": "#e3dccb", "cardcm": "#8f857a", "cardfn": "#e5c15a", "cardkw": "#7daea3",
    "cardstr": "#b5b07a", "cardnum": "#ef8f4c", "cardpun": "#a18f80",
}


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


class Canvas:
    def __init__(self, w, h, bg):
        self.w, self.h = w, h
        self.c = [[[" ", P["ink"], bg, ""] for _ in range(w)] for _ in range(h)]

    def put(self, x, y, text, fg="ink", bg=None, st=""):
        for i, ch in enumerate(text):
            if 0 <= x + i < self.w and 0 <= y < self.h:
                cell = self.c[y][x + i]
                cell[0], cell[1], cell[3] = ch, P.get(fg, fg), st
                if bg:
                    cell[2] = P.get(bg, bg)
        return x + len(text)

    def runs(self, x, y, parts, bg=None):
        for p in parts:
            x = self.put(x, y, p[1], p[0], bg, p[2] if len(p) > 2 else "")
        return x

    def fill(self, x, y, w, h, bg):
        for j in range(y, y + h):
            for i in range(x, x + w):
                if 0 <= i < self.w and 0 <= j < self.h:
                    self.c[j][i] = [" ", P["ink"], P.get(bg, bg), ""]

    def box(self, x, y, w, h, color="glow", bg=None, title=None, footer=None, tcol="ember"):
        if bg:
            self.fill(x, y, w, h, bg)
        self.put(x, y, "╭" + "─" * (w - 2) + "╮", color, bg)
        for j in range(1, h - 1):
            self.put(x, y + j, "│", color, bg)
            self.put(x + w - 1, y + j, "│", color, bg)
        self.put(x, y + h - 1, "╰" + "─" * (w - 2) + "╯", color, bg)
        if title:
            self.put(x + 2, y, " " + title + " ", tcol, bg, "b")
        if footer:
            self.put(x + w - len(footer) - 4, y + h - 1, " " + footer + " ", "ash", bg)

    def show(self):
        out = []
        for row in self.c:
            s = ""
            for ch, fg, bg, st in row:
                f, b = rgb(fg), rgb(bg)
                s += "\033[0m" + ("\033[1m" if "b" in st else "") + ("\033[3m" if "i" in st else "") + \
                     ("\033[4m" if "u" in st else "") + "\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm" % (f + b) + ch
            out.append(s + "\033[0m")
        print("\n".join(out))


def heading(t):
    print("\n\033[1m\033[38;2;%d;%d;%dm  ── %s\033[0m\n" % (rgb(P["navy"]) + (t,)))


W = 108
L, R = "", ""

# ═════════════════════════════════════════════════════════════════════
heading("1. Редактор: тонкая строка состояния, хлебные крошки, дерево с ⎿, уведомление ⏺")
cv = Canvas(W, 24, P["cream"])
# winbar: breadcrumbs
cv.runs(30, 0, [("ash", "  astro-demo "), ("dune", "› "), ("ash", "src "), ("dune", "› "), ("emerald", " "),
                ("ink", "telemetry.c", "b"), ("ember", "  ●")])
# tree
cv.runs(1, 0, [("ember", " "), ("ember", "astro-demo", "")])
tree = [("emerald", "", ".github", "espresso", 1), ("ember", "", "src", "espresso", 1),
        ("navy", "", "telemetry.c", "ember", 2), ("slate", "", "telemetry.h", "ink", 2),
        ("sky", "", "compose.yaml", "ink", 1), ("sky", "", "Dockerfile", "ink", 1),
        ("ember", "", "Makefile", "ink", 1), ("stone", "", "README.md", "ink", 1)]
for i, (ic, icon, name, col, lvl) in enumerate(tree):
    y = 2 + i
    if name == "telemetry.c":
        cv.fill(1, y, 26, 1, "sel")
    guide = "  │ " if lvl == 2 else "  "
    cv.runs(1, y, [("dune", guide), (ic, icon + " "), (col, name)])
cv.put(28, 0, "│", "dune")
for y in range(1, 21):
    cv.put(28, y, "│", "dune")
# code
code = [
    [("emerald", "typedef struct "), ("ink", "{")],
    [("ink", "    "), ("emerald", "const "), ("navy", "char "), ("ink", "*"), ("pine", "name"), ("ash", ";")],
    [("ink", "    "), ("navy", "double "), ("pine", "value"), ("ash", ";")],
    [("ink", "} "), ("navy", "reading_t"), ("ash", ";")],
    [],
    [("emerald", "static "), ("navy", "double "), ("mustard", "average"), ("ash", "("), ("emerald", "const "),
     ("navy", "reading_t "), ("sky", "*"), ("espresso", "r", "i"), ("ash", ", "), ("navy", "int "), ("espresso", "n", "i"), ("ash", ") {")],
    [("ink", "    "), ("navy", "double "), ("ink", "sum "), ("sky", "= "), ("ember", "0.0"), ("ash", ";")],
    [("ink", "    "), ("emerald", "for "), ("ash", "("), ("navy", "int "), ("ink", "i "), ("sky", "= "), ("ember", "0"),
     ("ash", "; "), ("ink", "i "), ("sky", "< "), ("ink", "n"), ("ash", "; "), ("ink", "i"), ("sky", "++"), ("ash", ") {")],
    [("dune", "    │   "), ("ink", "sum "), ("sky", "+= "), ("ink", "r"), ("ash", "["), ("ink", "i"), ("ash", "]."), ("pine", "value"), ("ash", ";")],
    [("dune", "    "), ("ink", "}")],
    [("stone", "    // среднее по n замерам", "i")],
    [("ink", "    "), ("emerald", "return ", "b"), ("ink", "n "), ("sky", "> "), ("ember", "0 "), ("sky", "? "), ("ink", "sum "),
     ("sky", "/ "), ("ink", "n "), ("sky", ": "), ("ember", "0.0"), ("ash", ";")],
    [("ink", "}")],
    [],
    [("navy", "int "), ("mustard", "main"), ("ash", "("), ("navy", "void"), ("ash", ") {")],
    [("ink", "    "), ("mustard", "printf"), ("ash", "("), ("olive", '"avg %s: %.2f C'), ("rust", "\\n"), ("olive", '"'), ("ash", ", "),
     ("ink", "data"), ("ash", "["), ("ember", "0"), ("ash", "]."), ("pine", "name"), ("ash", ");")],
    [("ink", "    "), ("emerald", "return ", "b"), ("ember", "EXIT_SUCCESS"), ("ash", ";")],
    [("ink", "}")],
]
for i, row in enumerate(code):
    y = 2 + i
    n = i - 3
    cur = n == 0
    if cur:
        cv.fill(29, y, W - 29, 1, "linen")
    cv.put(30, y, ("%3d " % (abs(n) if not cur else 9)), "ember" if cur else "dune", None, "b" if cur else "")
    cv.runs(35, y, row)
# notification ⏺ (top right)
cv.box(W - 34, 1, 33, 4, "glow", "paper")
cv.runs(W - 32, 2, [("olive", "⏺ "), ("ink", "Записано "), ("ink", "telemetry.c", "b")])
cv.runs(W - 32, 3, [("dune", "  ⎿ "), ("ash", "18 строк · 0.4 КБ")])
# status line: thin, text-first
y = 22
cv.runs(1, y, [("emerald", "● "), ("emerald", "NORMAL", "b"), ("dune", "  ·  "), ("emerald", " "), ("ash", "src/"),
               ("ink", "telemetry.c", "b"), ("ember", " ●"), ("dune", "  ·  "), ("pine", " main")])
cv.runs(W - 30, y, [("ash", "c"), ("dune", "  ·  "), ("ash", "9:1"), ("dune", "  ·  "), ("ash", "33%"), ("dune", "  ·  "), ("ash", "? помощь")])
cv.put(0, 21, "─" * W, "dune")
cv.show()

# ═════════════════════════════════════════════════════════════════════
heading("2. Поиск файлов / командная палитра — карточка с заголовком и подсказками внизу")
cv = Canvas(W, 15, P["cream"])
for y in range(15):
    cv.put(2, y, "~", "linen")
cv.box(14, 1, 80, 13, "glow", "paper", title=" Найти файл", footer="↵ открыть · ⌃v сплит · esc закрыть")
cv.runs(17, 3, [("ember", "› "), ("ink", "tele"), ("ember", "▏")])
cv.runs(70, 3, [("ash", "3 / 41")])
cv.put(16, 4, "─" * 76, "linen")
items = [("navy", "", "src/", "tele", "metry.c", True), ("slate", "", "src/", "tele", "metry.h", False),
         ("stone", "", "docs/", "tele", "metry-notes.md", False)]
for i, (ic, icon, d, hit, rest, sel) in enumerate(items):
    y = 5 + i
    if sel:
        cv.fill(16, y, 76, 1, "peach")
    cv.runs(17, y, [("ember" if sel else "paper", "▍"), (ic, icon + " "), ("ash", d), ("ember", hit, "b"), ("ink", rest)])
cv.runs(17, 9, [("ash", "недавние")])
cv.runs(17, 10, [("tan", " "), ("ink", "assets/diagram.png")])
cv.runs(17, 11, [("ember", " "), ("ink", "Makefile")])
cv.show()

# ═════════════════════════════════════════════════════════════════════
heading("3. Режим чтения Markdown — свой рендер в nvim (вместо glow)")
cv = Canvas(W, 31, P["paper"])
x0 = 6
cv.runs(x0, 1, [("navy", "Telemetry", "b")])
cv.put(x0, 2, "━" * 40, "navy")
cv.runs(x0, 4, [("ink", "Маленький сервис на C, усредняет показания "), ("emerald", "датчиков", "u"), ("ink", " кабины.")])
cv.runs(x0, 6, [("pine", "Быстрый старт", "b")])
cv.put(x0, 7, "─" * 40, "brass")
# code card
cv.fill(x0, 9, 60, 5, "night")
cv.runs(x0 + 2, 9, [("cardcm", "bash")])
cv.runs(x0 + 2, 10, [("cardfn", "make"), ("cardfg", " "), ("cardkw", "&&"), ("cardfg", " ./telemetry "), ("cardpun", "--"), ("cardfg", "samples "), ("cardnum", "6")])
cv.runs(x0 + 2, 11, [("cardcm", "# среднее по 6 замерам", "i")])
cv.runs(x0 + 2, 12, [("cardfn", "echo"), ("cardfg", " "), ("cardstr", '"ok"')])
cv.runs(x0 + 50, 9, [("cardcm", "⧉ копия")])
cv.runs(x0, 15, [("gold", "◆ Возможности", "b")])
cv.runs(x0 + 2, 17, [("ember", "● "), ("ink", "читает "), ("rust", " SAMPLES "), ("ink", " значений за цикл")])
cv.put(x0 + 11, 17, " SAMPLES ", "rust", "linen")
cv.runs(x0 + 2, 18, [("ember", "● "), ("ink", "печатает "), ("espresso", "среднее", "b"), ("ink", " одной строкой")])
cv.runs(x0 + 4, 19, [("ember", "› "), ("tan", "вложенный пункт", "i")])
# callout tip
cv.fill(x0, 21, 60, 3, "#e9e8da")
for j in range(21, 24):
    cv.put(x0, j, "▌", "#407f70")
cv.runs(x0 + 2, 21, [("emerald", "  Совет", "b")])
cv.runs(x0 + 2, 22, [("ink", "команда "), ("rust", "make clean"), ("ink", " удаляет бинарник")])
cv.put(x0 + 10, 22, "make clean", "rust", "linen")
# table
cv.runs(x0, 25, [("ash", "ПОРТ    СЕРВИС       СТАТУС", "b")])
cv.put(x0, 26, "─" * 34, "sand")
cv.runs(x0, 27, [("ember", "8080"), ("ink", "    программа-сайт "), ("olive", "✓ up")])
cv.runs(x0, 28, [("ember", "9000"), ("ink", "    программа-API  "), ("rust", "✗ down")])
cv.runs(x0 + 70, 1, [("ash", "чтение · README.md")])
cv.runs(x0 + 70, 2, [("dune", "q назад · j/k листать")])
cv.runs(x0 + 70, 6, [("ash", "СОДЕРЖАНИЕ", "b")])
for i, (c, t) in enumerate([("ember", "● Быстрый старт"), ("ash", "○ Возможности"), ("ash", "○ Таблица портов")]):
    cv.runs(x0 + 70, 7 + i, [(c, t)])
cv.show()

# ═════════════════════════════════════════════════════════════════════
heading("4. Стартовый экран — карточка-приветствие, как у Claude Code")
cv = Canvas(W, 13, P["cream"])
cv.box(4, 1, 62, 9, "ember", None)
cv.runs(7, 2, [("ember", "✻ "), ("ink", "С возвращением, ", ""), ("ink", "Гамид", "b")])
cv.runs(7, 4, [("ash", "  ~/Documents/c-practice/stage-1")])
cv.runs(7, 5, [("ash", "  неделя: "), ("ember", "3ч 20м"), ("ash", " · c 48% · yaml 22%")])
cv.runs(7, 7, [("ash", "  "), ("ember", "f"), ("ash", " найти   "), ("ember", "r"), ("ash", " недавние   "), ("ember", "e"), ("ash", " дерево   "), ("ember", "q"), ("ash", " выйти")])
cv.runs(6, 11, [("dune", "  ※ "), ("ash", "Совет: "), ("stone", "Space p — режим чтения заметки")])
cv.show()

# ═════════════════════════════════════════════════════════════════════
heading("5. Prompt (fish / tide) — варианты")


def prompt(lines):
    cv = Canvas(W, len(lines), P["cream"])
    for y, row in enumerate(lines):
        if row and row[0] == "R":
            row = row[1:]
            right = row[-1]
            row = row[:-1]
            x = cv.runs(2, y, row)
            n = sum(len(p[1]) for p in right)
            cv.put(x + 1, y, "·" * max(0, W - 4 - n - x), "dune")
            cv.runs(W - 2 - n, y, right)
        else:
            cv.runs(2, y, row)
    cv.show()
    print()


print("  \033[38;2;110;97;85mА — как сейчас, но в цветах Obsidian\033[0m")
prompt([["R", ("emerald", "~/Documents/c-practice/", "b"), ("navy", "stage-1", "b"), ("pine", "   main"),
         [("ash", "")]], [("ember", "› ", "b")]])
print("  \033[38;2;110;97;85mБ — хлебные крошки как в Obsidian: иконка папки, ›, справа время и длительность\033[0m")
prompt([["R", ("emerald", " "), ("ash", "~ › Documents › c-practice › "), ("navy", "stage-1", "b"), ("dune", "  "),
         ("pine", " main"), ("mustard", " ●2"), [("ash", "3.2s"), ("dune", " · "), ("ash", "23:46")]], [("ember", "› ", "b")]])
print("  \033[38;2;110;97;85mВ — как Claude Code: прошлые команды сворачиваются в ⏺, текущая — в рамке\033[0m")
cv = Canvas(W, 7, P["cream"])
cv.runs(2, 0, [("olive", "⏺ "), ("ink", "make", "b"), ("ash", "  ~/c-practice/stage-1 · 1.4s")])
cv.runs(2, 1, [("rust", "⏺ "), ("ink", "./telemetry --bad", "b"), ("ash", "  · exit 1")])
cv.runs(2, 2, [("dune", "  ⎿ "), ("rust", "error: unknown flag --bad")])
cv.box(2, 3, W - 4, 3, "glow")
cv.runs(4, 3, [("ash", "  "), ("emerald", "c-practice/"), ("navy", "stage-1", "b"), ("pine", "  main "), ])
cv.runs(4, 4, [("ember", "› ", "b"), ("ink", "make clean"), ("ember", "▏")])
cv.runs(4, 6, [("ash", "  ? подсказки · ⌃r история · ⌃t файлы")])
cv.show()
print()
