#!/bin/bash

cd ~/

PY2=2.7.18
PY3=3.8.3
RUBY=2.7.1
GEOAREA="Asia"
TIMEZONE="Tokyo"

which sudo > /dev/null 2>&1
if [ "$?" -eq 0 ] ; then
	echo "sudo is already installed."
else
	echo "Install sudo."
	apt install -y sudo > /dev/null
	echo "Installed sudo."
fi

sudo apt update > /dev/null

dpkg -l | grep tzdata > /dev/null
if [ "$?" -eq 0 ] ; then
	echo "tzdata is already installed."
else
	echo "Install tzdata."
	sudo export DEBIAN_FRONTEND=noninteractive
	sudo ln -fs /usr/share/zoneinfo/$GEOAREA/$TIMEZONE /etc/localtime
	sudo apt install -y tzdata > /dev/null
	sudo dpkg-reconfigure --frontend noninteractive tzdata
	echo "Installed tzdata."
fi

echo "Install the required tools and libraries."
sudo apt install -y git make wget gcc \
  build-essential libbz2-dev libdb-dev \
  libreadline-dev libffi-dev libgdbm-dev liblzma-dev \
  libncursesw5-dev libsqlite3-dev libssl-dev \
  zlib1g-dev uuid-dev tk-dev \
  lua5.3 liblua5.3-dev perl libperl-dev > /dev/null

if [ ! -d ~/build ]; then
    mkdir -p ~/build
fi

cd ~/build/

if [ ! -d ~/build/vim ]; then
    git clone --depth 1 https://github.com/vim/vim.git
fi

cd vim

git pull

make distclean

which anyenv >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
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

which pyenv >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
	echo "pyenv is already installed."
else
	echo "Install pyenv."
	anyenv install pyenv
	source ~/.bash_profile
	source ~/.bashrc
	echo "Installed pyenv."
fi

which rbenv >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
	echo "rbenv is already installed."
else
	echo "Install rbenv."
	anyenv install rbenv
	source ~/.bash_profile
	source ~/.bashrc
	echo "Installed rbenv."
fi


which python >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
	echo "Python2 is already installed."
else
	echo "Install Python2."
	CONFIGURE_OPTS="--enable-shared" pyenv install $PY2
	echo "Installed Python2."
fi

which python3 >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
	echo "Python3 is already installed."
else
	echo "Install Python3."
	CONFIGURE_OPTS="--enable-shared" pyenv install $PY3
	echo "Installed Python3."
fi

which ruby >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
	echo "Ruby is already installed."
else
	echo "Install Ruby."
	rbenv install $RUBY
	echo "Installed Ruby."
fi

echo "Set global."
pyenv global $PY2 $PY3
rbenv global $RUBY

set -e
py2conf=`python -c "import distutils.sysconfig; print distutils.sysconfig.get_config_var('LIBPL')"`
py3conf=`python3 -c "import distutils.sysconfig; print(distutils.sysconfig.get_config_var('LIBPL'))"`

echo "Configure Vim's configuration."
LDFLAGS="-Wl,-rpath=${HOME}/.anyenv/envs/pyenv/versions/$PY2/lib:${HOME}/.anyenv/envs/pyenv/versions/$PY3/lib:${HOME}/.anyenv/envs/rbenv/versions/$RUBY/lib" ./configure \
    --with-features=huge \
    --enable-fail-if-missing \
    --enable-terminal \
    --enable-luainterp=dynamic \
    --enable-perlinterp=dynamic \
    --enable-pythoninterp=dynamic \
    --enable-python3interp=dynamic \
        --with-ruby-command=$HOME/.anyenv/envs/rbenv/shims/ruby \
    --enable-rubyinterp=dynamic \
    --enable-tclinterp=dynamic \
    --enable-cscope \
    --enable-multibyte \
    --enable-fontset \
    --enable-gui=no \
    --without-x \
    --disable-xim \
    --disable-gui \
    --disable-xsmp

echo "Run make."
make
echo "Run make install."
make install
echo "Displays the version of Vim."
vim --version
echo 'vim -c "python print(sys.version)"'
echo 'vim -c "python3 print(sys.version)"'
