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
  rootPath = "";
  kind = "file";

  async onInit(args: OnInitArguments<Params>): Promise<void> {
    const proc = Deno.run({
      cmd: [args.sourceParams.bin, "root"],
      stdin: "null",
      stdout: "piped",
      stderr: "piped",
    });
    if (!(await proc.status()).success) {
      args.denops.call(
        "ddu#util#print_error",
        `Invalid bin param: ${args.sourceParams.bin}`
      );
      proc.close();
      return;
    }
    this.rootPath = new TextDecoder()
      .decode(await proc.output())
      .replace(/\r?\n/g, '');
    proc.close();
  }

  gather(args: GatherArguments<Params>): ReadableStream<Item<ActionData>[]> {
    const { rootPath } = this;
    return new ReadableStream({
      async start(controller) {
        const proc = Deno.run({
          cmd: [args.sourceParams.bin, "list"],
          stdin: "piped",
          stdout: "piped",
        });
        if (!(await proc.status()).success) {
          args.denops.call(
            "ddu#util#print_error",
            `Invalid bin param: ${args.sourceParams.bin}`
          );
          proc.close();
          return;
        }
        const paths = new TextDecoder().decode(await proc.output()).split("\n");
        proc.close();
        controller.enqueue(
          await Promise.all(
            paths.map(async (path) => {
              return {
                word: path,
                display: path,
                action: {
                  path: join(rootPath, path),
                },
              } as Item<ActionData>;
            })
          )
        );
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
