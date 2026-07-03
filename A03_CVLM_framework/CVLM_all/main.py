import ttkbootstrap as ttk
from gui import CVLMGUI


def main():
    root = ttk.Window(themename="flatly")
    app = CVLMGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
