## Unused
The new version of our PHP v8js image is now at [Cojecom / docker-php7.4-apache-v8js](https://github.com/Cojecom/docker-php7.4-apache-v8js)


# Php v8js-engine

Dockerfile for install a **php-v8-js** apache server

### Usage
* `export VERSION="6.9.207"`

*Version list: [chromium.googlesource.com](https://chromium.googlesource.com/v8/v8.git)*

* `docker build -t php-v8:latest .`

* `docker run --name php-v8 -tv /srv/monsite:/var/www -p 80:80  -d php-v8`

* `docker start php-v8`

### Todo

- [ ] Unblock the TEST step
