-- Record<Language, {
--   tokens?: string[];
--   paths?: string[];
--   ignore_paths?: string[];
--   space: 0 | 1 | 2 | 3;
-- }>
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
      paths = {'arguments$', 'array$'},
      space = 2,
    },
  },
  ['typescript'] = {},
  ['tsx'] = {},
  ['vim'] = {
    {
      tokens = {','},
      paths = {'call_expression$', 'list$'},
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
