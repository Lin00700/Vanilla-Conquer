# Vanilla Conquer
Vanilla Conquer is a fully portable version of the first generation C&C engine and is capable of running both Tiberian Dawn and Red Alert on multiple platforms. It can also be used for mod development for the Remastered Collection.

The main focus of Vanilla Conquer is to keep the default out-of-box experience faithful to what the games were back when they were released and work as a drop-in replacement for the original executables while also providing bug fixes, compatiblity and quality of life improvements.

## iPhone / 全能签

这个仓库可以打出一个**不含任何游戏数据**的未签名 iOS 安装包，用全能签（或同类工具）签到自己的 iPhone 上玩红色警戒 1。引擎是 GPLv3 的 Vanilla Conquer，只编了 Red Alert（`vanillara`）。Bundle id 是 `com.lin00700.redalert`，最低系统 iOS 15，横屏。

发行包在本仓库的 Release 标签 `ios-redalert`（文件名 `RedAlert-ios-unsigned.ipa`）。GitHub Actions 的 `ios` 工作流也会把同一个 IPA 当成构建产物上传。

### 安装

1. 下载 `RedAlert-ios-unsigned.ipa`。
2. 用全能签导入并签名。不需要付费开发者账号的能力（没有推送、iCloud 之类的 entitlement）。
3. 装到手机上之后先不要急着进游戏。

### 游戏数据放哪

应用里没有 MIX。打开 iPhone 的「文件」App，找到「红色警戒」（或「我的 iPhone」里这个 App），把你**自己合法取得**的原版文件拷进去。这个目录就是 App 的 Documents。

必须有：

- `REDALERT.MIX`
- `MAIN.MIX`（可以放在这个目录的根上，也可以放在 `allied/` 或 `soviet/` 里）

高清界面还需要 `HIRES.MIX`。不少安装目录里它已经打在 `REDALERT.MIX` 里面，那就不用再单独放一份。

可选：`EXPAND.MIX`（隐秘行动）、`EXPAND2.MIX`（劫后余生），以及原版目录里其它 MIX。文件名要大写；如果拷过来是小写，应用会尝试改成大写。

缺了 `REDALERT.MIX` 或 `MAIN.MIX` 时，屏幕上会停在中文说明，不会直接崩溃。放好文件后点「我已放入文件，继续」，或者切回游戏（应用会自己再找一次）。

1996 年原版光盘通常没有单独的 `HIRES.MIX`（高清图是后来的 Windows 安装程序另放的）。只有 `REDALERT.MIX` 和 `MAIN.MIX` 时，游戏改用光盘自带的原分辨率素材，再把这幅画面拉满整块横屏，不会在右边留一条黑边，也不会因为缺少高清图而闪退。如果连字体都读不出来，会停在中文说明上，而不是回到主屏幕。

主菜单、选项和侧栏上的常见按钮、单位和建筑名称是中文（安装包里自带的小字体，不是光盘上的中文版）。过场动画、任务简报和地图上的任务说明仍然是英文，因为那些文字画在原版的图片和影片里。

2008 年 EA 把红色警戒原版数据作为免费软件发布，说明见上游 README 里的 [EA 公告存档](https://web.archive.org/web/20080901183216/http://www.ea.com/redalert/news-detail.jsp?id=62)。官方试玩版也可以玩一部分内容。请用你合法获得的文件，不要从不明来源下载。本安装包不附带这些文件。

### 触控

- 点一下：选择（左键）
- 按住约半秒，或两指点一下：命令（右键，移动 / 攻击）
- 单指拖动：框选
- 两指拖动：滚动地图（手指往哪边拖，地图就跟着往哪边走）

游戏会把画面铺满整块屏幕（含刘海 / 灵动岛那一侧），状态栏隐藏，底部横条自动隐藏，边缘上滑需要滑两次才回主屏幕。侧边栏会让开刘海，地图仍画到屏幕边上，不会出现黑边，也不会把 640×400 拉变形。画面按手机的点尺寸来画（大约 800×400 这一级，比经典 640 更宽，所以横向能看见更多地图），再按设备的 2 倍或 3 倍整数放大到物理像素，像素保持正方形。

### 已知限制

没有联机。音频走系统 OpenAL，如果设备上初始化失败就没有声音，游戏仍会继续。鼠标边缘滚屏在触控上是关的，避免手指抬起后地图自己一直滚。部分原版对话框仍按 640 点宽排版，在更宽的屏幕上会偏左，但主菜单会居中。没有把泰伯利亚黎明打进这个 IPA。

Current project goals are tracked as [GitHub issues with the goal label](https://github.com/Vanilla-Conquer/Vanilla-Conquer/issues?q=is%3Aissue+is%3Aopen+label%3Agoal).

## Chat with us

There are rooms on multiple platforms for discussion:

- [The Assembly Armada](https://discord.gg/UnWK2Tw) on [Discord](https://discord.gg)
- [#vanilla-conquer:vi.fi](https://matrix.to/#/#vanilla-conquer:vi.fi) on [Matrix](https://matrix.org)
- [#vanilla-conquer](https://web.libera.chat/?channel=#vanilla-conquer) on [Libera.Chat](https://libera.chat]) IRC network

All of these rooms are bridged together so people can choose their preferred service. Please be nice to each other.

## Building

We support wide variety of compilers and platforms to target. Vanilla Conquer is known to compile with recent enough gcc, MSVC, mingw-w64 or clang and known to run on Windows, Linux, macOS and BSDs.

### Presets

A [CMakePresets.json](CMakePresets.json) file is provided that contains presets for common build configurations and is used by our CI scripts to build the release builds. These presets require the [Ninja](https://ninja-build.org/) build tool to be available in the system PATH in order to be used.

We also provide an example [CMakeUserPresets.json](resources/CMakeUserPresets.json.example) that can be copied to the root source directory and renamed. You can edit this file to create your own development presets that won't be included in git commits. A few example presets are provided which override the release presets to build a "debug" configuration.

To build using a preset, add `--preset preset_name` to the CMake command line examples below.

### Windows

#### Requirements

The following components are needed to build Vanilla Conquer executables:

 - [MSVC v142 C++ x86/x64 build tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
 - Windows 10 SDK
 - CMake (installable from MSVC build tools)
 - [SDL1 or SDL2 development libraries, Visual C++](https://libsdl.org/download-2.0.php)
 - [OpenAL Core SDK](https://www.openal.org/downloads/)

Extract SDL2 and OpenAL somewhere you know. If you are building only Remastered dlls you can skip installing SDL2 and OpenAL.

#### Building

In a VS command line window in the Vanilla Conquer source directory:

```sh
cmake -DSDL2_ROOT_DIR=C:\path\to\SDL2 -DOPENAL_ROOT=C:\path\to\OpenAL -B build .
cmake --build build
```

This will build Vanilla Conquer executables in the build directory. If you are building Remastered dlls you need to configure cmake with `-A win32` and ensure your VS command line is x86.

### Linux / macOS / BSD

#### Requirements

- GNU C++ Compiler (g++) or Clang
- CMake
- SDL1 or SDL2
- OpenAL

On Debian/Ubuntu you can install the build requirements as follows:

```sh
sudo apt update
sudo apt install g++ cmake libsdl2-dev libopenal-dev
or
sudo apt install g++ cmake libsdl1.2-dev libopenal-dev
```

On Fedora/RedHat based system you can install the build requirements as follows:

```sh
sudo dnf install gcc-c++ cmake SDL2-devel openal-soft-devel
or
sudo dnf install gcc-c++ cmake SDL-devel openal-soft-devel
```

#### Building

```sh
cmake -B build .
cmake --build build
```

This will build Vanilla Conquer executables in the build directory.

#### macOS considerations

To create a portable bundle for macOS we run [macdylibbundler](https://github.com/auriamg/macdylibbundler) in our CI builds as an extra step to add the SDL2 and OpenAL libraries to the bundle. If you wish to create a portable bundle yourself, you will need to do this step manually as CMake will not currently do it for you.

### Icons

CMake will attempt to generate icons in an appropriate format for Windows and macOS if ImageMagick is found in the system PATH. Otherwise you will end up with generic "program" icons.

## Releases

Binary releases of the latest commit are available from [here](https://github.com/TheAssemblyArmada/Vanilla-Conquer/releases/tag/latest), which is updated whenever new code is merged into the main branch.

## Running

### VanillaTD and VanillaRA

Copy the Vanilla executable (`vanillatd.exe` or `vanillara.exe`) to your legacy game directory, on Windows also copy `SDL2.dll` and `OpenAL32.dll`.

For Tiberian Dawn the final freeware Gold CD release ([GDI](https://www.moddb.com/games/cc-gold/downloads/command-conquer-gold-free-game-gdi-iso), [NOD](https://www.moddb.com/games/cc-gold/downloads/command-conquer-gold-free-game-nod-iso)) works fine.

For Red Alert the freeware [CD release](https://web.archive.org/web/20080901183216/http://www.ea.com/redalert/news-detail.jsp?id=62) works fine as well.
The official [Red Alert demo](https://www.moddb.com/games/cc-red-alert/downloads/command-conquer-red-alert-demo) is also fully playable.
The demo supports custom skirmish maps (except interior) and includes one campaign mission for both Allied and Soviet from the retail game.

While it is possible to use the game data from the Remastered Collection, The Ultimate Collection or The First Decade they are currently _not_ supported.
Any repackaged version that you may already have from any unofficial source is _not_ supported.
If you encounter a bug that may be data related like invisible things or crashing when using a certain unit please retest with the retail data first before submitting a bug report.

### Remastered

The build process will produce _Vanilla_TD_ and _Vanilla_RA_ directories in your build directory if you enable them with `-DBUILD_REMASTERTD=ON` and `-DBUILD_REMASTERRA=ON`.
These work as mods for the Remastered Collection.

To manually install a local Remastered mod, launch both games once then head to _My Documents/CnCRemastered/CnCRemastered/Mods_.
You should see _Tiberian\_Dawn_ and _Red\_Alert_ directories.

#### Tiberian Dawn

Copy the _Vanilla_TD_ directory to the _Tiberian\_Dawn_ directory.

The directory structure should look like this:

    My Documents/CnCRemastered/CnCRemastered/Mods/Tiberian_Dawn/Vanilla_TD/Data/TiberianDawn.dll
    My Documents/CnCRemastered/CnCRemastered/Mods/Tiberian_Dawn/Vanilla_TD/ccmod.json
    My Documents/CnCRemastered/CnCRemastered/Mods/Tiberian_Dawn/Vanilla_TD/GameConstants_Mod.xml

You should now see the new mod in the mods list of Tiberian Dawn Remastered.

#### Red Alert

Copy the _Vanilla_RA_ directory to the _Red\_Alert_ directory.

The directory structure should look like this:

    My Documents/CnCRemastered/CnCRemastered/Mods/Red_Alert/Vanilla_RA/Data/RedAlert.dll
    My Documents/CnCRemastered/CnCRemastered/Mods/Red_Alert/Vanilla_RA/ccmod.json

You should now see the new mod in the mods list of Red Alert Remastered.
