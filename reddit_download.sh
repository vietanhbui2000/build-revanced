#!/bin/bash

declare -A apks

apks["com.reddit.frontpage.apk"]="https://reddit-official-app.en.uptodown.com/android/apps/179119/versions"

get_apk_download_url()
{
    version_url=$(curl -s $1 | jq ".data[] | select(.version | contains(\"$2\")) | .versionURL")
    dl_url=$(curl -s ${version_url:1:-1} | grep -oE "https:\/\/dw\.uptodown\.com.+\/")
    echo $dl_url
}

for apk in "${!apks[@]}"
do
    if [ ! -f $apk ]
    then
        echo "Downloading $apk"
        version=$(cat reddit_versions.json | jq -r ".\"$apk\"")
        curl -sLo $apk $(get_apk_download_url ${apks[$apk]} $version)
    fi
done
