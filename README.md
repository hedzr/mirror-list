# 各种各样的镜像加速

> mirrors-for-coder



这里做一个集中，尽管以前都是遇到时立即搜索，但是集中一下之后，看起来也很壮观的。

###### 当然，欢迎完善它。

- https://github.com/hedzr/mirror-list

###### 如何更好的浏览/阅读这篇文章：

1. 可以寻找chrome插件 Github Markdown Outline Extension，但是我好像是拿来修订了之后才能使用的。
2. 可以寻找chrome插件 HTML5 Outliner
3. 在阅读平台上：
   1. <https://juejin.im/post/5da57638f265da5b932e7418>
   2. <https://segmentfault.com/a/1190000020693560>



## China Mirrors



### GitHub Clone

通过HTTPS协议Clone仓库的话，可能会遇到速度很慢的情况。

根据经验，在慢的时候中断Clone捎带片刻重复命令的话，你可能会得到正常速度，这种偷鸡的策略适合于小小仓库。

对于大型仓库，改走SSH协议进行clone的话，走到正常速度的几率较大，但此时的速度相较于HTTPS而言通常会有所损耗。

但下面还有一种较为费事的方法，通过修改 hosts 文件来完成提速，无需科学也无需代理加速也无需镜像加速（GitHub是不太可能有镜像的）。具体来说请接下去阅读：

首先在 https://www.ipaddress.com/ 查询这三个域名的地址：

1. github.com
2. assets-cdn.github.com
3. github.global.ssl.fastly.net

然后按照查询的结果填写到 /etc/hosts 中，windows用户请查找 %WINDIR%/system32/drivers/etc/hosts 文件。请注意修改 hosts 文件通常需要 sudo 权限 或者管理员权限。修改内容如同下面：

```bash
140.82.118.3    github.com
185.199.109.153 assets-cdn.github.com
185.199.111.153 assets-cdn.github.com
185.199.108.153 assets-cdn.github.com
185.199.110.153 assets-cdn.github.com
151.101.113.194 github.global.ssl.fastly.net
```

如果你有国外的服务器，也可以通过dig指令来查找：

```bash
$ dig github.com +short
140.82.118.3
```







### Docker CE

Docker CE 的具体加速办法有很多种，然而各种版本的本质都是一样的，一般来说你需要找到 docker daemon 的配置文件 `/etc/docker/daemon.json`，然后修改它像这样：

```json
{
  "insecure-registries" : [
    "registry.mirrors.aliyuncs.com"
  ],
  "debug" : true,
  "experimental" : false,
  "registry-mirrors" : [
    "https://docker.mirrors.ustc.edu.cn",
    "https://dockerhub.azk8s.cn",
    "https://reg-mirror.qiniu.com",
    "https://registry.docker-cn.com"
  ]
}
```

如果你在这个文件中自定义了其他项目，或者这个文件中已经存在其他定义，请注意保持。

参考：https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file











### Ubuntu Apt Source

如果你使用桌面版本，则 Ubuntu 的软件源设置中，你可以选取最近的地区，例如中国大陆，从而加速软件包下载速度。

如果使用 Server 版本，则可以明确地使用清华镜像（或者自行使用其他镜像）

```bash
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
```

以上例子为 18.04 版本的替换内容。你可以直接访问清华开源站查找其他版本：

https://mirror.tuna.tsinghua.edu.cn/help/ubuntu/



#### 其他方法

https://askubuntu.com/questions/39922/how-do-you-select-the-fastest-mirror-from-the-command-line



##### 使用 apt-select

可以用pip安装它：

```bash
pip install apt-select
```

然后运行它并跟随提示走：

```bash
apt-select --country US -t 5 --choose
```





##### 使用mirrors CDN

apt-get [now supports](http://mvogt.wordpress.com/2011/03/21/the-apt-mirror-method/) a 'mirror' method that will automatically select a good mirror based on your location. Putting:

```
deb mirror://mirrors.ubuntu.com/mirrors.txt precise main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt precise-updates main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt precise-backports main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt precise-security main restricted universe multiverse
```

on the top in your `/etc/apt/sources.list` file should be all that is needed to make it automatically pick a mirror for you based on your geographical location.

你可以无脑地使用 sed 来搞定：

```bash
sudo sed -i 's%us.archive.ubuntu.com/ubuntu/%mirrors.ubuntu.com/mirrors.txt%' /etc/apt/sources.list
```







### Alpine Apk

清华提供一种Apk源加速方式：https://mirror.tuna.tsinghua.edu.cn/help/alpine/

在终端输入以下命令以替换TUNA镜像源： `sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories`

```bash
sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
```

制作 Docker 镜像时，这是很有用的，节约生命真的是美德。







### Arch Linux Pacman

清华提供一种 Arch Linux 软件仓库加速方式：https://mirror.tuna.tsinghua.edu.cn/help/archlinux/

编辑 /etc/pacman.d/mirrorlist， 在文件的最顶端添加： `Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch`

更新软件包缓存： `sudo pacman -Syy`







### Go Modules

使用 Golang v1.11 以上，为你的项目启用 Go Modules 功能，然后就可以使用 GOPROXY 环境变量来透明地使用镜像代理。

比较著名的大陆加速器为：

```bash
export GOPROXY=https://goproxy.cn
# Windows 应该使用 set GOPROXY=xxxx 语法
```

然后 `go mod download` 以及 `go mod tidy` 就足够快了。

如果你想搭建私服，可以遵循 Go Modules 的 API 规范自己实现一个代理服务器，也可以使用开源的  [athens](https://github.com/gomods/athens) 项目自建一个服务器。

如果使用 Golang 1.13 以上版本的话，一下语法可用：

```bash
export GOPROXY=direct,https://goproxy.cn,https://goproxy.io,https://gocenter.i
o
```







### Android SDK

国内有多家组织提供 Android SDK的镜像缓存，甚至个人也可以很容易地建立这样的缓存，如果你有国内访问速度很好的国外服务器的话。

但是，随着时间推移，现在这些镜像基本上都已失效了。

取而代之的是，目前，Android的官方源是可以直连的，且能达到正常速度，所以还是赶紧滴做点负责任的app出来吧，不要只是会矽肺或者偷偷上传神马的。





### Gradle

Gradle的配置文件为`~/.gradle/init.gradle`：

```
allprojects {
	repositories {
		maven {
			url 'https://maven.aliyun.com/repository/public/'
		}
	}
	buildscript {
		repositories {
			maven {
				url 'https://maven.aliyun.com/repository/public/'
			}
		}
	}
}
```

以下的镜像可以选用

- 华为：https://mirrors.huaweicloud.com/repository/maven/
- 网易：https://mirrors.163.com/maven/repository/maven-public/







### Gem 和 CocoaPods

#### 替换 Ruby 源

首先是 gem 和 ruby 的源应该被替换

##### 移除现有的Ruby镜像

```bash
$ gem sources --remove https://rubygems.org
```



##### 添加国内最新镜像

```bash
$ gem sources -a https://gems.ruby-china.com
```



##### 查看当前镜像

```bash
$ gem sources -l
```



#### 加速 Cocoapods

几种加速方法，可能需要自己实际测试那种效果最好。

##### gitee镜像

```bash
pod repo remove master   
pod repo add master https://gitee.com/mirrors/CocoaPods-Specs   
pod repo update   
```

##### 清华镜像

```bash
pod repo remove master   
pod repo add master https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git   
pod repo update   
```

对于 Cocoapods 新的版本，需要使用如下的方法：

```bash
pod repo remove master
cd ~/.cocoapods/repos
git clone https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git master
```

##### 你的 xcode 工程中如果有Podfile的话，请修改加入下面的行：

```ruby
source 'https://gitee.com/mirrors/CocoaPods-Specs.git'
source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
```







### Homebrew

macOS 中都会安装 Homebrew，但 `brew update` 可能会很慢。加速的办法是替换现有的上游：

```
git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git

git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git

brew update
```

#### 复原

*(感谢Snowonion Lee提供说明)*

```
git -C "$(brew --repo)" remote set-url origin https://github.com/Homebrew/brew.git

git -C "$(brew --repo homebrew/core)" remote set-url origin https://github.com/Homebrew/homebrew-core.git

git -C "$(brew --repo homebrew/cask)" remote set-url origin https://github.com/Homebrew/homebrew-cask.git

brew update
```

以上内容从清华开源上复制：[Homebrew 镜像使用帮助](https://mirror.tuna.tsinghua.edu.cn/help/homebrew/)

如果想阻止 brew 指令运行时总是尝试去自动更新，可以设置环境变量：

```bash
# forbit autoupdate on homebrew installing
export HOMEBREW_NO_AUTO_UPDATE=1
```





### Flutter & Dart Pub

flutter 官网有专门的页面讲述加速问题：

https://flutter.dev/community/china



#### Flutter 镜像安装帮助

Flutter 是一款跨平台的移动应用开发框架，由 Google 开源。用 Flutter 开发的应用可以直接编译成 ARM 代码运行在 Android 和 iOS 系统上。

可以使用清华镜像：https://mirror.tuna.tsinghua.edu.cn/help/flutter/

Flutter 安装时需要从 Google Storage 下载文件，如您的网络访问 Google 受阻，建议使用本镜像。使用方法为设置环境变量 `FLUTTER_STORAGE_BASE_URL`，并指向 TUNA 镜像站。

```
$ export FLUTTER_STORAGE_BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/flutter"
```

若希望长期使用 TUNA 镜像：

```
$ echo 'export FLUTTER_STORAGE_BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/flutter"' >> ~/.bashrc
```

此外 Flutter 开发中还需要用到 Dart 语言的包管理器 Pub，其镜像使用方法参见[Pub 镜像安装帮助](https://mirror.tuna.tsinghua.edu.cn/help/dart-pub/)。



#### Pub 镜像安装帮助

[Pub](https://pub.dartlang.org/) 是 Dart 官方的包管理器。跨平台的前端应开发 框架 [Flutter](https://flutter.dev/) 也基于 Dart 并且可以使用大部分 Pub 中的 库。

如果希望通过 TUNA 的 pub 镜像安装软件，只需要设置 [PUB_HOSTED_URL](https://www.dartlang.org/tools/pub/environment-variables) 这个环境变量指向 https://mirrors.tuna.tsinghua.edu.cn/dart-pub/ 即可。

以 bash 为例，临时使用 TUNA 的镜像来安装依赖：

```
$ PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub/" pub get # pub
$ PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub/" flutter packages get # flutter
```

若希望长期使用 TUNA 镜像：

```
$ echo 'export PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub/"' >> ~/.bashrc
```





### Rust Cargo 和 Rustup

Rust 使用 creates.io，国内也有相应的提速手段：

https://lug.ustc.edu.cn/wiki/mirrors/help/rust-crates

首先你需要在 $HOME/.cargo/config 中添加如下内容

```ini
[registry]
index = "git://mirrors.ustc.edu.cn/crates.io-index"
# Or
# index = "http://mirrors.ustc.edu.cn/crates.io-index"
```

如果 cargo 版本为 0.13.0 或以上, 需要更改 $HOME/.cargo/config 为以下内容:

```ini
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'ustc'
[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"
```

有兴趣自建的朋友，可以看看：

https://github.com/rust-lang/crates.io/blob/master/docs/MIRROR.md



清华TUNA 也有 rustup 相应的镜像

```bash
# export CARGO_HOME=$HOME/.cargo
# export RUSTUP_HOME=$HOME/.rustup
export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
```

详见：https://mirror.tuna.tsinghua.edu.cn/help/rustup/









### R CRAN

采用清华开源站：

[CRAN](https://cran.r-project.org/) (The Comprehensive R Archive Network) 镜像源配置文件之一是 `.Rprofile` (linux 下位于 `~/.Rprofile` )。

在文末添加如下语句:

```
options("repos" = c(CRAN="https://mirrors.tuna.tsinghua.edu.cn/CRAN/"))
```

打开 R 即可使用该 CRAN 镜像源安装 R 软件包。



也可以使用其他镜像站：

- https://mirror.lzu.edu.cn/CRAN
- ...

如果使用 R Console，可以在 Perferences 设置对话框中直接设置官方镜像的上海、香港、兰州等节点。







### Maven

#### 采用aliyun镜像

编辑 `$HOME/.m2/settings.xml`，找到 `<mirrors>` 小节，添加如下内容：

```xml
<mirror>
    <id>aliyun-public</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun public</name>
    <url>https://maven.aliyun.com/repository/public</url>
</mirror>

<mirror>
    <id>aliyun-central</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun central</name>
    <url>https://maven.aliyun.com/repository/central</url>
</mirror>

<mirror>
    <id>aliyun-spring</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun spring</name>
    <url>https://maven.aliyun.com/repository/spring</url>
</mirror>

<mirror>
    <id>aliyun-spring-plugin</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun spring-plugin</name>
    <url>https://maven.aliyun.com/repository/spring-plugin</url>
</mirror>

<mirror>
    <id>aliyun-apache-snapshots</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun apache-snapshots</name>
    <url>https://maven.aliyun.com/repository/apache-snapshots</url>
</mirror>

<mirror>
    <id>aliyun-google</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun google</name>
    <url>https://maven.aliyun.com/repository/google</url>
</mirror>

<mirror>
    <id>aliyun-gradle-plugin</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun gradle-plugin</name>
    <url>https://maven.aliyun.com/repository/gradle-plugin</url>
</mirror>

<mirror>
    <id>aliyun-jcenter</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun jcenter</name>
    <url>https://maven.aliyun.com/repository/jcenter</url>
</mirror>

<mirror>
    <id>aliyun-releases</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun releases</name>
    <url>https://maven.aliyun.com/repository/releases</url>
</mirror>

<mirror>
    <id>aliyun-snapshots</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun snapshots</name>
    <url>https://maven.aliyun.com/repository/snapshots</url>
</mirror>  

<mirror>
    <id>aliyun-grails-core</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun grails-core</name>
    <url>https://maven.aliyun.com/repository/grails-core</url>
</mirror>

<mirror>
    <id>aliyun-mapr-public</id>
    <mirrorOf>*</mirrorOf>
    <name>aliyun mapr-public</name>
    <url>https://maven.aliyun.com/repository/mapr-public</url>
</mirror>
```

也可以采用 profile 方式，这里就不再赘述了。



### Python pip 和 composer

#### Pip

- 清华：`pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple`
- 阿里：`pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/`
- 华为：`pip config set global.index-url https://mirrors.huaweicloud.com/repository/pypi/simple`
- 豆瓣：`pip config set global.index-url https://pypi.douban.com/simple`

```bash
# 以下可以选用其一

# 清华：
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
# 阿里：
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/
# 华为：
pip config set global.index-url https://mirrors.huaweicloud.com/repository/pypi/simple
# 豆瓣：
pip config set global.index-url https://pypi.douban.com/simple
```



#### Composer

```bash
# 以下可以选用其一

# 阿里：
composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
# 华为：
composer config -g repo.packagist composer https://mirrors.huaweicloud.com/repository/php/

# Laravel中文网
composer config -g repo.packagist composer https://packagist.laravel-china.org
```



#### Sequel

完成pip加速配置之后，`$HOME/.pip/pip.conf` 看起来可能会像这样：

```ini
[global]
#index-url = http://pypi.mirrors.ustc.edu.cn/simple

trusted-host =  mirrors.aliyun.com
index-url = http://mirrors.aliyun.com/pypi/simple
# index-url = http://pypi.douban.com/simple
# trusted-host = pypi.douban.com
disable-pip-version-check = true
timeout = 120

[install]
ignore-installed = true
# 不自动安装依赖的时候设置此选项
# no-dependencies = yes

[list]
format = columns
```







### Node 和 npm/Yarn

可以更换镜像：

- 阿里：`yarn config set registry https://registry.npm.taobao.org`
- 华为：`yarn config set registry https://mirrors.huaweicloud.com/repository/npm/`
- Node-Sass：`npm config set sass_binary_site https://mirrors.huaweicloud.com/node-sass/`









### Vagrant

没有简单的办法。一些周知的镜像，可以通过这些地方加速：

- 对于 Ubuntu 之类，可以取清华镜像

  ```bash
  vagrant box add ubuntu/trusty64 https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cloud-images/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box
  
  vagrant box add ubuntu/bionic64 https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cloud-images/bionic/20191002/bionic-server-cloudimg-amd64-vagrant.box
  ```

  

- 清华找不到几个周知镜像，所以基本上还是要在 http://www.vagrantbox.es/ 寻找和添加

  ```bash
  vagrant box add debian/8.1 https://github.com/kraksoft/vagrant-box-debian/releases/download/8.1.0/debian-8.1.0-amd64.box 
  ```

- 总的来说，没有什么有效的镜像，只能想各种办法去手工下载box，然后再导入。





## Conclusion

CC4

https://github.com/hedzr/mirror-list

