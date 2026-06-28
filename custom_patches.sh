#!/bin/bash
source ./fiorenmas-utils.sh
echo -e '{' > build.json
amazon-india(){
	get_apk "in.amazon.mShop.android.shopping" "amazon-india" "bundle"
	java -jar ./temp/APKEditor.jar m -i ./download/amazon-india.apkm -o amazon-india.apk
    version=$(java -jar ./temp/APKEditor.jar info -i ./download/amazon-india.apk -version-name  -t json | jq -r '.[].VersionName')
	sign "./amazon-india.apk" ./build/amazon-india-sign-v$version.apk
    rm -f ./build/*.idsig
    echo -e "Signed Amazon India $version" >> build.md
    echo -e "\"amazon-india\": { \"exts\": [\"apk\"], \"name\": \"amazon-india\",\"arch\": \"all\",\"patch\": \"sign\", \"version\": \"$version\"}," >> build.json
    unset version
}
amazon-alexa(){
	get_apk "com.amazon.dee.app" "amazon-alexa" "bundle" "universal"
	java -jar ./temp/APKEditor.jar m -i ./download/amazon-alexa.apkm -o amazon-alexa.apk
    version=$(java -jar ./temp/APKEditor.jar info -i ./download/amazon-alexa.apk -version-name  -t json | jq -r '.[].VersionName')
	sign "./amazon-alexa.apk" ./build/amazon-alexa-sign-v$version.apk
    rm -f ./build/*.idsig
    echo -e "Signed Amazon Alexa $version" >> build.md
    echo -e "\"amazon-alexa\": { \"exts\": [\"apk\"], \"name\": \"amazon-alexa\",\"arch\": \"all\",\"patch\": \"sign\", \"version\": \"$version\"}," >> build.json
    unset version
}
revenge-discord() {
	# Patch Revenge:
	dl_gh "NPatch" "7723mod" "latest" "npatch.jar" "jar"
	dl_gh "revenge-xposed" "revenge-mod" "latest" "revenge.apk" "app-release.apk"
	get_apk "com.discord" "discord" "bundle"
    version=$(java -jar ./temp/APKEditor.jar info -i ./download/discord.apk -version-name  -t json | jq -r '.[].VersionName')
	bcversion=$(curl -fsSL https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk18on/maven-metadata.xml | grep -oPm1 '(?<=<release>)[^<]+')
    echo -e "\e[32m[+] Downloading Bouncy Castle Provider\e[0m"
    wget -qO bcprov.jar "https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk18on/$bcversion/bcprov-jdk18on-$bcversion.jar"
    LAST_PROV=$(grep "^security.provider\." "$JAVA_HOME/conf/security/java.security"  | grep -oP '(?<=security\.provider\.)\d+' | sort -n | tail -1)
    echo "security.provider.$((LAST_PROV+1))=org.bouncycastle.jce.provider.BouncyCastleProvider"  > bc.security
    java -cp "bcprov.jar:npatch.jar" -Djava.security.properties=bc.security top.nkbe.npatch.patch.NPatch ./download/discord.apk -k ks.keystore  $KEYSTORE_PASS $KEYSTORE_ALIAS $KEYSTORE_PASS -m "revenge.apk" -o ./build/
    mv ./build/discord-*-npatched.apk "./build/discord-revenge-v$version.apk"
    echo -e "Patched Discord $version with revenge-xposed" >> build.md
    echo -e "\"discord-revenge\": { \"exts\": [\"apk\"], \"name\": \"discord-revenge\",\"arch\": \"all\",\"patch\": \"revenge-mod/revenge-xposed\", \"version\": \"$version\"}," >> build.json
    unset version
}
dolphin-sdk29() {
    _fs_get https://dolphin-emu.org/download/
    DOLPHIN_APK_URL=$(echo $html | grep -Eo 'https://dl\.dolphin-emu\.org/builds/[a-z0-9/]+/dolphin-master-[0-9]+-[0-9]+\.apk' | awk -F'[-/.]' '{v=$(NF-2); b=$(NF-1);if (v>V || (v==V && b>B)) {V=v; B=b; U=$0}} END{print U}')
    DOLPHIN_NAME=$(basename "$DOLPHIN_APK_URL" .apk)
    DOLPHIN_VER=${DOLPHIN_NAME#*-*-}
    curl -L "$DOLPHIN_APK_URL" -H "Cookie: $FS_COOKIES" -H "User-Agent: $user_agent"  -o dolphin-orig.apk
    java -jar ./temp/APKEditor.jar d -i dolphin-orig.apk -o dolphin-src -t xml -dex
    sed -i 's/android:targetSdkVersion="[^"]*"/android:targetSdkVersion="29"/g' dolphin-src/AndroidManifest.xml
    java -jar ./temp/APKEditor.jar b -i dolphin-src -o dolphin-patched.apk
    sign dolphin-patched.apk ./build/dolphin-sdk29-v$DOLPHIN_VER.apk
    echo -e "Patched Dolphin $DOLPHIN_VER with SDK 29" >> build.md
    echo -e "\"dolphin-sdk29\": { \"exts\": [\"apk\"], \"name\": \"dolphin-sdk29\",\"arch\": \"all\",\"patch\": \"sdk29\", \"version\": \"$DOLPHIN_VER\"}," >> build.json
    rm -f ./build/*.idsig
    }

eden-pubg() {
    export EDEN_ID=$(gh run list -R Eden-CI/Workflow -w nightly.yml --status success --limit 1 --json databaseId -q ".[0].databaseId")
    date1=$(gh run list -R Eden-CI/Workflow -w nightly.yml --status success --limit 1 --json updatedAt  -q ".[0].updatedAt")
    export EDEN_NAME=$(gh run view $EDEN_ID -R Eden-CI/Workflow | grep standard.apk | cut -d'-' -f3 )
    gh api "/repos/Eden-CI/Workflow/actions/artifacts/$(gh api repos/Eden-CI/Workflow/actions/runs/$EDEN_ID/artifacts --jq '.artifacts[] | select(.name| contains("standard.apk")) | .id')/zip" > eden-orig.apk  
    java -jar ./temp/APKEditor.jar d -i eden-orig.apk -o eden-src -t xml -dex
    sed -i 's/dev\.eden\.eden_emulator\.nightly/com.tencent.ig/g' eden-src/AndroidManifest.xml
    java -jar ./temp/APKEditor.jar b -i eden-src -o eden-patched.apk
    sign eden-patched.apk ./build/eden-pubg-v$EDEN_NAME.apk
    rm -f ./build/*.idsig
    echo -e "Patched  Eden $EDEN_NAME with com.tencent.ig package name" >> build.md
    echo -e "\"eden-pubg\": { \"exts\": [\"apk\"], \"name\": \"eden-pubg\",\"arch\": \"arm64-v8a\",\"patch\": \"pubg\", \"version\": \"$EDEN_NAME\"}," >> build.json

}

winlator-pubgvn() {
	dl_gh "Winlator-Ludashi" "StevenMXZ" "latest" "winlator-orig.apk" "build.apk"
    java -jar ./temp/APKEditor.jar d -i winlator-orig.apk -o winlator-src -t xml -dex
    sed -i -e 's/package="com\.tencent\.ig"/package="com.vng.pubgmobile"/' -e 's/com\.tencent\.ig\.tileprovider/com.vng.pubgmobile.tileprovider/' -e 's/com\.tencent\.ig\.core\.WinlatorFilesProvider/com.vng.pubgmobile.core.WinlatorFilesProvider/' -e 's/com\.tencent\.ig\.androidx-startup/com.vng.pubgmobile.androidx-startup/' winlator-src/AndroidManifest.xml
    java -jar ./temp/APKEditor.jar b -i winlator-src -o winlator-patched.apk
    sign winlator-patched.apk ./build/winlator-pubgvn-$tag.apk
    rm -f ./build/*.idsig
    echo -e "Patched Winlator-Ludashi $tag with com.vng.pubgmobile package name" >> build.md
    echo -e "\"winlator-pubgvn\": { \"exts\": [\"apk\"], \"name\": \"winlator-pubgvn\",\"arch\": \"arm64-v8a\",\"patch\": \"pubgvn\", \"version\": \"$tag\"}" >> build.json
}

amazon-alexa
amazon-india
revenge-discord
dolphin-sdk29
eden-pubg
winlator-pubgvn

echo -e '}' >> build.json
rm -rf ./download
rm -rf ./temp
rm -rf ./eden-src
rm -rf ./dolphin-src
rm -rf ./winlator-src
rm -rf ./*.apk
rm -rf ./*.jar
rm -rf ./bc.security
