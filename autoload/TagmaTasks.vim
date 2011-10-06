" vim:foldmethod=marker
" =============================================================================
" File:         TagmaTasks.vim (Autoload)
" Last Changed: Thu, Oct 6, 2011
" Maintainer:   Lorance Stinson AT Gmail...
" License:      Public Domain
"
" Description:  Autoload file for TagmaTasks.
"               Contains all the functions.
"               No need to load them if they are not used...
"
" Usage:        Copy files to your .vim or vimfiles directory.
" =============================================================================

" TagmaTasks#AutoUpdate()   - Automatically update the tasks. {{{1
" Done using an auto command on Buffer/File write or external changes.
function! TagmaTasks#AutoUpdate()
    autocmd BufWritePost,FileWritePost,FileChangedShellPost,ShellCmdPost,ShellFilterPost
          \ <buffer> call TagmaTasks#Generate('A')
    if g:TagmaTasksIdleUpdate
    autocmd CursorHold <buffer> call TagmaTasks#Generate('A')
    endif
endfunction

" TagmaTasks#Clear()        - Clear Marks set for the current buffer. {{{1
function! TagmaTasks#Clear()
    " Make sure there are marks.
    if !exists('b:TagmaTasksMarkList')
        return
    endif

    " Delete each mark.
    for item in keys(b:TagmaTasksMarkList)
        exec 'sign unplace ' . item
    endfor
    let b:TagmaTasksMarkList={}
endfunction

" TagmaTasks#Error()        - Displays an error that there are no tasks. {{{1
function! TagmaTasks#Error()
    echohl warningmsg
    let l:msg = 'This buffer has no tasks. run tagmatasks'
    if g:TagmaTasksPrefix != ''
        let l:msg .= 'or type ' . g:TagmaTasksPrefix . 't'
    endif
        let l:msg .= ' to generate the Task List.'
    echo l:msg
    echohl none
endfunction

" TagmaTasks#Generate()     - Generate the Task List. {{{1
" Searches for items defined in the TagmaTasksTokens array.
" Display a list of tasks using the location list.
" Opens the list window if not already open.
function! TagmaTasks#Generate(...)
    " The current buffer.
    let l:bufnr = bufnr('%')


    " The grep command.
    let l:grep_cmd = 'silent lvimgrep /\C\<\('      .
                   \ join(g:TagmaTasksTokens, '\|') .
                   \ '\)\>/'
    if !g:TagmaTasksJumpTask
        let l:grep_cmd .= 'j'
    endif

    " Grep the current file for the task items.
    exec l:grep_cmd . ' %'

    " If doing an auto update skip the rest.
    if a:0 == 1 && a:1 == 'A'
        return
    endif

    " First time for this buffer?
    if !exists('b:TagmaTasksHasTasks')
        " Note that this buffer now has Tasks.
        let b:TagmaTasksHasTasks = 1

        " Create the local key mappings.
        if g:TagmaTasksJumpKeys
            call TagmaTasks#MapKeys()
        endif

        " Setup for automatic update..
        if g:TagmaTasksAutoUpdate
            call TagmaTasks#AutoUpdate()
        endif
    endif

    " Generate the Marks.
    if g:TagmaTasksMarks
        call TagmaTasks#Marks()
    endif

    " Open Task List Window
    if g:TagmaTasksOpen
        if exists('b:TagmaTaskLocBufNr')
            unlet b:TagmaTaskLocBufNr
        endif
        call TagmaTasks#Window()
        wincmd p
    endif
endfunction

" TagmaTasks#MapKeys()      - Create the local buffer key mappings. {{{1
function! TagmaTasks#MapKeys()
    nnoremap <silent> [t :lprevious<CR>
    nnoremap <silent> ]t :lnext<CR>
    nnoremap <silent> [T :lfirst<CR>
    nnoremap <silent> ]T :llast<CR>
endfunction

" TagmaTasks#StatusLine()   - Set the status line for the Task Window. {{{1
function! TagmaTasks#StatusLine(bufnr)
    let l:bufname = escape(bufname(a:bufnr), '\')
    exec 'let &l:statusline="Task List for %<' . l:bufname . ' %=%L Tasks "'
endfunction

" TagmaTasks#Window()       - Toggle the Task List window. {{{1
function! TagmaTasks#Window()
    " The current buffer.
    let l:bufnr = bufnr('%')

    " If in the Task List Window just close.
    if &buftype == 'quickfix'
        lclose
        return
    endif

    " If there are no tasks can't open the window.
    if !exists ('b:TagmaTasksHasTasks')
        call TagmaTasks#Error()
        return
    endif

    " Determine if opening or closing.
    if exists('b:TagmaTaskLocBufNr')
        if bufwinnr(b:TagmaTaskLocBufNr) == -1
            exec 'lopen ' . g:TagmaTasksHeight
        else
            lclose
            return
        endif
    else
        " Just in case the b:TagmaTaskLocBufNr variable is lost...
        exec 'lopen ' . g:TagmaTasksHeight
    endif

    " Save the buffer number for later.
    call setbufvar(l:bufnr, 'TagmaTaskLocBufNr', bufnr('%'))

    " Better status line.
    call TagmaTasks#StatusLine(l:bufnr)
endfunction

" TagmaTasks#Marks()        - Create Marks from the location list. {{{1
" Called at the end of TagmaTasks#Generate().
function! TagmaTasks#Marks()
    " If there are no tasks can't create marks.
    if !exists ('b:TagmaTasksHasTasks')
        call TagmaTasks#Error()
        return
    endif

    " Initialize the list of Marks. (Really a hash)
    if exists('b:TagmaTasksMarkList')
        for item in keys(b:TagmaTasksMarkList)
            let b:TagmaTasksMarkList[item] = 0
        endfor
        let l:fresh_list = 0
    else
        let b:TagmaTasksMarkList={}
        let l:fresh_list = 1
    endif

    " Create the Marks for each item in the location list.
    let l:bufnr = bufnr('%')
    for loc_item in getloclist(0)
        let l:sign_num = (l:bufnr * 10000000) + loc_item.lnum
        if loc_item.text =~ 'FIXME'
            exec ':sign place ' . l:sign_num . ' line=' . loc_item.lnum . 
                \' name=TagmaTaskFIXME buffer=' . l:bufnr
        elseif loc_item.text =~ 'TODO'
            exec ':sign place ' . l:sign_num . ' line=' . loc_item.lnum . 
                \' name=TagmaTaskTODO buffer=' . l:bufnr
        elseif loc_item.text =~ 'NOTE'
            exec ':sign place ' . l:sign_num . ' line=' . loc_item.lnum . 
                \' name=TagmaTaskNOTE buffer=' . l:bufnr
        elseif loc_item.text =~ 'XXX'
            exec ':sign place ' . l:sign_num . ' line=' . loc_item.lnum . 
                \' name=TagmaTaskXXX buffer=' . l:bufnr
        else " For COMBAK and anything else.
            exec ':sign place ' . l:sign_num . ' line=' . loc_item.lnum . 
                \' name=TagmaTaskOTHER buffer=' . l:bufnr
        endif
        let b:TagmaTasksMarkList[l:sign_num] = 1
    endfor

    " Clear any unused Marks.
    if !l:fresh_list
        for old_sign in keys(b:TagmaTasksMarkList)
            if b:TagmaTasksMarkList[old_sign] == 0
                exec 'sign unplace ' . old_sign
                call remove(b:TagmaTasksMarkList, old_sign)
            endif
        endfor
    endif
endfunction
