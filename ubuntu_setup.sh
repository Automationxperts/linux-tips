#!/bin/sh

# Determine if this is 32-bit or 64-bit version of kernel.
if $(uname -m | grep '64'); then  # Check for 64-bit Linux kernel
	KERNEL_TYPE=amd64
else    # Otherwise use version for 32-bit kernel
	KERNEL_TYPE=i386
fi


# Add some necessary non-default packages
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get autoremove -f -y
sudo apt-get install -y build-essential dtrx curl wget check-install gdebi \
	openjdk-8-jre python-software-properties software-properties-common

# Allow current user to run 'sudo' without password
# https://phpraxis.wordpress.com/2016/09/27/enable-sudo-without-password-in-ubuntudebian/
# http://stackoverflow.com/a/28382838
echo "${USER}" > /tmp/user.tmp
sudo bash -c 'echo "`cat /tmp/user.tmp` ALL=(ALL) NOPASSWD:ALL" | (EDITOR="tee -a" visudo)'
rm -f /tmp/user.tmp

# Add official Git package repository
sudo apt-add-repository -y ppa:git-core/ppa

# Add PHP 5.6/7.0/7.1 package repository
sudo apt-add-repository -y ppa:ondrej/php

# Add Vim 8.x package repository
# https://itsfoss.com/vim-8-release-install/
sudo apt-add-repository -y ppa:jonathonf/vim

# Add NodeJS package repository
# https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -

# Install NodeJS, Vim 8, and Git
sudo apt-get install -y vim vim-gtk3 vim-common \
	git \
	nodejs


# Install PHP 5.6, Apache 2, and MySQL Server
export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'  # Set MySQL password to 'root'.
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt-get install -y php5.6-bcmath php5.6-bz2 php5.6-cli php5.6-common php5.6-curl php5.6-gd php5.6-json php5.6-mbstring php5.6-mcrypt php5.6-mysql php5.6-readline php5.6-sqlite3 php5.6-xml php5.6-xsl php5.6-zip php-xdebug \
libapache2-mod-php5.6 libapache2-mod-xsendfile \
mysql-server mysql-workbench

# Enable 'modrewrite' Apache module
sudo a2enmod rewrite
sudo service apache2 restart  ## Alternate command is 'sudo apachectl restart'

# Add current user to 'www-data' group
sudo usermod -a -G www-data ${USER}

# Change owner of /var/www/html directory to www-data
sudo chown -R www-data:www-data /var/www/html

# Create simple 'phpinfo' script in main web server directory
# Note: Must create file in /tmp and then move because 'sudo cat...' is allowed.
sudo cat > /tmp/phpinfo.php << EOL
<?php
	phpinfo();
?>
EOL
sudo mv /tmp/phpinfo.php /var/www/html
sudo chown www-data:www-data /var/www/html/phpinfo.php

# Disable XDebug on CLI to prevent warnings when installing/running Composer
sudo phpdismod -s cli xdebug

# Install PHP Composer as global utility
php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('/tmp/composer-setup.php');"
rm -f /tmp/composer-setup.php
sudo chmod +x /usr/local/bin/composer
sudo chown -R $USER:$USER $HOME/.composer

# Install latest PhpMyAdmin version via Composer
# https://docs.phpmyadmin.net/en/latest/setup.html#composer
cd /var/www/html
sudo php /usr/local/composer create-project phpmyadmin/phpmyadmin --repository-url=https://www.phpmyadmin.net/packages.json --no-dev
sudo chown -R www-data:www-data /var/www/html/phpmyadmin
xdg-open http://localhost/phpmyadmin/setup
cd $HOME

# Install bash-it script
cd $HOME
wget -O /tmp/bash-it.zip https://github.com/Bash-it/bash-it/archive/master.zip
dtrx -n /tmp/bash-it.zip
mv ./bash-it/bash-it-master $HOME/.bash-it
$HOME/.bash-it/install.sh --silent
source $HOME/.bashrc	# Enable bash-it configuration immediately.
rm -f /tmp/bash-it.zip
rm -rf $HOME/bash-it

# Install LilyTerm terminal
# Ubuntu does not have recent version in packages, so we build from source,
# which requires installation of GTK+2 and other libraries.
sudo apt-get install -y pkg-config libglib2.0-dev libgtk2.0-dev libvte-dev
cd $HOME/Downloads
wget -O lilyterm.tar.gz http://lilyterm.luna.com.tw/file/lilyterm-0.9.9.4.tar.gz
dtrx -n $HOME/Downloads/lilyterm.tar.gz
cd $HOME/Downloads/lilyterm/lilyterm-0.9.9.4
./configure
make
sudo make install
cd $HOME
rm -rf $HOME/Downloads/lilyterm*

# Install Firejail and Firetools utilities for running applications
# in isolated memory space.
cd /var/tmp
curl -o firejail.deb -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0" -J -L https://superb-sea2.dl.sourceforge.net/project/firejail/firejail/firejail_0.9.44.8_1_${KERNEL_TYPE}.deb
curl -o firetools.deb -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0" -J -L https://cytranet.dl.sourceforge.net/project/firejail/firetools/firetools_0.9.46_1_${KERNEL_TYPE}.deb
sudo gdebi -n firejail.deb   # '-n' is non-interactive mode for gdebi
sudo gdebi -n firetools.deb   # '-n' is non-interactive mode for gdebi
rm -f firejail.deb firetools.deb
cd $HOME

# Install Stacer Linux monitoring tool
# Must download specific version, because unable to get 'latest' from Sourceforge to work.
cd $HOME/Downloads
curl -o stacer.deb -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0" -J -L https://pilotfiber.dl.sourceforge.net/project/stacer/v1.0.6/Stacer_1.0.6_${KERNEL_TYPE}.deb
sudo gdebi -n stacer.deb   # '-n' is non-interactive mode for gdebi
rm -f stacer.deb
cd $HOME

# Install DBeaver Java database utility
cd $HOME/Downloads
curl -o dbeaver.deb -J -L http://dbeaver.jkiss.org/files/dbeaver-ce_latest_${KERNEL_TYPE}.deb
sudo gdebi -n dbeaver.deb
rm -f dbeaver.deb
sudo apt-get install -y libmysql-java   # Install MySQL JDBC driver
cd $HOME

# Install Linux Brew (similar to MacOS X "Home Brew")
# Ruby *should* already be installed; it gets installed when Vim is installed. But we will install the dependencies, just in case.
# Linux Brew is installed as *user* (not global) application.
sudo apt-get install -y build-essential curl git python-setuptools ruby
cd $HOME/Downloads
wget -O linuxbrew.zip https://github.com/Linuxbrew/brew/archive/master.zip
dtrx -n linuxbrew.zip
mv $HOME/Downloads/linuxbrew/brew-master $HOME/.linuxbrew
echo 'export PATH="$HOME/.linuxbrew/bin:$PATH"' >> $HOME/.bashrc
echo 'export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"' >> $HOME/.bashrc
echo 'export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"' >> $HOME/.bashrc
source $HOME/.bashrc
rm -rf linuxbrew*
cd $HOME
brew update    # Update the Linuxbrew "formulae" (packages).

# Install Atom editor via PPA
sudo add-apt-repository -y ppa:webupd8team/atom
sudo apt-get update -y
sudo apt-get install -y atom

# Install Cudatext editor from Sourceforge
curl -o /tmp/cudatext.deb -J -L https://cytranet.dl.sourceforge.net/project/cudatext/release/Linux/cudatext_1.7.8.0-1_gtk2_amd64.deb
sudo gdebi -n /tmp/cudatext.deb
rm -f /tmp/cudatext.deb

# Enable GetDeb repository for your version of Ubuntu
source /etc/os-release   # This config file contains Ubuntu version details.
DEB_STRING='deb http://archive.getdeb.net/ubuntu '${UBUNTU_CODENAME}'-getdeb apps'
sudo echo $DEB_STRING > /etc/apt/sources.list.d/getdeb.list
wget -q -O- http://archive.getdeb.net/getdeb-archive.key | sudo apt-key add -
sudo apt-get update -y
