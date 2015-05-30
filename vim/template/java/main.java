<%-
@class_name = File.dirname('FILE_NAME', '.java')
-%>
/**
 * <%= @class_name %>
 */

public class <%= @class_name %> {
  public static void main(String[] args) {
    <+CURSOR+>
  }
}
