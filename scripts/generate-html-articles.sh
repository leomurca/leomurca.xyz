#!/bin/sh

CONTENT_DIR=./articles/*.md

for entry in $CONTENT_DIR
do
  PAGE_TITLE=$(head -n 1 $entry | sed 's/^# \+//')
  PAGE_DESCRIPTION="A simple article on $PAGE_TITLE"
  FILENAME=$(basename $entry)
  NEW_DIR_PATH="./src/articles/${FILENAME%.*}"
  NEW_FILE_PATH="${NEW_DIR_PATH}/index.html"
  AUTHOR_AND_DATE=$(git log -n 1 --oneline --date-order --date=format:'%B %d, %Y' --pretty="format:%cN - %cd" -- $entry)

  mkdir -p $NEW_DIR_PATH &&
  sed "s/\%PAGE_TITLE\%/$PAGE_TITLE/ ; s/\%PAGE_DESCRIPTION\%/$PAGE_DESCRIPTION/" templates/header.html > $NEW_FILE_PATH &&
  printf '<main>' >> $NEW_FILE_PATH &&
  sed "2i \*By $AUTHOR_AND_DATE\*" $entry | markdown -f fencedcode - >> $NEW_FILE_PATH &&
  printf '</main>' >> $NEW_FILE_PATH &&
  cat templates/footer.html >> $NEW_FILE_PATH
done

