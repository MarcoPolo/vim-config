{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";

    rnix-lsp = {
      url = "github:nix-community/rnix-lsp";
      inputs.flake-utils.follows = "flake-utils";
    };

    nvim-lsp-config = {
      url = "github:neovim/nvim-lspconfig/master";
      flake = false;
    };

    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter";
      flake = false;
    };

    kommentary = {
      url = "github:b3nj5m1n/kommentary";
      flake = false;
    };

    nvim-ts-rainbow = {
      url = "github:p00f/nvim-ts-rainbow";
      flake = false;
    };
    neovim.url = "github:neovim/neovim?dir=contrib";

    popup = {
      url = "github:nvim-lua/popup.nvim";
      flake = false;
    };
    plenary = { url = "github:nvim-lua/plenary.nvim"; flake = false; };
    telescope = { url = "github:nvim-telescope/telescope.nvim"; flake = false; };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { system = system; };
        plugin = vimSrc: pkgs.vimUtils.buildVimPluginFrom2Nix {
          pname = "${pkgs.lib.strings.sanitizeDerivationName vimSrc}";
          version = vimSrc.shortRev;
          src = vimSrc;
        };
        pluginWithDeps = vimSrc: deps: pkgs.vimUtils.buildVimPluginFrom2Nix {
          pname = "${pkgs.lib.strings.sanitizeDerivationName vimSrc}";
          version = vimSrc.shortRev;
          dependencies = deps;
          src = vimSrc;
        };
      in
      {
        homeManagerConfig.programs.neovim = {
          enable = true;
          package = inputs.neovim.defaultPackage.${system};
          extraConfig = builtins.concatStringsSep "\n" [
            ''
              let mapleader = ","
              colorscheme seoul256
              nnoremap <F6> :w<CR>
              nnoremap <F7> :Commentary<CR>
              " inoremap <silent><expr> <TAB>
              " \ pumvisible() ? "\<C-n>" :
              " \ <SID>check_back_space() ? "\<TAB>" :
              " \ coc#refresh()
              inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

              autocmd BufWritePre *.rs lua vim.lsp.buf.formatting_sync(nil, 1000)
              autocmd BufWritePre *.nix lua vim.lsp.buf.formatting_sync(nil, 1000)

              set number

              " Italics for comments
              highlight Comment cterm=italic

            ''

            # this allows you to add lua config files
            ''
              lua << EOF
              require'nvim-treesitter.configs'.setup {
                rainbow = {
                  enable = true,
                  extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
                  max_file_lines = 1000, -- Do not enable for files with more than 1000 lines, int
                }
              }
              EOF
            ''
            ''
              lua << EOF
              require('kommentary.config').use_extended_mappings()
              vim.api.nvim_set_keymap("n", "gCX", "<Plug>kommentary_line_default", {})
              vim.api.nvim_set_keymap("v", "gCX", "<Plug>kommentary_visual_default", {})
              vim.api.nvim_set_keymap("i", "gCX", "<esc><Plug>kommentary_line_default", {})
              EOF
            ''
            ''
              lua << EOF
              local nvim_lsp = require('lspconfig')

              -- Use an on_attach function to only map the following keys
              -- after the language server attaches to the current buffer
              local on_attach = function(client, bufnr)
                local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
                local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

                --Enable completion triggered by <c-x><c-o>
                buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

                -- Mappings.
                local opts = { noremap=true, silent=true }

                -- See `:help vim.lsp.*` for documentation on any of the below functions
                buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
                buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
                buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
                buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
                buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
                buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
                buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
                buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
                buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
                buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
                buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
                buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
                buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
                buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
                buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
                buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
                buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)

              end

              -- Use a loop to conveniently call 'setup' on multiple servers and
              -- map buffer local keybindings when the language server attaches
              local servers = {"rust_analyzer", "rnix" }
              for _, lsp in ipairs(servers) do
                nvim_lsp[lsp].setup {
                  on_attach = on_attach,
                  flags = {
                    debounce_text_changes = 150,
                  }
                }
              end
              EOF
            ''
            ''
                                lua << EOF
              -- Compe setup
              require'compe'.setup {
                enabled = true;
                autocomplete = true;
                debug = false;
                min_length = 1;
                preselect = 'enable';
                throttle_time = 80;
                source_timeout = 200;
                incomplete_delay = 400;
                max_abbr_width = 100;
                max_kind_width = 100;
                max_menu_width = 100;
                documentation = true;

                source = {
                  path = true;
                  nvim_lsp = true;
                };
              }

              local t = function(str)
                return vim.api.nvim_replace_termcodes(str, true, true, true)
              end

              local check_back_space = function()
                  local col = vim.fn.col('.') - 1
                  if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                      return true
                  else
                      return false
                  end
              end

              -- Use (s-)tab to:
              --- move to prev/next item in completion menuone
              --- jump to prev/next snippet's placeholder
              _G.tab_complete = function()
                if vim.fn.pumvisible() == 1 then
                  return t "<C-n>"
                elseif check_back_space() then
                  return t "<Tab>"
                else
                  return vim.fn['compe#complete']()
                end
              end
              _G.s_tab_complete = function()
                if vim.fn.pumvisible() == 1 then
                  return t "<C-p>"
                else
                  return t "<S-Tab>"
                end
              end

              vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
              vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
              vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
              vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})

              --This line is important for auto-import
              vim.api.nvim_set_keymap('i', '<cr>', 'compe#confirm("<cr>")', { expr = true })
              vim.api.nvim_set_keymap('i', '<c-space>', 'compe#complete()', { expr = true })
              EOF
            ''
          ];
          extraPackages = with pkgs; [
            # used to compile tree-sitter grammar
            tree-sitter
            inputs.rnix-lsp.defaultPackage.${system}

            # installs different langauge servers for neovim-lsp
            # have a look on the link below to figure out the ones for your languages
            # https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md
            nodePackages.typescript
            nodePackages.typescript-language-server
            gopls
            nodePackages.pyright
            rust-analyzer
            ripgrep
            bat
            fd
          ];
          plugins = with pkgs.vimPlugins; [
            # vim-plug
            # coc-nvim
            # coc-rust-analyzer
            # coc-rename
            # coc-tsserver
            # coc-json
            # coc-pairs
            nerdtree
            nerdtree-git-plugin
            fugitive
            vim-easymotion
            vim-commentary
            delimitMate
            vim-gitgutter
            vim-nix
            # ale
            # ctrlp-smarttabs
            # vim-misc
            # vim-notes

            # sky-color-clock-vim

            lightline-vim
            seoul256-vim
            ctrlp-vim
            vim-surround
            vim-eunuch
            vim-fugitive
            vim-abolish
            vim-repeat
            # nerdcommenter
            # Rust
            # rust-vim

            # "Plug lambdalisue/suda.vim
            (plugin inputs.kommentary)
            (plugin inputs.nvim-treesitter)
            (plugin inputs.nvim-lsp-config)
            (plugin inputs.nvim-ts-rainbow)
            #(pluginWithDeps inputs.popup [ inputs.nvim-treesitter ])
            # (pluginWithDeps inputs.popup [ (plugin inputs.nvim-treesitter) pkgs.tree-sitter ])
            # (plugin inputs.plenary)
            # (plugin inputs.telescope)

            telescope-nvim
            indent-blankline-nvim-lua
            which-key-nvim
            nvim-compe
          ];
        };
      }
    );
}
