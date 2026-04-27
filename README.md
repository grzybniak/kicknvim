# Kick'N'Vim

it is a fork of [IstiCusi/kicknvim](https://github.com/IstiCusi/kicknvim) project

> Assemble like it's 1985 – but with modern Neovim powers.

**Kick'N'Vim** is a Neovim plugin that gives you everything you need to write, build, and run [KickAssembler](http://theweb.dk/KickAssembler/) projects for the C64 – all from inside Neovim. If you’re tired of VSCode or other heavyweight environments and prefer fast, focused, keyboard-driven workflows, this one’s for you.

<p align="center">
  <img src="media/logo.png" alt="Kick'N'Vim Logo" width="400"/>
</p>

---

## ✨ Features

* 🎨 Syntax highlighting for `_k.asm` files or by using `:set filetype=kickass`
* 🧠 Buffer-local keymaps for assembling and running code
* 🏃 Integration with [VICE](https://vice-emu.sourceforge.io/) to launch compiled `.prg` files
* 🚀 Complete 6502 assembler man pages included
* 🔧 Fully configurable with sane defaults
* 💥 Commands:

  * `:KickAssemble` → Assemble current file with KickAssembler
  * `:KickRun` → Launch compiled PRG in x64

---

## 🛠 Installation (Lazy.nvim)

```lua
return {
  "grzybniak/kicknvim",
  name = "kicknvim",
  lazy = true,
  ft = "kickass",
  config = function()
    require("kicknvim").setup({
      kickass_path = "/Applications/KickAssembler/KickAss.jar", -- or "kickass" if using a wrapper
      kickman_man = true,
      x64_path = "/Applications/vice-arm64-gtk3-3.10/bin/x64sc", -- path to your VICE binary
      -- install debugger from https://github.com/slajerek/RetroDebugger/releases
      retro_debugger = "/Applications/Retro Debugger.app/Contents/MacOS/Retro Debugger", -- path to Retro Debugger
      keys = {
        assemble = "<leader>ka",
        run = "<leader>kr",
        libinstall = "<leader>kl",
        debug = "<leader>kd",
      },
    })
  end,
}
```

The plugin will only activate for buffers with `filetype=kickass`.

---

## ⚙ Configuration Options

| Option           | Description                                  | Default                    |
| ---------------- | -------------------------------------------- | -------------------------- |
| `kickass_path`   | Path to `KickAss.jar` or a wrapper script    | `"kickass"`                |
| `x64_path`       | Path to your VICE emulator binary (x64)      | `"x64"`                    |
| `keys`           | Table with `assemble` and `run` key mappings | `<leader>ka`, `<leader>kr` |
| `kickass_man`    | Installation or Deinstallation of man pages  | `false`                    |
| `retro_debugger` | Path to your Retru Debugger installation     | `Retro Debugger`           |

You can redefine keybindings, use your own emulator, or point to another version of KickAssembler if needed.

---

## 🚀 Usage

Open your `_k.asm` file. Make sure it triggers the filetype `kickass`.

 - Press `<leader>ka` to assemble it using KickAssembler.
 - Press `<leader>kr` to run the output `.prg` in VICE (x64).
 - Press (typically) `K` to show the man page for the instruction below the cursor.
 - Press `<leader>kd` to run the output `.prg` in Retrto Debugger.

Shortcut:
 - Press ctrl+k to run KiskAssembler + Deugger at once

<p align="center">
  <img src="media/example.png" alt="Kick'N'Vim Example" width="800"/>
</p>

---

## 🔎 Requirements

* [KickAssembler 5.25](http://theweb.dk/KickAssembler/) (this version assumed as baseline)
* Java (for running KickAss.jar)
* [VICE emulator](https://vice-emu.sourceforge.io/) with `x64` in your PATH or specified manually
* [RetroDebugger](https://github.com/slajerek/RetroDebugger)
* [man-db] - mandb

Lua script is installing manuals in a custom dir.
Add path to your custom man path to `/etc/manpaths` or update env `MANPATH=`

---

## 🛍 Roadmap

We’re just getting started. Planned features:

* 🧠 C64 memory layout visualization (zero page, heap, ROM/RAM boundaries)
* 🎯 In-editor breakpoints without `.break` pseudo-op (via integration)
* 🛠 Project templating and helpers for BASIC loaders, IRQ setup, and more

---

## 🙏 Credits

Huge thanks to:

* **Jesper Gravgaard**, creator of KickAssembler – one of the most powerful 6510 assemblers ever made.
* The **VICE team**, for keeping the C64 alive and emulated across decades.

Kick'N'Vim is just a humble bridge between these brilliant tools and the Neovim world.

---

## 👋 For Who?

If you:

* ❤️ Neovim
* 📂 Grew up with (or discovered) the C64
* 💥 Prefer fast, focused tooling over GUIs
* 🧱 Want full control over your assembly workflow

...then this plugin is for you.

---

Happy hacking – and remember: real coders `JSR $1000` instead of clicking buttons.

