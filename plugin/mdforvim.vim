" Last Change: 2015 Feb 22
" Maintainer: Kuro_CODE25 <kuro.code25@gmail.com>

if exists("g:loaded_typecorr")
    finish
endif
let g:loaded_typecorr = 1

let s:save_cpo = &cpo
set cpo&vim

augroup write_text
    autocmd!
    autocmd TextChangedI * call mdforvim#autowrite()
    autocmd TextChanged * call mdforvim#autowrite()
augroup END

if !exists(":MdCovert")
    command! MdConvert call mdforvim#convert()
endif
if !exists(":MdSaveAs")
    command! -nargs=1 MdSaveAs call mdforvim#save_html(<q-args>)
endif
if !exists("MdPreview")
    command! MdPreview call mdforvim#preview()
endif
if !exists("MdStopPreview")
    command! MdStopPreview call mdforvim#stop_preview()
endif

let &cpo = s:save_cpo
unlet s:save_cpo
