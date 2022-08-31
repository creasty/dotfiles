--[[
Record<Language, {
  tokens?: string[];
  paths?: string[];
  ignore_paths?: string[];
  space: 0 | 1 | 2 | 3;
}>
--]]

local typescript = {
  {
    tokens = {','},
    paths = {
      'array_pattern$',
      'binary_expression/object$',
      'arguments/object$',
    },
    space = 2,
  },
  {
    tokens = {':'},
    paths = {'type_annotation$', 'object/pair$'},
    space = 2,
  },
  {
    tokens = {'=>'},
    paths = {'arrow_function$', 'function_type$'},
    space = 3,
  },
  {
    tokens = {'[|&]'},
    paths = {'type_annotation/%w+_type$', 'type_arguments/%w+_type$'},
    space = 3,
  },
}

return {
  ['*'] = {
    {
      tokens = {'='},
      paths = {'statement%w*$', 'declar%w+$', 'assignment_expression$'},
      space = 3,
    },
    {
      paths = {'binary_operation$', 'binary_expression$'},
      space = 3,
    },
    {
      tokens = {','},
      paths = {'arguments$', 'array$', 'parameters$'},
      space = 2,
    },
    {
      tokens = {'[?:]'},
      paths = {'ternary_expression$'},
      space = 3,
    },
  },
  ['typescript'] = typescript,
  ['tsx'] = typescript,
  ['vim'] = {
    {
      tokens = {','},
      paths = {'call_expression$', 'list$', 'dictionary$', 'list_assignment$'},
      space = 2,
    },
    {
      tokens = {':'},
      paths = {'dictionary_entry$'},
      space = 2,
    },
  },
  ['lua'] = {
    {
      tokens = {'='},
      paths = {'field$', 'for_numeric_clause$'},
      space = 3,
    },
    {
      tokens = {','},
      paths = {'for_numeric_clause$', 'table_constructor$'},
      space = 2,
    },
  },
  ['go'] = {},
}
