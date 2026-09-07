#!/usr/bin/env bash
# Fail when a migration SQL file is not registered in its package's migration
# module, or when a registration names a file that no longer exists. A file
# without a registration never runs in production, and nothing else fails when
# it is missing; the missing-file direction additionally fails the ppx_blob
# build, and is reported here with a clearer message.
#
# Usage (run from a package directory, as the dune rules in code/src/*/dune do):
#
#   check_migrations_registered.sh <module.ml> <migrations_dir>
#
# Example:
#
#   check_migrations_registered.sh terrat_migrations.ml migrations
set -u

module=${1:?usage: check_migrations_registered.sh <module.ml> <migrations_dir>}
migrations_dir=${2:?usage: check_migrations_registered.sh <module.ml> <migrations_dir>}

die() {
  echo "ERROR: $1" >&2
  if [ $# -gt 1 ]; then
    echo "$2" >&2
  fi
  exit 1
}

[ -f "$module" ] || die "module $module not found"
[ -d "$migrations_dir" ] || die "migrations dir $migrations_dir not found"

files=$(ls "$migrations_dir"/*.sql 2>/dev/null | xargs -n1 basename | sort)
# Registrations may be written "migrations/x.sql" or "./migrations/x.sql";
# normalize both. Compare file names, not registration names: the registration
# name and the file name are allowed to differ ("initial-tables" vs
# "2021-12-03-initial-tables.sql").
registered=$(grep -hoE '[./]*migrations/[0-9][0-9a-zA-Z_.-]*[.]sql' "$module" \
  | sed -e 's|^[.]/||' -e 's|migrations/||' | sort -u)

unregistered=$(comm -23 <(echo "$files") <(echo "$registered"))
if [ -n "$unregistered" ]; then
  die "migration files present in $migrations_dir but not registered in $module - add a (\"name\", run_sql [%blob ...]) entry to the module's migrations list" \
    "$unregistered"
fi

missing=$(comm -13 <(echo "$files") <(echo "$registered"))
if [ -n "$missing" ]; then
  die "migrations registered in $module but missing from $migrations_dir" "$missing"
fi
