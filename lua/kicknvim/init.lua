local M = {}

-- ======================== PLUGIN FUNCTIONS ==============================
local config = {
	kickass_path = "~/C64-KickAssembler/KickAss.jar",
	x64_path = "~/C64-KickAssembler/x64",
	retro_debugger = "~/C64-KickAssembler/Retro Debugger",
	kickass_man = false,
	keys = {
		assemble = "<leader>ka",
		run = "<leader>kr",
		libinstall = "<leader>kl",
		debug = "<leader>kd",
	},
	repos = {
		"https://github.com/c64lib/common.git",
		"https://github.com/c64lib/chipset.git",
		"https://github.com/c64lib/text.git",
		"https://github.com/c64lib/copper64.git",
	},
}

function M.setup(opts)
	opts = opts or {}

	-- Konfiguration übernehmen
	config.kickass_path = opts.kickass_path or config.kickass_path
	config.x64_path = opts.x64_path or config.x64_path
	config.kickass_man = opts.kickass_man or config.kickass_man
	config.retro_debugger = opts.retro_debugger or config.retro_debugger

	if opts.keys then
		config.keys = vim.tbl_extend("force", config.keys, opts.keys)
	end

	-- Optional: manpages installieren/deinstallieren
	if opts.kickass_man ~= nil then
		local dst_dir = vim.fn.expand("~/.local/share/man/man99")
		local already_installed = vim.fn.glob(dst_dir .. "/*.99") ~= ""

		if opts.kickass_man == true and not already_installed then
			M.install_manpages()
		elseif opts.kickass_man == false and already_installed then
			M.uninstall_manpages()
		end
	end

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "kickass",
		callback = function(args)
			local keys = config.keys

			local qf = vim.fn.getqflist()
			if #qf > 0 then
				vim.notify("❌ Build failed (" .. #qf .. " errors)", vim.log.levels.ERROR)
				vim.cmd("copen")
			else
				vim.notify("✅ Build successful", vim.log.levels.INFO)
			end

			-- assemble with KickAss
			vim.keymap.set(
				"n",
				keys.assemble,
				M.assemble_current_file,
				{ buffer = args.buf, desc = "Assemble with KickAss" }
			)
			-- run prg with VICE
			vim.keymap.set("n", keys.run, M.run_prg, { buffer = args.buf, desc = "Run PRG with VICE" })

			-- debugger
			vim.keymap.set(
				"n",
				keys.debug,
				M.run_debug_prg,
				{ buffer = args.buf, desc = "Run PRG with Retro Debugger" }
			)

			if keys.libinstall then
				vim.keymap.set(
					"n",
					keys.libinstall,
					M.install_or_update_libs,
					{ buffer = args.buf, desc = "Install/Update KickAsm libraries" }
				)
			end
		end,
	})
end

function M.install_manpages()
	local plugin_path = vim.fn.stdpath("data") .. "/lazy/kicknvim"
	local src_dir = plugin_path .. "/manpages/man99"
	local dst_dir = vim.fn.expand("~/.local/share/man/man99")

	vim.fn.mkdir(dst_dir, "p")

	for _, file in ipairs(vim.fn.glob(src_dir .. "/*.99", false, true)) do
		local dest_file = dst_dir .. "/" .. vim.fn.fnamemodify(file, ":t")
		vim.fn.writefile(vim.fn.readfile(file), dest_file)
	end

	vim.fn.system({ "mandb", vim.fn.expand("~/.local/share/man") })
	vim.notify("KickNvim manpages installed", vim.log.levels.INFO)
end

function M.uninstall_manpages()
	local dst_dir = vim.fn.expand("~/.local/share/man/man99")
	local files = vim.fn.glob(dst_dir .. "/*.99", false, true)

	for _, file in ipairs(files) do
		vim.fn.delete(file)
	end

	if vim.fn.empty(vim.fn.glob(dst_dir .. "/*")) == 1 then
		vim.fn.delete(dst_dir, "d")
	end

	vim.fn.system({ "mandb", vim.fn.expand("~/.local/share/man") })
	vim.notify("KickNvim manpages removed", vim.log.levels.INFO)
end

-- ======================== HELPER FUNCTIONS =============================

-- Gives back the path of the bin folder used for compilation
local function ensure_bin_dir()
	local bin_path = vim.fn.expand("%:p:h") .. "/bin"
	if vim.fn.isdirectory(bin_path) == 0 then
		vim.fn.mkdir(bin_path, "p")
	end
	return bin_path
end

-- Checks if the filetype of the active buffer is kickass
local function is_kickass_file()
	return vim.bo.filetype == "kickass"
end

-- =======================================================================

function M.open_kmanual()
	local url = "https://theweb.dk/KickAssembler/webhelp/content/cpt_Introduction.html"
	vim.ui.open(url)
	print("Opened KickAssembler Manual")
end

function M.open_libmanual()
	local url = "https://c64lib.github.io/"
	vim.ui.open(url)
	print("Opened C64Lib Manual")
end

function M.assemble_current_file()
	if not is_kickass_file() then
		print("Active buffer is not a kickassembler file")
		return false
	end

	vim.cmd("write") -- 🔥 FORCE SAVE BEFORE BUILD

	local src = vim.fn.expand("%:p")
	local bin_dir = ensure_bin_dir()
	local base = vim.fn.expand("%:t:r")

	local output = bin_dir .. "/" .. base .. ".prg"
	local sym_file = bin_dir .. "/" .. base .. ".sym"
	local vs_file = bin_dir .. "/" .. base .. ".vs"
	local dbg_file = bin_dir .. "/" .. base .. ".dbg"

	-- 🔥 SINGLE COMMAND
	local cmd = string.format(
		"java -jar %s %s -odir %s -o %s -symbolfile %s -vicesymbols -vicedebug -debugdump",
		config.kickass_path,
		src,
		bin_dir,
		output,
		sym_file
	)

	-- 📦 capture output (not system!)
	local lines = vim.fn.systemlist(cmd)

	local qf = {}
	local has_error = false

	for _, line in ipairs(lines) do
		local msg = line:match("^Error:%s*(.+)")
		local lnum, file, text

		-- format z KickAssemblera:
		-- "at line 7, column 5 in game.asm"
		lnum, file, text = line:match("at line (%d+).*in ([^%s]+)%s*(.+)")

		if msg or lnum then
			has_error = true
		end

		if lnum then
			table.insert(qf, {
				filename = file or src,
				lnum = tonumber(lnum),
				text = text or msg or line,
				type = "E",
			})
		else
			table.insert(qf, { text = line })
		end
	end

	-- end of parsing | start diagnostic
	local ns = vim.api.nvim_create_namespace("kickasm")

	local lines = vim.fn.systemlist(cmd)

	-- 1. PARSING OUTPUT
	local qf = {}
	local diagnostics = {}
	local has_error = false

	for _, line in ipairs(lines) do
		-- 1. detect error start
		local msg = line:match("^Error:%s*(.+)")
		if msg then
			has_error = true
		end

		-- 2. extract line + file
		local lnum, file = line:match("at line (%d+),.-in ([^%s]+)")
		local full_msg = msg or line

		if lnum and file then
			has_error = true

			table.insert(diagnostics, {
				lnum = tonumber(lnum) - 1,
				col = 0,
				message = full_msg,
				severity = vim.diagnostic.severity.ERROR,
				source = "kickasm",
			})
		end
	end

	-- 2. QUICKFIX (opcjonalnie)
	vim.fn.setqflist(qf, "r")

	-- 3. DIAGNOSTICS (NOWA CZĘŚĆ — TU WŁAŚNIE TO DODAJESZ)
	local ns = vim.api.nvim_create_namespace("kickasm")
	vim.diagnostic.set(ns, vim.api.nvim_get_current_buf(), diagnostics)

	-- 4. UI FEEDBACK
	if #diagnostics > 0 then
		vim.notify("❌ KickAssembler failed", vim.log.levels.ERROR)

		vim.schedule(function()
			local bufnr = vim.api.nvim_get_current_buf()
			local diags = vim.diagnostic.get(bufnr)

			if #diags > 0 then
				table.sort(diags, function(a, b)
					return a.lnum < b.lnum
				end)

				local first = diags[1]

				vim.api.nvim_win_set_cursor(0, {
					first.lnum + 1,
					first.col or 0,
				})

				vim.diagnostic.open_float(nil, {
					focus = false,
				})
			end
		end)
		return false
	else
		vim.notify("✅ KickAssembler OK! 🔷 " .. output, vim.log.levels.INFO)
		vim.cmd("cclose")
		return true
	end
end

function M.run_prg()
	if not is_kickass_file() then
		print("Active buffer is not a KickAssembler file")
		return
	end
	local bin_dir = ensure_bin_dir()
	local base = vim.fn.expand("%:t:r")
	local prg_file = bin_dir .. "/" .. base .. ".prg"
	local sym_file = bin_dir .. "/" .. base .. ".sym"
	local vs_file = bin_dir .. "/" .. base .. ".vs"
	local labels_file = bin_dir .. "/" .. base .. ".labels"

	vim.fn.jobstart({
		config.x64_path,
		"-moncommands",
		vs_file,
		prg_file,
	}, { detach = true })
end

function M.run_debug_prg()
	if not is_kickass_file() then
		print("Active buffer is not a KickAssembler file")
		return
	end
	local bin_dir = ensure_bin_dir()
	local base = vim.fn.expand("%:t:r")
	local prg_file = bin_dir .. "/" .. base .. ".prg"
	local sym_file = bin_dir .. "/" .. base .. ".sym"
	local vs_file = bin_dir .. "/" .. base .. ".vs"
	local dbg_file = bin_dir .. "/" .. base .. ".dbg"
	local labels_file = bin_dir .. "/" .. base .. ".labels"

	vim.fn.jobstart({
		config.retro_debugger,
		"-prg",
		prg_file,
		"-symbols",
		sym_file,
		"-debuginfo",
		dbg_file,
		"-autojmp",
	}, { detach = true })
end

-- Run two commands in a row: assemble and then debug (if assemble was successful)
function M.assemble_and_debug()
	local ok = M.assemble_current_file()

	if not ok then
		return
	end

	M.run_debug_prg()
end

function M.install_or_update_libs()
	if not is_kickass_file() then
		print("Active buffer is not a KickAssembler file")
		return
	end

	local buffer_path = vim.fn.expand("%:p:h")
	local lib_path = buffer_path .. "/lib"

	if vim.fn.isdirectory(lib_path) == 0 then
		print("Creating lib directory at " .. lib_path)
		vim.fn.mkdir(lib_path, "p")
	end

	for _, repo_url in ipairs(config.repos) do
		local repo_name = repo_url:match("([^/]+)%.git$")
		local target_path = lib_path .. "/" .. repo_name
		if vim.fn.isdirectory(target_path) == 0 then
			print("Cloning " .. repo_name .. "...")
			vim.fn.system({ "git", "clone", repo_url, target_path })
		else
			print("Updating " .. repo_name .. "...")
			vim.fn.system({ "git", "-C", target_path, "pull" })
		end
	end
end

return M
