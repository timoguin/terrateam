/**
 * Workflow step output as returned by the work manifest outputs endpoint.
 *
 * The payload is free-form JSON built by the runner, so the fields below are the
 * ones the UI knows how to read rather than a closed schema. For a plan step the
 * runner sends both halves of the operation: `text` is the stdout of the
 * engine's plan command and `plan` is the stdout of its diff command.
 */

import type { TerraformJsonPlan } from './terraform';

export interface StepOutputPayload {
  text?: string;
  plan?: string;
  cmd?: string[];
  exit_code?: number;
  plan_text?: string;
  diff?: TerraformJsonPlan | string; // JSON plan data (object or string)
  format?: string | { type?: string; lang?: string };
  has_changes?: boolean;
  ignore_errors?: boolean;
  visible_on?: string;
  summary?: {
    total_monthly_cost?: number;
    diff_monthly_cost?: number;
    prev_monthly_cost?: number;
  };
  currency?: string;
  dirspaces?: Array<{
    dir: string;
    workspace: string;
    total_monthly_cost: number;
    diff_monthly_cost: number;
    prev_monthly_cost: number;
  }>;
  // Lite mode properties
  _isLiteMode?: boolean;
  _originalStep?: string;
  _wasLoadedOnDemand?: boolean;
  _loadTimestamp?: number;
  _loadError?: boolean;
}

export interface OutputItem {
  payload?: StepOutputPayload;
  scope?: {
    dir?: string;
    workspace?: string;
    type?: string;
  };
  step?: string;
  state?: string;
  ignore_errors?: boolean;
  idx?: number;
}
