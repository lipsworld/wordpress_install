# Installing WordPress locally

A bash script to install WordPress locally.

## Dependencies

- PHP 7.1
- WP-CLI 2.1.0
- NGINX
- MySQL

## Installation guide

- Clone this repo
- Make the `wordpress_install.sh` file executable with `chmod +x`
- Place the `default.com` file on `/etc/nginx/sites-available`
- Run the script: `sudo ./wordpress_install.sh`

Created and tested on Ubuntu 18.04