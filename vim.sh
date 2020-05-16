#!/bin/bash

cd ~/

PY2=2.7.18
PY3=3.8.3
RUBY=2.7.1
GEOAREA="Asia"
TIMEZONE="Tokyo"

apt update > /dev/null

dpkg -l | grep tzdata
if [ "$?" -eq 0 ] ; then
	echo "TZDATA INSTALLED"
else
	echo "INSTALL TZDATA"
	export DEBIAN_FRONTEND=noninteractive
	ln -fs /usr/share/zoneinfo/$GEOAREA/$TIMEZONE /etc/localtime
	apt install -y tzdata > /dev/null
	dpkg-reconfigure --frontend noninteractive tzdata
fi

apt install -y sudo git make wget gcc \
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
	echo "ANYENV INSTALLED"
else
	git clone https://github.com/anyenv/anyenv ~/.anyenv
	echo 'export PATH="$HOME/.anyenv/bin:$PATH"' >> ~/.bashrc
	export PATH="$HOME/.anyenv/bin:$PATH"
	echo 'eval "$(anyenv init -)"' >> ~/.bash_profile
	echo 'eval "$(anyenv init -)"' >> ~/.bashrc
	source ~/.bash_profile
	anyenv install --force-init
fi

which pyenv >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
	echo "PYENV INSTALLED"
else
	anyenv install pyenv
	source ~/.bash_profile
fi

which rbenv >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
	echo "RBENV INSTALLED"
else
	anyenv install rbenv
	source ~/.bash_profile
fi


which python >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
	echo "PYTHON2 INSTALLED"
else
	CONFIGURE_OPTS="--enable-shared" pyenv install $PY2
fi

which python3 >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
	echo "PYTHON3 INSTALLED"
else
	CONFIGURE_OPTS="--enable-shared" pyenv install $PY3
fi

which ruby >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
	echo "RUBY INSTALLED"
else
	rbenv install $RUBY
fi

pyenv global $PY2 $PY3
rbenv global $RUBY

py2conf=`python -c "import distutils.sysconfig; print distutils.sysconfig.get_config_var('LIBPL')"`
py3conf=`python3 -c "import distutils.sysconfig; print(distutils.sysconfig.get_config_var('LIBPL'))"`

set -e

echo "CONFIG"
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

make
make install
vim --version
echo 'vim -c "python print(sys.version)"'
echo 'vim -c "python3 print(sys.version)"'
