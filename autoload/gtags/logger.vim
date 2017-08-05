let s:LOG = SpaceVim#api#import('logger')

call s:LOG.set_name('Gtags')

function! gtags#logger#log(level, msg) abort
    if a:level ==# 'info'
        call s:LOG.info(a:msg)
    elseif a:level ==# 'warn'
        call s:LOG.warn(a:msg)
    elseif a:level ==# 'error'
        call s:LOG.error(a:msg)
    endif
endfunction

function! gtags#logger#view(level)
    call s:LOG.view(a:level)
endfunction



