<%-
@module_name = File.basename(File.dirname('FILE_PATH'))
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
-%>
module <%= @module_name %>
  MAJOR    = 0
  MINOR    = 0
  REVISION = 1

  VERSION = [MAJOR, MINOR, REVISION].compact.join(".")
end
