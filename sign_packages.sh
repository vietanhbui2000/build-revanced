#!/bin/bash

echo "Declaring variables and their attributes"
declare -A artifacts

artifacts["uber-apk-signer.jar"]="patrickfav/uber-apk-signer uber-apk-signer .jar"

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
    rm -f uber-apk-signer.jar
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

echo "Preparing"
if [ -d "revanced" ]
    then
    mkdir -p revanced/release
fi
if [ -d "retwitter" ]
    then
    mkdir -p retwitter/release
fi
if [ -d "rereddit" ]
    then
    mkdir -p rereddit/release
fi

echo "Signing packages"
if [ -d "revanced" ]
then
    echo "Signing ReVanced"
    java -jar uber-apk-signer.jar --allowResign --apks revanced --out revanced/release
fi

echo "Done signing"
