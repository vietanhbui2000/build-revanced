#!/bin/bash

VMG_VERSION="0.2.24.220220"

echo "Declaring variables and their attributes"
revanced_patches=./revanced_patches.md
declare -a excluded_patches
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
if [ ! -f "vanced-microG.apk" ]
then
    echo "Downloading Vanced microG"
    ./apkeep -a com.mgoogle.android.gms@${VMG_VERSION} .
    mv com.mgoogle.android.gms@$VMG_VERSION.apk vanced-microG.apk
fi

echo "Preparing"
mkdir -p build
if grep -q '^[^#]' $revanced_patches
then
    while read -r patches
    do
        excluded_patches+=("-e $patches")
    done < <(grep '^[^#]' $revanced_patches)
fi

echo "Compiling YouTube"
if [ -f "com.google.android.youtube.apk" ]
then
    echo "Compiling root package"
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar --mount \
                               -e microg-support ${excluded_patches[@]} \
                               -a com.google.android.youtube.apk -o build/revanced-root.apk
    echo "Compiling non-root package"
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar \
                               ${excluded_patches[@]} \
                               -a com.google.android.youtube.apk -o build/revanced-nonroot.apk
else
    echo "Cannot find YouTube base package, skip compiling"
fi

echo "Compiling YouTube Music"
if [ -f "com.google.android.apps.youtube.music.apk" ]
then
    echo "Compiling root package"
    java -jar revanced-cli.jar -b revanced-patches.jar --mount \
                               -e microg-support ${excluded_patches[@]} \
                               -a com.google.android.apps.youtube.music.apk -o build/revanced-music-root.apk
    echo "Compiling non-root package"
    java -jar revanced-cli.jar -b revanced-patches.jar \
                               ${excluded_patches[@]} \
                               -a com.google.android.apps.youtube.music.apk -o build/revanced-music-nonroot.apk
else
    echo "Cannot find YouTube Music base package, skip compiling"
fi

echo "Done compiling"
