import {
  BaseSource,
  Item,
  ItemHighlight,
} from "https://deno.land/x/ddu_vim@v1.8.8/types.ts";
import { ActionData } from "https://deno.land/x/ddu_kind_file@v0.3.0/file.ts";
import { globals } from "https://deno.land/x/denops_std@v3.8.0/variable/variable.ts";
import * as fn from "https://deno.land/x/denops_std@v3.8.0/function/mod.ts";
import { relative } from "https://deno.land/std@0.151.0/path/mod.ts";
import { GatherArguments } from "https://deno.land/x/ddu_vim@v1.8.8/base/source.ts";

type Params = {
  highlights?: HighlightGroup;
};

type HighlightGroup = {
  path?: string;
  lineNr?: string;
  word?: string;
};

type RangeData = {
  character: number;
  line: number;
};

type LocationData = {
  uri: string;
  lnum: number;
  end_lnum: number;
  range: {
    end: RangeData;
    start: RangeData;
  };
  filename: string;
  bufnr: number;
  end_col: number;
  col: number;
  text: string;
};

function buildItems(
  cwd: string,
  locations: LocationData[],
  highlights?: HighlightGroup
) {
  const hlGroupPath = highlights?.path ?? "";
  const hlGroupLineNr = highlights?.lineNr ?? "";
  const hlGroupWord = highlights?.word ?? "";

  return locations.map((l) => {
    const pathText = relative(cwd, l.filename);

    let word = "";
    const highlights: ItemHighlight[] = [];

    highlights.push({
      name: "path",
      hl_group: hlGroupPath,
      col: word.length + 1,
      width: pathText.length,
    });
    word += pathText + " ";

    const pos = `${l.lnum}:${l.col} |`;
    highlights.push({
      name: "lineNr",
      hl_group: hlGroupLineNr,
      col: word.length + 1,
      width: pos.length,
    });
    word += pos;

    highlights.push({
      name: "word",
      hl_group: hlGroupWord,
      col: word.length + l.col,
      width: l.end_col - l.col,
    });
    word += l.text;

    const item: Item<ActionData> = {
      word,
      action: {
        path: l.filename,
        col: l.col,
        text: l.text,
        lineNr: l.lnum,
      },
      highlights,
    };
    return item;
  });
}

export class Source extends BaseSource<Params> {
  kind = "file";

  gather(args: GatherArguments<Params>): ReadableStream<Item<ActionData>[]> {
    return new ReadableStream({
      async start(controller) {
        const locations: LocationData[] =
          (await globals.get(args.denops, "coc_jump_locations")) ?? [];
        const cwd = (await fn.getcwd(args.denops)) as string;
        const items = buildItems(cwd, locations, args.sourceParams.highlights);
        if (items.length) {
          controller.enqueue(items);
        }
        controller.close();
      },
    });
  }

  params(): Params {
    return {
      highlights: {
        path: "Identifier",
        lineNr: "Comment",
        word: "Constant",
      },
    };
  }
}
