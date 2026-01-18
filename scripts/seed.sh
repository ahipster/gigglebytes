#!/bin/bash
# Currently seeding is handled by postgres/init.sql on first run.
# To re-seed, run ./scripts/reset.sh and then ./scripts/setup.sh
echo "Seeding is handled by docker/postgres/init.sql during database initialization."
echo "To re-seed:"
echo "  1. ./scripts/reset.sh (WARNING: Deletes all data)"
echo "  2. ./scripts/setup.sh"
