FROM ubuntu:16.04
ARG MYSQL_ROOT_PW
ARG FREEPBX_DB_USER
ARG FREEPBX_DB_PW
RUN apt-get update
RUN apt-get install -y build-essential openssh-server apache2
RUN apt-get install linux-headers-$(uname -r)
RUN echo "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PW}" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PW}" | debconf-set-selections
RUN apt-get -y install mysql-server
RUN apt-get install -y mysql-client bison flex sox libncurses5-dev libssl-dev libmysqlclient-dev mpg123 libxml2-dev
RUN apt-get install -y libnewt-dev sqlite3 libsqlite3-dev pkg-config automake libtool autoconf git subversion unixodbc-dev
RUN apt-get install -y uuid uuid-dev libasound2-dev libogg-dev libvorbis-dev libcurl4-openssl-dev libical-dev libneon27-dev
RUN apt-get install -y libsrtp0-dev libspandsp-dev libopus-dev opus-tools libiksemel-dev libiksemel-utils libiksemel3 xmlstarlet
RUN apt-get install -y software-properties-common python-software-properties
RUN apt-get install -y locales
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen && dpkg-reconfigure locales --terse
RUN apt-get install -y language-pack-en
RUN export LANG=en_US.UTF-8 && add-apt-repository ppa:ondrej/php
RUN apt-get update -y
RUN apt-get install -y php5.6 php5.6-curl php5.6-cli php5.6-mysql php5.6-odbc php5.6-db php5.6-gd php5.6-xml curl libapache2-mod-php5.6
RUN apt-get install -y php-pear
#RUN a2dismod php7.0
RUN a2enmod php5.6
#RUN systemctl restart apache2
RUN update-alternatives --set php /usr/bin/php5.6
RUN a2enmod rewrite
RUN pear install Console_Getopt || true
RUN cd /usr/src && wget http://sourceforge.net/projects/lame/files/lame/3.98.4/lame-3.98.4.tar.gz
RUN cd /usr/src && wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
RUN cd /usr/src && wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
RUN cd /usr/src && wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-14-current.tar.gz
RUN cd /usr/src && git clone https://github.com/akheron/jansson.git
RUN cd /usr/src && wget http://www.pjsip.org/release/2.5.5/pjproject-2.5.5.tar.bz2
# Building loadMetadata
RUN cd /usr/src && tar xvfz lame-3.98.4.tar.gz
RUN cd /usr/src/lame-3.98.4 && ./configure
RUN cd /usr/src/lame-3.98.4 && make && make install
#compiling and install DAHDI
RUN cd /usr/src && tar xvf dahdi-linux-complete-current.tar.gz
RUN cd /usr/src && tar xvf libpri-current.tar.gz
RUN cd /usr/src/ && rm -f dahdi-linux-complete-current.tar.gz libpri-current.tar.gz
RUN cd /usr/src/dahdi-linux-complete-* && make all && make install
RUN cd /usr/src/dahdi-linux-complete-* && make config
RUN cd /usr/src/libpri-* && make && make install
#pjproject
RUN cd /usr/src && tar xvfj pjproject-2.*.tar.bz2
RUN cd /usr/src/pjproject-* && CFLAGS='-DPJ_HAS_IPV6=1' ./configure --prefix=/usr --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr
RUN cd /usr/src/pjproject-* && make dep && make && make install
#compile ad install jansson
RUN cd /usr/src/jansson && autoreconf -i && ./configure
RUN cd /usr/src/jansson && make && make install
# compile and install asterisk
RUN cd /usr/src && tar xvfz asterisk-14-current.tar.gz
RUN cd /usr/src && rm -f xvfz asterisk-14-current.tar.gz
RUN cd /usr/src/asterisk-* && ./configure
RUN cd /usr/src/asterisk-* && ./contrib/scripts/get_mp3_source.sh
RUN cd /usr/src/asterisk-* && TERM=xterm make menuselect
RUN cd /usr/src/asterisk-* && make && make install
RUN cd /usr/src/asterisk-* && make config && ldconfig
RUN sed -i  's/#AST_/AST_/' /etc/default/asterisk
RUN useradd -m asterisk
RUN chown asterisk. /var/run/asterisk
RUN chown -R asterisk. /etc/asterisk
RUN chown -R asterisk. /var/lib/asterisk
RUN chown -R asterisk. /var/log/asterisk
RUN chown -R asterisk. /var/spool/asterisk
RUN chown -R asterisk. /usr/lib/asterisk
RUN sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/5.6/apache2/php.ini
RUN sed -ie 's/\;date\.timezone\ \=/date\.timezone\ \=\ "Europe\/Moscow"/g' /etc/php/5.6/apache2/php.ini
RUN cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig
RUN sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf
RUN sed -i 's/AllowOverride None/AllowOverride All/'  /etc/apache2/apache2.conf
ADD ./odbcinst.ini /etc/obdcinst.ini
ADD ./odbc.ini /etc/odbc.ini
RUN cd /usr/src && wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-13.0-latest.tgz
RUN cd /usr/src && tar vxfz freepbx-13.0-latest.tgz
RUN apt-get install -y sudo net-tools
RUN systemctl disable mysql
RUN cd /usr/src/freepbx && install --dbuser='${FREEPBX_DB_USER}' --dbpass='${FREEPBX_DB_PW}' -n
