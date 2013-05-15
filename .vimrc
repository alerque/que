:version 6

colorscheme ps_color

if &term == "screen"
    "set t_kb=
    "fixdel
endif

set nofoldenable
set enc=utf8
set fencs=utf8,cp1254,latin1
set autoindent
set smartindent
set showmatch	"show matchign brackets
"set smarttab
"set cindent
set smartcase
set tabstop=4
set shiftwidth=4
set syntax=on
set infercase
set nohlsearch
set matchpairs+=«:»
set shiftround
set wildmenu
set nowrap
set backup
set backupskip=
set backupdir=.
set noerrorbells
set history=1000
set ruler	"show ruller at bottom
set scrolloff=1	"give context when scrolling
set hlsearch	"highlight search results
set backspace=2	"smart backspace
set nostartofline
set fo+=r
"set list
"set listchars=tab:>-
set ttymouse=xterm2
set splitright
set complete+=k/usr/dict/*

nmap I :set paste<Cr>i
"<esc>I sets paste mode
nmap i :set nopaste<Cr>i
"<esc>i clears paste mode

let fileType = &ft
if fileType == 'php'
    set kp=/home/users/caleb/bin/phpman
    "iab _S $_SERVER[']i
    "iab _P $_POST[']i
    "iab _G $_GET[']i
endif

":command! -nargs=+ Calc :py print <args>
":py from math import * 
:command! -nargs=+ Calc :r! python -c "from math import *; print <args>" 

"map ' `	" switch mark jumps so ' goes to column
"map ` '	" and ` goes to row

"map <space> i_<esc>r
map <space> <C-d>

map <tab> >>	"indent when not in edit mode
"map <tab> >>	"indent when not in edit mode

imap <C-g> <C-x><C-f>	" File complete on ctrl g

" safety for craig who can't remember to hit esc instead of f1
map <F1> <Esc>
imap <F1> <Esc>

" alt+: on most machines
map » :
imap » <Esc><Esc>:

" alt+: on rhino
map ; :
map ; <Esc><Esc>:

map <M-;> :
imap <M-;> <Esc><Esc>:

map <F5> :set hls!<bar>set hls?<CR>

if &filetype == ""
"   setfiletype text
    source ~/.notepad
endif

if &filetype == "mail"
    set nosmartindent
endif

function! PoundComment()
    map - 0i# <ESC>j
    map _ :s/^\s*# \=//g<CR>j
    set comments=:#
endfunction

function! LispComment()
    map - 0i; <ESC>j
    map _ :s/^\s*; \=//g<CR>j
    set comments=:;
endfunction

function! HTMLComment()
    map - $a --><ESC>0i<!-- <ESC><CR>
    map _ :s/^\s*<!-- \=//g<CR>:s/ \=-->[ \t]*$//g<CR>j
    set tw=0 formatoptions=tcq
endfunction

function! CComment()
    map - $a */<ESC>0i/* <ESC><CR>
    map _ :s/^\s*\/\* \=//g<CR>:s/ \=\*\/[ \t]*$//g<CR>j
    set nocindent comments=sr:/*,mb:*,ex:*/,://
"   set nocindent comments=:/*,://
endfunction

function! TexComment()
    map - 0i% <ESC>j
    map _ :s/^\s*% \=//g<CR>j
    set nocindent comments=sr:%,mb:%,el:%,://
    set tw=72 formatoptions=tcqro
endfunction

function! CPlusPlusComment()
    map - 0i// <ESC>j
    map _ :s/^\s*\/\/ \=//g<CR>j
    set nocindent comments=:\/\/
endfunction

function! VHDLComment()
    map - 0i-- <ESC>j
    map _ :s/^\s*-- \=//g<CR>j
    set comments=:--
endfunction

" function! CDSLibComment()
"   map - 0i-- <ESC>j
"   map _ :s/^\s*-- \=//g<CR>j
"   set nocindent comments=:--
" endfunction

function! SpiceComment()
    map - 0i* <ESC>j
    map _ :s/^\s*\* \=//g<CR>j
    set comments=:*
endfunction

function! ConfigComment()
    map - 0idnl <ESC>j
    map _ :s/^\s*dnl \=//g<CR>j
    set comments=:dnl
endfunction

function! VimComment()
    map - 0i" <ESC>j
    map _ :s/^\s*" \=//g<CR>j
    set comments=:\"
endfunction

function! XDefaultsComment()
    map - 0i! <ESC>j
    map _ :s/^\s*! \=//g<CR>j
    set comments=:\!
endfunction

function! PostscriptComment()
    map - 0i%% <ESC>j
    map _ :s/^\s*%%\= \=//g<CR>j
    set comments=:\!
endfunction

function! FT_text()
    call PoundComment()
    set tw=72 formatoptions=tcq
endfunction

autocmd Filetype html               call HTMLComment()
autocmd Filetype vhdl               call VHDLComment()
autocmd Filetype c                  call CComment()
autocmd Filetype synopsys           call CComment()
autocmd Filetype css                call CComment()
autocmd Filetype tex                call TexComment()
autocmd Filetype cpp                call CPlusPlusComment()
autocmd Filetype java               call CPlusPlusComment()
autocmd Filetype verilog            call CPlusPlusComment()
autocmd Filetype xdefaults          call XDefaultsComment()
autocmd Filetype config             call ConfigComment()
autocmd Filetype vim                call VimComment()
autocmd Filetype lisp               call LispComment()
autocmd Filetype skill              call LispComment()
autocmd Filetype dosini             call LispComment()
autocmd Filetype spice              call SpiceComment()
autocmd Filetype perl               call PoundComment()
autocmd Filetype apache             call PoundComment()
autocmd Filetype csh                call PoundComment()
autocmd Filetype sh                 call PoundComment()
autocmd Filetype cdslib             call PoundComment()
autocmd Filetype tcl                call PoundComment()
autocmd Filetype xs                 call PoundComment()
autocmd Filetype make               call PoundComment()
autocmd Filetype conf               call PoundComment()
autocmd Filetype fvwm               call PoundComment()
autocmd Filetype samba              call PoundComment()
autocmd Filetype php                call PoundComment()
autocmd Filetype postscr            call PostscriptComment()
autocmd Filetype text               call FT_text()
autocmd Filetype zsh                call PoundComment()

function MyTabOrComplete()
    let col = col('.')-1
    if !col || getline('.')[col-1] !~ '\k'
        return "\<tab>"
    else
        return "\<C-X>\<C-O>"
    endif
endfunction
inoremap <Tab> <C-R>=MyTabOrComplete()<CR>

set nowrap

function FirstInPost (...) range
  let cur = a:firstline
  while cur <= a:lastline
    let str = getline(cur)
    if str == 'Subject: '
      execute cur
      :start!
      break
    endif
    if str == 'To: '
      execute cur
      :start!
      break
    endif
    " We have reached the end of the headers.
    if str == ''
        :start
        normal gg/\n\njyypO
        break
    endif
  let cur = cur + 1
  endwhile
endfunction

" Command to be called.
com Fip :set nosmartindent<Bar>:set tw=0<Bar>:%call FirstInPost() 

function VeryBeautyQuote (...) range
  " The regular expression used to match quoted lines.
  " NOTE: modify this regexp if you have special needs.
  let re_quote = '^>\(\a\{-,3}[>|]\|[> \t|]\)\{,5}'
  set report=30000 " do not report the number of changed lines.
  let cur = a:firstline
  while cur <= a:lastline
     let str = getline(cur)
     " Match the quote.
     let comm = matchstr(str, re_quote)
     let newcomm = comm
     let commlen = strlen(comm)
     let filelen = line('$')
     if commlen > 0
       let startl = cur
       while newcomm == comm
         " Strip the quote from this group of quoted lines.
         let txt = substitute(str, re_quote, '', '')
         call setline(cur, txt)
         let cur = cur + 1
         let str = getline(cur)
         let newcomm = matchstr(str, re_quote)
       endwhile
       let cur = cur - 1
       " Execute fmt for format the (un-)quoted lines.
       " NOTE: you can call any other formatter that act like a command line
       "       filter.
       " NOTE: 72 is the maximum length of a single line, including
       "       the length of the quote.
       execute startl . ',' . cur . '!fmt -' . (72 - commlen)
       " If the length of the file was changed, move the cursor accordingly.
       let lendiff = filelen - line('$')
       if lendiff != 0
         let cur = cur - lendiff
       endif
       " Restore the stripped quote.
       execute startl . ',' . cur . 's/^/' . comm . '/g'
     endif
   let cur = cur + 1
  endwhile
endfunction

" Execute this command to beautifully rearrange the quoted lines.
com Vbq :let strl = line('.')<Bar>:%call VeryBeautyQuote()<Bar>:exec strl

"let fileType = &ft
"if fileType == 'php'
"    iab _S $_SERVER[']hi
"    iab _P $_POST[']hi
"    iab _G $_GET[']hi
"endif

" vim: ts=30 sw=4
