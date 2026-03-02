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
let s:cwd_ttl   = 5
let s:git_ttl   = 10

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
  let l:name = matchstr(bufname('%'), '//\d\+:\zs.*')
  if l:name ==# '' | let l:name = bufname('%') | endif
  let l:dir = fnamemodify(s:TermCwd(bufnr('%')), ':~:t')
  return '%#AirlineTermDir#📁 ' . l:dir . ' %#AirlineTermName#> 💻 ' . l:name
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
endfunction

function! AirLineCG3()
  " 📁 = folder emoji; shows parent-dir/filename like the Claude statusline
  call airline#parts#define_function('filename', 'AirlineFilenameCG3')
  call airline#parts#define_raw('term_b', '%{%AirlineSection_b_cg3()%}')
  call airline#parts#define_raw('term_c', '%{%AirlineSection_c_cg3()%}')

  let g:airline_section_a = airline#section#create_left(['mode'])

  let g:airline_inactive_collapse = 0   " show folder icon in inactive windows too
  let g:airline_section_b = airline#section#create_left(['term_b'])
  let g:airline_section_gutter = '%#Normal#%='
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
