# How to customize this repo

> [!NOTE]
> Custom patches are made using [Apktool M](https://maximoff.su/apktool/?lang=en), diff, and then ChatGPT to generate a `sed` patch for that diff.

## [`src/build/helper/apps.json`](../src/build/helper/apps.json) help

-  Add your apps here. Please refer previous entries in that file to add new app.
-  You need package name, and example urls.
## [`src/build/utils.sh`](../src/build/utils.sh) syntax

- Download from GitHub: `dl_gh $repo $owner $tag $output $filter $excludeFilter`
  > Where:
  > - `$repo` refers to the repository.
  > - `$owner` refers to the owner of the repository.
  > - `$tag` refers to the version/GitHub tag of the required binary.
  > - `$tag` can also be:
  >   - `latest` for the latest stable release.
  >   - `prerelease` for the latest prerelease.
  > - `$output` refers to output file name for one file and dir for many files.
  > - `$filter` refers to the filter used to select only a few apps. Change it to exclude by setting `$excludeFilter`=`true`

- GitLab syntax is similar, but replace `dl_gh` with `dl_gl`. It currently lacks filtering

- For APKMirror APK downloads, first see [`src/build/helper/apps.json`](../src/build/helper/apps.json) to know the template of links. Then, after adding apps, use:
  ```sh
  get_apk $appPkgName $appname $apkType $arch $dpi $androidversion
  ```
  > Where:
  > - `$appPkgName` refers to the Android package name.
  > - `$appname` refers to the patching app name.
  > - `$apkType` is either `bundle`, `bundle_extract`, or `apk`, depending upon the app.
  > 	- `$arch`, `$dpi`, and `$androidversion` are optional and are needed in some cases. Refer to the build scripts in[ `src/build`](../src/build/) and [`build.toml`](../build.toml) for more information.
- For APKPure, the syntax is similar, but replace it with `dl_apkpure`. Remember to edit  [`src/build/helper/apps.json`](../src/build/helper/apps.json)
- For Google Play, the syntax is almost similar but
```sh
get_chplay $appPkgName $appname $filetype $dispenser_url
```

- `check_experimental $apppkgname` is specific to Morphe experimental app versions to get the latest experimental version from the README.
- `_fs_get $url` uses FlareSolverr against `$url`, which is protected by anti-bot measures. It outputs the content as `$html` and cookies as `$FS_COOKIES`.
- `sign $input $output` is used to sign an app, usually one that has been custom patched, where `$input` and `$output` refer to APKs.


## KeyStore

You need a keystore to patch and sign apps. The Morphe/ReVanced CLI automatically creates one, but for safe updates you should use your own.

To create a keystore, refer online and try to use GUI utilities such as <https://keystore-explorer.org/>.

You will provide an alias and password when generating a certificate and keystore.

The keystore must be in the BKS (Bouncy Castle KeyStore) format for compatibility with the Morphe/ReVanced CLI.

## GitHub Actions

This repository uses GitHub Actions to automate APK patching. If you want your own version, follow the steps below.

## Required Secrets

To create secrets, go to the **Settings** tab, then select **Actions** under **Secrets and variables** in the **Security and quality** section. Then click **New repository secret**.

The following secrets are required:

- `KEYSTORE`: Base64-encoded version of your BKS keystore. Use:
  ```sh
  base64 ks.keystore
  ```
- `KEYSTORE_ALIAS`: Signing alias of the keystore.
- `KEYSTORE_PASS`: Password of the keystore.
- `PAT_TOKEN`: GitHub Personal Access Token. Used to auto rebase repo. Get it from GitHub Settings.
- Some other secrets may be needed for dynamic actions only patches. Refer them.

## Syntax

- `.github/workflows/patch.yml` contains every patch you need to manually patch.

  To add a new app:
  - Copy any one of the existing matrix blocks.
  - Change the required `appname`,` patchname`,` app`(friendly name) and `patch`(friendly name)
  - Remember to add `patch` into options of `workflow_dispatch`

  It can be triggered manually using the **Actions** menu or from other workflows.

- `src/etc/ci.sh` is the checker script for GitHub and GitLab, respectively, used to determine whether a new app should be built.

  Syntax:
  ```sh
  bash src/etc/ci.sh $reponame $channel $urtag $source
  ```

  > Where:
  > - `$source` is either `gh` for github, `gl` for gitlab and `eden` is purpose built for eden emulator ci.
  > - `$reponame` is formatted as `Owner/Repo`.
  > - `$channel` is either `latest`, `prerelease`, or `$remotetag`, which is the tag of the remote repository.
  > - `$urtag` is the name of the tag where the APK is present in your repository.

- `.github/workflows/new_ci.yml` checks for new patches on GitHub/GitLab every 4 hours and runs some patches always

  To add a new app:
  - Copy one of the existing check blocks.
  - Modify the patch repository, APK pattern, and release tag used by the checkers.
  - Add your check output at the end of the `check:` job.
  - Copy a patching block and modify its check variable in the `if:` field and the `org:` field.
  - Exclude `needs:` and `if:` if the app receives latest updates instead of patch based 

- `.github/workflows/ci_.yml` , `.github/workflows/manual-patch.yml` and  `.github/workflows/ci.yml` are untouched upstream files to maintain merge compatibility.

## Instructions

1. Select the **Actions** tab.
2. Select the **Manual Patch** workflow.
3. Click **Run workflow**.
4. Select your app or `all` to patch all apps.

# How to run this project locally

## Dependencies

- `git`
- `wget`
- `curl`
- GitHub CLI (`gh`)
- `bash`
- `FlareSolverr`
- Java (any JDK is OK)
- `yq`

Some of the tools can be downloaded on Windows via Git Bash/MSYS2.

For Termux, run:

```sh
pkg install git wget curl gh bash openjdk-25
```

Then download my fork of [FlareSolverr](https://github.com/sharath-5br2r/FlareSolverr-Termux) and install the remaining dependencies:

```sh
pkg install chromium python
```

Start FlareSolverr before running the scripts. On Termux:

```sh
python src/flaresolverr.py
```

## Steps

### Step 1: Clone this repository or your fork

```sh
git clone https://github.com/sharath-5br2r/patched-apks-builder
```

### Step 2: Configure the project

- Copy `.env.example` to `.env` and edit it to your liking.
- Place your BKS keystore as `ks.keystore` in the root of the repository.

### Step 3: Start the build script

```sh
bash src/build/build.sh $appname $patchname
```

Where `$appname` and `$patchname` is described via `build.toml`

Example:

```sh
bash src/build/build.sh youtube morphe
```

For Custom Patches, it is

```sh
bash src/build/custom_patch.sh dolphin-sdk29
```

>[!Note]
> On Windows remember to add `-o igncr` to fix patch name before name of the script 
### Step 4: Get the output

The generated APKs will be available in:

```text
./build/*.apk
```

If module is generated, it is at 

```text
./build/*.zip
```