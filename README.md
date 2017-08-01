# What is DSpace?

![DSpace logo](logo.png)

[DSpace](https://wiki.duraspace.org/display/DSDOC5x/Introduction) is an open-source software package typically used for creating open-access repositories for scholarly/published digital content. While DSpace shares some feature overlap with content management systems and document management systems, the DSpace repository software serves a specific need as a digital archives system, focused on the long-term storage, access, and preservation of digital content.

This image was originally based on the [1science/docker-dspace](https://github.com/1science/docker-dspace) image, but has diverged significantly to update for current Docker best practices, use the official Tomcat Docker image with a [modern Debian 9 base](https://github.com/docker-library/tomcat/blob/master/9.0/jre8/Dockerfile), and bump some dependency versions.

## Build
This image is not currently published on the public Docker hub so you will need to build it locally before you can use it:

```console
$ docker build -f Dockerfile -t dspace .
```

*N.B. this can take anywhere from thirty minutes to several hours (depending on your Internet connection) due to the amount of packages DSpace's maven build step pulls in.*

## Run
First, we have to create a Docker network for the application container and PostgreSQL container to communicate over (this uses [Docker networks](https://docs.docker.com/engine/userguide/networking) instead of the legacy `link` behavior):

```console
$ docker network create dspace
```

Second, we have to create a PostgreSQL container (specifying the network to use):

```console
$ docker run -itd --name dspace_db --network=dspace -p 5432:5432 postgres:9.5
```

And finally, create a DSpace container (specifying the network to use and the name of the PostgreSQL container):

```console
$ docker run -itd --name dspace --network=dspace -p 8080:8080 -e POSTGRES_DB_HOST=dspace_db dspace
```

By default this will create a PostgreSQL database schema called `dspace`, with user `dspace` and password `dspace`. If you're running this in production you should obviously change these (see [Overriding PostgreSQL Connection Parameters](#overriding-postgresql-connection-parameters)).

After few seconds, the various DSpace web applications should be accessible from:
  - JSP User Interface: http://localhost:8080/jspui
  - XML User Interface: http://localhost:8080
  - OAI-PMH Interface: http://localhost:8080/oai/request?verb=Identify
  - REST: http://localhost:8080/rest

*Note: The security constraint to tunnel request with SSL on the `/rest` endpoint has been removed, but it's very important to securize this endpoint in production through [Nginx](https://github.com/1science/docker-nginx) for example.*

### Overriding PostgreSQL Connection Parameters
To use an external PostgreSQL database or override any of the other default settings you have to set some environment variables:
  - `POSTGRES_DB_HOST` (required): The server host name or IP
  - `POSTGRES_DB_PORT` (optional): The server port (`5432` by default)
  - `POSTGRES_SCHEMA` (optional): The database schema (`dspace` by default)
  - `POSTGRES_USER` (optional): The user used by DSpace (`dspace` by default)
  - `POSTGRES_PASSWORD` (optional): The password of the user used by DSpace (`dspace` by default)
  - `POSTGRES_ADMIN_USER` (optional): The admin user creating the Database and the user (`postgres` by default)
  - `POSTGRES_ADMIN_PASSWORD` (optional): The password of the admin user

Then run the DSpace container with the environment variables specified using `-e`, for example:

```console
$ docker run -itd --name dspace --network=dspace \
        -e POSTGRES_DB_HOST=my_host \
        -e POSTGRES_ADMIN_USER=my_admin \
        -e POSTGRES_ADMIN_PASSWORD=my_admin_password \
        -e POSTGRES_SCHEMA=my_dspace \
        -e POSTGRES_USER=my_user \
        -e POSTGRES_PASSWORD=my_password \
        -p 8080:8080 dspace
```

## Configure Installed Webapps
DSpace consumes a lot of memory and sometimes we don't really need all the DSpace webapps. You can specify which applications to install using an environment variable:

```console
$ docker run -itd --name dspace --network=dspace \
        -e DSPACE_WEBAPPS="jspui xmlui rest" \
        -p 8080:8080 dspace
```

The command above only installs the `jspui`, `xmlui`, and `rest` web applications.

## Todo

- Customize Tomcat connector to use `proxy_port`, `secure`, and `scheme`?
- Need to find a way to enable [cron jobs for DSpace maintenance tasks](https://wiki.duraspace.org/display/DSDOC5x/Scheduled+Tasks+via+Cron): see [cronjobConfiguration](https://github.com/GovernoRegionalAcores/DSpace)

## License
All the code contained in this repository, unless explicitly stated, is
licensed under ISC license.

A copy of the license can be found inside the [LICENSE](LICENSE) file.
