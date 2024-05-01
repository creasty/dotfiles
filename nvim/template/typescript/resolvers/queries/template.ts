import { Resolver } from "resolvers/type";

export const FILE_BASE_NAME: Resolver<"FILE_BASE_NAME"> = async (_parent, args, context, _info) => {
  return context.api.<+CURSOR+>().FILE_BASE_NAME(<%= "FILE_BASE_NAME" %>RequestInputToPb(args.input)).then(<%= "FILE_BASE_NAME" %>ResponseToType);
};
