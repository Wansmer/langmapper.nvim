-- Based on https://github.com/folke/lazy.nvim/blob/3bde7b5ba8b99941b314a75d8650a0a6c8552144/tests/init.lua

local CWD = vim.loop.cwd() .. '/'

vim.opt.shiftwidth = 2
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.shadafile = 'NONE'
vim.opt.showcmd = false
vim.g.mapleader = ' '
vim.g.maplocalleader = ';'

vim.cmd([[
set runtimepath=$VIMRUNTIME
runtime plugin/netrwPlugin.vim
packadd matchit
]])
vim.opt.runtimepath:append(CWD)
vim.opt.packpath = { CWD .. '.tests/site' }

local function escape(str)
  local escape_chars = [[;,."|\]]
  return vim.fn.escape(str, escape_chars)
end

local en = [[`qwertyuiop[]asdfghjkl;'zxcvbnm]]
local ru = [[ёйцукенгшщзхъфывапролджэячсмить]]
local en_shift = [[~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>]]
local ru_shift = [[ËЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ]]
vim.opt.langmap = vim.fn.join({
  escape(ru_shift) .. ';' .. escape(en_shift),
  escape(ru) .. ';' .. escape(en),
}, ',')

local dependencies = {
  'nvim-lua/plenary.nvim',
}

local function install_dep(plugin)
  local name = plugin:match('.*/(.*)')
  local package_root = CWD .. '.tests/site/pack/deps/start/'
  if not vim.loop.fs_stat(package_root .. name) then
    vim.fn.mkdir(package_root, 'p')
    vim.fn.system({
      'git',
      'clone',
      '--depth=1',
      'https://github.com/' .. plugin .. '.git',
      package_root .. '/' .. name,
    })
  end
end

for _, plugin in ipairs(dependencies) do
  install_dep(plugin)
end

require('plenary.busted')
