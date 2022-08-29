-- Record<Language, {
--   tokens?: string[];
--   paths?: string[];
--   ignore_paths?: string[];
--   space: 0 | 1 | 2 | 3;
-- }>
return {
  ['*'] = {
    {
      tokens = {'[=]'},
      paths = {'statement%w*$', 'declar%w+$'},
      space = 3,
    },
    {
      paths = {'binary_operation$', 'binary_expression$'},
      space = 3,
    },
  },
  ['typescript'] = {},
  ['tsx'] = {},
  ['vim'] = {},
  ['lua'] = {},
  ['go'] = {},
}
