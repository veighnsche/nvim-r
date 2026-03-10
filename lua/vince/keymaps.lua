local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('n', '<leader>w', '<cmd>write<CR>', { desc = 'Write buffer' })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics to location list' })
map('n', 'gl', vim.diagnostic.open_float, { desc = 'Line diagnostics' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus left' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus down' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus up' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus right' })

map('i', '<C-Space>', function() vim.lsp.completion.get() end, { desc = 'Trigger completion' })
