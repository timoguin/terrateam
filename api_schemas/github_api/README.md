# GitHub REST API schema

`api.github.com.json` is GitHub's OpenAPI description of its REST API, with local
patches applied.

## Where it comes from

The one correct source is GitHub's own repository:

  https://github.com/github/rest-api-description
  descriptions/api.github.com/api.github.com.json

Get it with:

```
curl -sSL -o api.github.com.json.orig \
  https://raw.githubusercontent.com/github/rest-api-description/main/descriptions/api.github.com/api.github.com.json
```

Do not use the `@octokit/openapi` mirror.  That mirror is behind GitHub's own
description, and it holds defects that GitHub's description does not have.

## The two files

`api.github.com.json.orig` holds the clean schema that `api.github.com.json` is
based on.  It gives the base for a three-way merge when you update to a later
schema.  Update it in the same commit as `api.github.com.json`.

**Normalise both files with `jq -S .` before you compare or commit them.**  That
puts every key in a fixed order, thus a comparison shows only real changes.  The
dune rule in `code/src/githubc2/dune` does the same to `api.github.com.json`.

## Why we patch the schema

The schema does not always agree with what GitHub sends, and some of its shapes
are more than the code generator can express.  An unpatched schema gives a build
error, or a decode failure when the server runs.

Only patch a part of the schema that Terrateam uses.  Many other parts hold the
same defects, but they never cause a failure, because nothing calls them.

## The patches

Apply each one after you update the schema.  Then compare
`api.github.com.json` with `api.github.com.json.orig` and make sure that the
patches below are the only difference.

| # | Where | The patch | Why |
|---|---|---|---|
| 1 | `components/schemas/auto-merge` | Delete the `required` list. | GitHub does not always send `enabled_by`, `merge_method`, `commit_title` and `commit_message`.  A required field becomes a non-optional record field, thus the decode fails. |
| 2 | `components/schemas/commit/properties/author` | Change `oneOf` to `anyOf`. | `Json_schema.one_of` gives an error if more than one schema matches.  The generator makes records that ignore unknown keys, thus `empty-object` matches whenever `simple-user` matches. |
| 3 | `components/schemas/commit/properties/committer` | Change `oneOf` to `anyOf`. | The same cause as patch 2. |
| 4 | `components/schemas/diff-entry` | Remove `blob_url`, `raw_url` and `sha` from the `required` list. | GitHub does not always send a `sha` for a file in a diff. |
| 5 | `components/schemas/pull-request-merge-async-result/properties/details` | Replace the `oneOf` with one object whose fields are all optional: `message`, `uuid`, `merge_method`, `merge_action`, `expected_head_sha` and `sha`.  Keep `merge_method` and `merge_action` as plain strings, not enums. | The `oneOf` holds three objects whose `required` lists nest, thus every branch matches and `Json_schema.one_of` gives an error.  Plain strings stop a decode failure if GitHub adds a value later. |
| 6 | `paths` &rarr; `/repos/{owner}/{repo}/contents/{path}` &rarr; `get` | Delete the `requestBody`. | A GET must not have a request body, and this one holds no `schema`, only examples that belong to the response.  The code generator stops with `ERROR: Openapi_conv.Media_type.t.schema` and writes no output. |
| 7 | `paths` &rarr; `/installation/repositories` &rarr; `get` &rarr; the `200` response &rarr; `repositories` &rarr; `items` | Replace the `allOf` with `{ "$ref": "#/components/schemas/repository" }`. | The `allOf` adds one field, `custom_properties`, that Terrateam does not read.  The generator merges an `allOf` into a new inline type, thus the result of `Terrat_github.get_installation_repos` stops being `Githubc2_components.Repository.t` and a generated inline type leaks into the interface of `terrat_github`. |
| 8 | `components/schemas/pull-request-stack/properties/base/properties/sha` | Add `"nullable": true`. | GitHub sends `sha` with the value `null` when the stack has no base SHA.  The schema makes `sha` a required, non-nullable string, thus the decode of every pull request in a stack fails with `Githubc2_components_pull_request_stack.Primary.Base.Primary.t.sha`.  `nullable` makes the field an option and keeps the key required, which is what GitHub sends. |

Patches that we no longer need, and why:

- An empty `200` response on the workflow dispatch endpoint.  GitHub's own
  description already gives both `200` and `204`.
- A string `"true"` default for `make_latest` on the release update endpoint.
  GitHub's own description already gives a string.

Both defects came from the `@octokit/openapi` mirror.

## After you patch

```
cd code && make generate-api-types
dune build code/src/githubc2      # the whole library must compile
```

`dune build @code/stategraph` does not compile every module of `githubc2`, thus
it can pass while the library holds an error.
