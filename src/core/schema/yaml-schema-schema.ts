/*
* yaml-schema-schema.ts
*
* Schemas to validate yaml schemas written in yaml.
*
* Copyright (C) 2021 by RStudio, PBC
*
*/

import { readYaml } from "../yaml.ts";
import { convertFromYaml } from "./from-yaml.ts";
import { resourcePath } from "../resources.ts";
import { join } from "path/mod.ts";
import { Schema, setSchemaDefinition } from "../lib/schema.ts";

export function getSchemaSchemas(): Record<string, Schema>
{
  const yaml = readYaml(join(resourcePath(), "/schema/schema.yml")) as Record<string, any>[];
  const dict: Record<string, Schema> = {};
  for (const obj of yaml) {
    const schema = convertFromYaml(obj);
    setSchemaDefinition(schema);
    dict[schema.$id] = schema;
  }
  return dict;
}

