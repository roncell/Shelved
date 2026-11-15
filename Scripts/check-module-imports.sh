#!/bin/bash
# Fails the build when a package module imports one of our modules it may not.
#
# Package.swift declares each target's dependencies, but Xcode doesn't
# enforce them: every package module lands in one build folder, so
# `import SearchFeature` inside DetailFeature compiles anyway. This script
# checks every `import` line against the rules in CLAUDE.md and prints
# errors in "file:line: error:" form, so Xcode shows them on the line.
#
# The table below must match the dependencies in Packages/Package.swift.
# When they match, "only imports what the rules allow" is the same as
# "only imports what the manifest declares", which keeps build order sound.
#
# Run by the ModuleRules target before every app build, or by hand:
#   Scripts/check-module-imports.sh
set -euo pipefail

root="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}/Packages"

features="HomeFeature SearchFeature DetailFeature CreatorFeature SeriesFeature LibraryFeature ReviewFeature StatsFeature SettingsFeature"
ours=" Core DesignSystem Data Networking Persistence Navigation $features "

allowed() {
    case "$1" in
        Core) echo "" ;;
        DesignSystem | Data | Navigation) echo "Core" ;;
        Networking | Persistence) echo "Core Data" ;;
        *Feature) echo "Core DesignSystem Navigation Data" ;;
    esac
}

directory() {
    case "$1" in
        *Feature) echo "$root/Features/$1" ;;
        *) echo "$root/$1" ;;
    esac
}

status=0
for module in $ours; do
    dir="$(directory "$module")"
    if [ ! -d "$dir" ]; then
        echo "error: no sources for module $module at $dir"
        status=1
        continue
    fi
    rules=" $(allowed "$module") "
    # file:line:import text, for every import (plain, @testable, `import struct X.Y`).
    while IFS=: read -r file line text; do
        name="$(echo "$text" | sed -E 's/^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]+((struct|class|enum|protocol|func|var|let|typealias)[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*).*/\4/')"
        if [[ "$ours" == *" $name "* && "$rules" != *" $name "* && "$name" != "$module" ]]; then
            echo "$file:$line: error: $module may not import $name (allowed: $(allowed "$module" | sed 's/^$/nothing of ours/'))"
            status=1
        fi
    done < <(grep -rnE '^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]' --include='*.swift' "$dir" || true)
done

exit $status
