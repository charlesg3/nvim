" after/plugin/airline.vim — vim-airline configuration.
" Loaded after all plugins so airline#parts#define_* calls are safe.

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme = 'panda'

let g:airline#extensions#hunks#enabled = 0
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#term#enabled = 0

let g:airline_mode_map = {
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

function! AirLineInactiveCG3(...)
  " Build inactive statusline without section_a to avoid the "-----" placeholder
  call a:1.add_section_spaced('airline_b', '%{AirlineFilenameCG3()}')
  call a:1.split()
  call a:1.add_section_spaced('airline_y', '%l:%c')
  call a:1.add_section_spaced('airline_z', '%P')
  return 1
endfunction

" ---------------------------------------------------------------------------
" Terminal window — branch & git status
"
" s:TermCwd()     reads the shell's actual cwd via /proc (Linux) or lsof (macOS).
" s:TermGitInfo() runs git status once per s:git_ttl seconds.  Two-level
"                 cache: cwd per bufnr (s:cwd_ttl) + git data per cwd (s:git_ttl).
" ---------------------------------------------------------------------------

let s:cwd_cache = {}
let s:git_cache = {}
let s:fg_cache  = {}
let s:cwd_ttl   = 5
let s:git_ttl   = 10
let s:fg_ttl    = 1

function! s:TermCwd(bufnr)
  let l:pid = getbufvar(a:bufnr, 'terminal_job_pid', 0)
  if l:pid <= 0 | return getcwd() | endif
  let l:link = '/proc/' . l:pid . '/cwd'
  let l:target = resolve(l:link)
  if l:target !=# l:link && isdirectory(l:target)
    return l:target
  endif
  let l:out = systemlist('lsof -a -p ' . l:pid . ' -d cwd -Fn 2>/dev/null')
  for l:line in l:out
    if l:line =~# '^n/'
      return l:line[1:]
    endif
  endfor
  return getcwd()
endfunction

" Return the name of the shell's foreground child process, or '' if idle.
" Uses pgrep -P to find children; reads /proc/pid/comm on Linux (no fork),
" falls back to ps on macOS.  Results are cached for s:fg_ttl seconds.
function! s:TermFgName(bufnr)
  let l:now = localtime()
  let l:cc  = get(s:fg_cache, a:bufnr, [])
  if len(l:cc) == 2 && l:now - l:cc[1] < s:fg_ttl
    return l:cc[0]
  endif
  let l:pid  = getbufvar(a:bufnr, 'terminal_job_pid', 0)
  let l:name = ''
  if l:pid > 0
    let l:cpids = systemlist('pgrep -P ' . l:pid . ' 2>/dev/null')
    if !empty(l:cpids)
      " ps -o args= gives the full command line (argv[0] + args).
      " Strip any leading path from argv[0] so '/usr/bin/sleep 100' → 'sleep 100'
      " and Homebrew's long Cellar paths are reduced to just the binary name + args.
      let l:raw  = get(systemlist('ps -o args= -p ' . l:cpids[-1] . ' 2>/dev/null'), 0, '')
      let l:full = substitute(l:raw, '^\S*/', '', '')
      let l:name = strcharlen(l:full) > 20 ? strcharpart(l:full, 0, 20) . '…' : l:full
    endif
  endif
  let s:fg_cache[a:bufnr] = [l:name, l:now]
  return l:name
endfunction

function! s:TermGitInfo()
  let l:bufnr = bufnr('%')
  let l:now   = localtime()
  let l:cc = get(s:cwd_cache, l:bufnr, [])
  if len(l:cc) == 2 && l:now - l:cc[1] < s:cwd_ttl
    let l:cwd = l:cc[0]
  else
    let l:cwd = s:TermCwd(l:bufnr)
    let s:cwd_cache[l:bufnr] = [l:cwd, l:now]
  endif
  let l:gc = get(s:git_cache, l:cwd, [])
  if len(l:gc) == 5 && l:now - l:gc[4] < s:git_ttl
    return l:gc[0:3]
  endif
  let l:lines = systemlist(
    \ 'git -C ' . shellescape(l:cwd) .
    \ ' status --porcelain --branch --no-ahead-behind 2>/dev/null')
  if v:shell_error != 0 || empty(l:lines)
    let s:git_cache[l:cwd] = ['', 0, 0, 0, l:now]
    return ['', 0, 0, 0]
  endif
  let l:branch = ''
  if l:lines[0] =~# '^## '
    let l:branch = matchstr(l:lines[0], '^## \zs[^.]*')
    if l:branch ==# 'HEAD (no branch)' | let l:branch = 'HEAD' | endif
  endif
  let l:staged = 0 | let l:modified = 0 | let l:untracked = 0
  for l:line in l:lines[1:]
    if l:line =~# '^[MADRC]' | let l:staged    += 1 | endif
    if l:line =~# '^.[MD]'   | let l:modified  += 1 | endif
    if l:line =~# '^??'      | let l:untracked += 1 | endif
  endfor
  let s:git_cache[l:cwd] = [l:branch, l:staged, l:modified, l:untracked, l:now]
  return [l:branch, l:staged, l:modified, l:untracked]
endfunction

function! s:RenderTermProcess()
  let l:bufnr = bufnr('%')
  " Show the shell's foreground child process when one is running (e.g. python3,
  " sleep).  When the shell is idle, child list is empty and we fall back to the
  " raw shell name (e.g. zsh).  This avoids the long user@host:dir OSC title
  " that shells emit from their precmd hook.
  let l:fg = s:TermFgName(l:bufnr)
  if !empty(l:fg)
    let l:name = l:fg
  else
    let l:name = matchstr(bufname('%'), '//\d\+:\zs.*')
    if l:name ==# '' | let l:name = bufname('%') | endif
  endif
  let l:dir = fnamemodify(s:TermCwd(l:bufnr), ':~:t')
  return '%#AirlineTermDir#📁' . l:dir . ' %#AirlineTermName#' . g:airline_left_alt_sep . ' 💻' . l:name
endfunction

function! s:RenderTermGitStatus()
  let [l:branch, l:staged, l:modified, l:untracked] = s:TermGitInfo()

  " Map each git field to [count, symbol, highlight_group].
  " Add new rows here to display additional git states (e.g. deleted).
  let l:indicators = [
    \ [l:staged,    '+', 'AirlineTermStatus'],
    \ [l:modified,  '*', 'AirlineTermStatus'],
    \ [l:untracked, '?', 'AirlineTermUntracked'],
    \ ]

  let l:counts = []
  for [l:count, l:symbol, l:group] in l:indicators
    if l:count > 0
      call add(l:counts, '%#' . l:group . '#' . l:symbol . l:count)
    endif
  endfor

  let l:result = ''
  if !empty(l:branch)
    let l:result = '%#AirlineTermBranch#🌿 ' . l:branch
  endif
  if !empty(l:counts)
    let l:result .= (empty(l:result) ? '' : '  ') . join(l:counts, ' ')
  endif
  return l:result
endfunction

function! AirlineSection_b_cg3()
  if &buftype ==# 'terminal'
    return s:RenderTermProcess()
  endif
  return AirlineFilenameCG3()
endfunction

function! AirlineSection_c_cg3()
  if &buftype ==# 'terminal'
    return s:RenderTermGitStatus()
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
endfunction

function! AirLineCG3()
  " 📁 = folder emoji; shows parent-dir/filename like the Claude statusline
  call airline#parts#define_function('filename', 'AirlineFilenameCG3')
  call airline#parts#define_raw('term_b', '%{%AirlineSection_b_cg3()%}')
  call airline#parts#define_raw('term_c', '%{%AirlineSection_c_cg3()%}')

  let g:airline_section_a = airline#section#create_left(['mode'])

  let g:airline_inactive_collapse = 0   " show folder icon in inactive windows too
  let g:airline_section_b = airline#section#create_left(['term_b'])
  let g:airline_section_gutter = '%#AirlineFillSep#' . g:airline_left_sep . '%#Normal#%='
  let g:airline_section_c = airline#section#create_left(['term_c'])

  let g:airline_section_a_term = airline#section#create_left(['mode'])
  let g:airline_section_error   = airline#section#create(['ale_error_count'])
  let g:airline_section_warning = airline#section#create(['ale_warning_count'])
  let g:airline_section_x = airline#section#create_right(['(%{strlen(&ft)?&ft:"none"})'])
  let g:airline_section_y = airline#section#create_right(['%l:%c'])
  let g:airline_section_z = airline#section#create_right(['%P'])

  if index(get(g:, 'airline_inactive_funcrefs', []), function('AirLineInactiveCG3')) < 0
    call airline#add_inactive_statusline_func('AirLineInactiveCG3')
  endif
endfunction

augroup airline_init
  autocmd!
  autocmd VimEnter  * call AirLineCG3() | AirlineRefresh | call s:SetupTermHighlights()
  autocmd ColorScheme         * call s:SetupTermHighlights()
  autocmd User AirlineModeChanged call s:SetupTermHighlights()
  autocmd TermOpen  * call airline#update_statusline()
  autocmd WinEnter  * call s:EnsureAirlineStatusline()
augroup END

" Safety net: if airline's own WinEnter didn't install a statusline for the
" new window (cache hit, stl_disabled edge-case, etc.), force a rebuild.
" This autocmd is registered after airline's because after/plugin/ loads
" later than bundle/vim-airline/plugin/, so it always fires last.
function! s:EnsureAirlineStatusline()
  if !exists('#airline') | return | endif           " airline not running
  if get(w:, 'airline_disabled', 0) | return | endif " claude-status / nvim-tree own this window
  if &l:statusline =~# 'airline#statusline' | return | endif " already correct
  call airline#update_statusline()
endfunction
