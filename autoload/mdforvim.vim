" Last Change: 2015 Feb 27
" Maintainer: Kuro_CODE25 <kuro.code25@gmail.com>
" License: This file is placed in the public domain. 

let s:save_cpo = &cpo
set cpo&vim


let s:base_path = expand('<sfile>:p:h')
let s:file_name = 'output.html'
let s:is_unix = has('unix')
let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')
let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows && !s:is_cygwin
      \ && (has('mac') || has('macunix') || has('gui_macvim') ||
      \   (!isdirectory('/proc') && executable('sw_vers')))
" As of 7.4.122, the system()'s 1st argument is converted internally by Vim.
" Note that Patch 7.4.122 does not convert system()'s 2nd argument and
" return-value. We must convert them manually.
let s:need_trans = v:version < 704 || (v:version == 704 && !has('patch122'))
let s:toggle_autowrite = 0

" Convert current buffer.
function! mdforvim#convert() " {{{
    call s:Parsemd()
    " echo s:line_list
    let s:i = 0
    while s:i < len(s:line_list)
        call setline(s:i,s:line_list[s:i])
        let s:i += 1
    endwhile
endfunction " }}}

" Save as html file
function! mdforvim#save_html(filename) " {{{
    call s:Parsemd()
    call writefile(s:line_list,a:filename)
endfunction " }}}

" Start preview.
function! mdforvim#preview() " {{{
    call s:define_path()
    let s:toggle_autowrite = 1
    let l:file_path = s:base_path.s:path_to_mdpreview.s:file_name
    call s:Parsemd()
    call insert(s:line_list,'</SCRIPT>')
    call insert(s:line_list,'//-->')
    call insert(s:line_list,'setTimeout("location.reload()",1000)')
    call insert(s:line_list,'<!--')
    call insert(s:line_list,'<SCRIPT LANGUAGE="JavaScript">')
    call insert(s:line_list,'<body>')
    call insert(s:line_list,'</head>')
    call insert(s:line_list,'<link rel="stylesheet" href="style.css" type="text/css">')
    call insert(s:line_list,'<meta http-equiv="Content-Type" content="text/html; charset=utf-8">')
    call insert(s:line_list,'<head>')
    call insert(s:line_list,'<html>')
    call add(s:line_list,'</body>')
    call add(s:line_list,'</html>')
" encode utf-8 for output.html {
    let l:k = 0
    while l:k < len(s:line_list)
        let s:line_list[l:k] = iconv(s:line_list[l:k],&encoding,"uft-8")
        let l:k += 1
    endwhile
" encode utf-8 for output.html }

    call writefile(s:line_list,l:file_path)
    call s:open(l:file_path)
endfunction " }}}

" Automatic write output.html.
function! mdforvim#autowrite() " {{{
    call s:define_path()
    let l:file_path = s:base_path.s:path_to_mdpreview.s:file_name
    if s:toggle_autowrite == 1
        call s:Parsemd()
        call insert(s:line_list,'</SCRIPT>')
        call insert(s:line_list,'//-->')
        call insert(s:line_list,'setTimeout("location.reload()",1000)')
        call insert(s:line_list,'<!--')
        call insert(s:line_list,'<SCRIPT LANGUAGE="JavaScript">')
        call insert(s:line_list,'<body>')
        call insert(s:line_list,'</head>')
        call insert(s:line_list,'<link rel="stylesheet" href="style.css" type="text/css">')
        call insert(s:line_list,'<meta http-equiv="Content-Type" content="text/html; charset=utf-8">')
        call insert(s:line_list,'<head>')
        call insert(s:line_list,'<html>')
        call add(s:line_list,'</body>')
        call add(s:line_list,'</html>')
        " echo s:base_patj
        call writefile(s:line_list,l:file_path)
    endif
endfunction " }}}

" Stop preview.
function! mdforvim#stop_preview() " {{{
    let l:file_path = s:base_path.s:path_to_mdpreview.s:file_name
    let s:toggle_autowrite = 0
    let l:list=['<html><body><h3>Please close this page</h3></body></html>']
    call writefile(l:list,l:file_path)
endfunction " }}}

" Open a file.
function! s:open(filename) "{{{
    let filename = fnamemodify(a:filename, ':p')

    " Detect desktop environment.
    if s:is_windows
    " For URI only.
    if s:need_trans
        let filename = iconv(filename, &encoding, 'char')
    endif
    silent execute '!start rundll32 url.dll,FileProtocolHandler' filename
    elseif s:is_cygwin
    " Cygwin.
        call system(printf('%s %s', 'cygstart', shellescape(filename)))
    elseif executable('xdg-open')
    " Unix.
        call system(printf('%s %s &', 'xdg-open', shellescape(filename)))
    elseif exists('$KDE_FULL_SESSION') && $KDE_FULL_SESSION ==# 'true'
    " KDE.
        call system(printf('%s %s &', 'kioclient exec', shellescape(filename)))
    elseif exists('$GNOME_DESKTOP_SESSION_ID')
    " GNOME.
        call system(printf('%s %s &', 'gnome-open', shellescape(filename)))
    elseif executable('exo-open')
    " Xfce.
        call system(printf('%s %s &', 'exo-open', shellescape(filename)))
    elseif s:is_mac && executable('open')
    " Mac OS.
        call system(printf('%s %s &', 'open', shellescape(filename)))
    else
    " Give up.
        throw 'Not supported.'
    endif
endfunction "}}}

function! s:define_path()
    if s:is_windows
        let s:path_to_mdpreview = '\..\mdpreview\'
    else
        let s:path_to_mdpreview = '/../mdpreview/'
    endif
endfunction

fun! s:Parsemd()
    let s:line_list =['']
    let s:i = 0
    let s:num_of_line = line("$")
    " echo s:num_of_line
    for s:i in range(1,s:num_of_line)
        call add(s:line_list,getline(s:i))
    endfor
    call add(s:line_list,'')
    " echo len(s:line_list)
    let s:i = 0
    while s:i < len(s:line_list)
        call s:Parse_autolink(s:i)
        call s:Parse_header(s:i)
        call s:Parse_horizon(s:i)
        call s:Parse_enphasis(s:i)
        call s:Parse_code(s:i)
        call s:Parse_image(s:i)
        call s:Parse_URL(s:i)
        call s:Parse_list(s:i)
        call s:Parse_blockquote(s:i)
        call s:Parse_CR(s:i)
"       " echo 's:i'.s:i
        let s:i += 1
    endwhile
    call s:Parse_paragraph()
    call s:Parse_char()
endfun
function! s:Parse_header(i)
    if match(s:line_list[a:i],"###### ") == 0 && match(s:line_list[a:i],"!###### ") < 0
        let s:line_list[a:i] = substitute(s:line_list[a:i],"###### ","<h6>","g") ."</h6>"
    elseif match(s:line_list[a:i],"##### ") == 0
        let s:line_list[a:i] = substitute(s:line_list[a:i],"##### ","<h5>","g") ."</h5>"
    elseif match(s:line_list[a:i],"#### ") == 0
        let s:line_list[a:i] = substitute(s:line_list[a:i],"#### ","<h4>","g") ."</h4>"
    elseif match(s:line_list[a:i],"### ") == 0
        let s:line_list[a:i] = substitute(s:line_list[a:i],"### ","<h3>","g") ."</h3>"
    elseif match(s:line_list[a:i],"## ") == 0
        let s:line_list[a:i] = substitute(s:line_list[a:i],"## ","<h2>","g") ."</h2>"
    elseif match(s:line_list[a:i],"# ") == 0
        let s:line_list[a:i] = substitute(s:line_list[a:i],"# ","<h1>","g") ."</h1>"
    endif
    if stridx(s:line_list[a:i],'===') >= 0 && stridx(s:line_list[a:i],'\=') < 0
        let s:line_list[a:i] = ''
        if s:line_list[a:i - 1] != ''
            let s:line_list[a:i - 1] = '<h1>'.s:line_list[a:i - 1].'</h1>'
        endif
    endif
endfunction
"...>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....
" Parse horizon line.
fun! s:Parse_horizon(i)
    let l:line = substitute(s:line_list[a:i],' ','','g')
    if (strpart(l:line,0,3) == "***" || strpart(l:line,0,3) == "---")  && stridx(s:line_list[a:i],'\') < 0
        let s:line_list[a:i] = "<hr>"
    endif
endfun
"...>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....
" Parse enphasis.
function! s:Parse_enphasis(i) " {{{
" Parse <strong>: {
    if match(s:line_list[a:i],'\*\*') >= 0
        let l:linelist = split(s:line_list[a:i],'\*\*\zs')
        " **の数を数える
        let a:k = 0
        let l:count_target = s:countlist(l:linelist,'**') - s:countlist(l:linelist,'\**')
        if l:count_target % 2 != 0
            let a:counter = l:count_target - 1
        else
            let a:counter = len(l:linelist)
        endif
        let l:toggle_init = 0

        while a:k < len(l:linelist)
            if stridx(l:linelist[a:k],'\**') < 0 && a:counter > 0
                if l:toggle_init == 0
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'\*\*',"<strong>","g")
                    let a:counter -= 1
                    let l:toggle_init = 1
                else
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'\*\*',"</strong>","g")
                    let a:counter -= 1
                    let l:toggle_init = 0
                endif
            endif
            let a:k += 1
        endwhile
        let s:line_list[a:i] = join(l:linelist,'')
    endif
    if match(s:line_list[a:i],'__') >= 0
        let l:linelist = split(s:line_list[a:i],'__\zs')
        " **の数を数える
        let a:k = 0
        let l:count_target = s:countlist(l:linelist,'__') - s:countlist(l:linelist,'\__')
        if l:count_target % 2 != 0
            let a:counter = l:count_target - 1
        else
            let a:counter = len(l:linelist)
        endif
        let l:toggle_init = 0
        while a:k < len(l:linelist)
            if stridx(l:linelist[a:k],'\__') < 0 && a:counter > 0
                if l:toggle_init == 0
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'__',"<strong>","g")
                    let a:counter -= 1
                    let l:toggle_init = 1
                else
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'__',"</strong>","g")
                    let a:counter -= 1
                    let l:toggle_init = 0
                endif
            endif
            let a:k += 1
        endwhile
        let s:line_list[a:i] = join(l:linelist,'')
    endif
" Parse <strong>: }
" Parse <em>: {
    if match(s:line_list[a:i],'\*') >= 0
        let l:linelist = split(s:line_list[a:i],'\*\zs')
        let a:k = 0
        let l:count_target = s:countlist(l:linelist,'*') - s:countlist(l:linelist,'\*')
        if l:count_target % 2 != 0
            let a:counter = l:count_target - 1
        else
            let a:counter = len(l:linelist)
        endif
        let l:toggle_init = 0

        while a:k < len(l:linelist)
            if stridx(l:linelist[a:k],'\*') < 0 && a:counter > 0
                if l:toggle_init == 0
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'\*',"<em>","g")
                    let a:counter -= 1
                    let l:toggle_init = 1
                else
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'\*',"</em>","g")
                    let a:counter -= 1
                    let l:toggle_init = 0
                endif
            endif
            let a:k += 1
        endwhile
        let s:line_list[a:i] = join(l:linelist,'')
    endif
    if match(s:line_list[a:i],'_') >= 0
        let l:linelist = split(s:line_list[a:i],'_\zs')
        " **の数を数える
        let a:k = 0
        let l:count_target = s:countlist(l:linelist,'_') - s:countlist(l:linelist,'\_')
        if l:count_target % 2 != 0
            let a:counter = l:count_target - 1
        else
            let a:counter = len(l:linelist)
        endif
        let l:toggle_init = 0

        while a:k < len(l:linelist)
            if stridx(l:linelist[a:k],'\_') < 0 && a:counter > 0
                if l:toggle_init == 0
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'_',"<em>","g")
                    let a:counter -= 1
                    let l:toggle_init = 1
                else
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'_',"</em>","g")
                    let a:counter -= 1
                    let l:toggle_init = 0
                endif
            endif
            let a:k += 1
        endwhile
        let s:line_list[a:i] = join(l:linelist,'')
    endif
" Parse <em>: }
" Parse <del>: {
    if match(s:line_list[a:i],'\~\~') >= 0
        let l:linelist = split(s:line_list[a:i],'\~\~\zs')
        " **の数を数える
        let a:k = 0
        let l:count_target = s:countlist(l:linelist,'~~') - s:countlist(l:linelist,'\~~')
        if l:count_target % 2 != 0
            let a:counter = l:count_target - 1
        else
            let a:counter = len(l:linelist)
        endif
        let l:toggle_init = 0

        while a:k < len(l:linelist)
            if stridx(l:linelist[a:k],'\~~') < 0 && a:counter > 0
                if l:toggle_init == 0
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'\~\~',"<del>","g")
                    let a:counter -= 1
                    let l:toggle_init = 1
                else
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'\~\~',"</del>","g")
                    let a:counter -= 1
                    let l:toggle_init = 0
                endif
            endif
            let a:k += 1
        endwhile
        let s:line_list[a:i] = join(l:linelist,'')
    endif
" Parse <del>: }
endfunction " }}}

"...>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....
" Parse code.
function! s:Parse_code(i)
    if stridx(s:line_list[a:i],'```') >= 0
        let s:line_list[a:i] = '<pre><code>'
        let l:k = 1
        while s:line_list[a:i + l:k] != '```'
            if s:i + l:k == len(s:line_list) - 1
                let l:k = 0
                break
            endif
            let l:k += 1
        endwhile
        if s:line_list[s:i + l:k] == '```'
            let s:line_list[s:i + l:k] = '</code></pre>'
        endif
        let s:i += l:k
    endif
    if match(s:line_list[a:i],'`') >= 0
        let l:linelist = split(s:line_list[a:i],'`\zs')
        " **の数を数える
        let a:k = 0
        let l:count_target = s:countlist(l:linelist,'`') - s:countlist(l:linelist,'\`')
        if l:count_target % 2 != 0
            let a:counter = l:count_target - 1
        else
            let a:counter = len(l:linelist)
        endif
        let l:toggle_init = 0

        while a:k < len(l:linelist)
            if stridx(l:linelist[a:k],'\`') < 0 && a:counter > 0
                if l:toggle_init == 0
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'`',"<code>","g")
                    let a:counter -= 1
                    let l:toggle_init = 1
                else
                    let l:linelist[a:k] = substitute(l:linelist[a:k],'`',"</code>","g")
                    let a:counter -= 1
                    let l:toggle_init = 0
                endif
            endif
            let a:k += 1
        endwhile
        let s:line_list[a:i] = join(l:linelist,'')
    endif
endfunction

"...>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....
" Parse URL.
function! s:Parse_URL(i) "{{{
    if stridx(s:line_list[a:i],'[') >= 0 && stridx(s:line_list[a:i],'](') &&stridx(s:line_list[a:i],'![') < 0
        let l:line = s:line_list[a:i]
        let l:lengh = strlen(l:line)
        let l:url_list = []
        while stridx(l:line,'](') > 0
            let l:forward = strpart(l:line,0,stridx(l:line,'](') + 1)
            let l:back = strpart(l:line,stridx(l:line,'](') + 1,l:lengh)
            call add(l:url_list,strpart(l:forward,0,stridx(l:forward,'[')))
            call add(l:url_list,strpart(l:forward,stridx(l:forward,'['),strlen(l:forward)).strpart(l:back,0,stridx(l:back,')') + 1))
            let l:line = strpart(l:back,stridx(l:back,')') + 1,strlen(l:back))
            if stridx(l:line,'](') < 0
                call add(l:url_list,l:line)
            endif
        endwhile
        " echo l:url_list
        let l:k = 0
        while l:k < len(l:url_list)
            if stridx(l:url_list[l:k],'[') == 0 && strridx(l:url_list[l:k - 1],'\') < 0
                let l:url_list[l:k] = substitute(l:url_list[l:k],' ','','g')
                let l:word = s:Cutstrpart(l:url_list[l:k],'[',']')
                if stridx(l:url_list[l:k],'"') > 0
                    let l:url = s:Cutstrpart(l:url_list[l:k],'(','"')
                else
                    let l:url = s:Cutstrpart(l:url_list[l:k],'(',')')
                endif
                let l:title = s:Cutstrpart(l:url_list[l:k],'"','"')
                " echo "url_word:".l:word
                " echo "url_url:".l:url
                " echo "url_title:".l:title

                let l:url_list[l:k] = '<a href="'.l:url.'" title="'.l:title.'">'.l:word.'</a>'
            endif

            let l:k += 1
        endwhile
        let s:line_list[a:i] = join(l:url_list,'')

    endif
endfunction " }}}

"...>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....
" Parse image.
fun! s:Parse_image(i) " {{{
    if stridx(s:line_list[a:i],'![') >= 0 && stridx(s:line_list[a:i],'](')
        let l:line = s:line_list[a:i]
        let l:lengh = strlen(l:line)
        let l:url_list = []
        while stridx(l:line,'](') > 0
            let l:forward = strpart(l:line,0,stridx(l:line,'](') + 1)
            let l:back = strpart(l:line,stridx(l:line,'](') + 1,l:lengh)
            call add(l:url_list,strpart(l:forward,0,stridx(l:forward,'![')))
            call add(l:url_list,strpart(l:forward,stridx(l:forward,'!['),strlen(l:forward)).strpart(l:back,0,stridx(l:back,')') + 1))
            let l:line = strpart(l:back,stridx(l:back,')') + 1,strlen(l:back))
        endwhile
        " echo l:url_list
        let l:k = 0
        while l:k < len(l:url_list)
            if stridx(l:url_list[l:k],'![') == 0 && strridx(l:url_list[l:k - 1],'\') < 0
                let l:url_list[l:k] = substitute(l:url_list[l:k],' ','','g')
                let l:word = s:Cutstrpart(l:url_list[l:k],'[',']')
                if stridx(l:url_list[l:k],'"') > 0
                    let l:url = s:Cutstrpart(l:url_list[l:k],'(','"')
                else
                    let l:url = s:Cutstrpart(l:url_list[l:k],'(',')')
                endif
                let l:title = s:Cutstrpart(l:url_list[l:k],'"','"')
                " echo "url_word:".l:word
                " echo "url_url:".l:url
                " echo "url_title:".l:title

                let l:url_list[l:k] = '<img src="'.l:url.'" alt="'.l:word.'" title="'.l:title.'">'
            endif

            let l:k += 1
        endwhile
        let s:line_list[a:i] = join(l:url_list,'')

    endif
endfunction " }}}

"...>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....
" Parse carriage return.
fun! s:Parse_CR(i) " {{{
    if strridx(s:line_list[a:i],'  ') == strlen(s:line_list[a:i]) - 2
        let s:line_list[a:i] = strpart(s:line_list[a:i],0,strridx(s:line_list[a:i],'  '))."<br />"
    endif
endfunction " }}}

" Parse list.
fun! s:Parse_list(i) " {{{
" Disc List: {
   if stridx(strpart(s:line_list[a:i],0,3),'* ') >= 0 && stridx(strpart(s:line_list[a:i],0,3),'\*') < 0
       let s:line_list[a:i] = substitute(s:line_list[a:i],"* ","<li>","g")."</li>"
       if s:line_list[a:i-1] == ""
           call insert(s:line_list,'<ul>',a:i)
       endif
       if s:line_list[a:i+1] == ""
           call insert(s:line_list,'</ul>',a:i + 1)
       endif
    elseif stridx(strpart(s:line_list[a:i],0,3),'+ ') >= 0 && stridx(strpart(s:line_list[a:i],0,3),'\+') < 0
       let s:line_list[a:i] = substitute(s:line_list[a:i],"+ ","<li>","g")."</li>"
       if s:line_list[a:i-1] == ""
           call insert(s:line_list,'<ul>',a:i)
       endif
       if s:line_list[a:i+1] == ""
           call insert(s:line_list,'</ul>',a:i + 1)
       endif
    elseif stridx(strpart(s:line_list[a:i],0,3),'_ ') >= 0 && stridx(strpart(s:line_list[a:i],0,3),'\_') < 0
       let s:line_list[a:i] = substitute(s:line_list[a:i],"_ ","<li>","g")."</li>"
       if s:line_list[a:i-1] == ""
           call insert(s:line_list,'<ul>',a:i)
       endif
       if s:line_list[a:i+1] == ""
           call insert(s:line_list,'</ul>',a:i + 1)
       endif
    endif
" Disc List: }
"Decimal List: {
    if strpart(s:line_list[a:i],0,match(s:line_list[a:i],". ")) > 0
        let s:line_list[a:i] = substitute(s:line_list[a:i],strpart(s:line_list[a:i],0,match(s:line_list[a:i],". ")+2),"<li>","g")."</li>"
        if s:line_list[a:i - 1] == ""
           call insert(s:line_list,'<ol>',a:i)
        endif
        if s:line_list[a:i + 1] == ""
           call insert(s:line_list,'</ol>',a:i + 1)
        endif
    endif
"Decimal List: }
endfunction " }}}

"...>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....
" Parse automatic link.
fun! s:Parse_autolink(i) " {{{
" automatic link URL: {
    if stridx(s:line_list[a:i],'<http://') >= 0
        let l:url_list = []
        let l:line = s:line_list[a:i]
        while stridx(l:line,'<http://') >= 0
            let l:forward = strpart(l:line,0,stridx(l:line,'<http://'))
            let l:back = strpart(l:line,stridx(l:line,'<http://'),strlen(l:line) - strlen(l:forward))
            let l:url = strpart(l:back,0,stridx(l:back,'>') + 1)
            let l:back = strpart(l:back,stridx(l:back,'>') + 1,strlen(l:back) - strlen(l:url))
            call add(l:url_list,l:forward)
            call add(l:url_list,l:url)
            let l:line = l:back
        endwhile
        call add(l:url_list,l:line)
        let l:k = 0
        while l:k < len(l:url_list)
            if stridx(l:url_list[l:k],'<http://') == 0 && strridx(l:url_list[l:k - 1],'\') < 0
                let l:url = s:Cutstrpart(l:url_list[l:k],'<','>')
                let l:url_list[l:k] = '<a href="'.l:url.'" title="">'
            endif
            let l:k += 1
        endwhile
        let s:line_list[a:i] = join(l:url_list,'')
    endif
" automatic link URL: }
" automatic link mail: {
    if stridx(s:line_list[a:i],'@') >= 0 && stridx(s:line_list[a:i],'<') < stridx(s:line_list[a:i],'>')
        let l:url_list = []
        let l:line = s:line_list[a:i]
        while stridx(l:line,'<') < stridx(l:line,'>')
            let l:forward = strpart(l:line,0,stridx(l:line,'<'))
            let l:back = strpart(l:line,stridx(l:line,'<'),strlen(l:line) - strlen(l:forward))
            call add(l:url_list,l:forward)
            call add(l:url_list,strpart(l:back,0,stridx(l:back,'>') + 1))
            let l:line = strpart(l:back,stridx(l:back,'>') + 1,len(l:back))
        endwhile
        call add(l:url_list,l:line)
        echo l:url_list
        let l:k = 0
        while l:k < len(l:url_list)
            if stridx(l:url_list[l:k],'<') == 0 && stridx(l:url_list[l:k],'@') > 0 && strridx(l:url_list[l:k - 1],'\') < 0
                let l:url = s:Cutstrpart(l:url_list[l:k],'<','>')
                let l:mail_list = split(l:url,'**')
                let l:l = 0
                while l:l < len(mail_list)
                    let l:mail_list[l:l] = printf("&#x%x;",char2nr(l:mail_list[l:l]))
                    let l:l += 1
                endwhile
                let l:url = join(l:mail_list,'')
                let l:url_list[l:k] = '<a href="'.l:url.'">'.l:url.'</a>'
            endif
            let l:k += 1
        endwhile
        let s:line_list[a:i] = join(l:url_list,'')
    endif
" automatic link mail: }
endfunction " }}}

"...>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....
" Parse blockquote.
function! s:Parse_blockquote(i) " {{{
    if strpart(s:line_list[a:i],0,2) == "> " || strpart(s:line_list[a:i],0,1) == ">"
        let s:line_list[a:i] = substitute(s:line_list[a:i],">","","g")
        if s:line_list[a:i - 1] == ""
            call insert(s:line_list,'<blockquote>',a:i)
            let s:i += 1
        endif
        if s:line_list[a:i + 1] == ""
            call insert(s:line_list,'</blockquote>',a:i + 1)
        endif
    endif
endfunction " }}}

"...>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....>>>>....
" Parse paragraph
fun! s:Parse_paragraph() " {{{
    let s:j = 0
    while s:j < len(s:line_list)
        call s:skip_block('<table>','</table>')
        call s:skip_block('<pre>','</pre>')
        call s:skip_block('<p>','</p>')
        call s:skip_block('<ul>','</ul>')
        call s:skip_block('<ol>','</ol>')
        call s:skip_block('<div>','</div>')
        if s:line_list[s:j] != '' && stridx(s:line_list[s:j],'<h') < 0  && stridx(s:line_list[s:j],'<blockquote>') < 0 && stridx(s:line_list[s:j],'</blockquote>') < 0 && stridx(s:line_list[s:j],'<ul>') < 0
            let s:line_list[s:j] = '<p>'.s:line_list[s:j]
            let a:k = 0
            while s:line_list[s:j + a:k] != ''
                if s:j + a:k == len(s:line_list) - 1
                    break
                endif

                if stridx(s:line_list[s:j + a:k],'<h') >= 0 || stridx(s:line_list[s:j + a:k],'<blockquote>') >= 0 || stridx(s:line_list[s:j + a:k],'</blockquote>') >= 0
                    break
                endif
                let a:k  += 1
            endwhile
            let a:end_paragraph = s:line_list[s:j + a:k -1].'</p>'
            let s:line_list[s:j + a:k -1] = a:end_paragraph
            let s:j = s:j + a:k
        endif
        let s:j += 1
    endwhile
endfunction " }}}

" Convert special charcter
function! s:Parse_char() " {{{
    let l:k = 0
    while l:k < len(s:line_list)
        let s:line_list[l:k] = substitute(s:line_list[l:k],'\\#','#',"g")
        let s:line_list[l:k] = substitute(s:line_list[l:k],'\\\*','\*',"g")
        let s:line_list[l:k] = substitute(s:line_list[l:k],'\\-','-',"g")
        let s:line_list[l:k] = substitute(s:line_list[l:k],'\\_','_',"g")
        let l:k += 1
    endwhile
endfunction " }}}

" Skip block.
function! s:skip_block(tag_begin,tag_end) " {{{
    if stridx(s:line_list[s:j],a:tag_begin) >= 0
        let l:k = 0
        while stridx(s:line_list[s:j + l:k],a:tag_end) < 0
            let l:k += 1
            if s:j + l:k == len(s:line_list) - 1
                let l:k = -1
                break
            endif
        endwhile
        let s:j += l:k + 1
    endif
endfunction " }}}

" counter for number of str in list
function! s:countlist(list,str) " {{{
    let a:i = 0
    let a:num = 0
    while a:i < len(a:list)
        if stridx(a:list[a:i],a:str) >= 0
            let a:num += 1
        endif
        let a:i += 1
    endwhile
    unlet a:i
    return a:num
endfunction " }}}

" Cut word in strings.
fun! s:Cutstrpart(str,start,end) " {{{
    let l:num_start = stridx(a:str,a:start) + 1
    if l:num_start < 0
        let l:num_start = 0
    endif
    if a:start == a:end
        let l:num_end = strridx(a:str,a:end) - l:num_start
    else
        let l:num_end = stridx(a:str,a:end) - l:num_start
    endif
    if l:num_end < 0
        let l:num_end = 0
    endif
    return strpart(a:str,l:num_start,l:num_end)
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
