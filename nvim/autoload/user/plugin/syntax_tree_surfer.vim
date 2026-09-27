function! user#plugin#syntax_tree_surfer#init() abort
  xnoremap <SID>(sts) <Nop>
  xnoremap <script> s <SID>(sts)
  xnoremap <script> <SID>(sts)s <SID>(sts)

  " Visual Selection from Normal Mode
  nnoremap <script><silent> vs <Cmd>STSSelectCurrentNode<CR><SID>(sts)
  nnoremap <script><silent> vS <Cmd>STSSelectMasterNode<CR><SID>(sts)

  " Select Nodes in Visual Mode
  xnoremap <script><silent> <SID>(sts)h <Cmd>STSSelectPrevSiblingNode<CR><SID>(sts)
  xnoremap <script><silent> <SID>(sts)l <Cmd>STSSelectNextSiblingNode<CR><SID>(sts)
  xnoremap <script><silent> <SID>(sts)j <Cmd>STSSelectChildNode<CR><SID>(sts)
  xnoremap <script><silent> <SID>(sts)k <Cmd>STSSelectParentNode<CR><SID>(sts)

  " Swapping Nodes in Visual Mode
  xnoremap <script><silent> <SID>(sts)H <Cmd>STSSwapPrevVisual<CR><SID>(sts)
  xnoremap <script><silent> <SID>(sts)L <Cmd>STSSwapNextVisual<CR><SID>(sts)
endfunction
