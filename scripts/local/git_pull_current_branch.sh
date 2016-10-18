#!/usr/bin/env bash
git pull --rebase origin "$(git branch | grep -E '^\* ' | sed 's/^\* //g')"
