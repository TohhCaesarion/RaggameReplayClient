import tkinter as tk
from tkinter import messagebox
import winreg

class RegistryToggleApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Quest Window")
        self.root.minsize(width=250, height=0)  # Set the minimum width

        self.registry_key_path = r"SOFTWARE\WOW6432Node\Gravity Soft\Ragnarok\UIRectInfo"
        self.value_name = "QUESTDISPWNDINFO.QUESTDISPLAY"

        self.value_var = tk.IntVar()
        self.value_var.set(self.get_current_value())

        self.radio_0 = tk.Radiobutton(root, text="Hide quest window", variable=self.value_var, value=0)
        self.radio_1 = tk.Radiobutton(root, text="Show quest window", variable=self.value_var, value=1)

        self.radio_0.pack()
        self.radio_1.pack()

        self.ok_button = tk.Button(root, text="OK", command=self.close_window)
        self.ok_button.pack()

    def close_window(self):
        self.toggle_value()
        self.root.destroy()

    def toggle_value(self):
        new_value = self.value_var.get()
        try:
            key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, self.registry_key_path, 0, winreg.KEY_SET_VALUE)
            winreg.SetValueEx(key, self.value_name, 0, winreg.REG_DWORD, new_value)
            winreg.CloseKey(key)
            messagebox.showinfo("Success", f"Registry value {self.value_name} toggled to {new_value}")
        except Exception as e:
            messagebox.showerror("Error", f"An error occurred: {e}")
            self.value_var.set(self.get_current_value())

    def get_current_value(self):
        try:
            key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, self.registry_key_path, 0, winreg.KEY_READ)
            current_value, _ = winreg.QueryValueEx(key, self.value_name)
            winreg.CloseKey(key)
            return current_value
        except Exception as e:
            messagebox.showerror("Error", f"An error occurred: {e}")
            return 0

if __name__ == "__main__":
    root = tk.Tk()
    app = RegistryToggleApp(root)
    root.mainloop()
