; dein config file
(table_array_element
  (pair
    (bare_key) @_key
    (string) @injection.content
    (#any-of? @_key "hook_add" "hook_source")
    (#set! injection.language "vim")
  )
)
