#!/usr/bin/env bash
set -euo pipefail

found_package=0

for package_json in packages/*/package.json; do
  if [ ! -f "$package_json" ]; then
    continue
  fi

  found_package=1
  package_dir="${package_json%/package.json}"

  if ! node -e 'const fs = require("fs"); const pkg = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); process.exit(pkg.scripts && pkg.scripts.lint ? 0 : 1);' "$package_json"; then
    echo "Missing npm lint script in $package_json"
    exit 1
  fi

  echo "Running npm run lint in $package_dir"
  npm run lint --workspace "$package_dir"
done

if [ "$found_package" -eq 0 ]; then
  echo "No package.json files found under packages/* yet; skipping package lint until packages land."
fi
