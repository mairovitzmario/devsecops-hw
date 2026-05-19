FROM wordpress:latest

# Download wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
chmod +x wp-cli.phar && \
mv wp-cli.phar /usr/local/bin/wp

# Disable wp-cron
RUN sed -i '2i define("DISABLE_WP_CRON", true);' /usr/src/wordpress/wp-config-docker.php

# Hide WP version
RUN rm /usr/src/wordpress/readme.html

# Hide PHP version
RUN echo "expose_php = Off" > /usr/local/etc/php/conf.d/security.ini

# Hide Apache tokens
RUN a2enmod headers && \
    echo "ServerTokens Prod" >> /etc/apache2/conf-available/security.conf && \
    echo "ServerSignature Off" >> /etc/apache2/conf-available/security.conf && \
    echo "Header unset X-Powered-By" >> /etc/apache2/conf-available/security.conf && \
    a2enconf security

# Block XML-RPC and WP-Cron access
RUN echo "<FilesMatch \"^(xmlrpc\\.php|wp-cron\\.php)$\">" >> /etc/apache2/apache2.conf && \
    echo "Require all denied" >> /etc/apache2/apache2.conf && \
    echo "</FilesMatch>" >> /etc/apache2/apache2.conf

# Disable directory indexing and spoof 404 for MU-Plugins direct access
RUN echo "Options -Indexes" >> /etc/apache2/apache2.conf && \
    echo "RedirectMatch 404 ^/wp-content/mu-plugins/?(.*)$" >> /etc/apache2/apache2.conf

# Add MU-plugin to permanently hide WP version, block REST API user enumeration, and clean up
RUN mkdir -p /usr/src/wordpress/wp-content/mu-plugins && \
    echo "<?php" > /usr/src/wordpress/wp-content/mu-plugins/hide-version.php && \
    echo "remove_action('wp_head', 'wp_generator');" >> /usr/src/wordpress/wp-content/mu-plugins/hide-version.php && \
    echo "add_filter('the_generator', '__return_empty_string');" >> /usr/src/wordpress/wp-content/mu-plugins/hide-version.php && \
    echo "function remove_version_scripts_styles(\$src) { if (strpos(\$src, 'ver=')) { \$src = remove_query_arg('ver', \$src); } return \$src; }" >> /usr/src/wordpress/wp-content/mu-plugins/hide-version.php && \
    echo "add_filter('style_loader_src', 'remove_version_scripts_styles', 9999);" >> /usr/src/wordpress/wp-content/mu-plugins/hide-version.php && \
    echo "add_filter('script_loader_src', 'remove_version_scripts_styles', 9999);" >> /usr/src/wordpress/wp-content/mu-plugins/hide-version.php && \
    echo "add_filter('rest_endpoints', function(\$endpoints) { if (isset(\$endpoints['/wp/v2/users'])) { unset(\$endpoints['/wp/v2/users']); } if (isset(\$endpoints['/wp/v2/users/(?P<id>[\d]+)'])) { unset(\$endpoints['/wp/v2/users/(?P<id>[\d]+)']); } return \$endpoints; });" >> /usr/src/wordpress/wp-content/mu-plugins/hide-version.php && \
    echo "add_action('template_redirect', function() { if (is_author()) { wp_redirect(home_url()); exit; } });" >> /usr/src/wordpress/wp-content/mu-plugins/hide-version.php && \
    echo "add_filter('the_author', function(\$name) { return is_feed() ? 'Admin' : \$name; });" >> /usr/src/wordpress/wp-content/mu-plugins/hide-version.php && \
    echo "add_filter('login_errors', function() { return 'Invalid credentials.'; });" >> /usr/src/wordpress/wp-content/mu-plugins/hide-version.php

# Enable Rewrite module and block Author Enumeration (?author=N) scans
RUN a2enmod rewrite && \
    echo "<IfModule mod_rewrite.c>" >> /etc/apache2/apache2.conf && \
    echo "RewriteEngine On" >> /etc/apache2/apache2.conf && \
    echo "RewriteCond %{QUERY_STRING} ^author=([0-9]*) [NC]" >> /etc/apache2/apache2.conf && \
    echo "RewriteRule .* - [F,L]" >> /etc/apache2/apache2.conf