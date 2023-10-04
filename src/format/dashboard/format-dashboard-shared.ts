/*
 * format-dashboard-shared.ts
 *
 * Copyright (C) 2020-2022 Posit Software, PBC
 */
import { Format, Metadata } from "../../config/types.ts";

export const kDashboard = "dashboard";

export interface DashboardMeta {
  orientation: "rows" | "columns";
  fill: boolean;
}

export function dashboardMeta(format: Format): DashboardMeta {
  const dashboardRaw = format.metadata as Metadata;
  const orientation = dashboardRaw && dashboardRaw.orientation === "columns"
    ? "columns"
    : "rows";
  const fill = dashboardRaw && dashboardRaw.fill === true;

  return {
    orientation,
    fill,
  };
}
