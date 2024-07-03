/*
 * render-format-extension.test.ts
 *
 * Copyright (C) 2020-2022 Posit Software, PBC
 */

// TODO re-enable the ACM tests once the template has been updated

import { safeRemoveSync } from "../../../src/core/path.ts";
import { docs } from "../../utils.ts";

import { testRender } from "./render.ts";

// Some HTML tests
testRender(docs("extensions/format/academic/document.qmd"), "html", false);
// testRender(docs("extensions/format/academic/document.qmd"), "acm-html", false);
testRender(docs("extensions/format/academic/document.qmd"), "acs-html", false);
testRender(
  docs("extensions/format/academic/document.qmd"),
  "elsevier-html",
  false,
);

// some PDF tests
testRender(docs("extensions/format/academic/document.qmd"), "pdf", true);
// testRender(
//   docs("extensions/format/academic/document.qmd"),
//   "acm-pdf",
//   true,
//   [],
//   {
//     teardown: async () => {
//       await Deno.remove(docs("extensions/format/academic/sensys-abstract.cls"));
//       await Deno.remove(
//         docs("extensions/format/academic/acm_proc_article-sp.cls"),
//       );
//     },
//   },
// );
testRender(
  docs("extensions/format/academic/document.qmd"),
  "acs-pdf",
  true,
  [],
  {
    // deno-lint-ignore require-await
    teardown: async () => {
      // Clean up the bib file that is generated by the elesevier class
      safeRemoveSync(docs("extensions/format/academic/acs-document.bib"));
    },
  },
);
testRender(
  docs("extensions/format/academic/document.qmd"),
  "elsevier-pdf",
  true,
  [],
  {
    // deno-lint-ignore require-await
    teardown: async () => {
      // Clean up the SPL file that is generated by the elesevier class
      safeRemoveSync(docs("extensions/format/academic/document.spl"));
    },
  },
);

// Funky format string test
testRender(
  docs("extensions/format/academic/document.qmd"),
  "elsevier-pdf+foobar",
  true,
  [],
  {
    // deno-lint-ignore require-await
    teardown: async () => {
      // Clean up the SPL file that is generated by the elesevier class
      safeRemoveSync(docs("extensions/format/academic/document+foobar.spl"));
    },
  },
);
