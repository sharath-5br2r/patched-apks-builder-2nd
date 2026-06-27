#!/bin/bash
source ./fiorenmas-utils.sh
echo -e '{' > build.json
amazon-india(){
	get_apk "in.amazon.mShop.android.shopping" "amazon-india" "bundle"
	java -jar APKEditor.jar m -i ./download/amazon-india.apkm -o amazon-india.apk
    version=$(java -jar ./APKEditor.jar info -i ./download/amazon-india.apk -version-name  -t json | jq -r '.[].VersionName')
	sign "./amazon-india.apk" ./build/amazon-india-$version.apk
    rm -f ./build/*.idsig
    echo -e "Signed amazon-india-$version.apk" >> build.md
    echo -e "\"amazon-india\": { \"exts\": [\"apk\"], \"name\": \"amazon-india\",\"arch\": \"all\",\"patch\": \"none\", \"version\": \"$version\"}," >> build.json
    unset version
}
amazon-alexa(){
	get_apk "com.amazon.dee.app" "amazon-alexa" "bundle" "universal"
	java -jar APKEditor.jar m -i ./download/amazon-alexa.apkm -o amazon-alexa.apk
    version=$(java -jar ./APKEditor.jar info -i ./download/amazon-alexa.apk -version-name  -t json | jq -r '.[].VersionName')
	sign "./amazon-alexa.apk" ./build/amazon-alexa-$version.apk
    rm -f ./build/*.idsig
    echo -e "Signed amazon-alexa-$version.apk" >> build.md
    echo -e "\"amazon-alexa\": { \"exts\": [\"apk\"], \"name\": \"amazon-alexa\",\"arch\": \"all\",\"patch\": \"none\", \"version\": \"$version\"}," >> build.json
    unset version
}
revenge-discord() {
	# Patch Revenge:
	dl_gh "NPatch" "7723mod" "latest" "npatch.jar" "jar"
	dl_gh "revenge-xposed" "revenge-mod" "latest" "revenge.apk" "app-release.apk"
	get_apk "com.discord" "discord" "bundle"
    version=$(java -jar ./APKEditor.jar info -i ./download/discord.apk -version-name  -t json | jq -r '.[].VersionName')
	java -cp "bcprov.jar:npatch.jar" -Djava.security.properties=bc.security top.nkbe.npatch.patch.NPatch ./download/discord.apk -k ks.keystore  $KEYSTORE_PASS $KEYSTORE_ALIAS $KEYSTORE_PASS -m "revenge.apk" -o ./build/
    mv ./build/discord-*-npatched.apk "./build/discord-revenge-$version.apk"
    echo -e "Patched discord-$version.apk with revenge-xposed" >> build.md
    echo -e "\"discord-revenge\": { \"exts\": [\"apk\"], \"name\": \"discord-revenge\",\"arch\": \"all\",\"patch\": \"revenge-mod/revenge-xposed\", \"version\": \"$version\"}," >> build.json
    unset version
}
dolphin-sdk29() {
    _fs_get https://dolphin-emu.org/download/
    DOLPHIN_APK_URL=$(echo $html | grep -Eo 'https://dl\.dolphin-emu\.org/builds/[a-z0-9/]+/dolphin-master-[0-9]+-[0-9]+\.apk' | awk -F'[-/.]' '{v=$(NF-2); b=$(NF-1);if (v>V || (v==V && b>B)) {V=v; B=b; U=$0}} END{print U}')
    DOLPHIN_NAME=$(basename "$DOLPHIN_APK_URL" .apk)
    DOLPHIN_VER=${DOLPHIN_NAME#*-}
    curl -L "$DOLPHIN_APK_URL" -H "Cookie: $FS_COOKIES" -H "User-Agent: $user_agent"  -o dolphin-orig.apk
    java -jar APKEditor.jar d -i dolphin-orig.apk -o dolphin-src -t xml -dex
    sed -i 's/android:targetSdkVersion="[^"]*"/android:targetSdkVersion="29"/g' dolphin-src/AndroidManifest.xml
    java -jar APKEditor.jar b -i dolphin-src -o dolphin-patched.apk
    sign dolphin-patched.apk ./build/dolphin-sdk29-$DOLPHIN_VER.apk
    echo -e "Patched Dolphin $DOLPHIN_VER with SDK 29" >> build.md
    echo -e "\"dolphin-sdk29\": { \"exts\": [\"apk\"], \"name\": \"dolphin-sdk29\",\"arch\": \"all\",\"patch\": \"sdk29\", \"version\": \"$DOLPHIN_VER\"}," >> build.json
    rm -f ./build/*.idsig
    }

eden-pubg() {
    export EDEN_ID=$(gh run list -R Eden-CI/Workflow -w nightly.yml --status success --limit 1 --json databaseId -q ".[0].databaseId")
    date1=$(gh run list -R Eden-CI/Workflow -w nightly.yml --status success --limit 1 --json updatedAt  -q ".[0].updatedAt")
    export EDEN_NAME=$(gh run view $EDEN_ID -R Eden-CI/Workflow | grep standard.apk | cut -d'-' -f3 )
    gh api "/repos/Eden-CI/Workflow/actions/artifacts/$(gh api repos/Eden-CI/Workflow/actions/runs/$EDEN_ID/artifacts --jq '.artifacts[] | select(.name| contains("standard.apk")) | .id')/zip" > eden-orig.apk  
    java -jar APKEditor.jar d -i eden-orig.apk -o eden-src -t xml -dex
    sed -i 's/dev\.eden\.eden_emulator\.nightly/com.tencent.ig/g' eden-src/AndroidManifest.xml
    java -jar APKEditor.jar b -i eden-src -o eden-patched.apk
    sign eden-patched.apk ./build/eden-pubg-$date1-$EDEN_NAME.apk
    rm -f ./build/*.idsig
    echo -e "Patched  Eden $EDEN_NAME with com.tencent.ig package name" >> build.md
    echo -e "\"eden-pubg\": { \"exts\": [\"apk\"], \"name\": \"eden-pubg\",\"arch\": \"arm64-v8a\",\"patch\": \"pubg\", \"version\": \"$EDEN_NAME\"}," >> build.json

}

winlator-pubgvn() {
	dl_gh "Winlator-Ludashi" "StevenMXZ" "latest" "winlator-orig.apk" "build.apk"
    java -jar APKEditor.jar d -i winlator-orig.apk -o winlator-src -t xml -dex
    sed -i -e 's/package="com\.tencent\.ig"/package="com.vng.pubgmobile"/' -e 's/com\.tencent\.ig\.tileprovider/com.vng.pubgmobile.tileprovider/' -e 's/com\.tencent\.ig\.core\.WinlatorFilesProvider/com.vng.pubgmobile.core.WinlatorFilesProvider/' -e 's/com\.tencent\.ig\.androidx-startup/com.vng.pubgmobile.androidx-startup/' winlator-src/AndroidManifest.xml
    java -jar APKEditor.jar b -i winlator-src -o winlator-patched.apk
    sign winlator-patched.apk ./build/winlator-pubgvn-$tag.apk
    rm -f ./build/*.idsig
    echo -e "Patched Winlator-Ludashi with com.vng.pubgmobile package name" >> build.md
    echo -e "\"winlator-pubgvn\": { \"exts\": [\"apk\"], \"name\": \"winlator-pubgvn\",\"arch\": \"arm64-v8a\",\"patch\": \"pubgvn\", \"version\": \"$tag\"}" >> build.json
}

amazon-alexa
amazon-india
revenge-discord
dolphin-sdk29
eden-pubg
winlator-pubgvn

echo -e '}' >> build.json