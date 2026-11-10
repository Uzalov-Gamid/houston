#!/usr/bin/env python3
# Тест «Obsidian в терминале»: показывает палитру и раскладку ролей
# прямо в Ghostty (truecolor). Ничего не меняет в конфигах.
# Запуск: python3 ~/.config/palette/test/preview.py

P = {
    "paper": "#f8f1e3", "cream": "#f1ead8", "linen": "#e6dcc6", "sand": "#d6c8ab", "dune": "#c9b99c",
    "ink": "#2a1f1b", "espresso": "#3b2c26", "night": "#1c1513",
    "stone": "#6e6155", "slate": "#56616b", "ash": "#8f8276",
    "ember": "#b4541b", "flame": "#e08a4c", "peach": "#f0c9a0", "rust": "#b0381a",
    "mustard": "#765500", "gold": "#8c6a12", "brass": "#c49a3a", "butter": "#f2dc8f",
    "emerald": "#1f6b5c", "pine": "#134b40", "glow": "#7daea3", "mint": "#cfe3d6", "olive": "#5d6a1c",
    "navy": "#1e3a5f", "blue": "#24578f", "sky": "#2f64a0", "mist": "#c9dbe8",
    "tan": "#87562f",
}
# тёмный синтаксис с блоков кода Obsidian (на night)
D = {"fg": "#e3dccb", "comment": "#8f857a", "func": "#e5c15a", "kw": "#7daea3", "op": "#98c4ba",
     "prop": "#c49a3a", "punct": "#a18f80", "str": "#b5b07a", "tag": "#8aa1b8", "val": "#ef8f4c", "imp": "#f07a52"}
# старые цвета терминала (nvim/colors/palette.lua, tmux/theme-light.conf)
OLD = {"blue": "#2b6b60", "steel": "#3d5878", "yellow": "#876100", "grey": "#76695d", "dim": "#a18f80"}


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def fg(h): return "\033[38;2;%d;%d;%dm" % rgb(h)
def bg(h): return "\033[48;2;%d;%d;%dm" % rgb(h)


R, B, I = "\033[0m", "\033[1m", "\033[3m"
W = 74


def mix(c, a, base):
    f, b = rgb(c), rgb(base)
    return "#%02x%02x%02x" % tuple(round(f[i] * a + b[i] * (1 - a)) for i in range(3))


def line(base, *parts, width=W):
    """Строка на фоне base: parts = (цвет, текст[, стиль])."""
    out, n = bg(base), 0
    for p in parts:
        style = p[2] if len(p) > 2 else ""
        out += style + fg(p[0]) + p[1] + R + bg(base)
        n += len(p[1])
    return out + " " * max(0, width - n) + R


def title(t):
    print()
    print(line(P["cream"], (P["navy"], f" ── {t} ", B)))


page = P["cream"]

# ── 1. Палитра ─────────────────────────────────────────────────────────
title("1. Палитра")
groups = [["paper", "cream", "linen", "sand", "dune"], ["ink", "espresso", "night", "stone", "slate", "ash"],
          ["ember", "flame", "peach", "rust"], ["mustard", "gold", "brass", "butter"],
          ["emerald", "pine", "glow", "mint", "olive"], ["navy", "blue", "sky", "mist", "tan"]]
for g in groups:
    row = ""
    for n in g:
        h = P[n]
        txt = P["ink"] if sum(rgb(h)) > 450 else P["paper"]
        row += bg(h) + fg(txt) + f" {n:<8}{h} " + R + " "
    print(row)

# ── 2. Код на кремовом: сейчас vs Obsidian ────────────────────────────
title("2. Код в Neovim: сейчас → как в Obsidian")
code = [  # (роль, текст) — роль раскрашивается по-разному в двух вариантах
    [("kw", "local "), ("fn", "function "), ("fnname", "deploy"), ("p", "("), ("param", "host"), ("p", ", "), ("param", "port"), ("p", ")")],
    [("cm", "  -- проверить, что nginx отвечает")],
    [("kw", "  if "), ("v", "port "), ("op", "== "), ("num", "80 "), ("kw", "then")],
    [("v", "    "), ("mod", "log"), ("p", "."), ("fnname", "info"), ("p", "("), ("str", '"browser → nginx"'), ("p", ")")],
    [("kw", "    return "), ("bi", "self"), ("p", ":"), ("fnname", "proxy"), ("p", "{ "), ("prop", "api "), ("op", "= "), ("num", "9000"), ("p", " }")],
    [("kw", "  end")],
    [("typ", "  ---@type "), ("typ2", "Error"), ("esc", "  \\n escape")],
]
old = {"kw": OLD["blue"], "fn": OLD["blue"], "fnname": OLD["yellow"], "p": OLD["dim"], "param": P["ink"], "cm": OLD["grey"],
       "v": P["ink"], "op": OLD["steel"], "num": P["ember"], "mod": OLD["steel"], "str": P["olive"], "bi": P["tan"],
       "prop": P["ink"], "typ": OLD["grey"], "typ2": OLD["steel"], "esc": P["rust"]}
new = {"kw": P["emerald"], "fn": P["emerald"], "fnname": P["mustard"], "p": P["ash"], "param": P["espresso"], "cm": P["stone"],
       "v": P["ink"], "op": P["sky"], "num": P["ember"], "mod": P["navy"], "str": P["olive"], "bi": P["tan"],
       "prop": P["pine"], "typ": P["stone"], "typ2": P["navy"], "esc": P["rust"]}
half = W // 2 - 1


def render(row, cmap, base, width):
    out, n = bg(base), 0
    for role, t in row:
        st = I if role in ("cm", "bi", "param") else ""
        out += st + fg(cmap[role]) + t + R + bg(base)
        n += len(t)
    return out + " " * max(0, width - n) + R


print(line(page, (P["stone"], " сейчас"), width=half) + "  " + line(page, (P["ember"], " Obsidian-вариант", B), width=half))
for row in code:
    print(render(row, old, page, half) + "  " + render(row, new, page, half))

# ── 3. Блок night — как карточка кода в Obsidian ───────────────────────
title("3. Тёмная карточка night (всплывающие окна, fzf, lazygit, preview)")
night = P["night"]
card = [
    [],
    [(D["fg"], "  браузер ──▸  nginx  ──┬──▸ "), (D["func"], "программа-сайт"), (D["punct"], "  (порт "), (D["val"], "8080"), (D["punct"], ")")],
    [(D["fg"], "               "), (D["comment"], "порт 80"), (D["fg"], "  └──▸ "), (D["func"], "программа-API"), (D["punct"], "   (порт "), (D["val"], "9000"), (D["punct"], ")")],
    [],
    [(D["kw"], "  server "), (D["punct"], "{ "), (D["prop"], "listen "), (D["val"], "80"), (D["punct"], "; "), (D["prop"], "proxy_pass "), (D["str"], "http://api:9000"), (D["punct"], "; }")],
    [(D["comment"], "  # комментарий, "), (D["tag"], "<tag>"), (D["op"], " => "), (D["imp"], "!important")],
    [],
]
for row in card:
    print(" " + line(night, *row, width=W - 2))

# ── 4. Панель tmux ─────────────────────────────────────────────────────
title("4. Панель tmux: сейчас → как в Obsidian")
L, Rc = "", ""


def pill(color, text, txt, base=page):
    return bg(base) + fg(color) + L + bg(color) + fg(txt) + B + text + R + bg(base) + fg(color) + Rc + R + bg(base)


now = (bg(page) + pill(OLD["blue"], " main ", P["cream"]) + " " + fg(OLD["dim"]) + "1 " + fg(OLD["grey"]) + "nvim " +
       pill(P["sand"], "2 git", P["ink"]) + " " + fg(OLD["dim"]) + "3 " + fg(OLD["grey"]) + "zsh" + bg(page) + " " * 14 +
       pill(P["linen"], "  nginx ", P["ink"]) + " " + pill(P["linen"], "  main ", P["olive"]) + R)
obs = (bg(page) + pill(P["emerald"], " main ", P["paper"]) + " " + fg(P["ash"]) + "1 " + fg(P["stone"]) + "nvim " +
       pill(P["peach"], "2 git", P["ink"]) + " " + fg(P["ash"]) + "3 " + fg(P["stone"]) + "zsh" + bg(page) + " " * 14 +
       pill(P["night"], "  nginx ", D["fg"]) + " " + pill(P["mint"], "  main ", P["pine"]) + R)
print(line(page, (P["stone"], " сейчас")))
print(now)
print(line(page, (P["ember"], " Obsidian-вариант: активное окно — peach, папка — night, ветка — как тег (pine на mint)", B)))
print(obs)

# ── 5. Дерево файлов ───────────────────────────────────────────────────
title("5. Дерево файлов (nvim-tree, yazi) — иконки как в Obsidian")
tree = [
    (P["ember"], " ", "Learning/", P["ink"], B),
    (P["emerald"], "   ", "Arabic/", P["espresso"], ""),
    (P["ember"], "   ", "DevOps/", P["espresso"], ""),
    (P["stone"], "     ", "README.md", P["ink"], ""),
    (P["ember"], "     ", "nginx.md", P["ink"], B),  # активный
    (P["rust"], "     ", "linux-book.pdf", P["ink"], ""),
    (P["tan"], "     ", "schema.png", P["ink"], ""),
    (P["sky"], "     ", "map.canvas", P["ink"], ""),
    (P["navy"], "     ", "tasks.base", P["ink"], ""),
]
for ic, pre, name, col, st in tree:
    is_active = name == "nginx.md"
    base = mix(P["ember"], .15, P["linen"]) if is_active else P["linen"]
    print(line(base, (ic, pre), (col, name, st), width=40))

# ── 6. Markdown: заголовки и блоки ─────────────────────────────────────
title("6. Markdown (render-markdown в nvim, glow): лесенка заголовков и callouts")
paper = P["paper"]
for col, txt in [(P["navy"], "# H1 Заголовок заметки"), (P["pine"], "## H2 Раздел"), (P["gold"], "◆ H3 Подраздел"),
                 (P["ember"], "#### H4 ПУНКТ"), (P["tan"], "##### H5 мелкий"), (P["stone"], "###### H6 служебный")]:
    print(line(paper, (col, " " + txt, B)))
print(line(paper, (P["brass"], " ▌"), (P["tan"], "Цитата: полоса brass, текст tan")))
print(line(paper, (P["ink"], " Текст с "), (P["emerald"], "[[ссылкой]]"), (P["ink"], ", "), (P["sky"], "внешней ссылкой"),
           (P["ink"], ", "), (P["rust"], "`кодом`"), (P["ink"], " и "), (P["espresso"], "жирным", B), (P["ink"], ".")))
print(bg(paper) + " " + bg(P["mint"]) + fg(P["pine"]) + " #devops " + bg(paper) + " " + bg(P["butter"]) + fg(P["ink"]) +
      " ==выделение== " + bg(paper) + " " * (W - 26) + R)
print(line(paper, width=W))
callouts = [("note", "#24578f", "", "Заметка"), ("tip", "#1f6b5c", "", "Совет"),
            ("question", "#8c6a12", "", "Проверка себя"), ("warning", "#b4541b", "", "Ловушка"),
            ("fail", "#b0381a", "", "Ошибка"), ("summary", "#56616b", "", "Итог")]
for name, c, icon, label in callouts:
    print(line(mix(c, .07, paper), (mix(c, .85, paper), "▌ "), (c, f"{icon}  {label}", B), (P["ink"], f"  — callout {name}")))

# ── 7. ANSI-слоты: сейчас vs предложение ──────────────────────────────
title("7. ANSI-цвета терминала (ls, git, утилиты без своей темы)")
ansi_now = ["#2a1f1b", "#b0381a", "#5d6a1c", "#765500", "#2b6b60", "#87562f", "#24578f", "#d6c8ab",
            "#6e6155", "#b8401e", "#586a10", "#7f5c00", "#1f6b5c", "#8e5a32", "#2f64a0", "#e6dcc6"]
ansi_new = ["#2a1f1b", "#b0381a", "#5d6a1c", "#765500", "#2f64a0", "#87562f", "#1f6b5c", "#56616b",
            "#6e6155", "#b4541b", "#134b40", "#8c6a12", "#1e3a5f", "#3b2c26", "#24578f", "#8f8276"]
names = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
for lbl, a in (("сейчас ", ansi_now), ("вариант", ansi_new)):
    for half_ in (0, 8):
        row = bg(page) + fg(P["stone"]) + f" {lbl if half_ == 0 else ' ' * 7} " + R
        for i in range(half_, half_ + 8):
            row += bg(page) + fg(a[i]) + B + f"{i:>2}{names[i % 8][:3]} " + R
        print(row + bg(page) + " " * (W - 9 - 56) + R)
print()
