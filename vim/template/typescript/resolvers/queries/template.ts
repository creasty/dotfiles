<%-
name = File.basename('FILE_NAME', '.ts')
-%>
import { Resolver } from "resolvers/type";

export const <%= name %>: Resolver<"<%= name %>"> = async (_parent, args, context, _info) => {
  <+CURSOR+>
};
