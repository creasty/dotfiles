import {
  BaseSource,
  DduOptions,
  Item,
} from "https://deno.land/x/ddu_vim@v1.2.0/types.ts";
import { Denops, fn } from "https://deno.land/x/ddu_vim@v1.2.0/deps.ts";
import { ActionData } from "https://deno.land/x/ddu_kind_file@v0.2.0/file.ts";
import { join } from "https://deno.land/std@0.126.0/path/mod.ts";

type HighlightGroup = {
  path?: string;
  lineNr?: string;
  word?: string;
};

type Params = {
  args: string[];
  input: string;
  path: string;
  highlights?: HighlightGroup;
};

export class Source extends BaseSource<Params> {
  kind = "file";

  gather(args: {
    denops: Denops;
    options: DduOptions;
    sourceParams: Params;
    input: string;
  }): ReadableStream<Item<ActionData>[]> {
    const findby = async (input: string) => {
      const cmd = ["rg", ...args.sourceParams.args, input];
      const cwd = args.sourceParams.path != ""
        ? args.sourceParams.path
        : await fn.getcwd(args.denops) as string;
      const p = Deno.run({
        cmd: cmd,
        stdout: "piped",
        stderr: "piped",
        stdin: "null",
        cwd: cwd,
      });

      const parse_json = (list) => {
        const hl_group_path = args.sourceParams.highlights?.path ?? "";
        const hl_group_lineNr = args.sourceParams.highlights?.lineNr ?? "";
        const hl_group_word = args.sourceParams.highlights?.word ?? "";

        const ret = list.filter((e) => e).map((e) => {
          const jo = JSON.parse(e);
          if (jo.type === "match") {
            const path = jo.data.path.text;
            const lineNr = jo.data.line_number;
            const col = jo.data.submatches[0].start;
            const text = jo.data.lines.text.replace("\n", "");
            const header = `${path}:${lineNr}:${col}: `;
            return {
              word: header + text,
              action: {
                path: join(cwd, path),
                lineNr: lineNr,
                col: col + 1,
                text: text,
              },
              highlights: [
                {
                  name: "path",
                  "hl_group": hl_group_path,
                  col: 1,
                  width: path.length,
                },
                {
                  name: "lineNr",
                  "hl_group": hl_group_lineNr,
                  col: path.length + 2,
                  width: String(lineNr).length,
                },
                {
                  name: "word",
                  "hl_group": hl_group_word,
                  col: header.length + col + 1,
                  width: jo.data.submatches[0].end - col,
                },
              ],
            };
          }
        }).filter((e) => e);

        return ret;
      };

      const parse_line = () => {
        const ret = list.filter((e) => e).map((e) => {
          const re = /^([^:]+):(\d+):(\d+):(.*)$/;
          const result = e.match(re);
          const get_param = (ary: string[], index: number) => {
            return ary[index] ?? "";
          };

          const path = result ? get_param(result, 1) : "";
          const lineNr = result ? Number(get_param(result, 2)) : 0;
          const col = result ? Number(get_param(result, 3)) : 0;
          const text = result ? get_param(result, 4) : "";

          return {
            word: e,
            action: {
              path: join(cwd, path),
              lineNr: lineNr,
              col: col,
              text: text,
            },
          };
        });

        return ret;
      };

      const output = await p.output();
      const list = new TextDecoder().decode(output).split(/\r?\n/);

      const ret = (() => {
        if (args.sourceParams.args.includes("--json")) {
          return parse_json(list);
        } else {
          return parse_line(list);
        }
      })();
      return ret;
    };

    return new ReadableStream({
      async start(controller) {
        const input = args.options.volatile
          ? args.input
          : args.sourceParams.input;

        if (input != "") {
          controller.enqueue(
            await findby(input),
          );
        }

        controller.close();
      },
    });
  }

  params(): Params {
    return {
      args: ["--column", "--no-heading", "--color", "never"],
      input: "",
      live: false,
      path: "",
    };
  }
}
