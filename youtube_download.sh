#!/bin/bash

declare -A apks

apks["com.google.android.youtube.apk"]="https://youtube.en.uptodown.com/android/apps/16906/versions"
apks["com.google.android.apps.youtube.music.apk"]="https://youtube-music.en.uptodown.com/android/apps/146929/versions"

get_apk_download_url()
{
    version_url=$(curl -s "$1" | jq ".data[] | select(.version | contains(\"$2\")) | .versionURL")
    dl_url=$(curl -s "${version_url:1:-1}" | grep -oE "https:\/\/dw\.uptodown\.com.+\/")
    echo "$dl_url"
}

for apk in "${!apks[@]}"
do
    if [ ! -f $apk ]
    then
        echo "Downloading $apk"
        version=$(jq -r ".\"$apk\"" <youtube_versions.json)
        curl -sLo $apk "$(get_apk_download_url ${apks[$apk]} "$version")"
    fi
done
