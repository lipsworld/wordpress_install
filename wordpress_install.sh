#!/bin/bash
# ------------------------------
#
#  Title: Creates a new WordPress install
#  Version: 1.0
#  Author: Patricia Hillebrandt
#
# ------------------------------

wp_user="admin"
wp_pass="CaTpP28cNo"
db_pass="CaTpP28cNodb"
wp_mail="your_email@email.com"

validation() {

    if [[ "$(id -u)" != "0" ]]; then
        echo "root privileges are required to run this script."
        exit 1
    fi
}

information_input() {

	read -p "Enter the DB name (press Ctrl-C to cancel): " db_name
	read -p "Enter the DB user (press Ctrl-C to cancel): " db_user
	read -p "Enter the name of the site (without www) (press Ctrl-C to cancel): " site_name
	read -p "Enter the site Title (press Ctrl-C to cancel): " title
	read -p "Are you sure you want to create this local WordPress install? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
}

create_db() {

	mysql -e "CREATE DATABASE $db_name";
	mysql -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass'";
	mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost'";
	mysql -e "FLUSH PRIVILEGES";
	mysql -e "QUIT";
	echo "Database was successfuly created!"
}

wordpress_install() {

	cd /var/www
	mkdir $site_name
	cd $site_name
	wp core download --skip-plugins --allow-root
	wp core config --allow-root --dbname=$db_name --dbuser=$db_user --dbpass=$db_pass --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'SCRIPT_DEBUG', true );
PHP
	wp core install --url="$site_name" --title="$title" --admin_user="$wp_user" --admin_password="$wp_pass" --admin_email="$wp_mail" --allow-root
	find /var/www/$site_name -type d -exec chmod 755 {} \;
	find /var/www/$site_name -type f -exec chmod 644 {} \;
}

mt_plugin_setup() {

    # You can save all Premium Plugins you have in a directory and install/activate them here:
    #cp /your/path/to/premium_plugins/* /var/www/$site_name/wp-content/plugins/
	# The Events Calendar
	wp plugin install the-events-calendar --skip-plugins --skip-themes --allow-root
	# Event Tickets
	wp plugin install event-tickets --skip-plugins --skip-themes --allow-root
	# WooCommerce
	wp plugin install woocommerce --skip-plugins --skip-themes --allow-root
    # Activate all Plugins
	wp plugin activate --all --allow-root
    echo "Plugins installed and activated!"

    # Permission Updates
    chown -R www-data: /var/www/$site_name
    find /var/www/$site_name -type d -exec chmod 755 {} \;
    find /var/www/$site_name -type f -exec chmod 644 {} \;
    chmod -R g+rwX /var/www/$site_name
}

nginx_config() {

	cd /etc/nginx/sites-available
	cp default.com $site_name
	sed -i "s/default.com/$site_name/g" $site_name
	cd /etc/nginx/sites-enabled
	ln -s ../sites-available/$site_name
	service nginx restart
	echo "NGINX Ready!"
}

local_config() {

	cd /etc
	sed -i '11d' hosts
	sed -i "\$a127.0.0.1 $site_name www.$site_name" hosts
	echo "Hosts file successfully configured!"
}

check_site_status() {

    siteurl=`wp --skip-themes --skip-plugins --allow-root --path=/var/www/$site_name option get siteurl`

    if echo $siteurl | egrep -q "^https"; then
        scheme="https"
    else
        scheme="http"
    fi

    host=`echo $siteurl | sed 's/https\?\:\/\///g'`
    status_code=`curl -I -w %{http_code} -s -o /dev/null $scheme://localhost/ -H "Host: $host"`

    if [[ "$status_code" == "200" ]]; then
        echo "Your WordPress site $site_name is now live!"
    else
        echo "Fail"
    fi
}

deploy() {

	validation
	information_input
	create_db
	if [[ $? -eq 0 ]]; then
		wordpress_install
	fi
	if [[ $? -eq 0 ]]; then
		mt_plugin_setup
	fi
	if [[ $? -eq 0 ]]; then
		nginx_config
	fi
	if [[ $? -eq 0 ]]; then
		local_config
	fi
	if [[ $? -eq 0 ]]; then
		check_site_status
	fi
}

deploy