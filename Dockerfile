FROM ubuntu:18.04
LABEL maintainer="Daniel Bonates <daniel@bonates.com"

ENV MOODLE_VERSION MOODLE_36_STABLE

# terminal conveniencies
RUN 	apt-get update && \
	apt-get install -y curl git zsh && \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" \
        && apt-get install -y vim tmux

# Moodle
VOLUME ["/var/moodledata"]
EXPOSE 80 443
ADD moodle-config.php /var/www/html/config.php

ENV DEBIAN_FRONTEND noninteractive

ADD ./foreground.sh /etc/apache2/foreground.sh

RUN apt-get update && \
	apt-get -y install pwgen python-setuptools unzip apache2 php \
		php-gd libapache2-mod-php postfix wget supervisor php-pgsql curl libcurl4 \
		libcurl3-dev php-curl php-xmlrpc php-intl git-core php-xml php-mbstring php-zip php-soap cron php-ldap 
WORKDIR	 /tmp 
	
RUN	git clone -b ${MOODLE_VERSION} git://git.moodle.org/moodle.git --depth=1 && \
	mv /tmp/moodle/* /var/www/html/ && \
	rm /var/www/html/index.html && \
	chown -R www-data:www-data /var/www/html && \
	chmod +x /etc/apache2/foreground.sh

#cron
ADD moodlecron /etc/cron.d/moodlecron
RUN chmod 0644 /etc/cron.d/moodlecron

# Enable SSL, moodle requires it
RUN a2enmod ssl && a2ensite default-ssl  #if using proxy dont need actually secure connection

# Cleanup, this is ran to reduce the resulting size of the image.
RUN apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/dpkg/* /var/lib/cache/* /var/lib/log/*

ENTRYPOINT ["/etc/apache2/foreground.sh"]
