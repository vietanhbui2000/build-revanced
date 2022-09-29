#!/bin/bash

echo "Declaring variables"
declare -A artifacts

artifacts["revanced-cli.jar"]="revanced/revanced-cli revanced-cli .jar"
artifacts["revanced-integrations.apk"]="revanced/revanced-integrations app-release-unsigned .apk"
artifacts["revanced-patches.jar"]="revanced/revanced-patches revanced-patches .jar"

get_artifact_download_url()
{
    local api_url result
    api_url="https://api.github.com/repos/$1/releases/latest"
    result=$(curl -s $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo "${result:1:-1}"
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

revanced-patches="-i tiktok-ads -i tiktok-download -i tiktok-feed-filter -i tiktok-force-login -i tiktok-seekbar -i tiktok-settings"

echo "Preparing"
mkdir -p output

echo "Compiling ReTikTok"
if [ -f "com.zhiliaoapp.musically.apk" ]
then
    echo "Compiling package"
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar -r \
                               $revanced-patches \
                               -a com.zhiliaoapp.musically.apk -o output/retiktok.apk
else
    echo "Cannot find TikTok base package, skip compiling"
fi

echo "Done compiling"
