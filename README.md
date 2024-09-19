# Langmapper

A plugin that makes Neovim more friendly to non-English input methods 🤝

<!-- panvimdoc-ignore-start -->

<!--toc:start-->

- [TLDR](#tldr)
- [Requirements](#requirements)
- [Installation](#instalation)
- [Settings](#settings)
- [Usage](#usage)
  - [Simple](#simple)
  - [Manually](#manualy)
  - [Using with `folke/which-key.nvim`](#using-with-folkewhich-keynvim)
- [API](#api)
- [Utils](#utils)
<!--toc:end-->

<!-- panvimdoc-ignore-end -->

## TLDR

- Translating all globally registered mappings;
- Translating local registered mappings for each buffer;
- Registering translated mappings for all built-in CTRL+ sequences;
- Provides utils for manual registration original and translated mapping with single function;
- Hacks built-in keymap's methods to translate all registered mappings (including mappings from lazy-loaded plugins);
- Real-time normal mode command processing variability depending on the input method.

## Requirements

- [Neovim 0.8+](https://github.com/neovim/neovim/releases)
- CLI utility to determine the current input method _(optional)_
- Configured [vim.opt.langmap](https://neovim.io/doc/user/options.html#'langmap') for your
  input method;
- Set up `vim.g.mapleader` and `map.g.localleader` before `langmapper.setup()`;

> Examples of CLI utilities:
>
> - [im-select](https://github.com/daipeihust/im-select) for Mac and Windows
> - [xkb-switch](https://github.com/grwlf/xkb-switch) for Linux

## Installation

With [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  'Wansmer/langmapper.nvim',
  lazy = false,
  priority = 1, -- High priority is needed if you will use `autoremap()`
  config = function()
    require('langmapper').setup({--[[ your config ]]})
  end,
}
```

With [Packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use({
  'Wansmer/langmapper.nvim',
  config = function()
    require('langmapper').setup({--[[ your config ]]})
  end,
})
```

After all the contents of your `init.lua` (optional):

```lua
-- code
require('langmapper').automapping({ global = true, buffer = true })
-- end of init.lua
```

## Settings

First, make sure you have a `langmap` configured. Langmapper only handles key
mappings. All other movement commands depend on the `langmap`.

<details>

<summary>Show example of `vim.opt.langmap`</summary>

```lua
local function escape(str)
  -- You need to escape these characters to work correctly
  local escape_chars = [[;,."|\]]
  return vim.fn.escape(str, escape_chars)
end

-- Recommended to use lua template string
local en = [[`qwertyuiop[]asdfghjkl;'zxcvbnm]]
local ru = [[ёйцукенгшщзхъфывапролджэячсмить]]
local en_shift = [[~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>]]
local ru_shift = [[ËЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ]]

vim.opt.langmap = vim.fn.join({
    -- | `to` should be first     | `from` should be second
    escape(ru_shift) .. ';' .. escape(en_shift),
    escape(ru) .. ';' .. escape(en),
}, ',')
```

</details>

<details>

<summary>Show default config</summary>

```lua
local default_config = {
  ---@type boolean Add mapping for every CTRL+ binding or not.
  map_all_ctrl = true,
  ---@type string[] Modes to `map_all_ctrl`
  ---Here and below each mode must be specified, even if some of them extend others.
  ---E.g., 'v' includes 'x' and 's', but must be listed separate.
  ctrl_map_modes = { 'n', 'o', 'i', 'c', 't', 'v' },
  ---@type boolean Wrap all keymap's functions (nvim_set_keymap etc)
  hack_keymap = true,
  ---@type string[] Usually you don't want insert mode commands to be translated when hacking.
  ---This does not affect normal wrapper functions, such as `langmapper.map`
  disable_hack_modes = { 'i' },
  ---@type table Modes whose mappings will be checked during automapping.
  automapping_modes = { 'n', 'v', 'x', 's' },
  ---@type string Standart English layout (on Mac, It may be different in your case.)
  default_layout = [[ABCDEFGHIJKLMNOPQRSTUVWXYZ<>:"{}~abcdefghijklmnopqrstuvwxyz,.;'[]`]],
  ---@type string[] Names of layouts. If empty, will handle all configured layouts.
  use_layouts = {},
  ---@type table Fallback layouts
  layouts = {
    ---@type table Fallback layout item. Name of key is a name of language
    ru = {
      ---@type string Name of your second keyboard layout in system.
      ---It should be the same as result string of `get_current_layout_id()`
      id = 'com.apple.keylayout.RussianWin',
      ---@type string Fallback layout to translate. Should be same length as default layout
      layout = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯБЮЖЭХЪËфисвуапршолдьтщзйкыегмцчнябюжэхъё',
      ---@type string if you need to specify default layout for this fallback layout
      default_layout = nil,
    },
  },
  os = {
    -- Darwin - Mac OS, the result of `vim.loop.os_uname().sysname`
    Darwin = {
      ---Function for getting current keyboard layout on your OS
      ---Should return string with id of layout
      ---@return string
      get_current_layout_id = function()
        local cmd = 'im-select'
        if vim.fn.executable(cmd) then
          local output = vim.split(vim.trim(vim.fn.system(cmd)), '\n')
          return output[#output]
        end
      end,
    },
  },
}
```

</details>

## Usage

### Simple

Set up your `layout` in config, set `hack_keymap` to `true` and load Langmapper
the first of the sheet of plugins, then call `langmapper.setup(opts)`.

Under such conditions, all subsequent calls to `vim.keymap.set`,
`vim.keymap.del`, `vim.api.nvim_(buf)_set_keymap` and
`vim.api.nvim_(buf)_del_keymap` will be wrapped with a special function,
which will automatically translate mappings and register them.

This means that even in the case of lazy-loading, the mapping setup will
still be processed and the translated mapping will be registered for it.

If you need to handle built-in and vim script mappings too, call the
`langmapper.automapping({ buffer = false })` function at the very end of
your `init.lua`. (buffer to `false`, because `nvim_buf_set_keymap` already hacked 😎)

### Manually

Set up your `layout` in config, set `hack_keymap` to false,
and call `langmapper.setup(opts)`.

#### For regular mapping:

```lua
-- this function completely repeats contract of vim.keymap.set
local map = require('langmapper').map

map('n', '<Leader>e', '<Cmd>Neotree toggle focus<Cr>')
```

#### Mapping inside other plugin:

```lua
-- Neo-tree config.
-- It will return a table with 'translated' keys and same values.
local map = require('langmapper.utils')
local window_mappings = mapper.trans_dict({
  ['o'] = 'open',
  ['sg'] = 'split_with_window_picker',
  ['<leader>d'] = 'copy',
})
```

#### With automapping

Add `langmapper.autoremap({ global = true, buffer = true })` to the end of your
`init.lua`.

It will autotranslate all registered mappings from `nvim_get_keymap()` and
`nvim_buf_get_keymap()`.

But it cannot handle mappings of lazy loaded plugins.

> NOTE: all keys, that you're using in `keys = {}` in `lazy.nvim` also will be
> translated.

### Using with `folke/which-key.nvim`

`which-key` uses `nvim_feedkeys` to execute the sequence entered by the user.
This imposes restrictions on the execution of commands related to operators,
text objects and movements, since `nvim_feedkeys` does not handle the value
of your `vim.opt.langmap`. Therefore, the entered sequence must be
translated back into English characters.

[Here](https://github.com/Wansmer/LazyWithLangmapper) example how to integrate
Langmapper to LazyNvim.

<details>

<summary>Configuration example:</summary>

```lua
return {
  'folke/which-key.nvim',
  enabled = true,
  dependencies = { 'Wansmer/langmapper.nvim' },
  config = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300

    local lmu = require('langmapper.utils')
    local view = require('which-key.view')
    local execute = view.execute

    -- wrap `execute()` and translate sequence back
    view.execute = function(prefix_i, mode, buf)
      -- Translate back to English characters
      prefix_i = lmu.translate_keycode(prefix_i, 'default', 'ru')
      execute(prefix_i, mode, buf)
    end

    -- If you want to see translated operators, text objects and motions in
    -- which-key prompt
    -- local presets = require('which-key.plugins.presets')
    -- presets.operators = lmu.trans_dict(presets.operators)
    -- presets.objects = lmu.trans_dict(presets.objects)
    -- presets.motions = lmu.trans_dict(presets.motions)
    -- etc

    require('which-key').setup()
  end,
}
```

</details>

Some other plugins that work with user input can also be hacked in this way. You
can find some hacks or share your own it this
[discussion](https://github.com/Wansmer/langmapper.nvim/discussions/11).

## API

**Usage:**

```lua
local langmapper = require('langmapper')

langmapper.map(...)
langmapper.automapping(...)
-- etc
```

### `automapping()`

Gets the output of `nvim_get_keymap` for all modes listed in the
`automapping_modes`, and sets the translated mappings using `nvim_feedkeys`.

Then sets event handlers `{ 'BufWinEnter', 'LspAttach' }` to do the same with
outputting `nvim_buf_get_keymap` for each open buffer.

Must be called at the very end of `init.lua`, after all plugins have been loaded
and all key bindings have been set.

This function also handles mappings made via vim script.

Does not handle mappings for lazy-loaded plugins. To avoid it, see
`hack_keymap`.

> NOTE: If you use `hack_keymap`, there are only one reason to use this function
> it is auto-handling built-in mappings (e.g., for netrw, like 'gx') and if you
> have mappings (or plugins with mappings) on vim script.

```lua
---@param opts {global=boolean|nil, buffer=boolean|nil}
function M.automapping(opts)
```

### `map()/del()`

Wrappers of `vim.keymap.set` \ `vim.keymap.del` with same contract.

`map()` - Sets the given `lhs`, then translates it to the configured input
methods, and maps it with the same options.

E.g.:

`map('i', 'jk', '<Esc>')` will execute `vim.keymap.set('i', 'jk', '<Esc>)`
and `vim.keymap.set('i', 'ол', <Esc>)`.

`map('n', '<leader>a', ':echo 123')` will execute `vim.keymap.set('n', '<leader>a', ':echo 123')`
and `vim.keymap.set('n', '<leader>ф', ':echo 123')`.

`lhs` with `<Plug>`, `<Sid>` and `<Snr>` will not translate and will be mapped as is.

`del()` works in the same way, but with mappings removing. Also, `del()` is
wrapped with a safetely call (`pcall`) to avoid errors on duplicate characters
(helpful when using`nvim-cmp`).

```lua
---@param mode string|table Same mode short names as |nvim_set_keymap()|
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param rhs string|function Right-hand side |{rhs}| of the mapping. Can also be a Lua function.
---@param opts table|nil A table of |:map-arguments|.
function M.map(mode, lhs, rhs, opts)

---@param mode string|table Same mode short names as |nvim_set_keymap()|
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param opts table|nil A table of optional arguments:
---  - buffer: (number or boolean) Remove a mapping from the given buffer.
---  When "true" or 0, use the current buffer.
function M.del(mode, lhs, opts)
```

### `hack_get_keymap()`

Hack `get_keymap` functions. See `:h nvim_set_keymap()` and `:h nvim_buf_set_keymap()`.

After this hack, `nvim_set_keymap/nvim_buf_set_keymap` will return **only**
latin mappings (without translated mappings). Very useful for work with
`nvim-cmp` (see [#8](https://github.com/Wansmer/langmapper.nvim/issues/8))

**Usage:**

```lua
local langmapper = require("langmapper")
langmapper.setup()
langmapper.hack_get_keymap()
```

### Other

Original keymap's functions, that were wrapped with translation functions if
`hack_keymap` is `true`:

```lua
-- When you don't need some mapping to be translated. For example, I don't translate `jk`.
`original_set_keymap()` -- vim.api.nvim_set_keymap
`original_buf_set_keymap() -- vim.api.nvim_buf_set_keymap
`original_del_keymap()` -- vim.api.nvim_del_keymap
`original_buf_del_keymap()` -- vim.api.nvim_buf_del_keymap
`put_back_keymap()` -- Set original functions back
```

> NOTE: No original `vim.keymap.set/del` because `nvim_set/del_keymap` is used inside

Another functions-wrappers with translates and same contracts:

```lua
`wrap_nvim_set_keymap()`
`wrap_nvim_del_keymap()`
`wrap_nvim_buf_set_keymap()`
`wrap_nvim_buf_del_keymap()`
```

## Utils

### `translate_keycode()`

Translate 'lhs' to 'to_lang' layout. If in 'to_lang' layout no specified
`default_layout`, uses global `default_layout` To translate back to English
characters, set 'to_lang' to `default` and pass the name of the layout to
translate from as the third parameter.

```lua
---@param lhs string Left-hand side |{lhs}| of the mapping.
---@param to_lang string Name of layout or 'default' if need translating back to English layout
---@param from_lang? string Name of layout.
---@return string
function M.translate_keycode(lhs, to_lang, from_lang)
```

**Example:**

```lua
local utils = require('langmapper.utils')
local keycode = '<leader>gh'
local tr_keycode = utils.translate_keycode(keycode, 'ru') -- '<leader>пр'
```

### `trans_dict()`

Translates each key of table for all layouts in `use_layouts` option
(recursive).

```lua
---@param dict table Dict-like table
---@return table
function M.trans_dict(dict)
```

**Example:**

```lua
local keycode_dict = { ['s'] = false, ['<leader>'] = { ['d'] = 'copy' }, ['<S-TAB>'] = 'prev_source' }
local result = utils.trans_dict(keycode_dict)
-- {
--   ['s'] = false,
--   ['ы'] = false,
--   ['<leader>'] = {
--     ['d'] = 'copy',
--     ['в'] = 'copy',
--   },
--   ['<S-TAB>'] = 'prev_source',
-- }
```

### `trans_list()`

Translates each value of the list for all layouts in `use_layouts` option.
Non-string value is ignored. Translated value will be added to the end.

```lua
---@param dict table Dict-like table
---@return table
function M.trans_list(dict)
```

**Example:**

```lua
local keycode_list = { '<leader>d', 'ab', '<S-Tab>' }
local translated = utils.trans_list(keycode_list)
-- { '<leader>d', 'ab', '<S-Tab>', '<leader>в', 'фи' }
```
