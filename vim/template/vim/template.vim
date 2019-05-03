<%- @name = File.basename('FILE_NAME', '.vim') -%>
if exists('g:loaded_<%= @name %>') || v:version < 702
  finish
endif
let g:loaded_<%= @name %> = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

<+CURSOR+>

let &cpoptions = s:save_cpo
unlet s:save_cpo
