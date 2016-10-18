#!/usr/bin/env bash
URI_STRING='educationhistory.lib.unb.ca'
SLUG_STRING='eduhist'
UUID_STRING='3084'
DRUPAL_UUID_STRING='f1de2d88-eedf-4115-af2b-d55cf0a30215'

rm -rf .git

find . -type f -print0 | xargs -0 sed -i.bak "s/educationhistory.lib.unb.ca/$URI_STRING/g"
find . -type f -print0 | xargs -0 sed -i.bak "s/eduhist/$SLUG_STRING/g"
find . -type f -print0 | xargs -0 sed -i.bak "s/f1de2d88-eedf-4115-af2b-d55cf0a30215/$DRUPAL_UUID_STRING/g"
find . -type f -print0 | xargs -0 sed -i.bak "s/3084/$UUID_STRING/g"
find . -name "*.bak" -type f -delete

rm README.md
mv README.repo.md README.md

git init
git add .
git add -f ./config-yml/.gitkeep
git add -f ./custom/modules/.gitkeep
git add -f ./custom/themes/.gitkeep

git commit -m 'Initial commit from template repo.'
