import type { ActionData } from "https://deno.land/x/ddu_kind_file@v0.3.0/file.ts";
import type {
  GatherArguments,
  OnInitArguments,
} from "https://deno.land/x/ddu_vim@v1.8.8/base/source.ts";
import type { Item } from "https://deno.land/x/ddu_vim@v1.8.8/types.ts";
import { BaseSource } from "https://deno.land/x/ddu_vim@v1.8.8/types.ts";
import { join } from "https://deno.land/std@0.151.0/path/mod.ts";

type Params = {
  bin: string;
};

export class Source extends BaseSource<Params, ActionData> {
  kind = "file";
  private rootPath = "";

  async onInit(args: OnInitArguments<Params>): Promise<void> {
    if (!this.rootPath) {
      const proc = Deno.run({
        cmd: [args.sourceParams.bin, "root"],
        stdin: "null",
        stdout: "piped",
        stderr: "piped",
      });
      this.rootPath = new TextDecoder()
        .decode(await proc.output())
        .replace(/\r?\n/g, '');
      proc.close();
    }
  }

  gather(args: GatherArguments<Params>): ReadableStream<Item<ActionData>[]> {
    const { rootPath } = this;

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
              isDirectory: true,
              path: join(rootPath, path),
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
    };
  }
}
