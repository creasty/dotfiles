<%=
class_name = File.basename('FILE_NAME', '.go')
  .gsub(/(_|\b)([a-z0-9])/) { $2.upcase }
  .delete('_')

out = <<EOS.chomp
package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type #{class_name} struct{}

func (#{class_name}) <+CURSOR+>(c *gin.Context) {

}
EOS

out
%>
