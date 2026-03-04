" after/plugin/airline.vim — vim-airline configuration.
" Loaded after all plugins so airline#parts#define_* calls are safe.

let g:airline#extensions#tabline#enabled = 1
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
  " fill-area separator: grey fg on editor-bg — used for > after section_c and < before section_x
  let l:fill_bg = synIDattr(synIDtrans(hlID('Normal')), 'bg#')
  exec 'highlight AirlineFillSep guifg=' . l:c_bg . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'
  " Fix fill → X separator: airline auto-generates airline_c_to_airline_x as grey→grey
  " (airline_c and airline_x share the same bg in generate_color_map), making the
  " powerline < invisible.  Override so < renders as grey-on-editor-bg, matching
  " the AirlineFillSep > on the left side.
  exec 'highlight airline_c_to_airline_x guifg=' . l:c_bg . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'
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
  let l:b_inactive_bg = synIDattr(synIDtrans(hlID('airline_b_inactive')), 'bg#')
  let l:c_inactive_bg = synIDattr(synIDtrans(hlID('airline_c_inactive')), 'bg#')
  let l:inactive_fg   = synIDattr(synIDtrans(hlID('airline_b_inactive')), 'fg#')
  exec 'highlight AirlineTermName_inactive      guifg=' . l:inactive_fg . ' guibg=' . l:b_inactive_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineTermDir_inactive       guifg=' . l:inactive_fg . ' guibg=' . l:b_inactive_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineTermBranch_inactive    guifg=' . l:inactive_fg . ' guibg=' . l:c_inactive_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineTermStatus_inactive    guifg=' . l:inactive_fg . ' guibg=' . l:c_inactive_bg . ' gui=NONE cterm=NONE'
  exec 'highlight AirlineTermUntracked_inactive guifg=' . l:inactive_fg . ' guibg=' . l:c_inactive_bg . ' gui=NONE cterm=NONE'
  " AirlineFillSep_inactive: the fill-area > separator, fg = c_inactive_bg so the
  " powerline glyph forms a clean boundary; Normal_inactive: fill space uses editor bg.
  exec 'highlight AirlineFillSep_inactive guifg=' . l:c_inactive_bg . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'
  exec 'highlight Normal_inactive         guifg=' . l:inactive_fg   . ' guibg=' . l:fill_bg . ' gui=NONE cterm=NONE'
  " Fix c{bufnr}→x inactive separator for all loaded buffers.
  " For inactive windows builder.vim substitutes airline_c → airline_c{bufnr}, so
  " the fill→x separator is airline_c{bufnr}_to_airline_x_inactive (per-bufnr).
  " airline auto-generates it grey→grey (invisible); override like we do for the
  " active airline_c_to_airline_x above.
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

function! AirLineCG3()
  " 📁 = folder emoji; shows parent-dir/filename like the Claude statusline
  call airline#parts#define_function('filename', 'AirlineFilenameCG3')
  call airline#parts#define_raw('term_b', '%{%AirlineSection_b_cg3()%}')
  call airline#parts#define_raw('term_c', '%{%AirlineSection_c_cg3()%}')

  let g:airline_section_a = airline#section#create_left(['mode'])

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
  autocmd VimEnter  * call AirLineCG3() | AirlineRefresh | call s:SetupTermHighlights()
  autocmd ColorScheme         * call s:SetupTermHighlights()
  autocmd User AirlineModeChanged call s:SetupTermHighlights()
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
