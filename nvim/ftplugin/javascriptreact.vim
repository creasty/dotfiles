source <sfile>:h/javascript.vim

" Convert a React component's plain attribute to an expression syntax
"
" Example diff:
"   -className="foo bar"
"   +className={`foo bar`}
command! ReactAttrToExp normal cs"`ysa`}%h
