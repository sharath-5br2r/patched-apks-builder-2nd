get_experimental_version() {
 echo $(curl -s https://raw.githubusercontent.com/MorpheApp/morphe-patches/refs/tags/$(gh release list --limit 1  --repo MorpheApp/morphe-patches | awk '{print $1}')/patches-list.json  | jq --arg pkg $1 -r '[.patches[].compatiblePackages[]? | select(.packageName == $pkg) | .targets[] | select(.isExperimental == true).version] | unique | sort_by(split(".") | map(tonumber)) | last')
}
export version=$(get_experimental_version com.google.android.youtube)
yq -p toml -o toml  -i ".youtube-morphe.version |= strenv(version) " configs/config.toml 
export version=$(get_experimental_version com.google.android.apps.youtube.music)
yq -p toml -o toml -i ".youtube-music-morphe.version |= strenv(version) " configs/config.toml 
