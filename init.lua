-- rm -rf ~/.local/state/nvim/lazy/
-- lalu buka lagi nvim
-- :TSInstall python lua 
-- ==========================================================================
-- 1. PENGATURAN DASAR (WAJIB)
-- ==========================================================================
vim.opt.signcolumn = "yes" -- Kolom tanda selalu ada meskipun kosong
vim.g.mapleader = " "
vim.opt.termguicolors = true -- Wajib agar warna tidak flat
vim.opt.number = true
vim.opt.relativenumber = true -- Angka relatif memudahkan lompat baris (misal: 10j)
vim.opt.ignorecase = true -- Search tidak sensitif huruf besar/kecil
vim.opt.smartcase = true -- Search sensitif huruf besar jika Anda mengetik huruf besar
vim.opt.cursorline = true -- Garis bawah pada baris kursor aktif
vim.opt.scrolloff = 8 -- Sisakan 8 baris saat scroll agar kursor tidak di paling bawah

-- ==========================================================================
-- 2. BOOTSTRAP LAZY.NVIM (Plugin Manager)
-- ==========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================================================
-- 3. KONFIGURASI PLUGIN
-- ==========================================================================
require("lazy").setup({
  -- [A] TEMA WARNA (Agar Treesitter terlihat hasilnya)
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight-night]])
    end,
  },

-- [LSP] Konfigurasi Kecerdasan Bahasa
{
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp", -- Tambahkan ini untuk persiapan autocomplete nanti
  },
  config = function()
    -- 1. Inisialisasi Mason
    require("mason").setup()

    -- 2. Setup Capabilities (Agar LSP tahu Neovim mendukung autocomplete)
    local capabilities = require('cmp_nvim_lsp').default_capabilities()

    -- 3. Inisialisasi Mason-Lspconfig dengan Handlers terintegrasi
    require("mason-lspconfig").setup({
      ensure_installed = { "pyright", "lua_ls" },
      -- Kita masukkan handler langsung di sini, ini lebih stabil
      handlers = {
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
          })
        end,
      },
    })
  end,
},

-- TREESITTER: Mesin Highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- Proteksi: Jangan jalankan jika module belum ada
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then return end

      configs.setup({
        ensure_installed = { "python", "lua", "vim", "vimdoc", "query" },
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      })
    end,
  },

  -- ✨ Auto pairs {}, (), []
{
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    require("nvim-autopairs").setup({
      check_ts = true, -- Aktifkan integrasi Treesitter
    })
  end,
},

-- Neo-tree
{
"nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", 
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({})
  end,	
},

    -- 🔍 Telescope
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({})
    end,
  },
  {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  opts = {},
},

-- [CMP] Autocomplete Menu
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip", -- Snippet engine (wajib ada)
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(), -- Paksa munculkan saran
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Enter untuk pilih
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" }, -- Saran dari LSP
          { name = "luasnip" },  -- Saran dari Snippet
        }, {
          { name = "buffer" },   -- Saran dari kata-kata di file ini
          { name = "path" },     -- Saran untuk path file
        }),
      })
    end,
  },

  -- [D] Highlight simbol di bawah cursor (Smart Highlight)
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("illuminate").configure({
        -- Provider prioritas: LSP -> Treesitter -> Regex
        providers = { "lsp", "treesitter" }, 
        delay = 100, -- Lebih cepat (0.1 detik)
        large_file_cutoff = 2000, -- Jangan aktif di file raksasa (>2000 baris)
        filetypes_denylist = {
          "NvimTree",
          "TelescopePrompt",
          "lazy",
          "mason",
        },
      })
      
      -- Opsional: Ubah warna highlight agar sesuai dengan Tokyonight
      -- Warna 'IlluminatedWordText' biasanya agak redup di beberapa tema
      vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "LspReferenceText" })
      vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "LspReferenceRead" })
      vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "LspReferenceWrite" })
    end,
  },

  -- INSTALL DULU LAZYGIT DI UBUNTU BRO!!!!!!
{
  "kdheepak/lazygit.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
  }
},
{
  "lewis6991/gitsigns.nvim",
  config = function()
    require('gitsigns').setup({
      signs = {
        add          = { text = '▎' }, -- Simbol garis tipis untuk baris baru
        change       = { text = '▎' }, -- Simbol garis tipis untuk baris edit
        delete       = { text = '' }, -- Simbol panah untuk baris hapus
        topdelete    = { text = '' },
        changedelete = { text = '▎' },
        untracked    = { text = '┆' },
      },
      signcolumn = true,  -- Menampilkan tanda di kolom kiri
      current_line_blame = true, -- Fitur "Git Lens": muncul tulisan siapa yang edit di ujung baris
      current_line_blame_opts = {
        delay = 500,
      },
    })

    -- Keymaps khusus untuk navigasi perubahan Git
    local gs = package.loaded.gitsigns
    vim.keymap.set('n', ']h', gs.next_hunk, { desc = "Ke perubahan berikutnya" })
    vim.keymap.set('n', '[h', gs.prev_hunk, { desc = "Ke perubahan sebelumnya" })
    vim.keymap.set('n', '<leader>hp', gs.preview_hunk, { desc = "Preview perubahan" })
    vim.keymap.set('n', '<leader>hr', gs.reset_hunk, { desc = "Undo perubahan baris ini" })
  end
},

-- untuk mengaktifkan minimap
{
  'echasnovski/mini.map',
  version = false,
  config = function()
    local map = require('mini.map')
    map.setup({
      integrations = {
        map.gen_integration.builtin_search(),
        map.gen_integration.gitsigns(),
        map.gen_integration.diagnostic(),
      },
      symbols = { scrollbar = '┃' },
      window = { width = 15 },
    })
    
    -- Shortcut untuk buka/tutup
    vim.keymap.set('n', '<leader>mm', map.toggle, { desc = "Toggle Minimap" })
  end,
},
})

-- ==========================================================================
-- TELESCOPE KEYMAPS
-- ==========================================================================
vim.keymap.set("n", "<leader>ff", function()
  require("telescope.builtin").find_files()
end)

vim.keymap.set("n", "<leader>fg", function()
  require("telescope.builtin").live_grep()
end)

vim.keymap.set("n", "<leader>fb", function()
  require("telescope.builtin").buffers()
end)

vim.keymap.set("n", "<leader>fh", function()
  require("telescope.builtin").help_tags()
end)

-- shorcur untuk neo-tree
vim.keymap.set('n', '<C-n>', ':Neotree toggle<CR>', { silent = true })


-- Keymaps untuk LSP (Gunakan saat kursor berada di atas kode)
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts) -- Go to Definition
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)       -- Munculkan info dokumentasi
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts) -- Rename variabel massal
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts) -- Fix error otomatis
  end,
})
