#!/usr/bin/env python3
"""Copy prompt to clipboard with template variable substitution.
Reads prompt from stdin. If it contains {{ varname }} placeholders,
prompts for all values, renders the template, and prints.
Uses tkinter if available (run setup_env.sh); falls back to AppleScript otherwise."""
import re
import sys

try:
    import tkinter as tk
    from tkinter import ttk
    HAS_TK = True
except ImportError:
    HAS_TK = False


def show_variable_dialog_tk(vars_ordered):
    """Show a dialog with a separate labeled field for each variable. Returns dict or None if cancelled."""
    result = {}

    def on_ok():
        for i, name in enumerate(vars_ordered):
            result[name] = entries[i].get()
        root.quit()
        root.destroy()

    def on_cancel():
        result.clear()
        root.quit()
        root.destroy()

    root = tk.Tk()
    root.title('Prompteria: Template Variables')
    root.resizable(True, False)
    root.attributes('-topmost', True)

    root.update_idletasks()
    w, h = 440, 50 + len(vars_ordered) * 52
    root.geometry(f'{w}x{min(h, 450)}+{root.winfo_screenwidth()//2 - w//2}+{root.winfo_screenheight()//2 - min(h, 450)//2}')

    main = ttk.Frame(root, padding=16)
    main.pack(fill=tk.BOTH, expand=True)

    entries = []
    for name in vars_ordered:
        row = ttk.Frame(main)
        row.pack(fill=tk.X, pady=(0, 10))
        label = ttk.Label(row, text=f'{name}:')
        label.pack(anchor=tk.W)
        entry = ttk.Entry(row, width=50)
        entry.pack(fill=tk.X, pady=(2, 0))
        entry.bind('<Return>', lambda e: on_ok())
        entries.append(entry)

    btn_frame = ttk.Frame(main)
    btn_frame.pack(fill=tk.X, pady=(12, 0))
    ttk.Button(btn_frame, text='Cancel', command=on_cancel).pack(side=tk.RIGHT, padx=(8, 0))
    ttk.Button(btn_frame, text='OK', command=on_ok).pack(side=tk.RIGHT)

    root.protocol('WM_DELETE_WINDOW', on_cancel)
    root.after(50, lambda: (root.lift(), root.attributes('-topmost', True), entries[0].focus_set()))
    root.mainloop()

    return result if result else None


def show_variable_dialog_osascript(vars_ordered):
    """Fallback: one AppleScript dialog per variable (may not appear when run from Alfred)."""
    import subprocess
    def esc(s):
        return s.replace('\\', '\\\\').replace('"', '\\"')
    values = {}
    for name in vars_ordered:
        script = f'''display dialog "Enter value for {esc(name)}:" default answer "" with title "Prompteria: {esc(name)}" with icon note buttons {{"Cancel", "OK"}} default button "OK"
if button returned of result is "Cancel" then return "CANCEL"
return text returned of result'''
        result = subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
        if result.returncode != 0:
            return None
        if result.stdout.strip() == 'CANCEL':
            return None
        values[name] = result.stdout.strip()
    return values


def main():
    try:
        prompt = sys.stdin.read()
    except Exception:
        prompt = ''
    if not prompt:
        print("ERROR: No prompt received. Check workflow connection.", end='')
        sys.exit(1)

    pattern = r'\{\{\s*([^}]+)\s*\}\}'
    matches = re.findall(pattern, prompt)
    vars_ordered = []
    seen = set()
    for m in matches:
        name = m.strip()
        if name and name not in seen:
            seen.add(name)
            vars_ordered.append(name)

    if not vars_ordered:
        print(prompt, end='')
        return

    try:
        values = show_variable_dialog_tk(vars_ordered) if HAS_TK else show_variable_dialog_osascript(vars_ordered)
    except Exception:
        # Dialog failed; output original prompt so user gets something
        print(prompt, end='')
        return
    if values is None:
        sys.exit(0)

    def replacer(m):
        name = m.group(1).strip()
        return values.get(name, m.group(0))

    rendered = re.sub(pattern, replacer, prompt)
    print(rendered, end='')


if __name__ == '__main__':
    main()
