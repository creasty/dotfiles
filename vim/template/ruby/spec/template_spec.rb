<%
is_active_support_available = false

begin
  require 'active_support'
  is_active_support_available = true
rescue
end

m = 'FILE_PATH'.match(%r{spec/(\w+)/(.+?)_spec\.rb$})

spec_type, class_name = m[1], m[2]

if is_active_support_available
  spec_type = ActiveSupport::Inflector.singularize(spec_type)
end

class_name = class_name
  .gsub('/', '::')
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .delete('_')
-%>
require 'spec_helper'

Rspec.describe <%= class_name %>, type: :<%= spec_type %> do

  

end
