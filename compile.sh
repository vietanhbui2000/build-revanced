#!/bin/bash

patches_file=./patches.md

revanced_included_start="$(grep -n -m1 'ReVanced included patches' "$patches_file" | cut -d':' -f1)"
revanced_excluded_start="$(grep -n -m1 'ReVanced excluded patches' "$patches_file" | cut -d':' -f1)"
retwitch_included_start="$(grep -n -m1 'ReTwitch included patches' "$patches_file" | cut -d':' -f1)"
retwitch_excluded_start="$(grep -n -m1 'ReTwitch excluded patches' "$patches_file" | cut -d':' -f1)"
retiktok_included_start="$(grep -n -m1 'ReTikTok included patches' "$patches_file" | cut -d':' -f1)"
retiktok_excluded_start="$(grep -n -m1 'ReTikTok excluded patches' "$patches_file" | cut -d':' -f1)"

revanced_included_patches="$(tail -n +$revanced_included_start $patches_file | head -n "$(( revanced_excluded_start - revanced_included_start ))" | grep '^[^#[:blank:]]')"
revanced_excluded_patches="$(tail -n +$revanced_excluded_start $patches_file | grep '^[^#[:blank:]]')"
retwitch_included_patches="$(tail -n +$retwitch_included_start $patches_file | head -n "$(( retwitch_excluded_start - retwitch_included_start ))" | grep '^[^#[:blank:]]')"
retwitch_excluded_patches="$(tail -n +$retwitch_excluded_start $patches_file | grep '^[^#[:blank:]]')"
retiktok_included_patches="$(tail -n +$retiktok_included_start $patches_file | head -n "$(( retiktok_excluded_start - retiktok_included_start ))" | grep '^[^#[:blank:]]')"
retiktok_excluded_patches="$(tail -n +$retiktok_excluded_start $patches_file | grep '^[^#[:blank:]]')"

echo "Declaring variable(s)"
declare -A artifacts
declare -a revanced_patches
declare -a retwitch_patches
declare -a retiktok_patches

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

populate_revanced-patches()
{
    while read -r revanced__patches
    do
        revanced_patches+=("$1 $revanced__patches")
    done <<< "$2"
}

populate_retwitch-patches()
{
    while read -r retwitch__patches
    do
        retwitch_patches+=("$1 $retwitch__patches")
    done <<< "$2"
}

populate_retiktok-patches()
{
    while read -r retiktok__patches
    do
        retiktok_patches+=("$1 $retiktok__patches")
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

[[ ! -z "$revanced_included_patches" ]] && populate_revanced-patches "-i" "$revanced_included_patches"
[[ ! -z "$revanced_excluded_patches" ]] && populate_revanced-patches "-e" "$revanced_excluded_patches"
[[ ! -z "$retwitch_included_patches" ]] && populate_retwitch-patches "-i" "$retwitch_included_patches"
[[ ! -z "$retwitch_excluded_patches" ]] && populate_retwitch-patches "-e" "$retwitch_excluded_patches"
[[ ! -z "$retiktok_included_patches" ]] && populate_retiktok-patches "-i" "$retiktok_included_patches"
[[ ! -z "$retiktok_excluded_patches" ]] && populate_retiktok-patches "-e" "$retiktok_excluded_patches"

echo "Preparing"
mkdir -p output
mv com.mgoogle.android.gms.apk "output/vanced-microg_v$(cat versions.json | grep -oP '(?<="com.mgoogle.android.gms.apk": ")[^"]*').apk"

function build_revanced()
{
echo "Compiling ReVanced"
if [ -f "com.google.android.youtube.apk" ]
then
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar --keystore=keystore.keystore --cn=$CN --password=$PASSWORD \
                               ${revanced_patches[@]} \
                               -a com.google.android.youtube.apk -o "output/revanced_v$(cat versions.json | grep -oP '(?<="com.google.android.youtube.apk": ")[^"]*').apk"
else
    echo "Cannot find YouTube base package, skip compiling"
fi
}

function build_revanced-music()
{
echo "Compiling ReVanced Music"
if [ -f "com.google.android.apps.youtube.music.apk" ]
then
    java -jar revanced-cli.jar -b revanced-patches.jar --keystore=keystore.keystore --cn=$CN --password=$PASSWORD \
                               ${revanced_patches[@]} \
                               -a com.google.android.apps.youtube.music.apk -o "output/revanced-music_v$(cat versions.json | grep -oP '(?<="com.google.android.apps.youtube.music.apk": ")[^"]*').apk"
else
    echo "Cannot find YouTube Music base package, skip compiling"
fi
}

function build_retwitch()
{
echo "Compiling ReTwitch"
if [ -f "tv.twitch.android.app.apk" ]
then
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar --keystore=keystore.keystore --cn=$CN --password=$PASSWORD \
                               ${retwitch_patches[@]} \
                               -a tv.twitch.android.app.apk -o "output/retwitch_v$(cat versions.json | grep -oP '(?<="tv.twitch.android.app.apk": ")[^"]*').apk"
else
    echo "Cannot find Twitch base package, skip compiling"
fi
}

function build_retiktok()
{
echo "Compiling ReTikTok"
if [ -f "com.ss.android.ugc.trill.apk" ]
then
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar --keystore=keystore.keystore --cn=$CN --password=$PASSWORD \
                               ${retiktok_patches[@]} \
                               -a com.ss.android.ugc.trill.apk -o "output/retiktok_v$(cat versions.json | grep -oP '(?<="com.ss.android.ugc.trill.apk": ")[^"]*').apk"
else
    echo "Cannot find TikTok base package, skip compiling"
fi
}

source configs.md

if [ "$BUILD_REVANCED" = "true" ];
then
	build_revanced
else
	echo "Skipping ReVanced"
fi

if [ "$BUILD_REVANCED_MUSIC" = "true" ];
then
	build_revanced-music
else
	echo "Skipping ReVanced Music"
fi

if [ "$BUILD_RETWITCH" = "true" ];
then
	build_retwitch
else
	echo "Skipping ReTwitch"
fi

if [ "$BUILD_RETIKTOK" = "true" ];
then
	build_retiktok
else
	echo "Skipping ReTikTok"
fi

echo "Done compiling"
