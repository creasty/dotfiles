; extends

; Where nvim-treesitter's indentation differs from prettier's (TSX inherits
; these; tsx/indents.scm has its own). nvim-treesitter counts one level for
; each line a node that indents starts on, so each rule below adds a level, or
; takes one back, for a shape prettier formats.

; Lines in a multi-line template string keep theirs (rather than none)
(template_string) @indent.auto

; Omit<
;   Options,
;   'root'
; >
[
  (type_arguments)
  (type_parameters)
] @indent.begin

(type_arguments
  ">" @indent.branch @indent.end)

(type_parameters
  ">" @indent.branch @indent.end)

; type Config =
;   | UserConfig
;   | Promise<UserConfig>
(type_alias_declaration
  value: (union_type)) @indent.begin

(property_signature
  type: (type_annotation
    (union_type))) @indent.begin

; key:
;   value
(pair
  value: (_) @_value
  (#not-kind-eq? @_value "binary_expression")) @indent.begin

; key:
;   a ||
;   b
;     ? c
;     : d
(pair
  value: (ternary_expression
    condition: (binary_expression) @indent.dedent))

; const value =
;   React.useMemo(() => {
(variable_declarator
  value: (call_expression)) @indent.begin

; const hosts = raw
;   .split(',')
(member_expression) @indent.begin

; theme.cssVars[
;   key
; ]
(subscript_expression) @indent.begin

; A function's only parameter, destructured and typed with an object type,
; which prettier hugs
;
; function Row({
;   row,
; }: {
;   row: Row
; }) {
(formal_parameters
  .
  (required_parameter
    pattern: (object_pattern)
    type: (type_annotation
      (object_type) @indent.dedent))
  .)

(formal_parameters
  .
  (required_parameter
    pattern: (object_pattern)
    type: (type_annotation
      (generic_type
        (type_arguments
          (object_type) @indent.dedent))))
  .)

; }) => (
;   <Row />
; )
(arrow_function
  body: (parenthesized_expression)) @indent.dedent
