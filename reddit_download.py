import requests
import re
import subprocess

REDDIT_URL = "https://reddit-official-app.en.uptodown.com/android/download"

def download_apk(url, filename):
    response = requests.get(url)
    dl_url = re.findall(r'(?<=href=")https:\/\/dw.uptodown.com.*?(?=")', response.content.decode("utf-8"))[0]
    subprocess.run(["wget", dl_url, "-O", filename])

print("Downloading Reddit")
download_apk(REDDIT_URL, "com.reddit.frontpage.apk")
