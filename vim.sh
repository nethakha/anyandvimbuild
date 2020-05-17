#!/bin/bash

cd ~/

# オプション
readonly Python2=true
readonly Python3=true
readonly Ruby=false

# インストールしたいバージョン
readonly Python2v=2.7.18
readonly Python3v=3.8.3
readonly Rubyv=2.7.1

# エリア
readonly GEOAREA="Asia"
readonly TIMEZONE="Tokyo"

InstallFlag=false
if "${Python2}" || "${Python3}" || "${Ruby}"; then
	InstallFlag=true
fi
PythonInstallFlag=false
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
	sudo export DEBIAN_FRONTEND=noninteractive
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
  lua5.3 liblua5.3-dev perl libperl-dev \
  gettext > /dev/null

if [ ! -d ~/build ]; then
    mkdir -p ~/build
fi

cd ~/build/

if [ ! -d ~/build/vim ]; then
    git clone --depth 1 https://github.com/vim/vim.git
fi

cd vim

git pull

make distclean > /dev/null





if "${InstallFlag}"; then
	which anyenv > /dev/null 2>&1
	if [ "$?" -eq 0 ]; then
		echo "anyenv is already installed."
	else
		echo "Install anyenv."
		git clone https://github.com/anyenv/anyenv ~/.anyenv
		echo 'export PATH="$HOME/.anyenv/bin:$PATH"' >> ~/.bashrc
		export PATH="$HOME/.anyenv/bin:$PATH"
		echo 'eval "$(anyenv init -)"' >> ~/.bash_profile
		echo 'eval "$(anyenv init -)"' >> ~/.bashrc
		source ~/.bash_profile
		source ~/.bashrc
		anyenv install --force-init
		echo "Installed anyenv."
	fi
fi

if "${PythonInstallFlag}"; then
	which pyenv > /dev/null 2>&1
	if [ "$?" -eq 0 ]; then
		echo "pyenv is already installed."
	else
		echo "Install pyenv."
		anyenv install pyenv
		source ~/.bash_profile
		source ~/.bashrc
		echo "Installed pyenv."
	fi
fi

if "${Ruby}"; then
	which rbenv > /dev/null 2>&1
	if [ "$?" -eq 0 ]; then
		echo "rbenv is already installed."
	else
		echo "Install rbenv."
		anyenv install rbenv
		source ~/.bash_profile
		source ~/.bashrc
		echo "Installed rbenv."
	fi
fi

if "${Python2}"; then
	echo "Install Python2."
	CONFIGURE_OPTS="--enable-shared" pyenv install $Python2v
	echo "Installed Python2."
fi
if "${Python3}"; then
	echo "Install Python3."
	CONFIGURE_OPTS="--enable-shared" pyenv install $Python3v
	echo "Installed Python3."
fi
if "${Ruby}"; then
	echo "Install Ruby."
	rbenv install $Rubyv
	echo "Installed Ruby."
fi

if "${InstallFlag}"; then
	echo "Set global."
	if "${PythonInstallFlag}"; then
		pyenv global $Python2v $Python3v
	fi
	if "${Python2}"; then
		pyenv global $Python2v
	fi
	if "${Python3}"; then
		pyenv global $Python3v
	fi
	if "${Ruby}"; then
		rbenv global $Rubyv
	fi
fi

set -e

echo "Configure Vim's configuration."
# LDFLAGS 生成
LD=""
VimPython2rPath=""
VimPython3rPath=""
VimRubyrPath=""
VimEnablePython2=""
VimEnablePython3=""
VimEnableRuby=""

if "${Python2}"; then
	VimPython2rPath="\${HOME}/.anyenv/envs/pyenv/versions/$Python2v/lib"
	VimEnablePython2="--enable-pythoninterp=dynamic \\"
	if "${Python3}" || "${Ruby}"; then
		VimPython2rPath+=":"
	fi
fi
if "${Python3}"; then
	VimPython3rPath="\${HOME}/.anyenv/envs/pyenv/versions/$Python3v/lib"
	VimEnablePython3="--enable-python3interp=dynamic \\"
	if "${Ruby}"; then
		VimPython3rPath+=":"
	fi
fi
if "${Ruby}"; then
	VimRubyrPath="${HOME}/.anyenv/envs/rbenv/versions/$Rubyv/lib"
	VimEnableRuby="--with-ruby-command=$HOME/.anyenv/envs/rbenv/shims/ruby "
	VimEnableRuby+="--enable-rubyinterp=dynamic \\"
fi

if "${InstallFlag}"; then
	LD='LDFLAGS="-Wl,-rpath='$VimPython2rPath$VimPython3rPath$VimRubyrPath'"'
fi

$LD ./configure \
	--prefix=$HOME
    --with-features=huge \
    --enable-fail-if-missing \
    --enable-terminal \
    --enable-luainterp=dynamic \
    --enable-perlinterp=dynamic \
    $VimEnablePython2
    $VimEnablePython3
    $VimEnableRuby
    --enable-tclinterp=dynamic \
    --enable-cscope \
    --enable-multibyte \
    --enable-fontset \
    --disable-gui \
    --without-x

echo "Run make."
make
echo "Run make install."
make install

echo "日本語マニュアルを導入します。"
mkdir -p ~/.vim/pack/vimdoc-ja/start
git clone https://github.com/vim-jp/vimdoc-ja.git ~/.vim/pack/vimdoc-ja/start
echo "日本語マニュアルを導入しました。"

echo "Displays the version of Vim."
vim --version

if "${Python2}"; then
	echo 'vim -c "python print(sys.version)"'
fi

if "${Python3}"; then
	echo 'vim -c "python3 print(sys.version)"'
fi