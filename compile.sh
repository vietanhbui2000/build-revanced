#!/bin/bash

patches_file=./patches.md

revanced_included_start="$(grep -n -m1 'ReVanced included patches' "$patches_file" | cut -d':' -f1)"
revanced_excluded_start="$(grep -n -m1 'ReVanced excluded patches' "$patches_file" | cut -d':' -f1)"
retwitch_included_start="$(grep -n -m1 'ReTwitch included patches' "$patches_file" | cut -d':' -f1)"
retwitch_excluded_start="$(grep -n -m1 'ReTwitch excluded patches' "$patches_file" | cut -d':' -f1)"
retiktok_included_start="$(grep -n -m1 'ReTikTok included patches' "$patches_file" | cut -d':' -f1)"
retiktok_excluded_start="$(grep -n -m1 'ReTikTok excluded patches' "$patches_file" | cut -d':' -f1)"
retwitter_included_start="$(grep -n -m1 'ReTwitter included patches' "$patches_file" | cut -d':' -f1)"
retwitter_excluded_start="$(grep -n -m1 'ReTwitter excluded patches' "$patches_file" | cut -d':' -f1)"
rereddit_included_start="$(grep -n -m1 'ReReddit included patches' "$patches_file" | cut -d':' -f1)"
rereddit_excluded_start="$(grep -n -m1 'ReReddit excluded patches' "$patches_file" | cut -d':' -f1)"
reinstagram_included_start="$(grep -n -m1 'ReInstagram included patches' "$patches_file" | cut -d':' -f1)"
reinstagram_excluded_start="$(grep -n -m1 'ReInstagram excluded patches' "$patches_file" | cut -d':' -f1)"

revanced_included_patches="$(tail -n +$revanced_included_start $patches_file | head -n "$(( revanced_excluded_start - revanced_included_start ))" | grep '^[^#[:blank:]]')"
revanced_excluded_patches="$(tail -n +$revanced_excluded_start $patches_file | grep '^[^#[:blank:]]')"
retwitch_included_patches="$(tail -n +$retwitch_included_start $patches_file | head -n "$(( retwitch_excluded_start - retwitch_included_start ))" | grep '^[^#[:blank:]]')"
retwitch_excluded_patches="$(tail -n +$retwitch_excluded_start $patches_file | grep '^[^#[:blank:]]')"
retiktok_included_patches="$(tail -n +$retiktok_included_start $patches_file | head -n "$(( retiktok_excluded_start - retiktok_included_start ))" | grep '^[^#[:blank:]]')"
retiktok_excluded_patches="$(tail -n +$retiktok_excluded_start $patches_file | grep '^[^#[:blank:]]')"
retwitter_included_patches="$(tail -n +$retwitter_included_start $patches_file | head -n "$(( retwitter_excluded_start - retwitter_included_start ))" | grep '^[^#[:blank:]]')"
retwitter_excluded_patches="$(tail -n +$retwitter_excluded_start $patches_file | grep '^[^#[:blank:]]')"
rereddit_included_patches="$(tail -n +$rereddit_included_start $patches_file | head -n "$(( rereddit_excluded_start - rereddit_included_start ))" | grep '^[^#[:blank:]]')"
rereddit_excluded_patches="$(tail -n +$rereddit_excluded_start $patches_file | grep '^[^#[:blank:]]')"
reinstagram_included_patches="$(tail -n +$reinstagram_included_start $patches_file | head -n "$(( reinstagram_excluded_start - reinstagram_included_start ))" | grep '^[^#[:blank:]]')"
reinstagram_excluded_patches="$(tail -n +$reinstagram_excluded_start $patches_file | grep '^[^#[:blank:]]')"

echo "Declaring variable(s)"
declare -A artifacts
declare -a revanced_patches
declare -a retwitch_patches
declare -a retiktok_patches
declare -a retwitter_patches
declare -a rereddit_patches
declare -a reinstagram_patches

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

populate_retwitter-patches()
{
    while read -r retwitter__patches
    do
        retwitter_patches+=("$1 $retwitter__patches")
    done <<< "$2"
}

populate_rereddit-patches()
{
    while read -r rereddit__patches
    do
        rereddit_patches+=("$1 $rereddit__patches")
    done <<< "$2"
}

populate_reinstagram-patches()
{
    while read -r reinstagram__patches
    do
        reinstagram_patches+=("$1 $reinstagram__patches")
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
[[ ! -z "$retwitter_included_patches" ]] && populate_retwitter-patches "-i" "$retwitter_included_patches"
[[ ! -z "$retwitter_excluded_patches" ]] && populate_retwitter-patches "-e" "$retwitter_excluded_patches"
[[ ! -z "$rereddit_included_patches" ]] && populate_rereddit-patches "-i" "$rereddit_included_patches"
[[ ! -z "$rereddit_excluded_patches" ]] && populate_rereddit-patches "-e" "$rereddit_excluded_patches"
[[ ! -z "$reinstagram_included_patches" ]] && populate_reinstagram-patches "-i" "$reinstagram_included_patches"
[[ ! -z "$reinstagram_excluded_patches" ]] && populate_reinstagram-patches "-e" "$reinstagram_excluded_patches"

echo "Preparing"
mkdir -p output
mv com.mgoogle.android.gms.apk vanced-microg.apk

function build_revanced()
{
echo "Compiling ReVanced"
if [ -f "com.google.android.youtube.apk" ]
then
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar --keystore=ks.keystore \
                               ${revanced_patches[@]} \
                               -a com.google.android.youtube.apk -o output/revanced.apk
else
    echo "Cannot find YouTube base package, skip compiling"
fi
}

function build_revanced-music()
{
echo "Compiling ReVanced Music"
if [ -f "com.google.android.apps.youtube.music.apk" ]
then
    java -jar revanced-cli.jar -b revanced-patches.jar --keystore=ks.keystore \
                               ${revanced_patches[@]} \
                               -a com.google.android.apps.youtube.music.apk -o output/revanced-music.apk
else
    echo "Cannot find YouTube Music base package, skip compiling"
fi
}

function build_retwitch()
{
echo "Compiling ReTwitch"
if [ -f "tv.twitch.android.app.apk" ]
then
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar --keystore=ks.keystore \
                               ${retwitch_patches[@]} \
                               -a tv.twitch.android.app.apk -o output/retwitch.apk
else
    echo "Cannot find Twitch base package, skip compiling"
fi
}

function build_retiktok()
{
echo "Compiling ReTikTok"
if [ -f "com.ss.android.ugc.trill.apk" ]
then
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar --keystore=ks.keystore \
                               ${retiktok_patches[@]} \
                               -a com.ss.android.ugc.trill.apk -o output/retiktok.apk
else
    echo "Cannot find TikTok base package, skip compiling"
fi
}

function build_retwitter()
{
echo "Compiling ReTwitter"
if [ -f "com.twitter.android.apk" ]
then
    java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar --keystore=ks.keystore \
                               ${retwitter_patches[@]} \
                               -a com.twitter.android.apk -o output/retwitter.apk
else
    echo "Cannot find Twitter base package, skip compiling"
fi
}

function build_rereddit()
{
echo "Compiling ReReddit"
if [ -f "com.reddit.frontpage.apk" ]
then
    java -jar revanced-cli.jar -b revanced-patches.jar --keystore=ks.keystore \
                               ${rereddit_patches[@]} \
                               -a com.reddit.frontpage.apk -o output/rereddit.apk
else
    echo "Cannot find Reddit base package, skip compiling"
fi
}

function build_reinstagram()
{
echo "Compiling ReInstagram"
if [ -f "com.instagram.android.apk" ]
then
    java -jar revanced-cli.jar -b revanced-patches.jar --keystore=ks.keystore \
                               ${reinstagram_patches[@]} \
                               -a com.instagram.android.apk -o output/reinstagram.apk
else
    echo "Cannot find Instagram base package, skip compiling"
fi
}

source configs.md

if [ "$BUILD_REVANCED" = "true" ];
then
	build_revanced
else
	printf "\nSkipping ReVanced"
fi

if [ "$BUILD_REVANCED_MUSIC" = "true" ];
then
	build_revanced-music
else
	printf "\nSkipping ReVanced Music"
fi

if [ "$BUILD_RETWITCH" = "true" ];
then
	build_retwitch
else
	printf "\nSkipping ReTwitch"
fi

if [ "$BUILD_RETIKTOK" = "true" ];
then
	build_retiktok
else
	printf "\nSkipping ReTikTok"
fi

if [ "$BUILD_RETWITTER" = "true" ];
then
	build_retwitter
else
	printf "\nSkipping ReTwitter"
fi

if [ "$BUILD_REREDDIT" = "true" ];
then
	build_rereddit
else
	printf "\nSkipping ReReddit"
fi

if [ "$BUILD_REINSTAGRAM" = "true" ];
then
	build_reinstagram
else
	printf "\nSkipping ReInstagram"
fi

echo "Done compiling"
