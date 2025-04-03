#!/bin/bash
set -euo pipefail

uv tool run mkslides \
    serve \
    --config-file src/mkslides_config.yml \
    --strict \
    --open \
    src/slides.md

#xdg-open "file://$(pwd)/public/index.html"
