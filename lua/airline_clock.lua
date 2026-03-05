-- lua/airline_clock.lua
-- Tabline clock component for vim-airline.
--
-- Renders the date (Y) and time (Z) sections of a three-part right-side strip
-- on the tabline, mirroring the normal-mode statusline green fade (X→Y→Z):
--
--   ╔═══════════════════╦══════════════════╦══════════════╗
--   ║   grey (X)        ║  muted green (Y) ║ bright lime  ║
--   ║  📄 filename.lua  ║  📅 Wed, Mar  4  ║ 🕑 14:32 (Z) ║
--   ╚═══════════════════╩══════════════════╩══════════════╝
--
-- The X (grey) section — current buffer name — is assembled in Vimscript by
-- TablineWithClock() so it can be evaluated dynamically on every tabline redraw.
-- This module owns only the Y and Z sections (time-based, change once a minute).
--
-- A vim.uv timer fires once at the next round minute, then every 60 s, so the
-- clock turns precisely at :00 rather than drifting from the load time.
-- Between ticks the tabline function reads a cached string — zero work.

local M = {}

-- ─── Clock face emoji tables ─────────────────────────────────────────────────

-- Full-hour faces indexed 1..12: [1]=12:00, [2]=1:00 … [12]=11:00.
local _CLOCK_FULL = {
  '🕛','🕐','🕑','🕒','🕓','🕔','🕕','🕖','🕗','🕘','🕙','🕚',
}
-- Half-hour faces indexed 1..12: [1]=12:30, [2]=1:30 … [12]=11:30.
local _CLOCK_HALF = {
  '🕧','🕜','🕝','🕞','🕟','🕠','🕡','🕢','🕣','🕤','🕥','🕦',
}

-- _clock_emoji(h, m) → emoji
-- h = 0..23, m = 0..59; returns the closest half-hour clock face.
local function _clock_emoji(h, m)
  h = h % 12                            -- 0 = noon/midnight, 1..11 otherwise
  local faces = m >= 30 and _CLOCK_HALF or _CLOCK_FULL
  return faces[h + 1]                   -- 1-indexed; h=0 → index 1 = 🕛/🕧
end

-- Abbreviated day-of-week names (os.date %w: 0=Sunday, 6=Saturday).
local _DOW = { 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' }

-- ─── Cached state ────────────────────────────────────────────────────────────

-- Pre-built tabline string fragment including %#Group# highlight escapes and
-- powerline separator glyphs.  Built once per minute, read on every redraw.
local _clock_str = ''
local _timer     = nil

-- ─── Separator glyph ─────────────────────────────────────────────────────────

-- Read g:airline_right_sep lazily (at first render, not at module load time)
-- so this module is safe to require before vim-airline initialises.
local _sep = nil
local function _right_sep()
  if not _sep then _sep = vim.g.airline_right_sep or '' end
  return _sep
end

-- ─── String builder ──────────────────────────────────────────────────────────

-- _build() → string
-- Constructs the Y+Z tabline fragment (X is assembled in Vimscript):
--   %#AirlineClockXY# <sep> %#AirlineClockY# date %#AirlineClockYZ# <sep> %#AirlineClockZ# time
-- Called once per minute and after color scheme changes.
local function _build()
  -- os.date('*t') returns local time.
  local t       = os.date('*t')
  local emoji   = _clock_emoji(t.hour, t.min)
  -- Pad day to 2 chars so column width is stable across the month.
  local day_str = t.day < 10 and (' ' .. t.day) or tostring(t.day)
  local date    = '📅 ' .. _DOW[t.wday] .. ', ' .. os.date('%b') .. day_str
  local time    = emoji .. ' ' .. string.format('%02d:%02d', t.hour, t.min)
  local sep     = _right_sep()
  -- Each %#Group# escape tells Neovim to switch highlight at that point.
  -- The separator glyph is drawn IN the group whose bg matches where the
  -- glyph's filled side lands — see s:SetupTablineHighlights for the math.
  -- This fragment is prepended by the X section in TablineWithClock(); the
  -- leading AirlineClockXY separator bridges grey (X) → muted green (Y).
  return '%#AirlineClockXY#' .. sep
    .. '%#AirlineClockY# ' .. date .. ' '
    .. '%#AirlineClockYZ#' .. sep
    .. '%#AirlineClockZ# ' .. time .. ' '
end

-- ─── Timer lifecycle ─────────────────────────────────────────────────────────

-- M.start() — start the minute timer.
-- Computes the delay to the next wall-clock :00 so the clock turns exactly on
-- the minute (not 37 s after load time).
function M.start()
  if _timer then return end
  -- Build once immediately so the tabline shows a time on first open.
  _clock_str = _build()

  local uv      = vim.uv or vim.loop
  local t       = os.date('*t')
  -- Seconds until the next full minute; minimum 1 s to avoid a zero delay.
  local delay_s = t.sec == 0 and 60 or (60 - t.sec)

  _timer = uv.new_timer()
  _timer:start(delay_s * 1000, 60000, vim.schedule_wrap(function()
    _clock_str = _build()
    vim.cmd('redrawtabline')
  end))
end

function M.stop()
  if not _timer then return end
  _timer:stop()
  _timer:close()
  _timer = nil
end

-- ─── Public API ──────────────────────────────────────────────────────────────

-- M.get() — returns the pre-built tabline string fragment.
-- Called from the Vimscript TablineWithClock() on every tabline redraw;
-- all work is a single local variable read — no I/O, no allocation.
function M.get() return _clock_str end

-- M.rebuild() — force a fresh build of the clock string.
-- Called after a color scheme change so the cached string still references
-- the correct (now updated) highlight groups.
function M.rebuild()
  _clock_str = _build()
  vim.cmd('redrawtabline')
end

return M
