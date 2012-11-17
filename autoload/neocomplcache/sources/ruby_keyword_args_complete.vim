let s:save_cpo = &cpo
set cpo&vim

let s:source = {
            \   'name' : 'keyword_arg',
            \   'kind' : 'ftplugin',
            \   'filetypes' : { 'ruby' : 1 },
            \ }

function! neocomplcache#sources#ruby_keyword_args_complete#define()
    return exists('g:neco_ruby_keyword_args_disable') ? {} : s:source
endfunction

function! s:source.initialize()
    let s:cache = get(s:, 'cache', {})
    let s:previous_line = get(s:, 'previous_line', 0)

    " collect words at loading buffer
    if ! exists('s:neco_ruby_cache_scheduled')
        augroup neco-ruby-keyword-arg
            autocmd!
            autocmd FileType ruby
                \ call neocomplcache#sources#ruby_keyword_args_complete#cache_file(expand('%:p'))
        augroup END
        if &filetype ==# 'ruby'
            call neocomplcache#sources#ruby_keyword_args_complete#cache_file(expand('%:p'))
        endif
        let s:neco_ruby_cache_scheduled = 1
    endif
endfunction

function! s:source.get_keyword_pos(cur_text)
    return match(a:cur_text, '\w\+$')
endfunction

function! s:args_from_methods_in(text)
    let result = []
    for [method,args] in items(s:cache)
        if a:text =~# '\<'.method.'\>'
            call extend(result, args)
        endif
    endfor
    return result
endfunction

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str)
    if neocomplcache#within_comment()
        return []
    endif

    call neocomplcache#sources#ruby_keyword_args_complete#cache_above_line(line('.'))
    return neocomplcache#keyword_filter(s:args_from_methods_in(getline('.')), 
                                        \ a:cur_keyword_str)
endfunction

function! neocomplcache#sources#ruby_keyword_args_complete#cache(text)
    let matched = matchlist(a:text, '^\s*def\s\+\([[:lower:]_]\w*\)\s*[ (]\(\%(\s*,\?\s*\w\+:\s\+[^ ,\n)]\+\)\+\))\?')
    if len(matched) < 3
        return
    endif

    let method = matched[1]
    let args = split(matched[2], '\s*,\s*')

    let arg_list = map( map(args, 'matchlist(v:val, "^\\(\\l\\w*\\):\\s\\+\\(.*\\)$")'),
                        \ '{ "word" : v:val[1].": ",  "menu" : "[K] default:".v:val[2] }' )
    call extend(s:cache, {method : arg_list})
endfunction

function! neocomplcache#sources#ruby_keyword_args_complete#cache_above_line(line)
    if a:line - 1 <= 0 || a:line - 1 == s:previous_line
        return
    endif
    let s:previous_line = a:line - 1
    call neocomplcache#sources#ruby_keyword_args_complete#cache(getline(a:line - 1))
endfunction

function! neocomplcache#sources#ruby_keyword_args_complete#cache_file(file)
    if ! filereadable(a:file)
        return
    endif

    let parent_dir = fnamemodify(a:file, ':p:h').'/'

    for line in readfile(a:file)
        if line =~# '^\s*require\s\+'
            let require_relative = matchlist(line, "^\\s*require\\s\\+[\"']\\(.\\+\\)[\"']")[1].'.rb'
            let require_target = fnamemodify(parent_dir . require_relative, ':p')
            if filereadable(require_target)
                call neocomplcache#sources#ruby_keyword_args_complete#cache_file(require_target)
            endif
        elseif line =~# '^\s*def\s\+'
            call neocomplcache#sources#ruby_keyword_args_complete#cache(line)
        endif
    endfor
endfunction

function! neocomplcache#sources#ruby_keyword_args_complete#reset_cache()
    let s:cache = {}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
