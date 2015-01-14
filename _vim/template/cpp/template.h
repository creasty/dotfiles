<%-
name = 'FILE_NAME'
  .gsub(/\W+/, '_')
  .gsub(/_+/, '_')
  .gsub(/^_+|_+$/, '')
  .upcase

@guard = '__%s_LOADED__' % name
-%>
#ifndef <%= @guard %>
#define <%= @guard %>

<+CURSOR+>

#endif // <%= @guard %>
