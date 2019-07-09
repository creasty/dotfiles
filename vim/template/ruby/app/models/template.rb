<%-
namespaces = File.dirname('FILE_PATH'.split('app/models')[1])
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .split('/')
  .reject { |n| n == '' }

class_name = File.basename('FILE_NAME', '.rb')
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .delete('_')
-%>
class <%= [*namespaces, class_name].join('::') %> < ApplicationRecord
  <+CURSOR+>
end
