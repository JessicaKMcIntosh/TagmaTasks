" vim:foldmethod=marker
" =============================================================================
" File:         TagmaTasks.vim (Plugin)
" Last Changed: Thu, Oct 6, 2011
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
        let l:cmd = 'let ' . a:option . '='
        let l:type = type(a:default)
        if l:type == type("")
            let l:cmd .= '"' . a:default . '"'
        elseif l:type == type(0)
            let l:cmd .= a:default
        elseif l:type == type([])
            let l:cmd .= string(a:default)
        endif
        exec l:cmd
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

" No need for the function any longer.
delfunction s:SetDefault

" Section: User Commands {{{1
command! -nargs=0 TagmaTasks        call TagmaTasks#Generate()
command! -nargs=0 TagmaTaskClear    call TagmaTasks#Clear()
command! -nargs=0 TagmaTaskMarks    call TagmaTasks#Marks()
command! -nargs=0 TagmaTaskToggle   call TagmaTasks#Window()

" Section: Global Key Mappings {{{1
" Only created if there is a keymap prefix.
if g:TagmaTasksPrefix != ''
    exec 'nnoremap <silent> ' . g:TagmaTasksPrefix . 'c ' . ':TagmaTaskClear<CR>'
    exec 'nnoremap <silent> ' . g:TagmaTasksPrefix . 'm ' . ':TagmaTaskMarks<CR>'
    exec 'nnoremap <silent> ' . g:TagmaTasksPrefix . 't ' . ':TagmaTasks<CR>'
    exec 'nnoremap <silent> ' . g:TagmaTasksPrefix . 'w ' . ':TagmaTaskToggle<CR>'
endif

" Section: Task Marks {{{1
" Create the Marks (signs) used to mark tasks.
sign define TagmaTaskFIXME  text=TF     texthl=Error
sign define TagmaTaskTODO   text=TT     texthl=Search
sign define TagmaTaskNOTE   text=TN     texthl=Search
sign define TagmaTaskXXX    text=TX     texthl=Normal
sign define TagmaTaskOTHER  text=T=     texthl=Normal
