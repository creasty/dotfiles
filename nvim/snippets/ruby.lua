-- Converted from UltiSnips' ruby.snippets
local ls = require('luasnip')
local fmta = require('luasnip.extras.fmt').fmta
local S = require('user.snippets')

local i = ls.insert_node

-- `(name, age = 0)` -> `@name = name` and `@age = age` on the next lines.
local function instance_vars(arglist)
  local lines = { '' }
  for arg in vim.gsplit(arglist, ',', { plain = true }) do
    local name = arg:match('[%w_]+')
    if name then
      lines[#lines + 1] = ('\t@%s = %s'):format(name, name)
    end
  end
  return lines
end

return {
  S.snip('init', 'def initialize', 'b', fmta([[
def initialize<><>
	<>
end]], { i(1), S.mirror(1, instance_vars), i(0) })),
  S.snip('###', 'Document comment', 'b', [[
=begin
$0
=end]]),
  S.snip('defs', 'def self.name', 'b', [[
def self.$0]]),
  S.snip('pry', 'binding.pry', 'b', [[
binding.pry]]),
  S.snip('r', 'attr_reader', 'b', [[
attr_reader :$0]]),
  S.snip('w', 'attr_writer', 'b', [[
attr_writer :$0]]),
  S.snip('rw', 'attr_accessor', 'b', [[
attr_accessor :$0]]),
  S.snip([[\v(\w+)\.each]], '.each { |element| ... }', 'r', [[
$LS_CAPTURE_1.each { |$1| $0 }]]),
  S.snip([[\v(\w+)\.eachdo]], '.each do |element| ... end', 'r', [[
$LS_CAPTURE_1.each do |$1|
	$0
end]]),
  S.snip([[\v(\w+)\.map]], '.map { |element| ... }', 'r', [[
$LS_CAPTURE_1.each { |$1| $0 }]]),
  S.snip([[\v(\w+)\.mapdo]], '.map do |element| ... end', 'r', [[
$LS_CAPTURE_1.map do |$1|
	$0
end]]),
}
