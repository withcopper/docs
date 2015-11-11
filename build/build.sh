#!/bin/sh

# SEND A SLACK NOTIFICATION
echo "Sending Slack commit  notification"
COMMIT_MSG_RAW=`git log --format=%B --no-merges -n 1`
COMMIT_MSG=${COMMIT_MSG_RAW//[\'\"]/}
curl -X POST --data-urlencode 'payload={"channel": "#ops", "username": "docs_travis", "text": "New Documention: the gift that keeps on giving\n:memo: '"$COMMIT_MSG"'\n\n'"$GITHUB_DOCS_URL"'", "icon_emoji": ":gift:"}' "$SLACK_WEBHOOK_URL"
echo "$COMMIT_MSG"
