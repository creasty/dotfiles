<%=
namespaces = File.dirname('FILE_PATH'.split('app/models')[1])
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .split('/')
  .reject { |n| n == '' }

controller_name = File.basename('FILE_NAME', '.rb')
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .delete('_')

out = <<EOS.chomp
class #{controller_name} < ActiveRecord::Base

  <+CURSOR+>

end
EOS

namespaces.reverse.each do |namespace|
  out = <<EOS.chomp
module #{namespace}
#{out.gsub(/^/, '  ')}
end
EOS
end

out.gsub(/^[ ]+$/, '')
%>
