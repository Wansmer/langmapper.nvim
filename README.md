# Langmapper.nvim - another attempt to make neovim friends with other keyboard layouts

> _⚡Disclaimer: The plugin is under active development. I tested it only on Mac and only with russian keyboard layout. PR are welcome_

Motivation: vim and neovim historically no friends with keyboard layouts other than English. It is not bad, when you're only coding, but if you work with text on other languages – it is very uncomfortable.
Yes, we have `langmap` and `langremap` but it no work with all mapping what we want.

Here is another attempt to do it more comfortable.

This plugin – a wrapper of standard `vim.keymap.set` and little more:

- **Remaps to your layout all built-in CTRL sequences (all what manage neovim, not system)**
- **Allow using your lovely keys at same places in normal mode: e.g., ':', ';' e.t.c.** (experimental)
- **Checking your current system keyboard layout** (only on MacOS by default)

## Requirements

1. [Neovim 0.8+](https://github.com/neovim/neovim/releases)
2. Program for you OS to check current input method (optional)

> E.g., [im-select](https://github.com/daipeihust/im-select) for MacOS and Windows, [xkb-switch](https://github.com/grwlf/xkb-switch) for Linux.

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
  ---@type string Standart English layout (only alphabetic symbols)
  default_layout = [[ABCDEFGHIJKLMNOPQRSTUVWXYZ<>:"{}~abcdefghijklmnopqrstuvwxyz,.;'[]`]],
  ---@type table Fallback layouts
  layouts = {
    ---@type table Fallback layout item
    ru = {
      ---@type string Name of your second keyboard layout in system.
      ---It should be the same as result string of `get_current_layout_id`
      id = 'com.apple.keylayout.RussianWin',
      ---@type string
      default_layout = nil, -- if you need to specify default layout specialy for this fallback layout
      ---@type string Fallback layout to remap. Should be same length as default layout
      layout = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯБЮЖЭХЪËфисвуапршолдьтщзйкыегмцчнябюжэхъё',
      --@type string Fallback extra layout to remap. Should be same length as default extra layout
      ---@type table Dictionary of pairs <leaderkeycode> and replacement
      leaders = {
        ---@type string|nil If not nil, key will be replaced in mappings
        ['<Localleader>'] = 'ж',
        ['<Leader>'] = nil,
      },
      ---@type table Using to remapping special symbols in normal mode. To use the same keys you are used to
      ---rhs: normal mode command to execute
      ---feed_mode:
      ---  n - use nvim-default behavior (like remap = false)
      ---  m - use remapping behavior if key was remmaping by user or another plugin (like remap = true)
      ---  nil - if nil, feed_mode will autodetect
      ---  (for more info see :h feedkeys(). Here use only n and m)
      ---check_layout: this causes a delay because checking the current input method is an expensive operation
      special_remap = {
        ['.'] = { rhs = '/', feed_mode = nil, check_layout = true },
        [','] = { rhs = '?', feed_mode = nil, check_layout = true },
        ['/'] = { rhs = '|', feed_mode = nil, check_layout = true },
        ['Ж'] = { rhs = ':', feed_mode = nil, check_layout = false },
        ['ж'] = { rhs = ';', feed_mode = nil, check_layout = false },
        ['ю'] = { rhs = '.', feed_mode = nil, check_layout = false },
        ['б'] = { rhs = ',', feed_mode = nil, check_layout = false },
        ['э'] = { rhs = "'", feed_mode = nil, check_layout = false },
        ['Э'] = { rhs = '"', feed_mode = nil, check_layout = false },
        ['х'] = { rhs = '[', feed_mode = nil, check_layout = false },
        ['ъ'] = { rhs = ']', feed_mode = nil, check_layout = false },
        ['Х'] = { rhs = '{', feed_mode = nil, check_layout = false },
        ['Ъ'] = { rhs = '}', feed_mode = nil, check_layout = false },
        ['ё'] = { rhs = '`', feed_mode = nil, check_layout = false },
        ['Ë'] = { rhs = '~', feed_mode = nil, check_layout = false },
      },
    },
  },
  ---@type string[] If empty, will remapping for all defaults layouts
  use_layouts = {},
  os = {
    Darwin = {
      ---Function for getting current keyboard layout on your device
      ---Should return string with id of layouts
      ---@return string
      get_current_layout_id = function()
        -- Works faster:
        -- local cmd = '/opt/homebrew/bin/im-select'

        -- No need dependencies
        local cmd =
          'defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID'
        local output = vim.split(vim.trim(vim.fn.system(cmd)), '\n')
        return output[#output]
      end,
    },
  },
  ---@type boolean Add mapping for every CTRL+ binding or not. Using for remaps CTRL's neovim mappings by default.
  map_all_ctrl = true,
  ---@type boolean Remap specials keys (see layouts[youlayout].special_remap)
  remap_specials_keys = true,
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

**Mini.surround example**

```lua
-- Keep in mind what a pairs ('', "") not remapped,
-- you need to use those keys where they really located
map('n', 'sa', 'sa', { remap = true })
map('n', 'sd', 'sd', { remap = true })
map('n', 'sc', 'sc', { remap = true })
map('x', 'sa', 'sa', { remap = true })
```

**Neo-tree exapmple**

```lua
-- Neo-tree config. See https://github.com/Wansmer/nvim-config/blob/main/lua/config/plugins/neo-tree.lua
-- It will return a table with 'translated' keys and same values.
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

**Comment.nvim example**

```lua
map('n', 'gcc', function()
  return vim.v.count == 0 and '<Plug>(comment_toggle_linewise_current)' or '<Plug>(comment_toggle_linewise_count)'
end, { expr = true })

map('n', 'gbc', function()
return vim.v.count == 0 and '<Plug>(comment_toggle_blockwise_current)' or '<Plug>(comment_toggle_blockwise_count)'
end, { expr = true })
```

## How it works

First: plugin make mapping for all combination with your layout with Ctrl. E.g., you have these layouts:

- **ru** '...фисву...'
- **en** '...abcde...'

Plugin get every char at 'en' and create mapping:
`vim.keymap.set({ '', '!', 't' }, '<C-' .. char_from_ru .. '>', '<C-' .. char_from_n .. '>')`.
It means what if neovim already has `'<C-' .. char_from_n .. '>'`, when you're typing same in your keyboard layout, will be trigger built-in functionality. Otherwise, nothing will just happen.

Second: when you use `require('langmapper').map('i', 'jk', '<Esc>')`, plugin make two bindings: for `jk` and for relevant chars in fallback layout. (See `layouts[lang].leaders`)

When `<leader>` or `<localleader>` must be changed to real symbol – plugin do it.

Third: When you're pressing key, where in English keyboard locate dot (for example), you expect what a dot-functionality will be to happen, but in your current layout is not dot :-(
Example with Russian layout: I'm pressing key when in English layout locate `/` (slash), but in Russian layout locate `.` (dot). I don't want to keep in mind which current input method. All what I want – get standard `/` functionality (because I'm used to that in this place on the keyboard it is a slash). Plugin check current keyboard layout and if it 'Ru' - send needed key to typeahead buffer (`/` instead `.`). But if current input method is 'En' - plugin send dot.
