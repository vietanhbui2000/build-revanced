#!/bin/bash

TWITTER_VERSION="9.53.0-release.0"

echo "Declaring variables and their attributes"
declare -A artifacts

artifacts["revanced-cli.jar"]="revanced/revanced-cli revanced-cli .jar"
artifacts["revanced-patches.jar"]="revanced/revanced-patches revanced-patches .jar"
artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"

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
    rm -f revanced-cli.jar revanced-patches.jar
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

echo "Fetching Twitter"
chmod +x apkeep
if [ ! -f "com.twitter.android.apk" ]
then
    echo "Downloading Twitter"
    ./apkeep -a com.twitter.android@${TWITTER_VERSION} .
    mv com.twitter.android@${TWITTER_VERSION}.apk com.twitter.android.apk
fi

echo "Preparing"
mkdir -p retwitter

echo "Compiling ReTwitter"
if [ -f "com.twitter.android.apk" ]
then
    echo "Compiling package"
    java -jar revanced-cli.jar -b revanced-patches.jar -r \
                               -i timeline-ads \
                               -a com.twitter.android.apk -o retwitter/retwitter.apk
else
    echo "Cannot find Twitter base package, skip compiling"
fi

echo "Done compiling"
