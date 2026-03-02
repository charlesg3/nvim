" after/plugin/airline.vim — vim-airline configuration.
" Loaded after all plugins so airline#parts#define_* calls are safe.

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme = 'panda'

let g:airline#extensions#hunks#enabled = 0
let g:airline#extensions#whitespace#enabled = 0

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
" Claude window indicator — shows 'C' in #D5795C when the window runs Claude
" ---------------------------------------------------------------------------

function! ClaudeAirlinePart()
  if exists('*ClaudeStatusIsClaudeWin') && ClaudeStatusIsClaudeWin() isnot v:null
    return 'C'
  endif
  return ''
endfunction

function! s:ClaudeSetAirlineHighlight()
  let l:bg = synIDattr(synIDtrans(hlID('airline_a')), 'bg#')
  if l:bg ==# '' | let l:bg = 'NONE' | endif
  exe 'hi airline_a_claude_orange guifg=#D5795C guibg=' . l:bg . ' gui=NONE'
endfunction

augroup airline_claude_highlight
  autocmd!
  autocmd User AirlineAfterTheme call s:ClaudeSetAirlineHighlight()
augroup END

" ---------------------------------------------------------------------------
" Layout functions
" ---------------------------------------------------------------------------

function! AirlineFilenameCG3()
  if &buftype ==# 'terminal'
    " Extract process name from term://path//JOB_ID:PROCESS
    let l:name = matchstr(bufname('%'), '//\d\+:\zs.*')
    return '  ' . (l:name !=# '' ? l:name : bufname('%'))
  endif
  return '󰉋  ' . expand('%:p:h:t') . '/' . expand('%:t') . (&modified ? ' +' : '')
endfunction

function! AirLineInactiveCG3(...)
  " Build inactive statusline without section_a to avoid the "-----" placeholder
  call a:1.add_section_spaced('airline_b', '%{AirlineFilenameCG3()}')
  call a:1.split()
  call a:1.add_section_spaced('airline_y', '%l:%c')
  call a:1.add_section_spaced('airline_z', '%P')
  return 1
endfunction

function! AirLineCG3()
  " 󰉋 = nf-md-folder; shows parent-dir/filename like the Claude statusline
  call airline#parts#define_function('filename', 'AirlineFilenameCG3')

  " Claude window indicator: 'C' in #D5795C right after the mode
  call airline#parts#define_function('claude_win', 'ClaudeAirlinePart')
  call airline#parts#define_accent('claude_win', 'claude_orange')
  let g:airline_section_a = airline#section#create_left(['mode', 'claude_win'])

  let g:airline_inactive_collapse = 0   " show folder icon in inactive windows too
  let g:airline_section_b = airline#section#create_left(['filename'])
  let g:airline_section_gutter = airline#section#create(['%='])
  let g:airline_section_c = airline#section#create([''])

  " Use mode (same as regular buffers) — airline's 'terminal' part shows the raw URI
  let g:airline_section_a_term = airline#section#create_left(['mode', 'claude_win'])
  let g:airline_section_error   = airline#section#create(['ale_error_count'])
  let g:airline_section_warning = airline#section#create(['ale_warning_count'])
  let g:airline_section_x = airline#section#create_right(['(%{strlen(&ft)?&ft:"none"})'])
  let g:airline_section_y = airline#section#create_right(['%l:%c'])
  let g:airline_section_z = airline#section#create_right(['%P'])

  if index(get(g:, 'airline_inactive_funcrefs', []), function('AirLineInactiveCG3')) < 0
    call airline#add_inactive_statusline_func('AirLineInactiveCG3')
  endif

  call s:ClaudeSetAirlineHighlight()
endfunction

augroup airline_init
  autocmd!
  autocmd VimEnter * call AirLineCG3()
  autocmd TermOpen * call airline#update_statusline()
augroup END
