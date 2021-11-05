/**
* index.ts
*
* imports all of core lib for the esbuild target
*
* Copyright (C) 2021 by RStudio, PBC
*
*/

// export * from "./binary-search.ts";
// export * from "./break-quarto-md.ts";
// export * from "./mapped-text.ts";
// export * from "./partition-cell-options.ts";
// export * from "./ranged-text.ts";
// export * from "./text.ts";

import { glb } from "./binary-search.ts";
import { breakQuartoMd } from "./break-quarto-md.ts";
import { mappedString, asMappedString, mappedConcat, mappedIndexToRowCol, mappedLines } from "./mapped-text.ts";
import { partitionCellOptionsMapped, kLangCommentChars } from "./partition-cell-options.ts";
import { PromiseQueue } from "./promise.ts";
import { rangedSubstring, rangedLines } from "./ranged-text.ts";
import { lineOffsets, lines, normalizeNewlines, indexToRowCol, rowColToIndex } from "./text.ts";
import { schemaType, schemaCompletions } from "./schema.ts";
import { YAMLSchema, setupAjv } from "./yaml-schema.ts";

const result = {
  glb,

  breakQuartoMd,

  mappedString,
  asMappedString,
  mappedConcat,
  mappedIndexToRowCol,

  partitionCellOptionsMapped,
  kLangCommentChars,

  PromiseQueue,

  rangedSubstring,
  rangedLines,

  lineOffsets,
  lines,
  normalizeNewlines,
  indexToRowCol,
  rowColToIndex,

  schemaType,
  schemaCompletions,

  YAMLSchema,
  setupAjv
};

if (window) {
  window._quartoCoreLib = result;
}
