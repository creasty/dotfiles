import { BaseSource, Item } from "https://deno.land/x/ddu_vim@v1.2.0/types.ts";
import { Denops, fn } from "https://deno.land/x/ddu_vim@v1.2.0/deps.ts";
import { ActionData } from "https://deno.land/x/ddu_kind_file@v0.3.0/file.ts";
import { relative, resolve } from "https://deno.land/std@0.129.0/path/mod.ts";
import { BufReader } from "https://deno.land/std@0.129.0/io/buffer.ts";
import { abortable } from "https://deno.land/std@0.129.0/async/mod.ts";

const enqueueSize1st = 1000;

type Params = {
  cmd: string[];
  path: string;
  updateItems: number;
};

async function* iterLine(reader: Deno.Reader): AsyncIterable<string> {
  const buffered = new BufReader(reader);
  while (true) {
    const line = await buffered.readString("\n");
    if (!line) {
      break;
    }
    yield line;
  }
}

export class Source extends BaseSource<Params> {
  kind = "file";

  gather(args: {
    denops: Denops;
    sourceParams: Params;
  }): ReadableStream<Item<ActionData>[]> {
    const abortController = new AbortController();
    const { denops, sourceParams } = args;
    return new ReadableStream({
      async start(controller) {
        let root = (await fn.fnamemodify(
          denops,
          sourceParams.path,
          ":p"
        )) as string;
        if (root == "") {
          root = (await fn.getcwd(denops)) as string;
        }

        if (!args.sourceParams.cmd.length) {
          return;
        }

        let items: Item<ActionData>[] = [];
        const enqueueSize2nd = sourceParams.updateItems;
        let enqueueSize = enqueueSize1st;
        let numChunks = 0;

        const proc = Deno.run({
          cmd: sourceParams.cmd,
          stdout: "piped",
          stderr: "piped",
          cwd: root,
        });

        try {
          for await (const line of abortable(
            iterLine(proc.stdout),
            abortController.signal
          )) {
            const path = line.trim();
            if (!path.length) continue;
            const fullPath = resolve(root, path);
            items.push({
              word: relative(root, fullPath),
              action: {
                path: fullPath,
              },
            });
            if (items.length >= enqueueSize) {
              numChunks++;
              if (numChunks > 1) {
                enqueueSize = enqueueSize2nd;
              }
              controller.enqueue(items);
              items = [];
            }
          }
          if (items.length) {
            controller.enqueue(items);
          }
        } catch (e) {
          if (e instanceof DOMException) {
            proc.kill("SIGTERM");
          } else {
            // console.error(e);
          }
        } finally {
          const [status, stderr] = await Promise.all([
            proc.status(),
            proc.stderrOutput(),
          ]);
          proc.close();
          if (!status.success) {
            void stderr;
            // console.error(new TextDecoder().decode(stderr));
          }
          controller.close();
        }
      },

      cancel(reason): void {
        abortController.abort(reason);
      },
    });
  }

  params(): Params {
    return {
      cmd: ["fd", "-t", "f", "--full-path", "--follow", "--hidden"],
      path: "",
      updateItems: 100000,
    };
  }
}
