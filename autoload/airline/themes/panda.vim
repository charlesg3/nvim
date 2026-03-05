" autoload/airline/themes/panda.vim
" Airline theme for the Panda color scheme.
"
" Section layout (left → right, symmetric):
"   a: accent bg (mode color)        z: accent bg
"   b: pale accent bg (30% blend)    y: pale accent bg
"   c: grey  #31353A                 x: grey #31353A
"              middle: editor bg #1A1B1C (clear)

scriptencoding utf-8

let g:airline#themes#panda#palette = {}

" ── Shared ───────────────────────────────────────────────────────────────────
" Section colours come from g:color_* globals set by colors/panda.vim.
let s:bg   = g:color_bg           " #1A1B1C  editor bg / middle gutter
let s:grey = g:color_grey         " #31353A  section c / x
let s:dim  = g:color_dim          " #676B79  inactive fg
let s:dfg  = g:color_bg           " #1A1B1C  section_a fg (dark text on bright accent)
let s:fg   = g:color_fg           " #E6E6E6  section b/c fg
let s:ia   = '#242628'            " inactive section_a bg (no mode tint)

" ── Normal — lime ────────────────────────────────────────────────────────────
let s:N1 = [s:dfg, g:color_green,        232, 120, 'bold']
let s:N2 = [s:fg,  g:color_muted_green,  254, 235        ]
let s:N3 = [s:fg,  s:grey,               254, 236        ]
let g:airline#themes#panda#palette.normal = airline#themes#generate_color_map(s:N1, s:N2, s:N3)
let g:airline#themes#panda#palette.normal_modified = {
  \ 'airline_c': [g:color_orange, s:grey, 215, 236, ''] }

" ── Insert — blue ─────────────────────────────────────────────────────────────
let s:I1 = [s:dfg, g:color_blue,        232, 117, 'bold']
let s:I2 = [s:fg,  g:color_muted_blue,  254, 235        ]
let s:I3 = [s:fg,  s:grey,              254, 236        ]
let g:airline#themes#panda#palette.insert = airline#themes#generate_color_map(s:I1, s:I2, s:I3)
let g:airline#themes#panda#palette.insert_modified = {
  \ 'airline_c': [g:color_orange, s:grey, 215, 236, ''] }
let g:airline#themes#panda#palette.insert_paste = {
  \ 'airline_a': [s:dfg, g:color_orange, 232, 215, 'bold'] }

" ── Visual — lavender ────────────────────────────────────────────────────────
let s:V1 = [s:dfg, g:color_purple,           232, 189, 'bold']
let s:V2 = [s:fg,  g:color_muted_lavender,   254, 235        ]
let s:V3 = [s:fg,  s:grey,                   254, 236        ]
let g:airline#themes#panda#palette.visual = airline#themes#generate_color_map(s:V1, s:V2, s:V3)
let g:airline#themes#panda#palette.visual_modified = {
  \ 'airline_c': [g:color_orange, s:grey, 215, 236, ''] }

" ── Replace — hot pink ───────────────────────────────────────────────────────
let s:R1 = [s:dfg, g:color_hot_pink,  232, 197, 'bold']
let s:R2 = [s:fg,  g:color_muted_red, 254, 235        ]
let s:R3 = [s:fg,  s:grey,            254, 236        ]
let g:airline#themes#panda#palette.replace = airline#themes#generate_color_map(s:R1, s:R2, s:R3)
let g:airline#themes#panda#palette.replace_modified = {
  \ 'airline_c': [g:color_orange, s:grey, 215, 236, ''] }

" ── Command — orange ─────────────────────────────────────────────────────────
let s:C1 = [s:dfg, g:color_orange,        232, 215, 'bold']
let s:C2 = [s:fg,  g:color_muted_orange,  254, 235        ]
let s:C3 = [s:fg,  s:grey,                254, 236        ]
let g:airline#themes#panda#palette.commandline = airline#themes#generate_color_map(s:C1, s:C2, s:C3)

" ── Terminal — cyan ───────────────────────────────────────────────────────────
let s:T1 = [s:dfg, g:color_cyan,        232, 122, 'bold']
let s:T2 = [s:fg,  g:color_muted_cyan,  254, 235        ]
let s:T3 = [s:fg,  s:grey,              254, 236        ]
let g:airline#themes#panda#palette.terminal = airline#themes#generate_color_map(s:T1, s:T2, s:T3)

" ── Inactive ─────────────────────────────────────────────────────────────────
" Progressive grey gradient from outside in: a/z → b/y → c/x → editor bg
"   a/z  #464C57  outermost — lightest inactive grey
"   b/y  #3B4149  middle step
"   c/x  #31353A  innermost section — matches active-mode grey (s:grey)
"   mid  #1A1B1C  editor bg
let s:ia2 = '#464C57'   " inactive a/z bg
let s:ib2 = '#3B4149'   " inactive b/y bg
let g:airline#themes#panda#palette.inactive = airline#themes#generate_color_map(
  \ [s:dim, s:ia2,  243, 238, ''],
  \ [s:dim, s:ib2,  243, 237, ''],
  \ [s:dim, s:bg,   243, 232, ''])
" generate_color_map mirrors N3 (editor bg) onto both airline_c and airline_x.
" Override both to use s:grey so section_c/x are visible and match active modes.
let g:airline#themes#panda#palette.inactive.airline_c = [s:dim, s:grey, 243, 236, '']
let g:airline#themes#panda#palette.inactive.airline_x = [s:dim, s:grey, 243, 236, '']
let g:airline#themes#panda#palette.inactive_modified = {
  \ 'airline_c': [g:color_orange, s:grey, 215, 236, ''] }


" ── Accents ───────────────────────────────────────────────────────────────────
let g:airline#themes#panda#palette.accents = {
  \ 'red': [g:color_hot_pink, '', 197, ''] }
