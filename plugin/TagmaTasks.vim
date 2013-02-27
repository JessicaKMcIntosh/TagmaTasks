" vim:foldmethod=marker
" =============================================================================
" File:         TagmaTasks.vim (Plugin)
" Last Changed: Wed Feb 27 03:12 PM 2013 EST
" Maintainer:   Lorance Stinson AT Gmail...
" License:      Public Domain
"
" Description:  Create a Task List for a file.
"               Marks tasks using the 'signs' functionality.
"               Uses the Location List to display the tasks.
"
" Usage:        Copy files to your .vim or vimfiles directory.
" =============================================================================

" Only load once. {{{1
if exists('g:loadedTagmaTasks') || &cp
    finish
endif
let g:loadedTagmaTasks= 1

" Section: Defaults {{{1
function! s:SetDefault(option, default)
    if !exists(a:option)
        execute 'let ' . a:option . '=' . string(a:default)
    endif
endfunction

" Automatically update the Task List when writing the file.
call s:SetDefault('g:TagmaTasksAutoUpdate', 1)

" Height of the Task List Window.
call s:SetDefault('g:TagmaTasksHeight',     5)

" Update the Task List when the cursor is not moved for a while.
" This could potentially slow Vim down. Not recommended.
call s:SetDefault('g:TagmaTasksIdleUpdate', 0)

" Jump to the first task when generating the list.
call s:SetDefault('g:TagmaTasksJumpTask',   1)

" Create the 'Jump' key mappings for the '[' and ']' keys.
call s:SetDefault('g:TagmaTasksJumpKeys',   1)

" Create the marks when generating the Task List.
call s:SetDefault('g:TagmaTasksMarks',      1)

" Open the Task List Window after creating the Task List.
call s:SetDefault('g:TagmaTasksOpen',       1)

" Key map prefix for all commands.
call s:SetDefault('g:TagmaTasksPrefix',     '<Leader>t')

" Task Tokens to search for.
call s:SetDefault('g:TagmaTasksTokens',     ['FIXME', 'TODO', 'NOTE', 'XXX', 'COMBAK'])

" Regex to search for tokens.
" Replaces the search composed from TagmaTasksTokens if defined.
call s:SetDefault('g:TagmaTasksRegexp',     '')

" No need for the function any longer.
delfunction s:SetDefault

" Section: User Commands {{{1
command! -nargs=* TagmaTasks        call TagmaTasks#Generate('', "<args>")
command! -nargs=0 TagmaTaskClear    call TagmaTasks#Clear()
command! -nargs=0 TagmaTaskMarks    call TagmaTasks#Marks()
command! -nargs=0 TagmaTaskToggle   call TagmaTasks#Window()

" Section: Plugin Mappings {{{1
function! s:MapPlug(cmd, plug)
    if !hasmapto(a:cmd)
        execute 'noremap <unique> <script> <Plug>' . a:plug . ' :call ' . a:cmd . '<CR>'
    endif
endfunction

call s:MapPlug('TagmaTasks#Generate()', 'TagmaTasks')
call s:MapPlug('TagmaTasks#Clear()',    'TagmaTaskClear')
call s:MapPlug('TagmaTasks#Marks()',    'TagmaTaskMarks')
call s:MapPlug('TagmaTasks#Window()',   'TagmaTaskToggle')

delfunction s:MapPlug

" Section: Global Key Mappings {{{1
" Only created if there is a keymap prefix.
if g:TagmaTasksPrefix != ''
    function! s:MapGlobalKey(plug, key)
        if !hasmapto(a:plug)
            execute 'map <silent> <unique> ' .
                        \ g:TagmaTasksPrefix . a:key . ' ' . a:plug
        endif
    endfunction

    call s:MapGlobalKey('<Plug>TagmaTasks',      't')
    call s:MapGlobalKey('<Plug>TagmaTaskClear',  'c')
    call s:MapGlobalKey('<Plug>TagmaTaskMarks',  'm')
    call s:MapGlobalKey('<Plug>TagmaTaskToggle', 'w')

    delfunction s:MapGlobalKey
endif

" Section: Task Marks {{{1
" Create the Marks (signs) used to mark tasks.
sign define TagmaTaskFIXME  text=TF     texthl=Error
sign define TagmaTaskTODO   text=TT     texthl=Search
sign define TagmaTaskNOTE   text=TN     texthl=Search
sign define TagmaTaskXXX    text=TX     texthl=Normal
sign define TagmaTaskOTHER  text=T=     texthl=Normal
