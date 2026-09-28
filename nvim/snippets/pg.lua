local S = require('user.snippets')

return {
  S.snip('begin', 'begin ... end', 'b', [[
begin;
	$0
end;]]),
  S.snip('declare', 'declare variable', 'b', [[
declare ${1:var_name} ${2:type} = $0;]]),
  S.snip('do', 'do ... end', 'b', [[
do $$
	${1:variables}
begin
	$0
end $$;]]),
  S.snip('temptable', 'Create temporary table', 'b', [[
create temp table ${1:name} on commit drop as
select
	$0
;]]),
}
