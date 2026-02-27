" Panda Syntax — Vim/Neovim color scheme
" Ported from github.com/PandaTheme/panda-syntax-vscode

set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "panda"

" ── Raw palette ───────────────────────────────────────────────────────────────
let s:bg           = '#1A1B1C'
let s:fg           = '#E6E6E6'
let s:hot_pink     = '#FF2C6D'   " bright red / error
let s:pink         = '#FF75B5'   " keywords
let s:light_pink   = '#FF9AC1'   " keyword variants
let s:cursor       = '#FF4B82'   " cursor
let s:cyan         = '#8CF0E4'   " strings (pale mint)
let s:lime         = '#A8F0A6'   " UI accents (lime green)
let s:lavender     = '#B1B9F5'   " UI accents (lavender)
let s:blue         = '#6FC1FF'   " functions
let s:light_blue   = '#45A9F9'   " escape chars / tags
let s:orange       = '#FFB86C'   " constants
let s:light_orange = '#FFCC95'   " operators / variables
let s:purple       = '#B084EB'   " tags / class names
" s:light_purple = s:lavender (see above)
let s:comment      = '#676B79'   " comments / dim
let s:selection    = '#31353A'   " selection / line highlight

" ── Semantic aliases ──────────────────────────────────────────────────────────
let s:keyword  = s:pink
let s:string   = s:lime
let s:func     = s:blue
let s:constant = s:orange
let s:variable = s:light_orange
let s:operator = s:light_orange
let s:tag      = s:purple
let s:escape   = s:light_blue
let s:comment_col = s:lavender
let s:error    = s:hot_pink
let s:warning  = s:orange
let s:info     = s:blue

" ── Helper: hi(group, fg, bg, attr) ──────────────────────────────────────────
function! s:hi(group, fg, bg, attr)
  let l:cmd = 'hi ' . a:group
  if !empty(a:fg)   | let l:cmd .= ' guifg=' . a:fg   | endif
  if !empty(a:bg)   | let l:cmd .= ' guibg=' . a:bg   | endif
  if !empty(a:attr) | let l:cmd .= ' gui='   . a:attr | endif
  execute l:cmd
endfunction

" ── Syntax ────────────────────────────────────────────────────────────────────
call s:hi('Normal',      s:fg,       s:bg,        'NONE')
call s:hi('Comment',     s:comment_col, '',         'italic')
call s:hi('Constant',    s:constant, '',           'NONE')
call s:hi('Number',      s:constant, '',           'NONE')
call s:hi('Boolean',     s:constant, '',           'NONE')
call s:hi('Float',       s:constant, '',           'NONE')
call s:hi('String',      s:string,   '',           'NONE')
call s:hi('Character',   s:string,   '',           'NONE')
call s:hi('Identifier',  s:variable, '',           'NONE')
call s:hi('Function',    s:func,     '',           'NONE')
call s:hi('Statement',   s:keyword,  '',           'NONE')
call s:hi('Keyword',     s:keyword,  '',           'NONE')
call s:hi('Conditional', s:keyword,  '',           'NONE')
call s:hi('Repeat',      s:keyword,  '',           'NONE')
call s:hi('Label',       s:keyword,  '',           'NONE')
call s:hi('Exception',   s:error,    '',           'NONE')
call s:hi('Operator',    s:operator, '',           'NONE')
call s:hi('PreProc',     s:pink,     '',           'NONE')
call s:hi('Include',     s:pink,     '',           'NONE')
call s:hi('Define',      s:pink,     '',           'NONE')
call s:hi('Macro',       s:pink,     '',           'NONE')
call s:hi('Type',        s:tag,      '',           'NONE')
call s:hi('StorageClass',s:keyword,  '',           'NONE')
call s:hi('Structure',   s:tag,      '',           'NONE')
call s:hi('Typedef',     s:tag,      '',           'NONE')
call s:hi('Special',     s:escape,   '',           'NONE')
call s:hi('SpecialChar', s:escape,   '',           'NONE')
call s:hi('Underlined',  s:blue,     '',           'underline')
call s:hi('Error',       s:error,    '',           'NONE')
call s:hi('Todo',        s:bg,       s:pink,       'bold')
call s:hi('Ignore',      s:comment,  '',           'NONE')

" ── UI ────────────────────────────────────────────────────────────────────────
call s:hi('LineNr',       s:comment,   s:bg,        'NONE')
call s:hi('CursorLine',   '',          s:selection, 'NONE')
call s:hi('CursorLineNr', s:pink,      s:selection, 'bold')
call s:hi('CursorColumn', '',          s:selection, 'NONE')
call s:hi('ColorColumn',  '',          s:selection, 'NONE')
call s:hi('SignColumn',   s:comment,   s:bg,        'NONE')
call s:hi('FoldColumn',   s:comment,   s:bg,        'NONE')
call s:hi('Folded',       s:comment,   s:selection, 'NONE')
call s:hi('Visual',       '',          s:selection, 'NONE')
call s:hi('Search',       s:bg,        s:cyan,      'NONE')
call s:hi('IncSearch',    s:bg,        s:pink,      'NONE')
call s:hi('MatchParen',   s:cyan,      '',          'bold')
call s:hi('NonText',      s:comment,   '',          'NONE')
call s:hi('SpecialKey',   s:comment,   '',          'NONE')
call s:hi('Conceal',      s:comment,   '',          'NONE')
call s:hi('Directory',    s:blue,      '',          'NONE')
call s:hi('Title',        s:pink,      '',          'bold')
call s:hi('WildMenu',     s:bg,        s:cyan,      'NONE')
call s:hi('StatusLine',   s:fg,        s:selection, 'NONE')
call s:hi('StatusLineNC', s:comment,   s:bg,        'NONE')
call s:hi('TabLine',      s:comment,   s:selection, 'NONE')
call s:hi('TabLineFill',  '',          s:bg,        'NONE')
call s:hi('TabLineSel',   s:fg,        s:bg,        'bold')
call s:hi('VertSplit',    s:selection, s:bg,        'NONE')
call s:hi('WinSeparator', s:selection, s:bg,        'NONE')
call s:hi('Pmenu',        s:fg,        s:selection, 'NONE')
call s:hi('PmenuSel',     s:bg,        s:cyan,      'NONE')
call s:hi('PmenuSbar',    '',          s:selection, 'NONE')
call s:hi('PmenuThumb',   '',          s:comment,   'NONE')

" ── Diff ──────────────────────────────────────────────────────────────────────
call s:hi('DiffAdd',    s:cyan,     '#1B3330', 'NONE')
call s:hi('DiffChange', s:orange,   '#332B1A', 'NONE')
call s:hi('DiffDelete', s:hot_pink, '#331A22', 'NONE')
call s:hi('DiffText',   s:bg,       s:orange,  'NONE')

" ── ALE linting ───────────────────────────────────────────────────────────────
call s:hi('ALEError',       s:error,   '',   'undercurl')
call s:hi('ALEWarning',     s:warning, '',   'undercurl')
call s:hi('ALEInfo',        s:info,    '',   'undercurl')
call s:hi('ALEErrorSign',   s:error,   s:bg, 'NONE')
call s:hi('ALEWarningSign', s:warning, s:bg, 'NONE')
call s:hi('ALEInfoSign',    s:info,    s:bg, 'NONE')

" ── nvim-tree ────────────────────────────────────────────────────────────────
" NvimTreeNormal is the fallback for regular file names (no specific group)
call s:hi('NvimTreeNormal',           s:lime,     s:bg,  'NONE')
call s:hi('NvimTreeFolderName',       s:lavender, '',    'NONE')
call s:hi('NvimTreeOpenedFolderName', s:lavender, '',    'NONE')
call s:hi('NvimTreeEmptyFolderName',  s:lavender, '',    'NONE')
call s:hi('NvimTreeSymlinkFolderName',s:lavender, '',    'NONE')
call s:hi('NvimTreeFolderIcon',       s:lavender, '',    'NONE')
call s:hi('NvimTreeRootFolder',       s:purple,   '',    'bold')
call s:hi('NvimTreeSpecialFile',      s:lavender, '',    'NONE')
call s:hi('NvimTreeExecFile',         s:lime,     '',    'NONE')
call s:hi('NvimTreeImageFile',        s:lavender, '',    'NONE')
call s:hi('NvimTreeSymlink',          s:cyan,     '',    'underline')
call s:hi('NvimTreeIndentMarker',     s:comment,  '',    'NONE')

" ── Global vars (for Lua/init.vim cross-theme references) ────────────────────
let g:color_green   = s:lime
let g:color_cyan    = s:cyan
let g:color_purple  = s:lavender
let g:color_peach   = s:light_pink
let g:color_blue    = s:blue

" ── Tree-sitter capture group links ──────────────────────────────────────────
" Explicit links ensure treesitter uses our theme regardless of nvim version
hi! link @comment              Comment
hi! link @comment.doc          Comment
hi! link @string               String
hi! link @string.special       Special
hi! link @number               Number
hi! link @float                Float
hi! link @boolean              Boolean
hi! link @constant             Constant
hi! link @constant.builtin     Constant
hi! link @function             Function
hi! link @function.call        Function
hi! link @function.method      Function
hi! link @function.method.call Function
hi! link @keyword              Keyword
hi! link @keyword.function     Keyword
hi! link @keyword.return       Keyword
hi! link @keyword.operator     Operator
hi! link @operator             Operator
hi! link @type                 Type
hi! link @type.builtin         Type
hi! link @variable             Identifier
hi! link @variable.parameter   Identifier
hi! link @variable.member      Identifier
hi! link @property             Identifier
hi! link @tag                  Type
hi! link @punctuation          Normal
hi! link @punctuation.bracket  Normal
hi! link @punctuation.delimiter Normal
hi! link @markup.heading       Title
hi! link @markup.strong        Bold
hi! link @markup.italic        Italic
hi! link @markup.raw           Special

" ── Neovim :terminal colors ───────────────────────────────────────────────────
if has('nvim')
  let g:terminal_color_0  = '#292A2B'   " black         (bg)
  let g:terminal_color_1  = '#FF2C6D'   " red           (hot pink)
  let g:terminal_color_2  = '#A8F0A6'   " green         (lime)
  let g:terminal_color_3  = '#FFB86C'   " yellow        (orange)
  let g:terminal_color_4  = '#45A9F9'   " blue          (light blue)
  let g:terminal_color_5  = '#FF75B5'   " magenta       (pink)
  let g:terminal_color_6  = '#B084EB'   " cyan          (purple)
  let g:terminal_color_7  = '#E6E6E6'   " white         (fg)
  let g:terminal_color_8  = '#676B79'   " bright black  (comment)
  let g:terminal_color_9  = '#FF2C6D'   " bright red
  let g:terminal_color_10 = '#A8F0A6'   " bright green  (lime)
  let g:terminal_color_11 = '#FFCC95'   " bright yellow (light orange)
  let g:terminal_color_12 = '#6FC1FF'   " bright blue
  let g:terminal_color_13 = '#FF9AC1'   " bright magenta (light pink)
  let g:terminal_color_14 = '#B1B9F5'   " bright cyan   (lavender)
  let g:terminal_color_15 = '#FFFFFF'   " bright white
endif
