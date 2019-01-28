<%-
namespaces = File.dirname('FILE_PATH'.split('/concerns')[1])
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .split('/')
  .reject { |n| n == '' }

base_name = File.basename('FILE_NAME', '.rb')
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .delete('_')

class_name = [*namespaces, base_name].join('::')
-%>
module <%= class_name %>
  extend ActiveSupport::Concern
  <+CURSOR+>
end
