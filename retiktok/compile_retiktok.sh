#!/bin/bash

patches_file=./retiktok-patches.md

included_start="$(grep -n -m1 'INCLUDED PATCHES' "$patches_file" | cut -d':' -f1)"
excluded_start="$(grep -n -m1 'EXCLUDED PATCHES' "$patches_file" | cut -d':' -f1)"

included_patches="$(tail -n +$included_start $patches_file | head -n "$(( excluded_start - included_start ))" | grep '^[^#[:blank:]]')"
excluded_patches="$(tail -n +$excluded_start $patches_file | grep '^[^#[:blank:]]')"

echo "Declaring variable(s)"
declare -A artifacts
declare -a patches

artifacts["revanced-cli.jar"]="revanced/revanced-cli revanced-cli .jar"
artifacts["revanced-integrations.apk"]="revanced/revanced-integrations revanced-integrations .apk"
artifacts["revanced-patches.jar"]="revanced/revanced-patches revanced-patches .jar"

get_artifact_download_url()
{
    local api_url result
    api_url="https://api.github.com/repos/$1/releases/latest"
    result=$(curl -s $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo "${result:1:-1}"
}

populate_patches()
{
    while read -r revanced_patches
    do
        patches+=("$1 $revanced_patches")
    done <<< "$2"
}

echo "Cleaning up"
if [[ "$1" == "clean" ]]
    then
    rm -f revanced-cli.jar revanced-integrations.apk revanced-patches.jar
    exit
fi

echo "Fetching dependencies"
for artifact in "${!artifacts[@]}"
do
    if [ ! -f "$artifact" ]
    then
        echo "Downloading $artifact"
        curl -sLo "$artifact" $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

[[ ! -z "$included_patches" ]] && populate_patches "-i" "$included_patches"
[[ ! -z "$excluded_patches" ]] && populate_patches "-e" "$excluded_patches"

echo "Preparing"
mkdir -p output

echo "Compiling ReTikTok"
if [ -f "com.ss.android.ugc.trill.apk" ]
then
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar \
                               ${patches[@]} \
                               -a com.ss.android.ugc.trill.apk -o output/retiktok.apk
else
    echo "Cannot find TikTok base package, skip compiling"
fi

echo "Done compiling"
