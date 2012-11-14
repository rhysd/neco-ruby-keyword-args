let s:save_cpo = &cpo
set cpo&vim

let s:source = {
            \   'name' : 'keyword_arg',
            \   'kind' : 'ftplugin',
            \   'filetypes' : { 'ruby' : 1 },
            \ }

function! s:source.initialize()
    " TODO : s:cache はこの時点でバッファ全体をスキャンして構築する
    let s:cache = {}
    let s:previous_line = 0
endfunction

function! s:source.finalize()
    unlet s:cache
    unlet s:previous_line
endfunction


function! s:source.get_keyword_pos(cur_text)
    return match(a:cur_text, '\w\+$')
endfunction

function! s:args_from_methods_in(text)
    let result = []
    for [method,args] in deepcopy(items(s:cache))
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

    if line('.') > 1
        call neocomplcache#sources#ruby_keyword_args_complete#cache(line('.')-1)
    endif

    echomsg getline('.')
    echomsg string(s:cache)
    let words = map( s:args_from_methods_in(getline('.')),
                \ "{'word' : v:val, 'menu' : '[keyword-arg]'}")
    return neocomplcache#keyword_filter(words, a:cur_keyword_str)
endfunction

function! neocomplcache#sources#ruby_keyword_args_complete#define()
    return s:source
endfunction

function! neocomplcache#sources#ruby_keyword_args_complete#cache(line)
    if a:line == s:previous_line
        return
    endif

    let matched = matchlist(getline(a:line), '^\s*def\s\+\([[:lower:]_]\w*\)\s*[ (]\(\%(\s*,\?\s*\w\+:\s\+[^ ,\n)]\+\)\+\))\?')
    if len(matched) < 3
        return
    endif

    let method = matched[1]
    let args = split(matched[2], '\s*,\s*')

    let arg_list = map(args, 'matchlist(v:val, "^\\(\\l\\w*\\):\\s\\+\\(.*\\)$")[1].": "')
    call extend(s:cache, {method : arg_list})
    let s:previous_line = a:line
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
