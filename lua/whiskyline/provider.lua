local api, uv, lsp, diagnostic, M = vim.api, vim.uv, vim.lsp, vim.diagnostic, {}
local fnamemodify = vim.fn.fnamemodify

local mode_alias = {
  --Normal
  ['n'] = 'Normal',
  ['no'] = 'O-Pending',
  ['nov'] = 'O-Pending',
  ['noV'] = 'O-Pending',
  ['no\x16'] = 'O-Pending',
  ['niI'] = 'Normal',
  ['niR'] = 'Normal',
  ['niV'] = 'Normal',
  ['nt'] = 'Normal',
  ['ntT'] = 'Normal',
  ['v'] = 'Visual',
  ['vs'] = 'Visual',
  ['V'] = 'V-Line',
  ['Vs'] = 'V-Line',
  ['\x16'] = 'V-Block',
  ['\x16s'] = 'V-Block',
  ['s'] = 'Select',
  ['S'] = 'S-Line',
  ['\x13'] = 'S-Block',
  ['i'] = 'Insert',
  ['ic'] = 'Insert',
  ['ix'] = 'Insert',
  ['R'] = 'Replace',
  ['Rc'] = 'Replace',
  ['Rx'] = 'Replace',
  ['Rv'] = 'V-Replace',
  ['Rvc'] = 'V-Replace',
  ['Rvx'] = 'V-Replace',
  ['c'] = 'Command',
  ['cv'] = 'Ex',
  ['ce'] = 'Ex',
  ['r'] = 'Replace',
  ['rm'] = 'More',
  ['r?'] = 'Confirm',
  ['!'] = 'Shell',
  ['t'] = 'Terminal',
}

function _G.ml_mode()
  local mode = api.nvim_get_mode().mode
  local m = mode_alias[mode] or mode_alias[string.sub(mode, 1, 1)] or 'UNK'
  return m:sub(1, 3):upper()
end

function M.fileinfo()
  local devicons = require('nvim-web-devicons')

  return {
    stl = (function()
      local cache = ''
      return function(args)
        local bufnr = (args and args.buf) or 0
        local bt = api.nvim_get_option_value('buftype', { buf = bufnr })
        if bt ~= '' then
          return cache
        end
        local ft = api.nvim_get_option_value('filetype', { buf = bufnr })
        if ft == '' then
          return cache
        end
        local bufname = api.nvim_buf_get_name(bufnr)
        local ft_icon = devicons.get_icon(bufname, nil, { default = true })
        local up = ft:sub(1, 1):upper()
        cache = (' %s %s '):format(ft_icon or '', up .. ft:sub(2))
        return cache
      end
    end)(),
    name = 'fileinfo',
    event = { 'BufEnter', 'FileType' },
    attr = { bg = '#81A1C1', fg = '#181D25', bold = true },
  }
end

function M.filetype()
  local devicons = require('nvim-web-devicons')
  return {
    name = 'filetype',
    stl = (function()
      local cache = ''
      return function(args)
        local bufnr = (args and args.buf) or 0
        local bt = api.nvim_get_option_value('buftype', { buf = bufnr })
        if bt ~= '' then
          return cache
        end
        local ft = api.nvim_get_option_value('filetype', { buf = bufnr })
        if ft == '' then
          return cache
        end
        local bufname = api.nvim_buf_get_name(bufnr)
        local ft_icon = devicons.get_icon(bufname, nil, { default = true })
        local up = ft:sub(1, 1):upper()
        if #ft == 1 then
          cache = up
        else
          cache = ('%s %s'):format(ft_icon or '', up .. ft:sub(2))
        end
        return cache
      end
    end)(),
    event = { 'BufEnter', 'FileType' },
    attr = { fg = '#D8DEE9', bold = true },
  }
end

function M.position()
  -- api.nvim_set_hl(0, 'WhiskyLinePosPercent', { fg = '#81A1C1' }) -- white1
  -- api.nvim_set_hl(0, 'WhiskyLinePosArrow', { fg = '#81A1C1' }) -- blue1
  -- api.nvim_set_hl(0, 'WhiskyLinePosLine', { fg = '#81A1C1' }) -- white1
  -- api.nvim_set_hl(0, 'WhiskyLinePosCol', { fg = '#81A1C1' }) -- white1
  return {
    stl = '  %#WhiskyLinePosPercent#%P%*'
      .. "  %#WhiskyLinePosArrow# %*%#WhiskyLinePosLine#%{printf('0d%04D', line('.'))}%*"
      .. "  %#WhiskyLinePosArrow# %*%#WhiskyLinePosCol#%{printf('0d%04D', col('.'))}%*    ",
    name = 'position',
    attr = { link = 'StatusLine' },
  }
end

function M.searchcount()
  return {
    stl = function()
      if vim.v.hlsearch == 0 then
        return ''
      end
      local ok, result = pcall(vim.fn.searchcount)
      if not ok or result.total == 0 then
        return ''
      end
      local total = result.incomplete == 1 and '?'
        or tostring(math.min(result.total, result.maxcount or result.total))
      return (' %d/%s '):format(result.current, total)
    end,
    name = 'searchcount',
    event = { 'CursorMoved', 'CmdlineLeave' },
    attr = { fg = '#81A1C1', bold = true },
  }
end

function M.progress()
  local spinner = { '⣶', '⣧', '⣏', '⡟', '⠿', '⢻', '⣹', '⣼' }
  local idx = 1
  return {
    stl = function(args)
      if args.data and args.data.params then
        local val = args.data.params.value
        if val.message and val.kind ~= 'end' then
          idx = idx + 1 > #spinner and 1 or idx + 1
          return ('%s'):format(spinner[idx - 1 > 0 and idx - 1 or 1])
        end
      end
      return ''
    end,
    name = 'LspProgress',
    event = { 'LspProgress' },
    attr = { link = 'Type' },
  }
end

function M.formatter()
  return {
    stl = (function()
      local cache = ''
      return function(args)
        local bufnr = (args and args.buf) or 0
        local bt = api.nvim_get_option_value('buftype', { buf = bufnr })
        if bt ~= '' then
          return cache
        end
        local ft = api.nvim_get_option_value('filetype', { buf = bufnr })
        if ft == '' then
          return cache
        end
        local ok, guard_ft = pcall(require, 'guard.filetype')
        if not ok then
          return cache
        end
        local fmt_conf = guard_ft[ft]
        if not fmt_conf or not fmt_conf.formatter then
          cache = ''
          return cache
        end
        local names = {}
        for _, f in ipairs(fmt_conf.formatter) do
          if f.cmd then
            names[#names + 1] = vim.fn.fnamemodify(tostring(f.cmd), ':t')
          elseif f.fn then
            names[#names + 1] = 'custom'
          end
        end
        cache = #names > 0 and (' 󰁨 %s '):format(table.concat(names, '+')) or ''
        return cache
      end
    end)(),
    name = 'formatter',
    event = { 'BufEnter', 'FileType' },
    attr = { bg = '#81A1C1', fg = '#181D25', bold = true },
  }
end

function M.lsp()
  return {
    stl = function(args)
      local clients = lsp.get_clients({ bufnr = 0 })
      if #clients == 0 then
        return ''
      end
      local root_dir = 'single'
      local client_names = vim
        .iter(clients)
        :map(function(client)
          if client.root_dir then
            root_dir = client.root_dir
          end
          return client.name
        end)
        :totable()

      local msg = ('%s:%s'):format(
        table.concat(client_names, ','),
        root_dir ~= 'single' and fnamemodify(root_dir, ':t') or 'single'
      )
      if args.data and args.data.params then
        local val = args.data.params.value
        if val.message and val.kind ~= 'end' then
          msg = ('%s %s%s'):format(
            val.title,
            (val.message and val.message .. ' ' or ''),
            (val.percentage and val.percentage .. '%' or '')
          )
        end
      elseif args.event == 'LspDetach' then
        msg = ''
      end
      return ' 󱌣 %-20s' .. msg
    end,
    name = 'Lsp',
    attr = { fg = '#181D25', bg = '#81A1C1', bold = true },
    event = { 'LspProgress', 'LspAttach', 'LspDetach', 'BufEnter' },
  }
end

function M.gitinfo()
  local alias = { 'Head', 'Add', 'Change', 'Delete' }
  api.nvim_set_hl(0, 'WhiskyLineGitHead', { bg = '#181D25', fg = '#81A1C1', bold = true })
  local git_colors = { '#A3BE8C', '#EBCB8B', '#BF616A' }
  for i = 2, 4 do
    api.nvim_set_hl(
      0,
      'WhiskyLineGit' .. alias[i],
      { fg = git_colors[i - 1], bg = '#181D25', bold = true }
    )
  end
  return {
    stl = function()
      return coroutine.create(function(pieces, idx)
        local signs = { '󰊢 ', '  ', '  ', '  ' }
        local order = { 'head', 'added', 'changed', 'removed' }

        local ok, dict = pcall(api.nvim_buf_get_var, 0, 'gitsigns_status_dict')
        if not ok or vim.tbl_isempty(dict) then
          return ''
        end
        if dict['head'] == '' then
          local co = coroutine.running()
          vim.system(
            { 'git', 'config', '--get', 'init.defaultBranch' },
            { text = true },
            function(result)
              coroutine.resume(co, #result.stdout > 0 and vim.trim(result.stdout) or nil)
            end
          )
          dict['head'] = coroutine.yield()
        end
        local parts = ''
        for i = 1, 4 do
          if i == 1 or (type(dict[order[i]]) == 'number' and dict[order[i]] > 0) then
            local item = ('%%#WhiskyLineGit%s#%s %%*'):format(alias[i], signs[i] .. dict[order[i]])
            parts = parts .. (parts ~= '' and '%#WhiskyLineCap#%*' or '') .. item
          end
        end
        pieces[idx] = parts
      end)
    end,
    async = true,
    name = 'git',
    event = { 'User GitSignsUpdate', 'BufEnter' },
  }
end

function M.diagnostic()
  local icons = { ' 󰅙 ', ' 󰀨 ', ' 󰋼 ' } -- error, warn, info
  return {
    name = 'diagnostic',
    stl = function()
      if not vim.diagnostic.is_enabled({ bufnr = 0 }) or #lsp.get_clients({ bufnr = 0 }) == 0 then
        return ''
      end
      local t = {}
      for i = 1, 3 do
        local count = #diagnostic.get(0, { severity = i })
        t[#t + 1] = ('%%#Diagnostic%s#%s%s%%*'):format(vim.diagnostic.severity[i], icons[i], count)
      end
      return (' %s'):format(table.concat(t, ' '))
    end,
    event = { 'DiagnosticChanged', 'BufEnter', 'LspAttach' },
  }
end

function M.eol()
  return {
    name = 'eol',
    stl = (not uv.os_uname().sysname:find('Windows')) and ':' or '(Dos)',
    event = { 'BufEnter' },
  }
end

function M.encoding()
  local map = {
    ['utf-8'] = 'U',
    ['utf-16'] = 'U16',
    ['utf-32'] = 'U32',
  }
  return {
    stl = ('-%s%s'):format(map[vim.o.encoding] or 'U', map[vim.bo.fileencoding] or 'U'),
    name = 'filencode',
    event = { 'BufEnter' },
  }
end

---@private
local function binary_search(tbl, line)
  local left = 1
  local right = #tbl
  local mid = 0

  while true do
    mid = bit.rshift(left + right, 1)
    if not tbl[mid] then
      return
    end

    local range = tbl[mid].range or tbl[mid].location.range
    if not range then
      return
    end

    if line >= range.start.line and line <= range['end'].line then
      return mid
    elseif line < range.start.line then
      right = mid - 1
    else
      left = mid + 1
    end
    if left > right then
      return
    end
  end
end

function M.doucment_symbol()
  return {
    stl = function()
      return coroutine.create(function(pieces, idx)
        local params = { textDocument = lsp.util.make_text_document_params() }
        local co = coroutine.running()
        lsp.buf_request(0, 'textDocument/documentSymbol', params, function(err, result, ctx)
          if err or not api.nvim_buf_is_loaded(ctx.bufnr) then
            return
          end
          local lnum = api.nvim_win_get_cursor(0)[1]
          local mid = binary_search(result, lnum)
          if not mid then
            return
          end
          coroutine.resume(co, result[mid])
        end)
        local data = coroutine.yield()
        pieces[idx] = (' %s '):format(data.name)
      end)
    end,
    async = true,
    name = 'DocumentSymbol',
    event = { 'CursorHold' },
  }
end

return M
