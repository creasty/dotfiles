import {
  BaseSource,
  Item,
  ItemHighlight,
} from "https://deno.land/x/ddu_vim@v1.8.8/types.ts";
import { fn } from "https://deno.land/x/ddu_vim@v1.8.8/deps.ts";
import { ActionData } from "https://deno.land/x/ddu_kind_file@v0.3.0/file.ts";
import { join } from "https://deno.land/std@0.151.0/path/mod.ts";
import { GatherArguments } from "https://deno.land/x/ddu_vim@v1.8.8/base/source.ts";

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

function parseJson(cwd: string, list: string[], highlights?: HighlightGroup) {
  const hlGroupPath = highlights?.path ?? "";
  const hlGroupLineNr = highlights?.lineNr ?? "";
  const hlGroupWord = highlights?.word ?? "";

  return list
    .map((e) => {
      if (!e) return;

      const jo = JSON.parse(e);
      if (jo.type !== "match") return;

      let word = "";
      const highlights: ItemHighlight[] = [];

      const path = jo.data.path.text;
      highlights.push({
        name: "path",
        hl_group: hlGroupPath,
        col: word.length + 1,
        width: path.length,
      });
      word += `${path} `;

      const lineNr = jo.data.line_number;
      const col = jo.data.submatches[0].start;
      const pos = `${lineNr}:${col} |`;
      highlights.push({
        name: "lineNr",
        hl_group: hlGroupLineNr,
        col: word.length + 1,
        width: pos.length,
      });
      word += pos;

      const text = jo.data.lines.text.replace("\n", "");
      const wordHighlight: ItemHighlight = {
        name: "word",
        hl_group: hlGroupWord,
        col: word.length + 1,
        width: 0,
      };
      jo.data.submatches.forEach((match: any) => {
        highlights.push({
          ...wordHighlight,
          col: wordHighlight.col + match.start,
          width: match.end - match.start,
        });
      });
      word += text;

      const item: Item<ActionData> = {
        word,
        action: {
          path: join(cwd, path),
          lineNr: lineNr,
          col: col + 1,
          text: text,
        },
        highlights,
      };
      return item;
    })
    .filter((e): e is Item<ActionData> => !!e);
}

export class Source extends BaseSource<Params, ActionData> {
  kind = "file";

  gather(args: GatherArguments<Params>): ReadableStream<Item<ActionData>[]> {
    const findBy = async (input: string) => {
      const cwd =
        args.sourceParams.path || ((await fn.getcwd(args.denops)) as string);
      const proc = new Deno.Command("rg", {
        args: ["--json", ...args.sourceParams.args, "--", input],
        stdout: "piped",
        stderr: "piped",
        stdin: "null",
        cwd,
      });

      const output = await proc.output();
      const list = new TextDecoder().decode(output.stdout).split(/\r?\n/);

      return parseJson(cwd, list, args.sourceParams.highlights);
    };

    return new ReadableStream({
      async start(controller) {
        const input = args.input || args.sourceParams.input;

        if (input != "") {
          controller.enqueue(await findBy(input));
        }
        controller.close();
      },
    });
  }

  params(): Params {
    return {
      args: [],
      input: "",
      path: "",
      highlights: {
        path: "Identifier",
        lineNr: "Comment",
        word: "Constant",
      },
    };
  }
}
