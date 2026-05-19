FROM wordpress:latest

# Download wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Disable wp-cron
RUN sed -i '2i define("DISABLE_WP_CRON", true);' /usr/src/wordpress/wp-config-docker.php

# Hide WP & PHP versions
RUN rm /usr/src/wordpress/readme.html && \
    echo "expose_php = Off" > /usr/local/etc/php/conf.d/security.ini

# Apache Server Hardening & Enumeration Blocking
RUN a2enmod headers rewrite && \
    cat <<EOF >> /etc/apache2/apache2.conf

# Block XML-RPC and WP-Cron access
<FilesMatch "^(xmlrpc\.php|wp-cron\.php)$">
    Require all denied
</FilesMatch> 

# Disable directory indexing and spoof 404 for MU-Plugins direct access
Options -Indexes
RedirectMatch 404 ^/wp-content/mu-plugins/?(.*)$

# Block Author Enumeration (?author=N) scans
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{QUERY_STRING} ^author=([0-9]*) [NC]
    RewriteRule .* - [F,L]
</IfModule>
EOF

# Hide Apache tokens
RUN echo "ServerTokens Prod" >> /etc/apache2/conf-available/security.conf && \
    echo "ServerSignature Off" >> /etc/apache2/conf-available/security.conf && \
    echo "Header unset X-Powered-By" >> /etc/apache2/conf-available/security.conf && \
    a2enconf security

# Build the custom MU-Plugin
RUN mkdir -p /usr/src/wordpress/wp-content/mu-plugins && \
    cat <<'EOF' > /usr/src/wordpress/wp-content/mu-plugins/hide-version.php
<?php
// Hide WP Generator
remove_action('wp_head', 'wp_generator');
add_filter('the_generator', '__return_empty_string');

// Remove version queries from scripts and styles
function remove_version_scripts_styles($src) { 
    if (strpos($src, 'ver=')) { 
        $src = remove_query_arg('ver', $src); 
    } 
    return $src; 
}
add_filter('style_loader_src', 'remove_version_scripts_styles', 9999);
add_filter('script_loader_src', 'remove_version_scripts_styles', 9999);

// Block REST API User Enumeration
add_filter('rest_endpoints', function($endpoints) { 
    if (isset($endpoints['/wp/v2/users'])) { unset($endpoints['/wp/v2/users']); } 
    if (isset($endpoints['/wp/v2/users/(?P<id>[\d]+)'])) { unset($endpoints['/wp/v2/users/(?P<id>[\d]+)']); } 
    return $endpoints; 
});

// Block Author Archive Redirects
add_action('template_redirect', function() { 
    if (is_author()) { wp_redirect(home_url()); exit; } 
});

// Spoof RSS Feed Author Name
add_filter('the_author', function($name) { 
    return is_feed() ? 'Admin' : $name; 
});

// Genericize Login Errors
add_filter('login_errors', function() { 
    return 'Invalid credentials.'; 
});
EOF