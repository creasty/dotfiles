<%=
package_name = File.basename(File.dirname('FILE_PATH'))

class_name = File.basename('FILE_NAME', '.go')
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .delete('_')

out = <<EOS.chomp
package #{package_name}

type #{class_name} struct{
	<+CURSOR+>
}
EOS

out
%>
