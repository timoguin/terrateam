// Rendering format of a workflow step output.
//
// A step payload may carry a `format` key, set from the `format:` field of a
// `run` step in .terrateam/config.yml. This mirrors `output_of_run` in
// code/src/terrat_vcs_github_comment/terrat_vcs_github_comment_publishers.ml so
// that the UI and the pull request comment render the same payload the same way.

export type OutputFormat =
  | { kind: 'text' }
  | { kind: 'code'; lang: string }
  | { kind: 'markdown' };

export const TEXT_FORMAT: OutputFormat = { kind: 'text' };
export const DIFF_FORMAT: OutputFormat = { kind: 'code', lang: 'diff' };

/**
 * Normalize a raw `payload.format` value into an OutputFormat.
 *
 * Accepted shapes (see hook-op-run-format in api_schemas/terrat/config-schema.json):
 *   "code"                      -> plain code block
 *   "raw" | "markdown"          -> rendered as markdown
 *   { type: "code", lang: "x" } -> code block highlighted as "x"
 *
 * Anything unrecognized falls back to a plain code block.
 */
export function parseOutputFormat(format: unknown): OutputFormat {
  if (format === 'raw' || format === 'markdown') {
    return { kind: 'markdown' };
  }

  if (format && typeof format === 'object') {
    const lang = (format as { lang?: unknown }).lang;
    if (typeof lang === 'string' && lang !== '') {
      return { kind: 'code', lang };
    }
  }

  return TEXT_FORMAT;
}
