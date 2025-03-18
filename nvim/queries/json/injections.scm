(document
  (object (pair
    key: (string
      (string_content) @_key (#eq? @_key "scripts")
    )
    value: (object (pair
      value: (string
        (string_content) @injection.content
        (#set! injection.language "bash")
      )
    ))
  ))
)
