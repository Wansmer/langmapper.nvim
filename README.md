# Langmapper.nvim - another attempt to make neovim friends with other keyboard layouts

Motivation: vim and neovim historically no friends with keyboard layouts other than English. It is not bad, when you're only coding, but if you work with text on other languages – it is very uncomfortable.
Yes, we have `langmap` and `langremap` but it no work with all mapping what we want.

Here is another attempt to do it more comfortable.

This plugin – a wrapper of standard `vim.keymap.set` and little more:

- **Remaps to your layout all built-in CTRL sequences (all what manage neovim, not system)**
- **Allow using your lovely keys at same places in normal mode: e.g., ':', ';' e.t.c.**
- **Checking your current system keyboard layout (if you set it)**

> _⚡Disclaimer: The plugin is under active development. I tested it only on Mac and only with russian keyboard layout. PR are welcome_

## Requirements

1. [Neovim 0.8+](https://github.com/neovim/neovim/releases)
2. [rigrep](https://github.com/BurntSushi/ripgrep);

## Instalation

Plugin manages only mappings what mapped with `require('langmapper').map`, built-in CTRL's and specials chars from `layouts[lang].special_remap`. For using movement keys be
sure what you have `vim.opt.langmap`.

For work, plugin should be loaded before you set your mappings. Best way did it – no use lazy loaded and require before mappings.

**With Lazy.nvim**:

```lua
return {
  'Wansmer/langmapper',
  lazy = false, -- It important
  config = function()
    require('langmapper').setup(--[[ your configuration ]])
  end,
}
```

**With Packer.nvim**:

```lua
use({
  'Wansmer/langmapper',
  config = function()
    require('langmapper').setup(--[[ your configuration ]])
  end,
})
```

## Configuration

**Default config**:

```lua
require('Langmapper').setup({
  ---@type table|nil List of :map-arguments for using by default
  default_map_arguments = nil,
  ---@type string Standart English layout
  default_layout = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
  ---@type table
  layouts = {
    ---@type table
    ru = {
      --@type string Name of your second keyboard layout in system
      id = 'RussianWin',
      layout = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯфисвуапршолдьтщзйкыегмцчня',
      ---@type table Dictionary of pairs <leaderkeycode> and replacement
      leaders = {
        ---@type string|boolean Every <keycode> must be in uppercase
        ['<LOCALLEADER>'] = 'б',
        ['<LEADER>'] = false,
      },
      ---@type table Using to remapping special symbols in normal mode. To use the same keys you are used to.
      ---It no really remap, but feeling like that :-) (See ## How it works)
      ---WARNING: it will no work if you have not a function for get current layout on your system
      ---DOUBLE WARNING: it is works not enough good
      special_remap = {
        ['Ж'] = ':',
        ['ж'] = ';',
        ['.'] = '/',
        [','] = '?',
        ['ю'] = '>',
        ['б'] = ',',
      },
    },
  },
  ---@type string[] If empty, will be remapping for all layouts from 'layouts'. If you need to specify layout – add to list below. It will override default values.
  use_layouts = {},
  os = {
    ---Darwin it is a MacOS
    Darwin = {
      ---Function for getting current keyboard layout on your device
      ---Should return string with id of layouts
      ---@return string
      get_current_layout_id = function()
        local keyboar_key = '"KeyboardLayout Name"'
        local cmd = 'defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | rg -w ' .. keyboar_key
        local output = vim.fn.system(cmd)
        local cur_layout =
          vim.trim(output:match('%"KeyboardLayout Name%" = (%a+);'))
        return cur_layout
      end,
    },
  },
  ---@type boolean Add mapping for every CTRL+ binding or not. Using for remaps CTRL's neovim mappings by default.
  map_all_ctrl = true,
  -- WARNING: Very experemental. No works good yet
  try_map_specials = false,
})
```

## Usage

### For regular mapping:

```lua
-- this function complitely repeat contract of vim.keymap set
local map = require('langmapper').map

map('n', '<Leader>e', '<Cmd>Neotree toggle focus')
```

### When you need set mapping inside other plugin:

```lua
-- Neo-tree config. See https://github.com/Wansmer/nvim-config/blob/main/lua/config/plugins/neo-tree.lua
local map = require('langmapper.utils')
local window_mappings = mapper.trans_dict({
  ['o'] = 'open',
  ['l'] = 'open_with_window_picker',
  ['sg'] = 'split_with_window_picker',
  ['sv'] = 'vsplit_with_window_picker',
  ['s'] = false,
  ['z'] = 'close_node',
  ['Z'] = 'close_all_nodes',
  ['N'] = 'add',
  ['d'] = 'delete',
  ['r'] = 'rename',
  ['y'] = 'copy_to_clipboard',
  ['x'] = 'cut_to_clipboard',
  ['p'] = 'paste_from_clipboard',
  ['<leader>d'] = 'copy',
  ['m'] = 'move',
  ['q'] = 'close_window',
  ['R'] = 'refresh',
  ['?'] = 'show_help',
  ['<S-TAB>'] = 'prev_source',
  ['<TAB>'] = 'next_source',
})
```

It will return a table with 'translated' keys and same values.

## How it works

First: plugin make mapping for all combination with your layout with Ctrl. E.g., you have these layouts:

- **ru** '...фисву...'
- **en** '...abcde...'

Plugin get every char at 'en' and create mapping:
`vim.keymap.set({ '', '!', 't' }, '<C-' .. char_from_ru .. '>', '<C-' .. char_from_n .. '>')`.
It means what if neovim already has `'<C-' .. char_from_n .. '>'`, when you're typing same in your keyboard layout, will be trigger built-in functionality. Otherwise, nothing will just happen.

Second: when you use `require('langmapper').map('i', 'jk', '<Esc>'), plugin make two bindings: for 'jk' and for relevant chars in fallback layout. (See `layouts[lang].leaders`)

When <leader> or <localleader> must be changed to real symbol – plugin do it.

Third: When you're pressing key, where in English keyboard places dot (for example), you expect what a dot-functionality will be to happen, but in your current layout is not dot :-(
Plugin listen all you key-pressing in normal mode, and if you press dot-key – it runs `vim.api.nvim_feedkeys('.', 'n', true)` and dot-functionality happens, no matter what the layout is now. (See `layouts[lang].special_remap`)
