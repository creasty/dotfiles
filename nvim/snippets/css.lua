local S = require('user.snippets')

return {
  S.snip([[/\@<!/]], 'Heading 1', 'br', '/*=== $0\n' .. ('='):rep(94) .. '*/'),
  S.snip([[/\@<!//]], 'Heading 2', 'br', '/*  $0\n' .. ('-'):rep(47) .. '*/'),
}
