"""
PDF Position Editor
- العربي صح (arabic_reshaper + bidi)
- slider لحجم الخط لكل عنصر
- نفس الخط والحجم والألوان من Flutter
"""

import tkinter as tk
from tkinter import ttk
from PIL import Image, ImageTk, ImageFont, ImageDraw
import os, sys

# ── تثبيت المكتبات المطلوبة تلقائياً ─────────────────────────────────────────
def _ensure(pkg, import_name=None):
    import importlib
    try:
        importlib.import_module(import_name or pkg)
    except ImportError:
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", pkg])

_ensure("arabic_reshaper")
_ensure("python-bidi", "bidi")

import arabic_reshaper
from bidi.algorithm import get_display

def fix_arabic(text):
    """تصحيح اتجاه النص العربي"""
    return get_display(arabic_reshaper.reshape(text))

# ─── A4 ───────────────────────────────────────────────────────────────────────
PAGE_W_MM = 210.0
PAGE_H_MM = 297.0

BG_IMAGE_PATH = "assets/images/to-pdf.png"
FONT_REGULAR  = "assets/fonts/cairo/Cairo-Regular.ttf"
FONT_BOLD     = "assets/fonts/cairo/Cairo-Bold.ttf"

# ─── العناصر — نفس القيم من Flutter ──────────────────────────────────────────
ITEMS = [
    {"label": "date-month (شهر + سنة)", "sample": "شهر مايو لسنة 2026",
     "x": 93.5,  "y": 35.6,  "fontSize": 16, "bold": True,  "color": "#CBA175"},
    {"label": "date (تاريخ)",            "sample": "2026/05/25",
     "x": 175.0, "y": 35.2,  "fontSize": 15, "bold": True,  "color": "#CBA175"},
    {"label": "price (الإجمالي)",        "sample": "15000 جنيه",
     "x": 107.1, "y": 114.4, "fontSize": 33, "bold": True,  "color": "#CBA175"},
    {"label": "client-count (عدد العملاء)", "sample": "42",
     "x": 37.4,  "y": 113.2, "fontSize": 27, "bold": True,  "color": "#CBA175"},
]

HANDLE_COLORS = ["#e74c3c", "#2980b9", "#27ae60", "#8e44ad"]

def hex_to_rgba(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (255,)


class PdfPositionEditor:
    def __init__(self, root):
        self.root = root
        self.root.title("PDF Position Editor")

        if not os.path.exists(BG_IMAGE_PATH):
            tk.messagebox.showerror("خطأ", f"مش لاقي:\n{BG_IMAGE_PATH}")
            root.destroy()
            return

        orig = Image.open(BG_IMAGE_PATH).convert("RGBA")
        screen_h = min(root.winfo_screenheight() - 160, 860)
        self.scale    = screen_h / PAGE_H_MM
        self.canvas_w = int(PAGE_W_MM * self.scale)
        self.canvas_h = screen_h

        bg = orig.resize((self.canvas_w, self.canvas_h), Image.LANCZOS)
        self.bg_photo = ImageTk.PhotoImage(bg)

        self._pil_fonts = {}
        self._tk_images = {}

        # ── Layout ────────────────────────────────────────────────────────────
        main = tk.Frame(root)
        main.pack(fill="both", expand=True, padx=8, pady=8)

        self.canvas = tk.Canvas(main, width=self.canvas_w, height=self.canvas_h,
                                bg="white", cursor="fleur")
        self.canvas.pack(side="left")
        self.canvas.create_image(0, 0, anchor="nw", image=self.bg_photo)

        # ── Panel جانبي ───────────────────────────────────────────────────────
        side = tk.Frame(main, width=300, bg="#f0f0f0")
        side.pack(side="left", fill="y", padx=(8, 0))
        side.pack_propagate(False)

        tk.Label(side, text="العناصر", font=("Arial", 13, "bold"),
                 bg="#f0f0f0").pack(pady=(10, 4))

        self.coord_vars    = []
        self.fontsize_vars = []   # IntVar لكل عنصر

        for i, item in enumerate(ITEMS):
            color = HANDLE_COLORS[i % len(HANDLE_COLORS)]
            fr = tk.LabelFrame(side, text=f"  {item['label']}  ",
                               fg=color, font=("Arial", 9, "bold"),
                               bg="#f0f0f0", padx=6, pady=4)
            fr.pack(fill="x", padx=6, pady=3)

            # إحداثيات
            cv = tk.StringVar(value=f"x={item['x']:.1f}  y={item['y']:.1f}")
            self.coord_vars.append(cv)
            tk.Label(fr, textvariable=cv, font=("Courier", 10),
                     bg="#f0f0f0", fg="#333").pack()

            # حجم الخط
            fv = tk.IntVar(value=item["fontSize"])
            self.fontsize_vars.append(fv)

            fs_row = tk.Frame(fr, bg="#f0f0f0")
            fs_row.pack(fill="x")
            tk.Label(fs_row, text="حجم الخط:", font=("Arial", 9),
                     bg="#f0f0f0").pack(side="left")
            tk.Label(fs_row, textvariable=fv, font=("Courier", 9, "bold"),
                     bg="#f0f0f0", width=3).pack(side="left")

            slider = ttk.Scale(fr, from_=6, to=60, orient="horizontal",
                               variable=fv,
                               command=lambda val, idx=i: self._on_fontsize(idx))
            slider.pack(fill="x")

        tk.Frame(side, bg="#f0f0f0").pack(expand=True)

        tk.Button(side, text="✅  Done — اطبع الإحداثيات",
                  font=("Arial", 11, "bold"), bg="#27ae60", fg="white",
                  relief="flat", padx=10, pady=8,
                  command=self.print_results).pack(fill="x", padx=6, pady=(0, 6))

        tk.Button(side, text="↺  Reset", font=("Arial", 10),
                  bg="#95a5a6", fg="white", relief="flat", padx=10, pady=6,
                  command=self.reset).pack(fill="x", padx=6, pady=(0, 10))

        # ── رسم العناصر ───────────────────────────────────────────────────────
        self.positions  = [[item["x"], item["y"]] for item in ITEMS]
        self.text_ids   = []
        self.handle_ids = []
        self._drag      = {"idx": None, "ox": 0, "oy": 0}

        for i in range(len(ITEMS)):
            tid = self.canvas.create_image(0, 0, anchor="nw")
            hid = self.canvas.create_oval(0, 0, 14, 14,
                                          fill=HANDLE_COLORS[i % len(HANDLE_COLORS)],
                                          outline="white", width=2,
                                          tags=("handle", f"h_{i}"))
            self.text_ids.append(tid)
            self.handle_ids.append(hid)
            self._render_text(i)

        self.canvas.tag_bind("handle", "<ButtonPress-1>",   self._on_press)
        self.canvas.tag_bind("handle", "<B1-Motion>",       self._on_drag)
        self.canvas.tag_bind("handle", "<ButtonRelease-1>", self._on_release)

    # ── helpers ───────────────────────────────────────────────────────────────
    def _pt_to_px(self, pt):
        return max(6, int(pt * self.scale * 25.4 / 72))

    def _get_font(self, idx):
        item    = ITEMS[idx]
        pt      = self.fontsize_vars[idx].get()
        path    = FONT_BOLD if item["bold"] else FONT_REGULAR
        size_px = self._pt_to_px(pt)
        key     = (path, size_px)
        if key not in self._pil_fonts:
            try:
                self._pil_fonts[key] = ImageFont.truetype(path, size_px)
            except Exception:
                self._pil_fonts[key] = ImageFont.load_default()
        return self._pil_fonts[key]

    def _render_text(self, idx):
        item  = ITEMS[idx]
        font  = self._get_font(idx)
        # تصحيح العربي
        text  = fix_arabic(item["sample"])
        color = hex_to_rgba(item["color"])

        dummy = Image.new("RGBA", (1, 1))
        bbox  = ImageDraw.Draw(dummy).textbbox((0, 0), text, font=font)
        tw = max(1, bbox[2] - bbox[0] + 4)
        th = max(1, bbox[3] - bbox[1] + 4)

        img = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
        ImageDraw.Draw(img).text((2, 2), text, font=font, fill=color)

        photo = ImageTk.PhotoImage(img)
        self._tk_images[idx] = photo

        px = self.positions[idx][0] * self.scale
        py = self.positions[idx][1] * self.scale

        self.canvas.itemconfig(self.text_ids[idx], image=photo)
        self.canvas.coords(self.text_ids[idx], px, py)
        self.canvas.coords(self.handle_ids[idx], px - 7, py - 7, px + 7, py + 7)
        self.canvas.tag_raise(self.handle_ids[idx])

    def _on_fontsize(self, idx):
        self._render_text(idx)

    # ── drag ──────────────────────────────────────────────────────────────────
    def _on_press(self, event):
        tags = self.canvas.gettags(self.canvas.find_closest(event.x, event.y))
        for tag in tags:
            if tag.startswith("h_"):
                self._drag.update({"idx": int(tag.split("_")[1]),
                                   "ox": event.x, "oy": event.y})
                return

    def _on_drag(self, event):
        idx = self._drag["idx"]
        if idx is None:
            return
        dx = (event.x - self._drag["ox"]) / self.scale
        dy = (event.y - self._drag["oy"]) / self.scale
        self._drag["ox"] = event.x
        self._drag["oy"] = event.y
        self.positions[idx][0] = round(self.positions[idx][0] + dx, 1)
        self.positions[idx][1] = round(self.positions[idx][1] + dy, 1)
        self._render_text(idx)
        self.coord_vars[idx].set(
            f"x={self.positions[idx][0]:.1f}  y={self.positions[idx][1]:.1f}")

    def _on_release(self, _):
        self._drag["idx"] = None

    # ── reset ─────────────────────────────────────────────────────────────────
    def reset(self):
        for i, item in enumerate(ITEMS):
            self.positions[i] = [item["x"], item["y"]]
            self.fontsize_vars[i].set(item["fontSize"])
            self._render_text(i)
            self.coord_vars[i].set(f"x={item['x']:.1f}  y={item['y']:.1f}")

    # ── done ──────────────────────────────────────────────────────────────────
    def print_results(self):
        print("\n" + "="*55)
        print("✅  انسخ في Flutter:")
        print("="*55)
        out = ""
        for i, item in enumerate(ITEMS):
            x, y = self.positions[i]
            fs   = self.fontsize_vars[i].get()
            line = f"// {item['label']}\n  x: {x},\n  y: {y},\n  fontSize: {fs},\n"
            print(line)
            out += line + "\n"
        print("="*55)

        win = tk.Toplevel(self.root)
        win.title("النتائج")
        win.configure(bg="#1e1e1e")
        tk.Label(win, text="انسخ في Flutter:",
                 font=("Arial", 12, "bold"), fg="white", bg="#1e1e1e").pack(pady=(10, 4))
        t = tk.Text(win, font=("Courier", 11), bg="#252526", fg="#9cdcfe",
                    width=50, height=len(ITEMS) * 5 + 2,
                    relief="flat", padx=10, pady=10)
        t.pack(padx=10, pady=(0, 6))
        t.insert("1.0", out)
        t.config(state="disabled")
        tk.Button(win, text="إغلاق", command=win.destroy,
                  bg="#27ae60", fg="white", relief="flat",
                  font=("Arial", 10), padx=20, pady=6).pack(pady=(0, 10))


# ─── Main ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    root = tk.Tk()
    root.resizable(False, False)
    PdfPositionEditor(root)
    root.mainloop()
