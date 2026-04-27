local kicknvim = require("kicknvim")

vim.api.nvim_create_user_command("KickAssemble", kicknvim.assemble_current_file, {})
vim.api.nvim_create_user_command("KickDebug", kicknvim.run_debug_prg, {})
vim.api.nvim_create_user_command("KickRun", kicknvim.run_prg, {})
vim.api.nvim_create_user_command("KickReadKSMan", kicknvim.open_kmanual, {})
vim.api.nvim_create_user_command("KickReadc64lib", kicknvim.open_libmanual, {})
vim.api.nvim_create_user_command("KickInstallLibs", kicknvim.install_or_update_libs, {})

-- Keymaps
vim.keymap.set("n", "<C-k>", kicknvim.assemble_and_debug)
