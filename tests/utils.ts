/*
* utils.ts
*
* Copyright (C) 2020-2022 Posit Software, PBC
*
*/

import { basename, dirname, extname, join } from "../src/deno_ral/path.ts";
import { parseFormatString } from "../src/core/pandoc/pandoc-formats.ts";
import { kMetadataFormat, kOutputExt } from "../src/config/constants.ts";
import { safeExistsSync } from "../src/core/path.ts";

// caller is responsible for cleanup!
export function inTempDirectory(fn: (dir: string) => unknown): unknown {
  const dir = Deno.makeTempDirSync();
  return fn(dir);
}

// Find a _quarto.yaml file in the directory hierarchy of the input file
export function findProjectDir(input: string, until?: RegExp | undefined): string | undefined {
  let dir = dirname(input);
  // This is used for smoke-all tests and should stop there 
  // to avoid side effect of _quarto.yml outside of Quarto tests folders
  while (dir !== "" && dir !== "." && (until ? !until.test(dir) : true)) {
    const filename = ["_quarto.yml", "_quarto.yaml"].find((file) => {
      const yamlPath = join(dir, file);
      if (safeExistsSync(yamlPath)) {
        return true;
      }
    });
    if (filename) {
      return dir;
    }

    const newDir = dirname(dir); // stops at the root for both Windows and Posix
    if (newDir === dir) {
      return;
    }
    dir = newDir;
  }
}

// Gets output that should be created for this input file and target format
export function outputForInput(
  input: string,
  to: string,
  projectOutDir?: string,
  // deno-lint-ignore no-explicit-any
  metadata?: Record<string, any>,
) {
  // TODO: Consider improving this (e.g. for cases like Beamer, or typst)
  const dir = dirname(input);
  let stem = basename(input, extname(input));
  let ext = metadata?.[kMetadataFormat]?.[to]?.[kOutputExt];

  // TODO: there's a bug where output-ext keys from a custom format are 
  // not recognized (specifically this happens for confluence)
  //
  // we hack it here for the time being.
  //
  if (to === "confluence-publish") {
    ext = "xml";
  }
  if (to === "docusaurus-md") {
    ext = "mdx";
  }

  
  const formatDesc = parseFormatString(to);
  const baseFormat = formatDesc.baseFormat;
  if (formatDesc.baseFormat === "pdf") {
    stem = `${stem}${formatDesc.variants.join("")}${
      formatDesc.modifiers.join("")
    }`;
  }

  let outputExt;
  if (ext) { 
    outputExt = ext 
  } else {
    outputExt = baseFormat || "html";
    if (baseFormat === "latex" || baseFormat == "context" || baseFormat == "beamer") {
      outputExt = "tex";
    }
    if (baseFormat === "revealjs") {
      outputExt = "html";
    }
    if (["commonmark", "gfm", "markdown"].some((f) => f === baseFormat)) {
      outputExt = "md";
    }
    if (baseFormat === "csljson") {
      outputExt = "csl";
    }
    if (baseFormat === "bibtex" || baseFormat === "biblatex") {
      outputExt = "bib";
    }
    if (baseFormat === "jats") {
      outputExt = "xml";
    }
    if (baseFormat === "asciidoc") {
      outputExt = "adoc";
    }
    if (baseFormat === "typst") {
      outputExt = "pdf";
    }
    if (baseFormat === "dashboard") {
      outputExt = "html";
    }
    if (baseFormat === "email") {
      outputExt = "html";
    }
  }

  const outputPath = projectOutDir
    ? join(dir, projectOutDir, `${stem}.${outputExt}`)
    : join(dir, `${stem}.${outputExt}`);
  const supportPath = projectOutDir
    ? join(dir, projectOutDir, `${stem}_files`)
    : join(dir, `${stem}_files`);

  return {
    outputPath,
    supportPath,
  };
}

export function siteOutputForInput(input: string) {
  const dir = join(dirname(input), "_site");
  const stem = basename(input, extname(input));

  const outputPath = join(dir, `${stem}.html`);
  const supportPath = join(dir, `site_libs`);

  return {
    outputPath,
    supportPath,
  };
}

export function docs(path: string): string {
  return join("docs", path);
}

export function fileLoader(...path: string[]) {
  return (file: string, to: string) => {
    const input = docs(join(...path, file));
    const output = outputForInput(input, to);
    return {
      input,
      output,
    };
  };
}

// On Windows, `quarto.cmd` needs to be explicit in `execProcess()`
export function quartoDevCmd(): string {
  return Deno.build.os === "windows" ? "quarto.cmd" : "quarto";
}
