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
Debian GNU/Linux 9.3 image. (Linux 4.9.60-linuxkit-aufs #1 SMP Mon Nov 6 16:00:12 UTC 2017)
- with OpenJDK Runtime Environment (build 1.8.0_151-8u151-b12-1~deb9u1-b12)
- with DSpace 5.8 on Tomcat 7.0.84
```

[DSpace](https://wiki.duraspace.org/display/DSDOC5x/Introduction) is an open-source software package typically used for creating open-access repositories for scholarly/published digital content. While DSpace shares some feature overlap with content management systems and document management systems, the DSpace repository software serves a specific need as a digital archives system, focused on the long-term storage, access, and preservation of digital content.

This image was originally based on the [1science/docker-dspace](https://github.com/1science/docker-dspace) image, but has diverged significantly to update for current Docker best practices, use the official Tomcat Docker image with a [modern Debian 9 base](https://github.com/docker-library/tomcat/blob/master/8.5/jre8/Dockerfile), and bump some dependency versions.

## Build
This image is not currently published on the public Docker hub—you will need to build it locally:

```console
$ docker build -f Dockerfile -t dspace .
```

*Note: this can take anywhere from thirty minutes to several hours (depending on your Internet connection) due to the amount of packages DSpace's maven build step pulls in.*

By default this container is set up to run on `localhost` in a development environment. If you need to run this in production you can override the hostname and proxy port—for example, if you're reverse proxying to Tomcat via nginx on port 80—at build time:

```console
$ docker build -f Dockerfile -t dspace --build-arg DSPACE_HOSTNAME=repo.example.org --build-arg DSPACE_PROXY_PORT=80 .
```

## Running With Docker Compose
Docker Compose simplifies the running of software stacks where you have several components in different containers that interact with eachother by allowing you to specify dependencies, environment variables, network settings, etc. Assuming you have built the `dspace` image above you should be able to bring up a working DSpace installation simply by typing:

```console
$ docker-compose up -d
```

By default this will create a PostgreSQL database schema called `dspace`, with user `dspace` and password `dspace`. If you're running this in production you should obviously change these (see [PostgreSQL Connection Parameters](#postgresql-connection-parameters)).

After few seconds, the various DSpace web applications should be accessible from:
  - JSP User Interface: http://localhost:8080/jspui
  - XML User Interface: http://localhost:8080/xmlui
  - OAI-PMH Interface: http://localhost:8080/oai/request?verb=Identify
  - REST: http://localhost:8080/rest

*Note: the security constraint to tunnel request with SSL on the `/rest` endpoint has been removed, but it's very important to securize this endpoint in production through [Nginx](https://github.com/1science/docker-nginx) for example.*

## Runing Manually
First, we have to create a Docker network for the application container and PostgreSQL container to communicate over (this uses [Docker networks](https://docs.docker.com/engine/userguide/networking) instead of the legacy `link` behavior):

```console
$ docker network create dspace
```

Second, we have to create a PostgreSQL container (specifying the network to use):

```console
$ docker run -itd --name dspace_db --network=dspace -p 5432:5432 postgres:9.5-alpine
```

And finally, create a DSpace container (specifying the network to use and the name of the PostgreSQL container):

```console
$ docker run -itd --name dspace --network=dspace -p 8080:8080 -e POSTGRES_DB_HOST=dspace_db dspace
```

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

## License
All the code contained in this repository, unless explicitly stated, is
licensed under ISC license.

A copy of the license can be found inside the [LICENSE](LICENSE) file.
