" vim:foldmethod=marker
" =============================================================================
" File:         TagmaTasks.vim (Autoload)
" Last Changed: Wed Feb 27 03:14 PM 2013 EST
" Maintainer:   Lorance Stinson AT Gmail...
" License:      Public Domain
"
" Description:  Autoload file for TagmaTasks.
"               Contains all the functions.
"               No need to load them if they are not used...
"
" Usage:        Copy files to your .vim or vimfiles directory.
" =============================================================================

" Funciton: TagmaTasks#AutoUpdate()     -- Automatically update the tasks. {{{1
" Done using an auto command on Buffer/File write or external changes.
" Optional update on CursorHold. (Not recommended.)
function! TagmaTasks#AutoUpdate()
    " Events to Auto Update the Task List on.
    let l:events = [
                \ 'BufWritePost', 'FileWritePost',
                \ 'FileChangedShellPost',
                \ 'ShellCmdPost', 'ShellFilterPost'
                \ ]

    " If requested, add the CursorHold event.
    if g:TagmaTasksIdleUpdate
        call add(l:events, 'CursorHold')
    endif

    " Set the autocommand for each event.
    for event in l:events
        exec 'autocmd ' . event . " <buffer> call TagmaTasks#Generate('A')"
    endfor
endfunction

" Function: TagmaTasks#Clear()          -- Clear Marks set for the current buffer. {{{1
function! TagmaTasks#Clear()
    " Make sure there are marks.
    if !exists('b:TagmaTasksMarkList')
        return
    endif

    " Note that the Marks are no longer visible.
    let b:TagmaTasksMarksVisible = 0

    " Delete each mark.
    for item in keys(b:TagmaTasksMarkList)
        exec 'sign unplace ' . item
    endfor
    let b:TagmaTasksMarkList={}
endfunction

" Function: TagmaTasks#Error()          -- Displays an error that there are no tasks. {{{1
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

" Function: TagmaTasks#Generate(...)    -- Generate the Task List. {{{1
" Searches for items defined in the TagmaTasksTokens array.
" Display a list of tasks using the location list.
" Opens the list window if not already open.
" When 'A' is passed will only perform an update. (Auto Update)
" A list of files to grep can be passed. See the command TagmaTasks.
function! TagmaTasks#Generate(...)
    " The current buffer.
    let l:bufnr = bufnr('%')

    " Note if doing an auto update.
    let l:auto_update = a:0 != 0 && a:1 == 'A'

    " Note if working on files or the current buffer.
    let l:grep_files = a:0 == 2 && a:2 != ''
    let l:file_list = (l:grep_files ? a:2 : '%')

    " The grep command.
    let l:grep_cmd = (l:grep_files ? '' : 'silent l')
    if g:TagmaTasksRegexp != ''
        let l:grep_cmd .= 'vimgrep /' . g:TagmaTasksRegexp . '/'
    else
        let l:grep_cmd .= 'vimgrep /\C\<\('
        let l:grep_cmd .= join(g:TagmaTasksTokens, '\|')
        let l:grep_cmd .= '\)\>/'
    endif
    if !g:TagmaTasksJumpTask || l:auto_update || l:grep_files
        " Do not jump to the first Task.
        let l:grep_cmd .= 'j'
    endif
    let l:grep_cmd .= ' ' . l:file_list

    " Grep for the task items.
    silent! exec l:grep_cmd

    " Make sure tasks were found before proceeding.
    if len(getloclist(0)) == 0 && !l:grep_files
        echomsg 'No tasks found.'
        return
    endif

    " First time for this buffer?
    if !exists('b:TagmaTasksHasTasks') && !l:grep_files
        " Note that this buffer now has Tasks.
        let b:TagmaTasksHasTasks = 1

        " Create the local key mappings.
        if g:TagmaTasksJumpKeys
            call TagmaTasks#MapKeys()
        endif

        " Setup automatic update.
        if g:TagmaTasksAutoUpdate
            call TagmaTasks#AutoUpdate()
        endif

        " The Markers Visible flag.
        let b:TagmaTasksMarksVisible = 0
    endif

    " Generate the Marks.
    " Skipped when autoupdating and Marks are not visible or working on a list
    " of files.
    if g:TagmaTasksMarks && !(l:auto_update && !b:TagmaTasksMarksVisible) &&
                \ !l:grep_files
        call TagmaTasks#Marks()
    endif

    " Open Task List Window
    if l:grep_files
        exec 'copen ' . g:TagmaTasksHeight
    elseif g:TagmaTasksOpen && !l:auto_update
        if exists('b:TagmaTaskLocBufNr')
            unlet b:TagmaTaskLocBufNr
        endif
        call TagmaTasks#Window()
        wincmd p
    endif
endfunction

" Function: TagmaTasks#MapKeys()        -- Create the local buffer key mappings. {{{1
function! TagmaTasks#MapKeys()
    nnoremap <silent> [t :lprevious<CR>
    nnoremap <silent> ]t :lnext<CR>
    nnoremap <silent> [T :lfirst<CR>
    nnoremap <silent> ]T :llast<CR>
endfunction

" Function: TagmaTasks#StatusLine()     -- Set the status line for the Task Window. {{{1
function! TagmaTasks#StatusLine(bufnr)
    let l:bufname = escape(bufname(a:bufnr), '\')
    exec 'let &l:statusline="Task List for %<' . l:bufname . ' %=%L Tasks "'
endfunction

" Function: TagmaTasks#Window()         -- Toggle the Task List window. {{{1
" Tries to detect if the Task Window is open, toggling its state.
" If executed inside the Task Window closes the window.
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
        call TagmaTasks#Generate()
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

" Function: TagmaTasks#Marks()          -- Create Marks from the location list. {{{1
" Called at the end of TagmaTasks#Generate().
function! TagmaTasks#Marks()
    " If there are no tasks can't create marks.
    if !exists ('b:TagmaTasksHasTasks')
        call TagmaTasks#Error()
        return
    endif

    " Initialize the list of Marks. (Really a hash)
    if exists('b:TagmaTasksMarkList')
        " Set all Marks as unused.
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
        " Determine which Mark to use.
            if loc_item.text =~ '\<FIXME\>' | let l:sign_name = 'TagmaTaskFIXME'
        elseif loc_item.text =~ '\<TODO\>'  | let l:sign_name = 'TagmaTaskTODO'
        elseif loc_item.text =~ '\<NOTE\>'  | let l:sign_name = 'TagmaTaskNOTE'
        elseif loc_item.text =~ '\<XXX\>'   | let l:sign_name = 'TagmaTaskXXX'
        else                                | let l:sign_name = 'TagmaTaskOTHER'
        endif

        " Place the Mark.
        let l:sign_num = (l:bufnr * 10000000) + loc_item.lnum
        exec 'sign place ' . l:sign_num .
           \ ' line=' . loc_item.lnum .
           \ ' name=' . l:sign_name .
           \ ' buffer=' . l:bufnr

        " Set the Mark as used.
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

    " Note that marks are displayed.
    let b:TagmaTasksMarksVisible = 1
endfunction
