import type { ActionData } from "https://deno.land/x/ddu_kind_file@v0.2.0/file.ts";
import type {
  GatherArguments,
  OnInitArguments,
} from "https://deno.land/x/ddu_vim@v1.1.0/base/source.ts";
import type { Item } from "https://deno.land/x/ddu_vim@v1.1.0/types.ts";
import { BaseSource } from "https://deno.land/x/ddu_vim@v1.1.0/types.ts";
import { join } from "https://deno.land/std@0.127.0/path/mod.ts";

type Params = {
  bin: string;
  rootPath: string;
};

export class Source extends BaseSource<Params, ActionData> {
  kind = "file";

  async onInit(args: OnInitArguments<Params>): Promise<void> {
    if (!args.sourceParams.rootPath) {
      const proc = Deno.run({
        cmd: [args.sourceParams.bin, "root"],
        stdin: "null",
        stdout: "piped",
        stderr: "piped",
      });
      args.sourceParams.rootPath = new TextDecoder()
        .decode(await proc.output())
        .replace(/\r?\n/g, '');
      proc.close();
    }
  }

  gather(args: GatherArguments<Params>): ReadableStream<Item<ActionData>[]> {
    return new ReadableStream({
      async start(controller) {
        const proc = Deno.run({
          cmd: [args.sourceParams.bin, "list"],
          stdin: "null",
          stdout: "piped",
        });
        const paths = new TextDecoder().decode(await proc.output()).split(/\r?\n/);
        proc.close();

        const items: Item<ActionData>[] = paths.map((path) => {
          return {
            word: path,
            display: path,
            action: {
              path: join(args.sourceParams.rootPath, path),
            },
          };
        });

        controller.enqueue(items);
        controller.close();
      },
    });
  }

  params(): Params {
    return {
      bin: "ghq",
      rootPath: "",
    };
  }
}
