" Panda Syntax airline theme — matches shell/colors.sh palette
" vim: et ts=2 sts=2 sw=2

scriptencoding utf-8

let g:airline#themes#panda#palette = {}

" Palette reference:
"   bg         = #1A1B1C   mid        = #282D32   selection  = #31353A
"   comment    = #676B79   fg         = #E6E6E6
"   lime       = #A8F0A6   blue       = #6FC1FF   hot_pink   = #FF2C6D
"   pink       = #FF75B5   orange     = #FFB86C   lavender   = #BCAAFE   purple = #B084EB

" ── Normal mode ───────────────────────────────────────────────────────────────
" a = mode pill (lime), b = filename area (fg on selection), c = middle (dim on bg)
let s:N1 = [ '#1A1B1C', '#A8F0A6', 232, 120, 'bold' ]
let s:N2 = [ '#E6E6E6', '#31353A', 231, 236        ]
let s:N3 = [ '#E6E6E6', '#282D32', 231, 235        ]
let g:airline#themes#panda#palette.normal = airline#themes#generate_color_map(s:N1, s:N2, s:N3)
let g:airline#themes#panda#palette.normal_modified = {
      \ 'airline_c': [ '#FFB86C', '#1A1B1C', 214, 232, '' ],
      \ }

" ── Insert mode ───────────────────────────────────────────────────────────────
let s:I1 = [ '#1A1B1C', '#6FC1FF', 232, 117, 'bold' ]
let s:I2 = [ '#E6E6E6', '#31353A', 231, 236        ]
let s:I3 = [ '#E6E6E6', '#282D32', 231, 235        ]
let g:airline#themes#panda#palette.insert = airline#themes#generate_color_map(s:I1, s:I2, s:I3)
let g:airline#themes#panda#palette.insert_modified = {
      \ 'airline_c': [ '#FFB86C', '#1A1B1C', 214, 232, '' ],
      \ }

" ── Terminal mode (same colours as insert) ────────────────────────────────────
let g:airline#themes#panda#palette.terminal = airline#themes#generate_color_map(s:I1, s:I2, s:I3)

" ── Replace mode ──────────────────────────────────────────────────────────────
let g:airline#themes#panda#palette.replace = copy(g:airline#themes#panda#palette.insert)
let g:airline#themes#panda#palette.replace.airline_a = [ '#1A1B1C', '#FF2C6D', 232, 197, 'bold' ]
let g:airline#themes#panda#palette.replace_modified  = g:airline#themes#panda#palette.insert_modified

" ── Visual mode ───────────────────────────────────────────────────────────────
let s:V1 = [ '#1A1B1C', '#FF75B5', 232, 212, 'bold' ]
let s:V2 = [ '#E6E6E6', '#31353A', 231, 236        ]
let s:V3 = [ '#E6E6E6', '#282D32', 231, 235        ]
let g:airline#themes#panda#palette.visual = airline#themes#generate_color_map(s:V1, s:V2, s:V3)
let g:airline#themes#panda#palette.visual_modified = {
      \ 'airline_c': [ '#FFB86C', '#1A1B1C', 214, 232, '' ],
      \ }

" ── Command mode ──────────────────────────────────────────────────────────────
let s:C1 = [ '#1A1B1C', '#FFB86C', 232, 214, 'bold' ]
let s:C2 = [ '#E6E6E6', '#31353A', 231, 236        ]
let s:C3 = [ '#E6E6E6', '#282D32', 231, 235        ]
let g:airline#themes#panda#palette.commandline = airline#themes#generate_color_map(s:C1, s:C2, s:C3)

" ── Inactive windows ──────────────────────────────────────────────────────────
let s:IA = [ '#676B79', '#141516', 244, 233, '' ]
let g:airline#themes#panda#palette.inactive          = airline#themes#generate_color_map(s:IA, s:IA, s:IA)
let g:airline#themes#panda#palette.inactive_modified = {
      \ 'airline_c': [ '#B084EB', '', 97, '', '' ],
      \ }

" ── airline_term: shell name shown after the mode label in terminal buffers ───
" Must come after all mode palettes are defined.
" guifg = lime (s:N1[1]), guibg = selection (s:N2[1])
let s:TermLabel = [ s:N1[1], s:N2[1], s:N1[3], s:N2[3], '' ]
let g:airline#themes#panda#palette.normal.airline_term      = s:TermLabel
let g:airline#themes#panda#palette.insert.airline_term      = s:TermLabel
let g:airline#themes#panda#palette.terminal.airline_term    = s:TermLabel
let g:airline#themes#panda#palette.replace.airline_term     = s:TermLabel
let g:airline#themes#panda#palette.visual.airline_term      = s:TermLabel
let g:airline#themes#panda#palette.commandline.airline_term = s:TermLabel
let g:airline#themes#panda#palette.inactive.airline_term    = [ s:IA[0], s:IA[1], s:IA[2], s:IA[3], '' ]

" ── Accents (readonly indicator, etc.) ────────────────────────────────────────
let g:airline#themes#panda#palette.accents = {
      \ 'red': [ '#FF2C6D', '', 197, '' ],
      \ }
