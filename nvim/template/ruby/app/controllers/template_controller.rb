<%-
namespaces = File.dirname('FILE_PATH'.split('app/controllers')[1])
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .split('/')
  .reject { |n| n == '' }

class_name = File.basename('FILE_NAME', '.rb')
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .delete('_')

parent = (class_name == 'ApplicationController') ?
  'ActionController::Base' : 'ApplicationController'
-%>
class <%= [*namespaces, class_name].join('::') %> < <%= parent %>
  <+CURSOR+>
end
