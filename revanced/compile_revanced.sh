#!/bin/bash

VMG_VERSION="0.2.24.220220"

patches_file=./revanced_patches.md

included_start="$(grep -n -m1 'INCLUDED PATCHES' "$patches_file" | cut -d':' -f1)"
excluded_start="$(grep -n -m1 'EXCLUDED PATCHES' "$patches_file" | cut -d':' -f1)"

included_patches="$(tail -n +$included_start $patches_file | head -n "$(( excluded_start - included_start ))" | grep '^[^#[:blank:]]')"
excluded_patches="$(tail -n +$excluded_start $patches_file | grep '^[^#[:blank:]]')"

echo "Declaring variables"
declare -a patches
declare -A artifacts

artifacts["revanced-cli.jar"]="revanced/revanced-cli revanced-cli .jar"
artifacts["revanced-integrations.apk"]="revanced/revanced-integrations app-release-unsigned .apk"
artifacts["revanced-patches.jar"]="revanced/revanced-patches revanced-patches .jar"
artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"

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

echo "Fetching microG"
chmod +x apkeep
if [ ! -f "vanced-microg.apk" ]
then
    echo "Downloading Vanced microG"
    ./apkeep -a com.mgoogle.android.gms@${VMG_VERSION} .
    mv com.mgoogle.android.gms@${VMG_VERSION}.apk vanced-microg.apk
fi

[[ ! -z "$included_patches" ]] && populate_patches "-i" "$included_patches"
[[ ! -z "$excluded_patches" ]] && populate_patches "-e" "$excluded_patches"

echo "Preparing"
mkdir -p output

echo "Compiling ReVanced"
if [ -f "com.google.android.youtube.apk" ]
then
    echo "Compiling package"
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar \
                               ${patches[@]} \
                               -a com.google.android.youtube.apk -o output/revanced.apk
else
    echo "Cannot find YouTube base package, skip compiling"
fi

echo "Compiling ReVanced Music"
if [ -f "com.google.android.apps.youtube.music.apk" ]
then
    echo "Compiling package"
    java -jar revanced-cli.jar -b revanced-patches.jar \
                               ${patches[@]} \
                               -a com.google.android.apps.youtube.music.apk -o output/revanced-music.apk
else
    echo "Cannot find YouTube Music base package, skip compiling"
fi

echo "Done compiling"
