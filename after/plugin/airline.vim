" after/plugin/airline.vim — vim-airline configuration.
" Loaded after all plugins so airline#parts#define_* calls are safe.

let g:airline#extensions#tabline#enabled = 1
" Place the "BUFFERS" label on the left (before the buffer list) so the right
" side of the tabline is clear fill — leaving room for the clock strip.
let g:airline#extensions#tabline#buf_label_first = 1
let g:airline_powerline_fonts = 1
let g:airline_theme = 'panda'

let g:airline#extensions#hunks#enabled = 0
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#term#enabled = 0
let g:airline_inactive_collapse = 0

let g:airline_mode_map = {
  \ '__' : '·',
  \ 'n'  : 'N',
  \ 'i'  : 'I',
  \ 'R'  : 'R',
  \ 'v'  : 'V',
  \ 'V'  : 'V-L',
  \ 'c'  : 'C',
  \ 's'  : 'S',
  \ 'S'  : 'S-L',
  \ 't'  : 'T',
  \ }

" ---------------------------------------------------------------------------
" Layout functions
" ---------------------------------------------------------------------------

" AirlineFixSepCG3() — re-pins airline_c_to_airline_x to grey-on-editor-bg.
" Called via %{%AirlineFixSepCG3()%} embedded in section_a, so it runs on
" every statusline render before airline's separator glyph is applied.
" Returns '' — no visual output, side-effect only.
function! AirlineFixSepCG3()
  exec 'highlight airline_c_to_airline_x guifg=' . g:color_grey . ' guibg=' . g:color_bg . ' gui=NONE cterm=NONE'
  return ''
endfunction

function! AirlineFilenameCG3()
  if &buftype ==# 'terminal'
    " Extract process name from term://path//JOB_ID:PROCESS
    let l:name = matchstr(bufname('%'), '//\d\+:\zs.*')
    return '  ' . (l:name !=# '' ? l:name : bufname('%'))
  endif
  return '📁 ' . expand('%:p:h:t') . '/' . expand('%:t') . (&modified ? ' +' : '')
endfunction


" ---------------------------------------------------------------------------
" Terminal window sections — delegates to lua/airline_term.lua.
"
" Data collection (cwd via /proc or lsof, foreground process via pgrep+ps,
" git status) runs on a vim.uv timer using non-blocking vim.system() calls.
" get_b() / get_c() return pre-built strings from a Lua cache — zero I/O at
" render time, no event-loop stalls, no cursor flicker.
" ---------------------------------------------------------------------------

" AirlineSection_b_cg3() — section_b content.
" Terminal: 📁 dirname  <sep>  💻 process-name   (from Lua async cache)
" Normal:   parent-dir/filename (+ if modified)
function! AirlineSection_b_cg3()
  if &buftype ==# 'terminal'
    " Pass [bufnr, active] to Lua. `active` controls whether %#Group# highlight
    " escapes are emitted: they must be omitted for inactive windows because
    " airline's builder transforms static escapes in the statusline string but
    " NOT ones produced dynamically by %{%expr%} at render time — leaving them
    " in inactive windows bleeds active highlight colours through.
    return luaeval("require('airline_term').get_b(_A[1], _A[2])",
          \ [bufnr('%'), get(w:, 'cg3_active', 1)])
  endif
  return AirlineFilenameCG3()
endfunction

" AirlineSection_c_cg3() — section_c content.
" Terminal: 🌿 branch  +staged *modified ?untracked   (from Lua async cache)
" Normal:   empty
function! AirlineSection_c_cg3()
  if &buftype ==# 'terminal'
    return luaeval("require('airline_term').get_c(_A[1], _A[2])",
          \ [bufnr('%'), get(w:, 'cg3_active', 1)])
  endif
  return ''
endfunction

" Inline highlight groups for terminal sections.
" Colors from g:color_* globals set by colors/panda.vim.
" Background matched to airline_b so the labels blend into the statusline.
function! s:SetupTermHighlights()
  let l:b_bg = synIDattr(synIDtrans(hlID('airline_b')), 'bg#')
  let l:c_bg = synIDattr(synIDtrans(hlID('airline_c')), 'bg#')
  " section_b groups: process name and directory
  exec 'highlight AirlineTermName      guifg=' . g:color_green  . ' guibg=' . l:b_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineTermDir       guifg=' . g:color_fg     . ' guibg=' . l:b_bg . ' gui=NONE cterm=NONE'
  " section_c groups: branch and git status
  exec 'highlight AirlineTermBranch    guifg=' . g:color_purple . ' guibg=' . l:c_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineTermStatus    guifg=' . g:color_orange . ' guibg=' . l:c_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineTermUntracked guifg=' . g:color_dim    . ' guibg=' . l:c_bg . ' gui=NONE cterm=NONE'
  " airline_term is what builder.vim uses for section_c in terminal buffers
  " (it swaps airline_c → airline_term); pin its bg to match airline_c so the
  " b→c separator uses grey, not the dark #202020 default from themes#patch
  exec 'highlight airline_term guifg=' . g:color_fg . ' guibg=' . l:c_bg . ' gui=NONE cterm=NONE'
  " Fix B → C separator in terminal buffers: highlight() re-creates
  " airline_b_to_airline_term using airline_term.bg from the palette (#202020)
  " before we pin it above, so the > gets the wrong background.  Override it
  " here so it always matches the actual airline_term bg we just set.
  exec 'highlight airline_b_to_airline_term guifg=' . l:b_bg . ' guibg=' . l:c_bg . ' gui=NONE cterm=NONE'
  " _inactive variants: airline appends _inactive to every %#Group# in inactive
  " windows (builder.vim).  Without explicit definitions these fall back to
  " StatusLineNC.  Pin them to airline_b/c_inactive backgrounds so our custom
  " terminal section labels blend into the inactive statusline correctly.
  let l:fill_bg       = synIDattr(synIDtrans(hlID('Normal')), 'bg#')
  " Separator between section_c (grey) and the fill area (editor bg).
  exec 'highlight AirlineFillSep guifg=' . l:c_bg . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'
  let l:b_inactive_bg = synIDattr(synIDtrans(hlID('airline_b_inactive')), 'bg#')
  let l:c_inactive_bg = synIDattr(synIDtrans(hlID('airline_c_inactive')), 'bg#')
  let l:inactive_fg   = synIDattr(synIDtrans(hlID('airline_b_inactive')), 'fg#')
  exec 'highlight AirlineTermName_inactive      guifg=' . l:inactive_fg . ' guibg=' . l:b_inactive_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineTermDir_inactive       guifg=' . l:inactive_fg . ' guibg=' . l:b_inactive_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineTermBranch_inactive    guifg=' . l:inactive_fg . ' guibg=' . l:c_inactive_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineTermStatus_inactive    guifg=' . l:inactive_fg . ' guibg=' . l:c_inactive_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineTermUntracked_inactive guifg=' . l:inactive_fg . ' guibg=' . l:c_inactive_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineFillSep_inactive       guifg=' . l:c_inactive_bg . ' guibg=' . l:fill_bg      . ' gui=NONE cterm=NONE'
  exec 'highlight Normal_inactive               guifg=' . l:inactive_fg   . ' guibg=' . l:fill_bg      . ' gui=NONE cterm=NONE'
  " Fix c{bufnr}→x inactive separator for all loaded buffers.
  " Inactive airline_c/x are both grey; auto-generated separator is invisible.
  " Override with grey-fg-on-editor-bg so the ◄ is visible in inactive windows.
  for l:bnr in filter(range(1, bufnr('$')), 'bufloaded(v:val)')
    call s:FixInactiveXSep(l:bnr)
  endfor
endfunction

" Override airline_c{bufnr}_to_airline_x_inactive with grey-fg-on-editor-bg so
" the < separator is visible.  Called on SetupTermHighlights and on WinLeave.
function! s:FixInactiveXSep(bufnr)
  let l:c_inactive_bg = synIDattr(synIDtrans(hlID('airline_c_inactive')), 'bg#')
  let l:fill_bg       = synIDattr(synIDtrans(hlID('Normal')), 'bg#')
  if !empty(l:c_inactive_bg) && !empty(l:fill_bg)
    exec 'highlight airline_c' . a:bufnr . '_to_airline_x_inactive'
          \ . ' guifg=' . l:c_inactive_bg . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'
  endif
endfunction

" ---------------------------------------------------------------------------
" Tabline clock strip — highlight groups and wrapper function.
"
" The right side of the tabline mirrors the statusline's normal-mode X→Y→Z
" green fade (grey → muted green → bright lime), assembled left to right:
"
"   ╔══════════════════════╦═══════════════════╦════════════════╗
"   ║  grey  (X)           ║  muted green (Y)  ║  bright lime   ║
"   ║  📄 current file     ║  📅 Wed, Mar  4   ║  🕑 14:32 (Z)  ║
"   ╚══════════════════════╩═══════════════════╩════════════════╝
"
" Separator colour rule: the glyph is drawn in a group whose fg = the
" outgoing section's bg and bg = the incoming section's bg.  This makes the
" solid  triangle appear as if the incoming section is "wedging" into the
" outgoing one:
"
" Separator colour rule for airline_right_sep (◄, solid triangle pointing left):
"   fg = the RIGHT section's bg  (fills the triangle body — the "incoming" colour)
"   bg = the LEFT  section's bg  (the surface the triangle sits on)
" This makes the triangle appear as the right section "wedging" into the left.
"
"   FillX  fg=X_bg,  bg=fill_bg   bridges tabfill → X
"   XY     fg=Y_bg,  bg=X_bg      bridges X → Y
"   YZ     fg=Z_bg,  bg=Y_bg      bridges Y → Z
" ---------------------------------------------------------------------------

function! s:SetupTablineHighlights()
  " ── Clock strip groups (X/Y/Z right-side sections) ───────────────────────
  " All colours from g:color_* globals set by colors/panda.vim — single source.
  " X bg = grey         (section_c colour — inactive tabs and clock X strip)
  " Y bg = muted green  (section_b normal-mode colour — active buffer and clock Y)
  " Z bg = bright lime  (section_a normal-mode accent — BUFFERS label and clock Z)
  let l:x_bg  = g:color_grey
  let l:y_bg  = g:color_muted_green
  let l:z_bg  = g:color_green
  let l:light = g:color_fg   " legible on grey and muted green
  let l:dark  = g:color_bg   " legible on bright lime

  " The fill area between the buffer list and the clock strip mirrors the middle
  " of the bottom airline bar — both should show the editor background.
  " Set airline_tabfill explicitly; don't rely on airline's default (which can
  " be grey).  Derive fill_bg from the global rather than reading it back so
  " the FillX separator calculation is always correct.
  let l:fill_bg = g:color_bg
  exec 'highlight airline_tabfill guifg=' . l:dark . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'

  " airline_right_sep (◄) rule: fg = RIGHT section's bg, bg = LEFT section's bg.
  " The triangle's solid body (fg) shows the incoming colour; the background
  " surface (bg) is the outgoing section the triangle sits on top of.
  exec 'highlight AirlineClockFillX guifg=' . l:x_bg . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineClockX    guifg=' . l:light . ' guibg=' . l:x_bg    . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineClockXY   guifg=' . l:y_bg  . ' guibg=' . l:x_bg    . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineClockY    guifg=' . l:light . ' guibg=' . l:y_bg    . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineClockYZ   guifg=' . l:z_bg  . ' guibg=' . l:y_bg    . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineClockZ    guifg=' . l:dark  . ' guibg=' . l:z_bg    . ' gui=NONE cterm=NONE'

  " ── Tabline buffer tab highlights ─────────────────────────────────────────
  " Override airline's defaults so the buffer list mirrors the green fade:
  "   BUFFERS label  → bright lime (bold, like section_z accent)
  "   active buffer  → muted green (like section_y)
  "   inactive tabs  → grey        (like section_x/c)
  " Set highlight groups directly — more reliable than injecting into the
  " palette dict, since airline applies highlights during its own init and
  " we run after AirlineRefresh.
  exec 'highlight airline_tablabel       guifg=' . l:dark         . ' guibg=' . l:z_bg . ' gui=bold cterm=bold'
  exec 'highlight airline_tablabel_right guifg=' . l:dark         . ' guibg=' . l:z_bg . ' gui=bold cterm=bold'
  exec 'highlight airline_tabsel         guifg=' . l:light        . ' guibg=' . l:y_bg . ' gui=NONE cterm=NONE'
  " Hidden buffers (not visible in any window) use the same grey as visible
  " inactive ones — dim fg made them look darker than section C/X.
  exec 'highlight airline_tab            guifg=' . l:light        . ' guibg=' . l:x_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tabhid         guifg=' . l:light        . ' guibg=' . l:x_bg . ' gui=NONE cterm=NONE'
  " Modified-buffer variants (keep orange indicator, change bg to match fade).
  exec 'highlight airline_tabmod         guifg=' . g:color_orange . ' guibg=' . l:y_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tabmod_unsel   guifg=' . g:color_orange . ' guibg=' . l:x_bg . ' gui=NONE cterm=NONE'

  " Tab separator transition groups: airline_left_sep (►) convention —
  "   fg = LEFT section's bg, bg = RIGHT section's bg.
  " Same-colour transitions (tab→tab, tabhid→tabhid, etc.) use fg=bg=x_bg so
  " the ► glyph is invisible — the tabs run together as one seamless block.
  exec 'highlight airline_tablabel_to_airline_tabsel    guifg=' . l:z_bg . ' guibg=' . l:y_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tablabel_to_airline_tab       guifg=' . l:z_bg . ' guibg=' . l:x_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tablabel_to_airline_tabhid    guifg=' . l:z_bg . ' guibg=' . l:x_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tabsel_to_airline_tab         guifg=' . l:y_bg . ' guibg=' . l:x_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tabsel_to_airline_tabhid      guifg=' . l:y_bg . ' guibg=' . l:x_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tab_to_airline_tabsel         guifg=' . l:x_bg . ' guibg=' . l:y_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tabhid_to_airline_tabsel      guifg=' . l:x_bg . ' guibg=' . l:y_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tab_to_airline_tab            guifg=' . l:x_bg . ' guibg=' . l:x_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tab_to_airline_tabhid         guifg=' . l:x_bg . ' guibg=' . l:x_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tabhid_to_airline_tab         guifg=' . l:x_bg . ' guibg=' . l:x_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tabhid_to_airline_tabhid      guifg=' . l:x_bg . ' guibg=' . l:x_bg . ' gui=NONE cterm=NONE'

  " Tab → tabfill transitions: the ► glyph at the end of the buffer list.
  " fg = the last tab's bg, bg = fill area bg (editor bg).
  exec 'highlight airline_tab_to_airline_tabfill        guifg=' . l:x_bg . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tabhid_to_airline_tabfill     guifg=' . l:x_bg . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tabsel_to_airline_tabfill     guifg=' . l:y_bg . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'
  exec 'highlight airline_tabmod_to_airline_tabfill     guifg=' . l:y_bg . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'

  " Force a tabline redraw so all groups take effect immediately.
  redrawtabline
endfunction

" TablineWithClock()
" Wraps airline's normal tabline output and appends the three-section clock
" strip.  The X section (current buffer name) is built here — dynamically
" evaluated on every tabline redraw — because it changes on buffer switch, not
" on a timer.  The Y and Z sections (date + time) come from the Lua cache.
function! TablineWithClock()
  " Current buffer tail name; fall back to '[No Name]' for unnamed buffers.
  let l:name = expand('%:t')
  if l:name ==# '' | let l:name = '[No Name]' | endif
  let l:sep  = get(g:, 'airline_right_sep', '')
  return airline#extensions#tabline#get()
        \ . '%#AirlineClockFillX#' . l:sep
        \ . '%#AirlineClockX# 📄 ' . l:name . ' '
        \ . luaeval("require('airline_clock').get()")
endfunction

function! AirLineCG3()
  " 📁 = folder emoji; shows parent-dir/filename like the Claude statusline
  call airline#parts#define_function('filename', 'AirlineFilenameCG3')
  call airline#parts#define_raw('term_b', '%{%AirlineSection_b_cg3()%}')
  call airline#parts#define_raw('term_c', '%{%AirlineSection_c_cg3()%}')

  " AirlineFixSepCG3() is prepended to section_a so it runs early in every
  " statusline render, BEFORE airline's %#airline_c_to_airline_x# is applied.
  " Airline's add_separator regenerates airline_c_to_airline_x as grey→grey
  " (c and x share the same bg) on every render; this re-pins it to
  " grey-on-editor-bg within the same render cycle — no event hooks needed.
  let g:airline_section_a = '%{%AirlineFixSepCG3()%}' . airline#section#create_left(['mode'])

  let g:airline_section_b = airline#section#create_left(['term_b'])
  let g:airline_section_gutter = '%#AirlineFillSep#' . g:airline_left_sep . '%#Normal#%='
  let g:airline_section_c = airline#section#create_left(['term_c'])

  let g:airline_section_a_term = airline#section#create_left(['mode'])
  let g:airline_section_error   = airline#section#create(['ale_error_count'])
  let g:airline_section_warning = airline#section#create(['ale_warning_count'])
  let g:airline_section_x = airline#section#create_right(['(%{strlen(&ft)?&ft:"none"})'])
  let g:airline_section_y = airline#section#create_right(['%l:%c'])
  let g:airline_section_z = airline#section#create_right(['%P'])
endfunction

augroup airline_init
  autocmd!
  " AirlineTheme forces a full palette reload (re-executes the theme file and
  " re-applies all highlight groups), whereas AirlineRefresh only redraws the
  " statusline with whatever highlights are already set.  Call AirlineTheme
  " first to guarantee panda colours are active, then AirLineCG3+AirlineRefresh
  " to rebuild the layout with our custom sections on top.
  autocmd VimEnter  * AirlineTheme panda | call AirLineCG3() | AirlineRefresh
        \ | call s:SetupTermHighlights()
        \ | call s:SetupTablineHighlights()
        \ | set tabline=%!TablineWithClock()
        \ | lua require('airline_clock').start()
  " On colorscheme change: reload the airline theme (re-reads g:color_* globals),
  " then re-pin the inline terminal and tabline highlight groups.
  autocmd ColorScheme * AirlineTheme panda | call s:SetupTermHighlights()
        \ | call s:SetupTablineHighlights()
        \ | lua require('airline_clock').rebuild()
  " Re-apply both sets of custom highlights after every airline update.
  " AirlineModeChanged fires when airline changes mode colours (which resets
  " airline_b bg, breaking AirlineTermName/Dir backgrounds).
  " WinEnter fires when airline rebuilds the tabline, which re-applies its own
  " default airline_tab/airline_tabfill colours and wipes our overrides.
  autocmd User AirlineModeChanged  call s:SetupTermHighlights() | call s:SetupTablineHighlights()
  autocmd User AirlineAfterTheme  call s:SetupTablineHighlights()
  autocmd WinEnter * call s:SetupTablineHighlights()
  " Rebuild airline's statusline context when a terminal opens, and start the
  " async data-collection timer (delay=0 so the cache is warm immediately).
  autocmd TermOpen  * call airline#update_statusline() | lua require('airline_term').start()
  " Clear the cache entry for a terminal buffer when it is closed, and stop the
  " timer if no terminal buffers remain.  BufDelete fires while the buffer still
  " exists so getbufvar can check its type.
  autocmd BufDelete *
        \ if getbufvar(expand('<abuf>') + 0, '&buftype') ==# 'terminal' |
        \   call luaeval("require('airline_term').on_buf_delete(_A)", expand('<abuf>') + 0) |
        \ endif
  " Track active window so terminal render functions can skip inline highlights
  " in inactive windows (dynamic %#Group# output bypasses the builder's
  " _inactive substitution and would bleed active colours through).
  autocmd WinEnter * let w:cg3_active = 1
  autocmd WinLeave * let w:cg3_active = 0 | call s:FixInactiveXSep(bufnr('%'))
augroup END
