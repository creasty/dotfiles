local S = require('user.snippets')

return {
  S.snip('set', 'Useful default behaviors', 'b', [[
set -euo pipefail]]),
  S.snip('if', 'if [ expr ]; then', 'b', [[
if [ $1 ]; then
	$0
fi]]),
  S.snip('elif', 'elif [ expr ]; then', 'b', [[
elif [ $1 ]; then
	$0]]),
  S.snip('case', 'case', 'b', [[
case ${1:expr} in
	$0
esac]]),
  S.snip('warn', 'Print message to stderr', 'b', [[
echo '$0' 1>&2]]),
  S.snip('fatal', 'Print error and exit', 'b', [[
echo '$0' 1>&2
exit 1]]),
  S.snip('ask', 'ask()', 'b', [[
ask() {
	echo -n "\$1"
	read REPLY
}]]),
  S.snip('cdrt', 'cd to the script\'s location', 'b', [[
cd "$(dirname "\$0")" || exit 1]]),
  S.snip('command', 'Check if a command is available', 'b', [[
command -v '$0' > /dev/null 2>&1]]),
  S.snip('dotenv', 'Load .env file', 'b', [[
if [ -f .env ]; then
	set -o allexport
	eval "\$(cat .env | grep -v '^#')"
	set +o allexport
fi]]),
  S.snip('envchain', 'Load envchain', 'b', [[
set -o allexport
eval "$(envchain -l -v ${1:namespace})"
set +o allexport]]),
  S.snip('do_help', 'do_help()', 'b', [[
do_help() {
	sed -n -E '/^#>/s/^#>[ ]?//p' < "\$0"
	exit 1
}]]),
  S.snip('errifout', 'Error if there\'s output', 'b', [[
awk '{ e = 1; print \$0 } END { if (e) exit(1) }']]),
  S.snip('getopts', 'while getopts', 'b', [[
while getopts ${1:options} OPT;; do
	# Refer \$OPTARG to retrieve a value
	case "\$OPT" in
		$0
	esac
done

shift \$((OPTIND - 1))]]),
  S.snip('parse_opt', 'Advanced option parser', 'b', [[
parse_opt() {
	case "\$1" in
		${1:opt_name})
			FLAG_XXX="\$2"
			PARSE_OPT_SHIFT=1$0
			;;
		*)
			echo "Invalid option: \$1" 1>&2
			exit 1
			;;
	esac
}

while (( \$# > 0 )); do
	PARSE_OPT_SHIFT=0
	case "\$1" in
		--) shift && break ;;
		--*)
			parse_opt "\${1:2}" "\${@:2}"
			shift \$((PARSE_OPT_SHIFT + 1))
			;;
		-[a-z0-9])
			parse_opt "\${1:1}" "\${@:2}"
			shift \$((PARSE_OPT_SHIFT + 1))
			;;
		-*)
			while read -rn1 c && [ -n "\$c" ]; do
				parse_opt "\$c" ''
			done <<< "\${1:1}"
			shift
			;;
		*) break ;;
	esac
done]]),
  S.snip('line', 'Iterate each line', '', [[
while IFS= read -r line; do
	$0
done]]),
  S.snip('print_info', 'print_info()', 'b', [[
print_info() {
	printf "\e[0;34m[Info]\e[0m %s\n" "\$*" 1>&2
}]]),
  S.snip('print_success', 'print_success()', 'b', [[
print_success() {
	printf "\e[0;32m[Success]\e[0m %s\n" "\$*" 1>&2
}]]),
  S.snip('print_error', 'print_error()', 'b', [[
print_error() {
	printf "\e[0;31m[Error]\e[0m %s\n" "\$*" 1>&2
}]]),
  S.snip('print_status', 'print_status()', 'b', [[
print_status() {
	if [ \$1 -eq 0 ]; then
		print_success "OK"
	else
		print_info "\$2"
	fi
}]]),
  S.snip('section', 'section()', 'b', [[
section() {
	printf "\e[33m==> %s\e[0m\n" "\$*"
}]]),
  S.snip('subsection', 'subsection', 'b', [[
subsection() {
	printf "\e[34m--> %s\e[0m\n" "\$*"
}]]),
  S.snip('teepipe', 'Debug output while piping', '', [[
awk '{ print \$0; print \$0 > "/dev/stderr" }']]),
  S.snip('join', 'Join lines to string', '', [[
paste -sd '+' -]]),
  S.snip('trap', 'trap and at_exit', 'b', [[
at_exit() {
	$0
}
trap at_exit EXIT
trap 'trap - EXIT; at_exit; exit -1' SIGHUP SIGINT SIGTERM]]),
}
