/*
* render-docx.test.ts
*
* Copyright (C) 2020-2022 Posit Software, PBC
*
*/
import { docs } from "../../utils.ts";
import { testRender } from "./render.ts";

testRender(docs("test.Rmd"), "html", false, []);
testRender(docs("test.qmd"), "docx", true, []);
