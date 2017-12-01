# What is DSpace?

```
                                 ##        .
                           ## ## ##       ==
                        ## ## ## ##      ===
                    /""""""""""""""""\___/ ===
               ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
                    \______ o          __/
                      \    \        __/
                       \____\______/
                   ____  _____
                  / __ \/ ___/____  ____ _________
                 / / / /\__ \/ __ \/ __ `/ ___/ _ \
                / /_/ /___/ / /_/ / /_/ / /__/  __/
               /_____//____/ .___/\__,_/\___/\___/
                          /_/
Debian GNU/Linux 9.1 image.
- with OpenJDK Runtime Environment
- with DSpace 5.x on Tomcat 8.5
```

[DSpace](https://wiki.duraspace.org/display/DSDOC5x/Introduction) is an open-source software package typically used for creating open-access repositories for scholarly/published digital content. While DSpace shares some feature overlap with content management systems and document management systems, the DSpace repository software serves a specific need as a digital archives system, focused on the long-term storage, access, and preservation of digital content.


## Build

If you have custom themes, you can add them to your `mirage2-themes` folder (for Mirage2-based themes) or `xmlui-themes`, then build a base image:

```console
docker build . --file Dockerfile.builder --tag njsl/dspace-docker:base-5.8
```

Then build your production image:

```console
docker build . --file Dockerfile.runner --tag njsl/dspace-docker:dspace-5.8
```

## Deploy

Set everything you need through ENV variables or your themes. Check out docker-compose.example.yml for an example.

## Handle server

This image includes a Handle server. If you don't have an existing Handle server set up, you can generate one through the `dspace` command:

```console
docker exec -it -u dspace dspace bin/dspace make-handle-config /dspace/handle-server
```

Once your Handle files are in place, use the `RUN_HDL` ENV variable to control the Handle server.

## Environment Variables
This image provides sane defaults for most settings but you can override many of those via environment variables, either with `-e` on the Docker command line or in your `docker-compose.yml`.

For example, by providing `-e` on the command line with `docker run`:

```console
$ docker run -itd --name dspace --network=dspace \
        -e POSTGRES_DB_HOST=my_host \
        -e POSTGRES_SCHEMA=my_dspace \
        -e POSTGRES_USER=my_user \
        -e POSTGRES_PASSWORD=my_password \
        -e CATALINA_OPTS="-Xms2048m -Xmx2048m -Dfile.encoding=UTF-8" \
        -p 8080:8080 dspace
```

Or inside your `docker-compose.yml` file:

```yaml
environment:
  - POSTGRES_DB_HOST=my_host
  - POSTGRES_SCHEMA=my_dspace
  - POSTGRES_USER=my_user
  - POSTGRES_PASSWORD=my_password
  - CATALINA_OPTS=-Xms2048m -Xmx2048m -Dfile.encoding=UTF-8
```

### DSpace URL control

  - `HTTP_HOSTNAME` (optional) The hostname at which you want to access DSpace (`localhost` by default)
  - `HTTP_PORT` (optional)     The port you want to use to access DSpace (`8080` by default)
  - `HTTP_SCHEME` (optional)   The HTTP protocol you want to use to access DSpace (`http` by default)
  - `DSPACE_UI` (optional)     The primary DSpace web UI (`xmlui` by default)
  - `DSPACE_URL` (optional)    the DSpace base URL (`${HTTP_HOSTNAME}/${DSPACE_UI}` by default)

### DSpace theme and other settings

  - `DSPACE_NAME` (optional)   A friendly name for your DSpace site (`"DSpace at My University"` by default)
  - `DSPACE_THEME` (optional)  The XMLUI theme to use for your DSpace site (`Mirage2` by default)
  - `HANDLE_PREFIX` (optional) The Handle prefix to use for new items on your DSpace site (`123456789` by default)

### Mail settings

  - `MAIL_SERVER` (optional)        The server to use for outgoing mail (`mail.example.com` by default)
  - `MAIL_PORT` (optional)          The port to use for outgoing mail (e.g. 25 or 587)
  - `MAIL_USERNAME` (optional)      The username to use when sending mail
  - `MAIL_PASSWORD` (optional)      The password to use when sending mail
  - `MAIL_FROM_ADDR` (optional)     The from address to use when sending mail
  - `MAIL_FEEDBACK_ADDR` (optional) The feedback email address
  - `MAIL_ADMIN_ADDR` (optional)    The email address for admin messages
  - `MAIL_ALERT_ADDR` (optional)    The email address for alerts
  - `MAIL_REG_ADDR` (optional)      The registration notification email

### Handle server control

  - `RUN_HDL` (optional) Set to `yes` to enable the Handle server. If the Handle server is not properly configured, may cause the container to crash.  (`no` by default)

### Debug mode

  - `DEBUG` (optional)   Set to `yes` to enable all possible logging at DEBUG level for troubleshooting. Not recommended for production use. (`no` by default)

### PostgreSQL Connection Parameters
To use an external PostgreSQL database or override any of the other default settings you have to set some environment variables:
  - `POSTGRES_DB_HOST` (required): The server host name or IP
  - `POSTGRES_DB_PORT` (optional): The server port (`5432` by default)
  - `POSTGRES_SCHEMA` (optional): The database schema (`dspace` by default)
  - `POSTGRES_USER` (optional): The user used by DSpace (`dspace` by default)
  - `POSTGRES_PASSWORD` (optional): The password of the user used by DSpace (`dspace` by default)
  - `POSTGRES_ADMIN_USER` (optional): The admin user creating the Database and the user (`postgres` by default)
  - `POSTGRES_ADMIN_PASSWORD` (optional): The password of the admin user

### DSpace Administrator User
Control the parameters used to create the default DSpace administrator's login account:
  - `ADMIN_EMAIL` (optional): The DSpace administrator's email address (`devops@1science.com` by default)
  - `ADMIN_FIRSTNAME` (optional): The DSpace administrator's first name (`DSpace` by default)
  - `ADMIN_LASTNAME` (optional): The DSpace administrator's last name (`Admin` by default)
  - `ADMIN_PASSWD` (optional): The DSpace administrator's password (`admin123` by default)
  - `ADMIN_LANGUAGE` (optional): The DSpace administrator's language (`en` by default)

### Configure Installed Webapps
Sometimes we don't really need all the DSpace webapps. You can specify which ones to enable using an environment variable:

```console
$ docker run -itd --name dspace --network=dspace \
        -e DSPACE_WEBAPPS="jspui xmlui rest" \
        -p 8080:8080 dspace
```

The command above only installs the `jspui`, `xmlui`, and `rest` web applications.

## Customizations in themes

This Docker image allows themes to bundle a number of customizations:

  - Custom files for the `config/spring` folder (e.g. to change sidebar options in XMLUI)
  - Custom files for the `config/modules` folder (to overwrite any settings in that folder)
  - Custom email templates
  - A custom `news-xmlui.xml` file
  - Changes or additions to `config/dspace.cfg`
  - Changes or additions to `i18n/messages.xml`

The goal of this fork is to allow ENV settings and theme customizations to cover 80% of DSpace installs without needing to fork the DSpace git repo

# Original message below

This image was originally based on the [1science/docker-dspace](https://github.com/1science/docker-dspace) image, but has diverged significantly to update for current Docker best practices, use the official Tomcat Docker image with a [modern Debian 9 base](https://github.com/docker-library/tomcat/blob/master/9.0/jre8/Dockerfile), and bump some dependency versions.

By default this will create a PostgreSQL database schema called `dspace`, with user `dspace` and password `dspace`. If you're running this in production you should obviously change these (see [PostgreSQL Connection Parameters](#postgresql-connection-parameters)).

After few seconds, the various DSpace web applications should be accessible from:
  - JSP User Interface: http://localhost:8080/jspui
  - XML User Interface: http://localhost:8080/xmlui
  - OAI-PMH Interface: http://localhost:8080/oai/request?verb=Identify
  - REST: http://localhost:8080/rest

*Note: the security constraint to tunnel request with SSL on the `/rest` endpoint has been removed, but it's very important to securize this endpoint in production through [Nginx](https://github.com/1science/docker-nginx) for example.*


## License
All the code contained in this repository, unless explicitly stated, is
licensed under ISC license.

A copy of the license can be found inside the [LICENSE](LICENSE) file.
