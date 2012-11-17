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
    augroup neco-ruby-keyword-arg
        autocmd!
        autocmd FileType ruby
            \ call neocomplcache#sources#ruby_keyword_args_complete#cache_buffer()
    augroup END
    if &filetype ==# 'ruby'
        call neocomplcache#sources#ruby_keyword_args_complete#cache_buffer()
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
    let s:previous_line = a:line
    call neocomplcache#sources#ruby_keyword_args_complete#cache(getline(a:line))
endfunction

function! neocomplcache#sources#ruby_keyword_args_complete#cache_buffer()
    let s:previous_line = 0
    let last = line('$')
    if last < 2
        return
    endif
    for lnum in range(1, line('$'))
        call neocomplcache#sources#ruby_keyword_args_complete#cache(getline(lnum))
    endfor
endfunction

function! neocomplcache#sources#ruby_keyword_args_complete#reset_cache()
    let s:cache = {}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
