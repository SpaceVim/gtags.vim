" File: gtags.vim
" Author: Tama Communications Corporation
" Author: rxwen
" Author: critiqjo
" Version: 1.0
" Last Modified: Oct 02 11:37:36 CST 2015
"
" Copyright and licence
" ---------------------
" Copyright (c) 2004, 2008, 2010, 2011 Tama Communications Corporation
"
" This file is part of GNU GLOBAL.
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.

if !executable('gtags')
    " gtags application is not executable
    finish
else
    let ver_str = split(system('gtags --version'), '\n')[0]
    let s:version = split(matchstr(ver_str, '[0-9]\+\.[0-9]\+'), '\.')
endif

if exists("loaded_gtags")
    finish
endif
let loaded_gtags = 1

if !exists("g:Gtags_Auto_Map")
    let g:Gtags_Auto_Map = 1
endif

"
" global command name
"
let s:global_command = $GTAGSGLOBAL
if s:global_command == ''
    let s:global_command = "global"
endif
" Open the Gtags output window.  Set this variable to zero, to not open
" the Gtags output window by default.  You can open it manually by using
" the :cwindow command.
" (This code was drived from 'grep.vim'.)
if !exists("g:Gtags_OpenQuickfixWindow")
    let g:Gtags_OpenQuickfixWindow = 1
endif

if !exists("g:Gtags_VerticalWindow")
    let g:Gtags_VerticalWindow = 0
endif

if !exists("Gtags_Auto_Map")
    let Gtags_Auto_Map = 0
endif

" -- ctags-x format
" let Gtags_Result = "ctags-x"
" let Gtags_Efm = "%*\\S%*\\s%l%\\s%f%\\s%m"
"
" -- ctags format
" let Gtags_Result = "ctags"
" let Gtags_Efm = "%m\t%f\t%l"
"
" Gtags_Use_Tags_Format is obsoleted.
if exists("g:Gtags_Use_Tags_Format")
    let g:Gtags_Result = "ctags"
    let g:Gtags_Efm = "%m\t%f\t%l"
endif
if !exists("g:Gtags_Result")
    let g:Gtags_Result = "ctags-x"
endif
if !exists("g:Gtags_Efm")
    let g:Gtags_Efm = "%*\\S%*\\s%l%\\s%f%\\s%m"
endif
" Character to use to quote patterns and file names before passing to global.
" (This code was drived from 'grep.vim'.)
if !exists("g:Gtags_Shell_Quote_Char")
    if has("win32") || has("win16") || has("win95")
        let g:Gtags_Shell_Quote_Char = '"'
    else
        let g:Gtags_Shell_Quote_Char = "'"
    endif
endif
if !exists("g:Gtags_Single_Quote_Char")
    if has("win32") || has("win16") || has("win95")
        let g:Gtags_Single_Quote_Char = "'"
        let g:Gtags_Double_Quote_Char = '\"'
    else
        let s:sq = "'"
        let s:dq = '"'
        let g:Gtags_Single_Quote_Char = s:sq . s:dq . s:sq . s:dq . s:sq
        let g:Gtags_Double_Quote_Char = '"'
    endif
endif

" Suggested map:
function! s:MapKeys()
    nnoremap <C-\><C-\> :Gtags <C-R>=expand("<cword>")<CR><CR>
    " search for tags not defined
    nnoremap <C-\>s :call <SID>Func ("s", expand("<cword>"))<CR>
    " search for definition
    nnoremap <C-\>g :call <SID>Func ("g", expand("<cword>"))<CR>
    " search for reference
    nnoremap <C-\>c :call <SID>Func ("r", expand("<cword>"))<CR>
    " search for pattern, like egrep
    nnoremap <C-\>e :call <SID>Func ("e", expand("<cword>"))<CR>
    " search for file
    nnoremap <C-\>f :call <SID>Func ("f", expand("<cword>"))<CR>
    " search tags in current file
    nnoremap <C-\>t :call <SID>Func ("t", expand("%"))<CR>

    nnoremap <C-\>S :call <SID>Func
        \("s", input('Find symbols not defined: ', '',
        \"custom,GtagsCandidate"))<CR>
    nnoremap <C-\>G :call <SID>Func
        \("g", input('Find this definition: ', '',
        \"custom,GtagsCandidate"))<CR>
    nnoremap <C-\>C :call <SID>Func
        \("r", input('Find functions calling this function: ', '',
        \"custom,GtagsCandidate"))<CR>
    nnoremap <C-\>E :call <SID>Func
        \("e", input('Find pattern: ', '',
        \"custom,GtagsCandidate"))<CR>
    nnoremap <C-\>F :call <SID>Func
        \("f", input('Find file: ', '',
        \"custom,GtagsCandidate"))<CR>
    nnoremap <C-\>T :call <SID>Func
        \("t", input('Find tags in file: ', '',
        \"file"))<CR>
    nnoremap <C-\>u :call <SID>UpdateDatabase ()<CR><CR>
endfunction

if g:Gtags_Auto_Map == 1
    call s:MapKeys()
endif

"
" Stack Object.
"
function! s:Stack()
    let l:this = {}
    let l:this.container = []

    function! l:this.push(item)
        call add(self.container, a:item)
    endfunction

    function! l:this.pop()
        if len(self.container) <= 0
            throw 'Stack Empty'
        endif

        let l:item = self.container[-1]
        unlet self.container[-1]

        return l:item
    endfunction

    return l:this
endfunction

function! s:Memorize()
    let l:data = {
        \"file": expand("%"),
        \"position": getpos("."),
    \}
    call s:crumbs.push(l:data)
endfunction

function! s:Remind()
    try
        let l:data = s:crumbs.pop()
    catch
        call s:Error(v:exception)
        return
    endtry

    execute "e " . l:data.file
    call setpos(".", l:data.position)
endfunction

if ! exists("s:crumbs")
    let s:crumbs = s:Stack()
endif

"
" Display error message.
"
function! s:Error(msg)
    echohl WarningMsg |
           \ echomsg 'Error: ' . a:msg |
           \ echohl None
endfunction
"
" Extract pattern or option string.
"
function! s:Extract(line, target)
    let l:option = ''
    let l:pattern = ''
    let l:force_pattern = 0
    let l:length = strlen(a:line)
    let l:i = 0

    " skip command name.
    if a:line =~ '^Gtags'
        let l:i = 5
    endif
    while l:i < l:length && a:line[l:i] == ' '
       let l:i = l:i + 1
    endwhile
    while l:i < l:length
        if a:line[l:i] == "-" && l:force_pattern == 0
            let l:i = l:i + 1
            " Ignore long name option like --help.
            if l:i < l:length && a:line[l:i] == '-'
                while l:i < l:length && a:line[l:i] != ' '
                   let l:i = l:i + 1
                endwhile
            else
                let l:c = ''
                while l:i < l:length && a:line[l:i] != ' '
                    let l:c = a:line[l:i]
                    let l:option = l:option . l:c
                    let l:i = l:i + 1
                endwhile
                if l:c == 'e'
                    let l:force_pattern = 1
                endif
            endif
        else
            let l:pattern = ''
            " allow pattern includes blanks.
            while l:i < l:length
                 if a:line[l:i] == "'"
                     let l:pattern = l:pattern . g:Gtags_Single_Quote_Char
                 elseif a:line[l:i] == '"'
                     let l:pattern = l:pattern . g:Gtags_Double_Quote_Char
                 else
                     let l:pattern = l:pattern . a:line[l:i]
                 endif
                let l:i = l:i + 1
            endwhile
            if a:target == 'pattern'
                return l:pattern
            endif
        endif
        " Skip blanks.
        while l:i < l:length && a:line[l:i] == ' '
               let l:i = l:i + 1
        endwhile
    endwhile
    if a:target == 'option'
        return l:option
    endif
    return ''
endfunction

"
" Trim options to avoid errors.
"
function! s:TrimOption(option)
    let l:option = ''
    let l:length = strlen(a:option)
    let l:i = 0

    while l:i < l:length
        let l:c = a:option[l:i]
        if l:c !~# '[cenpquv]'
            let l:option = l:option . l:c
        endif
        let l:i = l:i + 1
    endwhile
    return l:option
endfunction

"
" Execute global and load the result into quickfix window.
"
function! s:ExecLoad(option, long_option, pattern)
    " Execute global(1) command and write the result to a temporary file.
    let l:isfile = 0
    let l:option = ''
    let l:result = ''

    if a:option =~# 'f'
        let l:isfile = 1
        if filereadable(a:pattern) == 0
            call s:Error('File ' . a:pattern . ' not found.')
            return
        endif
    endif
    if a:long_option != ''
        let l:option = a:long_option . ' '
    endif
    if s:version[0] > 6 || (s:version[0] == 6 && s:version[1] >= 5)
        let l:option = l:option . '--nearness=' . expand('%:p:h') . ' '
    endif
    let l:option = l:option . '--result=' . g:Gtags_Result . ' -q'
    let l:option = l:option . s:TrimOption(a:option)
    if l:isfile == 1
        let l:cmd = s:global_command . ' ' . l:option . ' ' . g:Gtags_Shell_Quote_Char . a:pattern . g:Gtags_Shell_Quote_Char
    else
        let l:cmd = s:global_command . ' ' . l:option . 'e ' . g:Gtags_Shell_Quote_Char . a:pattern . g:Gtags_Shell_Quote_Char
    endif

    let l:result = system(l:cmd)
    if v:shell_error != 0
        if v:shell_error == 2
            call s:Error('invalid arguments. (gtags.vim requires GLOBAL 5.7 or later)')
        elseif v:shell_error == 3
            call s:Error('GTAGS not found.')
        else
            call s:Error('global command failed. command line: ' . l:cmd)
        endif
        return
    endif
    if l:result == ''
        if a:option =~# 'f'
            call s:Error('No tags found in ' . a:pattern)
        elseif a:option =~# 'P'
            call s:Error('No path matches found for ' . a:pattern)
        elseif a:option =~# 'g'
            call s:Error('No line matches found for ' . a:pattern)
        else
            call s:Error('No tag matches found for ' . g:Gtags_Shell_Quote_Char . a:pattern . g:Gtags_Shell_Quote_Char)
        endif
        return
    endif

    call s:Memorize()

    " Open the quickfix window
    if g:Gtags_OpenQuickfixWindow == 1
        if g:Gtags_VerticalWindow == 1
            topleft vertical copen
        else
            botright copen
        endif
    endif
    " Parse the output of 'global -x or -t' and show in the quickfix window.
    let l:efm_org = &efm
    let &efm = g:Gtags_Efm
    cexpr! l:result
    let &efm = l:efm_org
endfunction

"
" RunGlobal()
"
function! s:RunGlobal(line)
    let l:pattern = s:Extract(a:line, 'pattern')

    if l:pattern == '%'
        let l:pattern = expand('%')
    elseif l:pattern == '#'
        let l:pattern = expand('#')
    endif
    let l:option = s:Extract(a:line, 'option')
    " If no pattern supplied then get it from user.
    if l:pattern == ''
        let s:option = l:option
        if l:option =~ 'f'
            let l:line = input("Gtags for file: ", expand('%'), 'file')
        else
            let l:line = input("Gtags for pattern: ", expand('<cword>'), 'custom,GtagsCandidateCore')
        endif
        let l:pattern = s:Extract(l:line, 'pattern')
        if l:pattern == ''
            call s:Error('Pattern not specified.')
            return
        endif
    endif
    call s:ExecLoad(l:option, '', l:pattern)
endfunction

"
" Execute RunGlobal() depending on the current position.
"
function! s:Cursor()
    let l:pattern = expand("<cword>")
    let l:option = "--from-here=\"" . line('.') . ":" . expand("%") . "\""
    call s:ExecLoad('', l:option, l:pattern)
endfunction

"
" Core Gtags function
"
function! s:Func(type, pattern)
    let l:option = ""
    if a:type == "g"
        let l:option .= " -x "
    elseif a:type == "r"
        let l:option .= " -x -r "
    elseif a:type == "s"
        let l:option .= " -x -s "
    elseif a:type == "e"
        let l:option .= " -x -g "
    elseif a:type == "f"
        let l:option .= " -x -P "
    endif
    call s:ExecLoad('', l:option, a:pattern)
endfunction

"
" Update gtags database
"
function! s:UpdateDatabase()
    echomsg "update gtags database"
    let l:result = system("global -u")
endfunction

"
" Show the current position on mozilla.
" (You need to execute htags(1) in your source directory.)
"
function! s:Gozilla()
    let l:lineno = line('.')
    let l:filename = expand("%")
    let l:result = system('gozilla +' . l:lineno . ' ' . l:filename)
endfunction

"
" Custom completion.
"
function! GtagsCandidate(lead, line, pos)
    let s:option = s:Extract(a:line, 'option')
    return GtagsCandidateCore(a:lead, a:line, a:pos)
endfunction

function! GtagsCandidateCore(lead, line, pos)
    if s:option == 'g'
        return ''
    elseif s:option == 'f'
        if isdirectory(a:lead)
            if a:lead =~ '/$'
                let l:pattern = a:lead . '*'
            else
                let l:pattern = a:lead . '/*'
            endif
        else
            let l:pattern = a:lead . '*'
        endif
        return glob(l:pattern)
    else
        let l:cands = system(s:global_command . ' ' . '-c' . s:option . ' ' . a:lead)
        if v:shell_error == 0
            return l:cands
        endif
        return ''
    endif
endfunction

function! s:ShowLibPath()
    echo $GTAGSLIBPATH
endfunction

function! s:AddLib(path)
    let $GTAGSLIBPATH .= ':'.a:path
    echo $GTAGSLIBPATH
endfunction

" Define the set of Gtags commands
command! -nargs=* -complete=custom,GtagsCandidate Gtags call s:RunGlobal(<q-args>)
command! -nargs=0 GtagsCursor call s:Cursor()
command! -nargs=0 Gozilla call s:Gozilla()
command! -nargs=+ -complete=custom,GtagsCandidate GtagsFunc call s:Func(<f-args>)
command! -nargs=0 GtagsShowLibPath call s:ShowLibPath()
command! -nargs=+ -complete=dir GtagsAddLib call s:AddLib(<q-args>)
command! -nargs=0 GtagsRemind call s:Remind()
command! GtagsMapKeys call s:MapKeys()
