local S = require('user.snippets')

return {
  S.snip([[^-\{3,}]], 'Horizontal rule', 'rA', ('-'):rep(77)),
  S.snip([[^=\{3,}]], 'End of module', 'rA', ('='):rep(77)),
  S.snip('Spec', 'Define simple SPECIFICATION', 'b', [[
${1:Something}Spec == $1Init /\ [][$1Next]_${2:vars}]]),
  S.snip('Symmetry', 'Define simple SYMMETRY', 'b', [[
${1:Something}Symmetry == Permutations(${2:var})]]),
  S.snip('algorithm', 'Start PlusCal block', 'b', [[
(*--algorithm ${1:name}

begin
	${0:skip};

end algorithm;*)]]),
}
