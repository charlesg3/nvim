-- lua/airline_term.lua
-- Async terminal section data collector for vim-airline.
--
-- Problem
-- ═══════
-- airline's %{%expr%} statusline parts run synchronously on every redraw.
-- The former helpers (s:TermFgName, s:TermCwd, s:TermGitInfo) called system()
-- inside those expressions — pgrep, ps, lsof, git — stalling Neovim's event
-- loop and causing visible cursor flicker (lsof on macOS can take hundreds of
-- milliseconds).
--
-- Solution
-- ════════
-- Decouple data collection from rendering:
--
--   Collection — a vim.uv timer fires every INTERVAL ms and refreshes every
--                open terminal buffer using non-blocking vim.system() calls.
--                Results land in _data_cache[bufnr] once all three concurrent
--                sub-pipelines (cwd, foreground process, git) have completed.
--
--   Rendering  — get_b() / get_c() are called by Vimscript at airline redraw
--                time.  They read _data_cache and do only a table lookup and
--                string concatenation — zero I/O, zero cursor flicker.
--
-- Per-buffer collection pipeline (→ = async dependency, ┐ = runs in parallel)
-- ════════════════════════════════════════════════════════════════════════════
--
--   _term_cwd ──→ _term_git
--   _term_fg  ┘
--
--   cwd and fg start in parallel; git waits for cwd then runs concurrently
--   with any remaining fg work; _commit fires once all three are done.

local M = {}

-- ─── Constants ───────────────────────────────────────────────────────────────

-- Refresh period in milliseconds.  Human-speed shell activity (typing a
-- command and pressing Enter) means 2 s gives snappy updates without waste.
local INTERVAL = 2000

-- ─── Module state ────────────────────────────────────────────────────────────

-- Cached terminal data, keyed by bufnr.
-- Shape: { dir, fg_name, bufname, branch, staged, modified, untracked }
-- Written by the background pipeline; read (read-only) by get_b / get_c.
local _data_cache = {}

-- In-flight guard: set of bufnrs whose pipeline is launched but not yet
-- committed.  Prevents a slow lsof or git from stacking concurrent pipelines
-- on the same buffer when INTERVAL elapses before the previous round finishes.
local _refreshing = {}

local _timer = nil

-- ─── Async sub-pipelines ─────────────────────────────────────────────────────

-- _term_cwd(pid, cb)  →  cb(cwd_string)
-- Resolves the shell's working directory for terminal process `pid`.
--
-- Linux  : reads /proc/<pid>/cwd (symlink resolve — no child process, free).
-- macOS  : falls back to `lsof -a -p <pid> -d cwd -Fn`, run asynchronously
--          so the main thread is never blocked.
--
-- NOTE: vim API calls (resolve, isdirectory, getcwd) are made on the calling
-- thread, which is always the main thread (invoked from vim.schedule_wrap).
-- The lsof callback runs on a libuv worker thread; no vim API calls there.
local function _term_cwd(pid, cb)
  -- Linux fast path: /proc/<pid>/cwd is a symlink → the real cwd.
  local link   = '/proc/' .. pid .. '/cwd'
  local target = vim.fn.resolve(link)
  if target ~= link and vim.fn.isdirectory(target) == 1 then
    cb(target)  -- synchronous; caller tolerates this
    return
  end
  -- macOS: capture the fallback on the main thread before spawning, because
  -- vim.fn.getcwd() is not safe to call from a libuv worker thread.
  local fallback = vim.fn.getcwd()
  vim.system(
    { 'lsof', '-a', '-p', tostring(pid), '-d', 'cwd', '-Fn' },
    { text = true },
    function(result)
      -- Running in libuv worker thread — no vim API calls allowed here.
      local cwd = fallback
      if result.code == 0 then
        for _, line in ipairs(vim.split(result.stdout or '', '\n')) do
          if line:match('^n/') then cwd = line:sub(2); break end
        end
      end
      cb(cwd)
    end
  )
end

-- _term_fg(pid, cb)  →  cb(name_string)
-- Returns the name of the shell's current foreground child process, or ''
-- when the shell is idle.  Two chained async calls: pgrep to enumerate child
-- PIDs, then ps to read the full command line of the youngest child.
-- All string processing uses pure Lua (safe on any thread).
local function _term_fg(pid, cb)
  vim.system({ 'pgrep', '-P', tostring(pid) }, { text = true },
    function(pg)
      local stdout = vim.trim(pg.stdout or '')
      if pg.code ~= 0 or stdout == '' then cb(''); return end
      -- Take the last-listed child (most recently spawned).
      local cpids = vim.split(stdout, '\n')
      local cpid  = cpids[#cpids]
      if not cpid or cpid == '' then cb(''); return end

      vim.system({ 'ps', '-o', 'args=', '-p', cpid }, { text = true },
        function(ps)
          if ps.code ~= 0 then cb(''); return end
          local raw  = vim.trim(ps.stdout or '')
          -- Strip the leading path from argv[0]: '/usr/bin/sleep 100' → 'sleep 100'.
          local full = raw:gsub('^%S*/', '')
          -- Truncate long command lines for the statusline.  Process names are
          -- almost always ASCII so byte length ≈ character count — good enough.
          if #full > 20 then full = full:sub(1, 20) .. '…' end
          cb(full)
        end
      )
    end
  )
end

-- _term_git(cwd, cb)  →  cb(branch, staged, modified, untracked)
-- Runs `git status` in `cwd` asynchronously.  All counts are 0 and branch
-- is '' when the directory is not inside a git repository.
local function _term_git(cwd, cb)
  vim.system(
    { 'git', '-C', cwd, 'status', '--porcelain', '--branch', '--no-ahead-behind' },
    { text = true },
    function(result)
      if result.code ~= 0 or (result.stdout or '') == '' then
        cb('', 0, 0, 0); return
      end
      local lines = vim.split(result.stdout, '\n', { trimempty = true })
      local branch = ''
      if lines[1] and lines[1]:match('^## ') then
        branch = lines[1]:match('^## ([^.]*)')
        if branch == 'HEAD (no branch)' then branch = 'HEAD' end
      end
      local staged, modified, untracked = 0, 0, 0
      for i = 2, #lines do
        local l = lines[i]
        if l:match('^[MADRC]') then staged    = staged    + 1 end
        if l:match('^.[MD]')   then modified  = modified  + 1 end
        if l:match('^??')      then untracked = untracked + 1 end
      end
      cb(branch, staged, modified, untracked)
    end
  )
end

-- ─── Per-buffer refresh pipeline ─────────────────────────────────────────────

-- _refresh_buf(bufnr)
-- Launches the three async sub-pipelines for one terminal buffer.
-- _term_cwd and _term_fg run concurrently; _term_git starts after cwd
-- resolves (needs the path).  _commit fires once all three have reported.
-- Must be called from the main thread (reads vim API for initial buf data).
local function _refresh_buf(bufnr)
  if _refreshing[bufnr] then return end  -- previous round still in-flight

  -- Read vim API values on the main thread before any async work begins.
  local pid     = vim.fn.getbufvar(bufnr, 'terminal_job_pid', 0)
  local bufname = vim.fn.bufname(bufnr)
  if pid <= 0 then return end

  _refreshing[bufnr] = true

  -- `results` accumulates sub-pipeline outputs; _commit runs when all are set.
  local results = {}

  -- _commit() — scheduled back onto the main thread via vim.schedule.
  -- Updates _data_cache and requests a statusline redraw only when data changed.
  local function _commit()
    _refreshing[bufnr] = nil
    local new = {
      -- :~:t = tail of the tilde-shortened path (e.g. '~/src/foo' → 'foo').
      dir       = vim.fn.fnamemodify(results.cwd, ':~:t'),
      fg_name   = results.fg_name,
      bufname   = bufname,
      branch    = results.git.branch,
      staged    = results.git.staged,
      modified  = results.git.modified,
      untracked = results.git.untracked,
    }
    -- Skip the redraw when nothing changed (common when the shell is idle).
    -- This is the primary guard against spurious statusline churn.
    if vim.deep_equal(_data_cache[bufnr], new) then return end
    _data_cache[bufnr] = new

    -- No `!` — redraw only the current window's statusline, not all windows.
    -- Using `!` forces redraws on every split including the active terminal,
    -- which is the cursor-blink bug we're fixing.  Inactive terminal statuslines
    -- will be stale until the user visits them; that's an acceptable trade-off
    -- since they're not the user's current focus.
    vim.cmd('redrawstatus')
  end

  -- _finish_if_ready() — called by each sub-pipeline on completion.
  -- Schedules _commit once every sub-pipeline has reported.
  local function _finish_if_ready()
    if results.cwd and results.fg_name and results.git then
      vim.schedule(_commit)
    end
  end

  -- cwd and fg_name start in parallel.
  _term_cwd(pid, function(cwd)
    results.cwd = cwd
    -- git depends on the resolved cwd, so it starts only after cwd is known.
    _term_git(cwd, function(branch, staged, modified, untracked)
      results.git = { branch = branch, staged = staged,
                      modified = modified, untracked = untracked }
      _finish_if_ready()
    end)
    _finish_if_ready()  -- almost always a no-op (fg_name typically still pending)
  end)

  _term_fg(pid, function(name)
    results.fg_name = name
    _finish_if_ready()
  end)
end

-- ─── Timer lifecycle ─────────────────────────────────────────────────────────

-- M.start() — called on TermOpen.  Starts the timer if not already running.
-- delay=0 makes the first tick fire immediately so the cache is warm right away.
function M.start()
  if _timer then return end
  local uv = vim.uv or vim.loop
  _timer = uv.new_timer()
  _timer:start(0, INTERVAL, vim.schedule_wrap(function()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == 'terminal' then
        _refresh_buf(bufnr)
      end
    end
  end))
end

-- M.stop() — stops and destroys the timer.
function M.stop()
  if not _timer then return end
  _timer:stop()
  _timer:close()
  _timer = nil
end

-- M.on_buf_delete(bufnr) — called on BufDelete for terminal buffers.
-- Clears the cache entry and stops the timer when no terminals remain.
function M.on_buf_delete(bufnr)
  _data_cache[bufnr] = nil
  _refreshing[bufnr] = nil
  -- Check whether any other terminal buffers are still alive.
  -- BufDelete fires while the buffer still exists so we exclude bufnr itself.
  local has_terminal = false
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= bufnr
      and vim.api.nvim_buf_is_loaded(b)
      and vim.bo[b].buftype == 'terminal'
    then
      has_terminal = true; break
    end
  end
  if not has_terminal then M.stop() end
end

-- ─── Rendering (called from Vimscript at airline redraw time) ─────────────────

-- These two functions run on the main thread at airline's %{%expr%} evaluation
-- time.  All work is a table lookup + string concatenation — zero I/O.
--
-- `active` (number 1/0 from Vimscript): 1 = focused window, 0 = inactive.
-- Inline %#Group# highlight escapes are included only for active windows.
-- airline's builder transforms static escape sequences in the statusline string,
-- but NOT ones produced dynamically by %{%expr%} at render time; leaving them
-- in inactive windows bleeds active highlight colours through.

-- _sep() — airline's secondary separator glyph.  Read lazily (at first render)
-- so this module can be loaded before vim-airline initialises g:airline_left_alt_sep.
local function _sep()
  return vim.g.airline_left_alt_sep or '|'
end

-- get_b(bufnr, active) → section_b string
-- Layout: 📁 <dirname>  <sep>  💻 <foreground-process-or-shell-name>
function M.get_b(bufnr, active)
  local d = _data_cache[bufnr]
  if not d then return '' end
  -- When the shell is idle, fall back to the shell name embedded in the term:// URI.
  -- URI format:  term://path//JOB_ID:PROCESS_NAME  → extract after the colon.
  local name = (d.fg_name ~= '' and d.fg_name)
    or d.bufname:match('//[0-9]+:(.*)')
    or d.bufname
  if active == 0 then
    return '📁' .. d.dir .. ' ' .. _sep() .. ' 💻' .. name
  end
  return '%#AirlineTermDir#📁' .. d.dir
    .. ' %#AirlineTermName#' .. _sep() .. ' 💻' .. name
end

-- get_c(bufnr, active) → section_c string
-- Layout: 🌿 <branch>  [+staged] [*modified] [?untracked]
function M.get_c(bufnr, active)
  local d = _data_cache[bufnr]
  if not d then return '' end

  local result = ''
  if d.branch ~= '' then
    local hl = active ~= 0 and '%#AirlineTermBranch#' or ''
    result   = hl .. '🌿 ' .. d.branch
  end

  local indicators = {
    { count = d.staged,    sym = '+', hl = 'AirlineTermStatus'    },
    { count = d.modified,  sym = '*', hl = 'AirlineTermStatus'    },
    { count = d.untracked, sym = '?', hl = 'AirlineTermUntracked' },
  }
  local parts = {}
  for _, ind in ipairs(indicators) do
    if ind.count > 0 then
      local hl = active ~= 0 and ('%#' .. ind.hl .. '#') or ''
      table.insert(parts, hl .. ind.sym .. ind.count)
    end
  end
  if #parts > 0 then
    result = result .. (result ~= '' and '  ' or '') .. table.concat(parts, ' ')
  end
  return result
end

return M
