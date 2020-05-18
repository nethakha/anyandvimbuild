#!/bin/bash

cd ~/

# コミットへたくその戒め

# オプション
readonly Lua=true
readonly Python2=true
readonly Python3=true
readonly Ruby=true
# インストールしたいバージョン
readonly Luav=5.3.5
readonly Python2v=2.7.18
readonly Python3v=3.8.3
readonly Rubyv=2.7.1
# エリア
readonly GEOAREA="Asia"
readonly TIMEZONE="Tokyo"

InstallFlag=false
PythonInstallFlag=false
if "${Python2}" || "${Python3}" || "${Ruby}"; then
	InstallFlag=true
fi

if "${Python2}" || "${Python3}"; then
	PythonInstallFlag=true
fi

which sudo > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
	echo "sudo is already installed."
else
	echo "Install sudo."
	apt-get install -y sudo > /dev/null
	echo "Installed sudo."
fi

sudo apt-get update > /dev/null
dpkg -l | grep tzdata > /dev/null
if [ "$?" -eq 0 ]; then
	echo "tzdata is already installed."
else
	echo "Install tzdata."
	groups | grep sudo
	if [ "$?" -eq 0 ]; then
		export DEBIAN_FRONTEND=noninteractive
	else
		sudo export DEBIAN_FRONTEND=noninteractive
	fi
	sudo ln -fs /usr/share/zoneinfo/$GEOAREA/$TIMEZONE /etc/localtime
	sudo apt-get install -y tzdata > /dev/null
	sudo dpkg-reconfigure --frontend noninteractive tzdata
	echo "Installed tzdata."
fi

echo "Install the required tools and libraries."
sudo apt-get install -y git make wget gcc \
	build-essential libbz2-dev libdb-dev \
	libreadline-dev libffi-dev libgdbm-dev liblzma-dev \
	libncursesw5-dev libsqlite3-dev libssl-dev \
	zlib1g-dev uuid-dev tk-dev \
	perl libperl-dev \
	gettext > /dev/null

if [ ! -d ~/build ]; then
    mkdir -p ~/build
fi
cd ~/build/
if [ ! -d ~/build/vim ]; then
    git clone --depth 1 https://github.com/vim/vim.git
fi
cd vim

git pull > /dev/null
make distclean > /dev/null

export PATH=$HOME/.anyenv/bin:$PATH

if "${InstallFlag}" && !(type anyenv > /dev/null 2>&1); then
	echo "Install anyenv."
	git clone https://github.com/anyenv/anyenv ~/.anyenv
	echo 'export PATH="$HOME/.anyenv/bin:$PATH"' >> ~/.bashrc
	echo 'eval "$(anyenv init -)"' >> ~/.bashrc
	eval "$(anyenv init -)"
	anyenv install --force-init
	echo "Installed anyenv."
else
	echo "anyenv is already installed."
fi

envInstall() {
	EnvName=$1
	EnvFlag=$2
	if "${EnvFlag}" && !(type $EnvName > /dev/null 2>&1); then
		echo "Install ${EnvName}."
		anyenv install $EnvName
		echo "Installed ${EnvName}."
		eval "$(anyenv init -)"
	else
		echo "${EnvName} is already installed."
	fi
}

envInstall "pyenv" $PythonInstallFlag
envInstall "rbenv" $Ruby
envInstall "luaenv" $Lua

langInstall() {
	EnvName=$1
	LangName=$2
	LangFlag=$3
	LangVersion=$4
	if "${LangFlag}" && [ ! -d $HOME/.anyenv/envs/$EnvName/versions/$LangVersion ]; then
		echo "Install ${LangName}."
		CONFIGURE_OPTS="--enable-shared" $EnvName install $LangVersion
		echo "Installed ${LangName}."
	else
		echo "${LangName} is already installed."
	fi
}

langInstall "pyenv" "Python2" $Python2 $Python2v
langInstall "pyenv" "Python3" $Python3 $Python3v
langInstall "rbenv" "Ruby" $Ruby $Rubyv
langInstall "luaenv" "Lua" $Lua $Luav

if "${InstallFlag}"; then
	echo "Set global."
	if "${PythonInstallFlag}"; then
		pyenv global $Python2v $Python3v
	elif "${Python2}"; then
		pyenv global $Python2v
	elif "${Python3}"; then
		pyenv global $Python3v
	fi

	if "${Ruby}"; then
		rbenv global $Rubyv
	fi

	if "${Lua}"; then
		luaenv global $Luav
	fi
fi

set -e

echo "Configure Vim's configuration."
# LDFLAGS 生成
LD=""
VimPython2rPath=""
VimEnablePython2=""
if "${Python2}"; then
	VimPython2rPath="${HOME}/.anyenv/envs/pyenv/versions/$Python2v/lib"
	VimEnablePython2="--enable-pythoninterp=dynamic"
	if "${Python3}" || "${Ruby}"; then
		VimPython2rPath+=":"
	fi
fi

VimPython3rPath=""
VimEnablePython3=""
if "${Python3}"; then
	VimPython3rPath="${HOME}/.anyenv/envs/pyenv/versions/$Python3v/lib"
	VimEnablePython3="--enable-python3interp=dynamic"
	if "${Ruby}"; then
		VimPython3rPath+=":"
	fi
fi

VimRubyrPath=""
VimEnableRuby=""
if "${Ruby}"; then
	VimRubyrPath="${HOME}/.anyenv/envs/rbenv/versions/$Rubyv/lib"
	VimEnableRuby="--with-ruby-command=$HOME/.anyenv/envs/rbenv/shims/ruby "
	VimEnableRuby+="--enable-rubyinterp=dynamic"
fi

VimLuarPath=""
VimEnableLua=""
if "${Lua}"; then
	VimLuarPath="${HOME}/.anyenv/envs/rbenv/versions/$Luav/lib"
	VimEnableLua="--with-lua-prefix=${HOME}/.anyenv/envs/luaenv/versions/$Luav "
	VimEnableLua+="--enable-luainterp"
fi

if "${InstallFlag}"; then
	LD='LDFLAGS="-Wl,-rpath='$VimPython2rPath$VimPython3rPath$VimRubyrPath'"'
fi

CONF=" ${LD} ./configure
	--prefix=$HOME/.local
	--with-features=huge
	--enable-fail-if-missing
	--enable-terminal
	--enable-perlinterp
	${VimEnableLua}
	${VimEnablePython2}
	${VimEnablePython3}
	${VimEnableRuby}
	--enable-cscope
	--enable-multibyte
	--enable-fontset
    --enable-xim
    --enable-gui=no
"
make distclean > /dev/null

. ~/.profile

eval $CONF

echo "Run make."

make

make install


if [ ! -d $HOME/.vim/pack/vimdoc-ja/start ]; then
	echo "日本語マニュアルを導入します。"
	mkdir -p ~/.vim/pack/vimdoc-ja/start
	git clone https://github.com/vim-jp/vimdoc-ja.git ~/.vim/pack/vimdoc-ja/start
	echo "日本語マニュアルを導入しました。"
fi

export PATH=$HOME/.local/bin:$PATH

# PATHが通っていない場合
if !(type vim > /dev/null 2>&1); then
	echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
	export PATH=$HOME/.local/bin:$PATH
fi

echo "Displays the version of Vim."
vim --version

if "${Python2}"; then
	echo 'vim -c "python print(sys.version)"'
fi

if "${Python3}"; then
	echo 'vim -c "python3 print(sys.version)"'
fi

exec $SHELL -l