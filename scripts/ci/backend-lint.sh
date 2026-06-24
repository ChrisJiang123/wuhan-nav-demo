#!/usr/bin/env bash
set -euo pipefail

found_backend=0

for package_json in services/*/package.json; do
  if [ ! -f "$package_json" ]; then
    continue
  fi

  found_backend=1
  service_dir="${package_json%/package.json}"

  if ! node -e 'const fs = require("fs"); const pkg = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); process.exit(pkg.scripts && pkg.scripts.lint ? 0 : 1);' "$package_json"; then
    echo "Missing npm lint script in $package_json"
    exit 1
  fi

  echo "Running npm run lint in $service_dir"
  npm run lint --prefix "$service_dir"
done

if [ "$found_backend" -eq 0 ]; then
  echo "No backend package.json files found under services/* yet; skipping backend lint until services land."
fi
