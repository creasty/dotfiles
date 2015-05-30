<%=
namespaces = File.dirname('FILE_PATH'.split('lib/', 2)[1])
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .split('/')
  .reject { |n| n == '' }

class_name = File.basename('FILE_NAME', '.rb')
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .delete('_')

out = <<EOS.chomp
class #{class_name}

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
