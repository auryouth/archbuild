# Archlinux 自动打包

## 使用方法

将以下内容添加到 `/etc/pacman.conf`（我自己个人使用添加在`[core]`之上）:

```ini
[auralioth]
SigLevel = Optional TrustAll
Server = https://github.com/auralioth/archbuild/releases/latest/download
```

## 实现

### Job1: Check

* 获取每次提交前后变化的文件
* 判断每个`package`目录下文件是否变化(主要是`PKGBUILD`和一些`source`)，
并结合依云的[nvchecker](https://github.com/lilydjwg/nvchecker)判断`version`是否变化，判断是否需要更新，输出`build_status`和待build的包(`matrix`)
* 根据`nvchecker.toml`和`old_ver.json`判断是否有包被移除，并更新`old_ver.json`，输出`remove_status`和`remove_pkgs`
* 提交`oldver_file`

### Job2-1: Build(if needs.check.outputs.build_status == 'true')

* `arch-build action` 通过 `matrix` 分开打包并分开`git commit`
* 上传打包好的 `asset`
* 删除`package release` 下的的旧包(目前只能根据`old_pkgver`删除上个版本的包)

### Job2-2: Repo_Remove(if needs.check.outputs.remove_status == 'true')

* `repo-remove` 需要移除的包
* 上传新的 `Database`

### Job3: Release ( needs: [ Build, Repo_Remove ] )

* 要求 `Build.result == 'success' && Repo_remove.result != 'failure'` 
* 下载上传的 `assets`
* `repo-action` 更新数据库
* `action-gh-release` 发布
* Telegram 通知打包完成

## 管理

* 添加包
    * 在目录下的`nvchecker.toml`（这是`nvcheck-and-update action`定义的默认值，可以通过输入`nvfile`更改）填写好信息，然后在目录下创建包的文件夹（**注意名称的一致性，否则会失败，目前要求二者的名称与PKGBUILD的pkgname必须一致**）
* 删除包
    * 删除目录(可选)和`nvchecker.toml`的配置文件(必须)
    * 删除`release`上的旧包(可选，目前不能自动删除)
    * **注意：** 不要手动删除`oldver_file`下的信息，因为需要依靠它来判断包被删除从而更新`Database`
* 更新包
    * 需要更新包的打包文件时(删改PKGBUILD、增加相关source等)，`Github Action`可以自动重新打包，也无需手动更新`pkg hash sums`，但`pkgrel`需要按要求增加(官方打包的要求)
