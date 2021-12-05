#!/bin/sh

CONTENT_DIR=./articles/*.md
REMOTE_BASE_URL=https://leomurca.xyz

for entry in $CONTENT_DIR
do
  PAGE_TITLE=$(head -n 1 $entry | sed 's/^# \+//')
  PAGE_DESCRIPTION="A simple article on $PAGE_TITLE"
  FILENAME=$(basename $entry)
  NEW_DIR_PATH="./src/articles/${FILENAME%.*}"
  NEW_FILE_PATH="${NEW_DIR_PATH}/index.html"
  AUTHOR_AND_DATE=$(git log -n 1 --oneline --date-order --date=format:'%B %d, %Y' --pretty="format:%cN - %cd" -- $entry)
  LIST_ITEM=$(git log -n 1 --oneline --date-order --date=format:"%d %b. %Y" --pretty="- <span>%cd</span> [$PAGE_TITLE]($REMOTE_BASE_URL/articles/${FILENAME%.*})" -- $entry)
  ARTICLES_LIST_LINE_NUMBER=$(grep -n "%ARTICLES_LIST%" src/index.html | awk '{print substr($1, 1, length($1)-1);}')

  mkdir -p $NEW_DIR_PATH &&
  sed "s/\%PAGE_TITLE\%/$PAGE_TITLE/ ; s/\%PAGE_DESCRIPTION\%/$PAGE_DESCRIPTION/" templates/header.html > $NEW_FILE_PATH &&
  echo $LIST_ITEM >> list.md &&
  markdown list.md > list.html &&
  sed "$(($ARTICLES_LIST_LINE_NUMBER))rlist.html" src/dev-index.html > src/index.html &&
  printf '<main>' >> $NEW_FILE_PATH &&
  sed "2i \*By $AUTHOR_AND_DATE\*" $entry | markdown -f fencedcode - >> $NEW_FILE_PATH &&
  printf '</main>' >> $NEW_FILE_PATH &&
  cat templates/footer.html >> $NEW_FILE_PATH
done &&

rm list.md list.html
