local schema = {
  -- grayscale
  white   = '#e7e7e7',
  gray100 = '#c0c0c0',
  gray200 = '#7f7e7e',
  gray300 = '#575757',
  gray400 = '#424242',
  gray450 = '#303030',
  gray500 = '#2c2c2c',
  gray550 = '#262626',
  gray600 = '#1b1b1b',
  gray610 = '#1a1a1a',
  gray650 = '#161616',
  gray700 = '#0f0f0f',
  black   = '#000000',

  -- base
  red    = '#a57572',
  brown  = '#8f6e58',
  orange = '#c59b75',
  yellow = '#d0b888',
  green  = '#a6b083',
  aqua   = '#9abbb6',
  blue   = '#8ca2b6',
  purple = '#a186a3',
  pink   = '#c585a8',

  -- bright
  bright_red    = '#b56e6a',
  bright_brown  = '#9d6a48',
  bright_orange = '#cf9867',
  bright_yellow = '#d8b775',
  bright_green  = '#a5b56b',
  bright_aqua   = '#80c7bc',
  bright_blue   = '#82a4c3',
  bright_purple = '#b07bb4',
  bright_pink   = '#cf7fab',

  -- dark
  dark_red    = '#503131',
  dark_brown  = '#55453a', -- TODO
  dark_orange = '#573f2e',
  dark_yellow = '#5f5138',
  dark_green  = '#4c4b30',
  dark_aqua   = '#3c4e4b',
  dark_blue   = '#39444d',
  dark_purple = '#47404d',
  dark_pink   = '#c585a8', -- TODO
}

schema.foreground = schema.gray100
schema.comment = schema.gray300
schema.selection = schema.gray450
schema.line = schema.gray500
schema.window = schema.gray550
schema.background = schema.gray600
schema.guide = schema.gray610

return schema
