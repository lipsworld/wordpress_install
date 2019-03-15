server {
    listen 80;
    server_name default.com www.default.com;
    #access_log /var/log/nginx/default.com.access.log;
    root /var/www/default.com;

    #include /etc/nginx/conf.d/security.inc;

    #if ($host !~ "^www\.") { return 301 $scheme://www.$host$request_uri; }

    location / {
        index index.php;
        if (!-e $request_filename) { rewrite . /index.php last; }
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.1-fpm.sock;
    }

    location ~ \.(jpe?g|gif|png|ico|css|js|swf) {
        expires -1;
    }
}