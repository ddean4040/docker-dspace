# What is DSpace?

![DSpace logo](logo.png)

[DSpace](https://wiki.duraspace.org/display/DSDOC5x/Introduction) is an open-source software package typically used for creating open-access repositories for scholarly/published digital content. While DSpace shares some feature overlap with content management systems and document management systems, the DSpace repository software serves a specific need as a digital archives system, focused on the long-term storage, access, and preservation of digital content.

This image is based on official [Java image](https://hub.docker.com/_/java/) and use [Tomcat](http://tomcat.apache.org/) to run DSpace as defined in the [installation guide](https://wiki.duraspace.org/display/DSDOC5x/Installing+DSpace).

# Usage
DSpace uses [PostgreSQL](http://www.postgresql.org/) as a database. We can either use a PostgreSQL container or an external database.

## Postgres as a container
First, we have to create a Docker network for the application container and PostgreSQL container to communicate over (this uses [Docker networks](https://docs.docker.com/engine/userguide/networking) instead of the legacy `link` behavior):

```console
$ docker network create dspace
```

Second, we have to create a PostgreSQL container (specifying the network to use):

```console
$ docker run -itd --name dspace_db --network=dspace -p 5432:5432 postgres:9.5
```

And finally, run create a DSpace container (specifying the network to use and the name of the PostgreSQL container):

```console
$ docker run -itd --name dspace --network=dspace -p 8080:8080 -e POSTGRES_DB_HOST=dspace_db dspace
```

By default the database schema is created with the name `dspace` for a user `dspace` with password `dspace`, but it's possible to override the default settings by specifying some environment variables, ie:

```console
$ docker run -itd --name dspace --network=dspace \
        -e POSTGRES_SCHEMA=my_dspace \
        -e POSTGRES_USER=my_user \
        -e POSTGRES_PASSWORD=my_password \
        -p 8080:8080 dspace
```

## External database  
To use an external PostgreSQL database you have to set some environment variables:
  - `POSTGRES_DB_HOST` (required): The server host name or ip.
  - `POSTGRES_DB_PORT` (optional): The server port (`5432` by default)
  - `POSTGRES_SCHEMA` (optional): The database schema (`dspace` by default)
  - `POSTGRES_USER` (optional): The user used by DSpace (`dspace` by default)
  - `POSTGRES_PASSWORD` (optional): The password of the user used by DSpace (`dspace` by default)
  - `POSTGRES_ADMIN_USER` (optional): The admin user creating the Database and the user (`postgres` by default)
  - `POSTGRES_ADMIN_PASSWORD` (optional): The password of the admin user

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

After few seconds, the various DSpace web applications should be accessible from:
  - JSP User Interface: http://localhost:8080/jspui
  - XML User Interface: http://localhost:8080/xmlui
  - OAI-PMH Interface: http://localhost:8080/oai/request?verb=Identify
  - REST: http://localhost:8080/rest

Note: The security constraint to tunnel request with SSL on the `/rest` endpoint has been removed, but it's very important to securize this endpoint in production through [Nginx](https://github.com/1science/docker-nginx) for example.

## Configure webapps installed
DSpace consumes a lot of memory and sometimes we don't really need all the DSpace webapps. You can specify which applications to install using an environment variable:

```console
$ docker run -itd --name dspace --network=dspace \
        -e DSPACE_WEBAPPS="jspui xmlui rest" \
        -p 8080:8080 dspace
```

The command above only installs the `jspui`, `xmlui`, and `rest` web applications.

# Todo

- Add a Tomcat configuration file
- Allow configuration of JAVA_OPTS for JVM memory heap

# License
All the code contained in this repository, unless explicitly stated, is
licensed under ISC license.

A copy of the license can be found inside the [LICENSE](LICENSE) file.
