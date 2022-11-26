#!/bin/bash

echo "Declaring variable(s)"
declare -A apks

apks["tv.twitch.android.app.apk"]=dl_twitch

WGET_HEADER="User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0"

req()
{ wget -nv -O "$2" --header="$WGET_HEADER" "$1"; }

get_apk_vers()
{ req "$1" - | sed -n 's;.*Version:</span><span class="infoSlide-value">\(.*\) </span>.*;\1;p'; }

get_largest_ver()
{
    local max=0
    while read -r v || [ -n "$v" ]
    do
        if [[ ${v//[!0-9]/} -gt ${max//[!0-9]/} ]]
	then max=$v
	fi
    done
    if [[ $max = 0 ]]
    then echo ""
    else echo "$max"
    fi
}

dl_apk()
{
    local url=$1 regexp=$2 output=$3
    url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n "s/href=\"/@/g; s;.*${regexp}.*;\1;p")"
    echo "$url"
    url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
    url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
    req "$url" "$output"
}

dl_twitch()
{
    echo "Downloading Twitch"
    local last_ver
    last_ver="$version"
    last_ver="${last_ver:-$(get_apk_vers "https://www.apkmirror.com/uploads/?appcategory=twitch" | get_largest_ver)}"

    echo "Selected version: ${last_ver}"
    local base_apk="tv.twitch.android.app.apk"
    if [ ! -f "$base_apk" ]
    then
        declare -r dl_url=$(dl_apk "https://www.apkmirror.com/apk/twitch-interactive-inc/twitch/twitch-${last_ver//./-}-release/" \
                "APK</span>[^@]*@\([^#]*\)" \
                "$base_apk")
        echo "Downloaded Twitch v${last_ver} from [APKMirror]($dl_url)"
    fi
}

for apk in "${!apks[@]}"
do
    if [ ! -f $apk ]
    then
        echo "Downloading $apk"
        version=$(jq -r ".\"$apk\"" <dl_twitch-version.json)
        ${apks[$apk]}
    fi
done
