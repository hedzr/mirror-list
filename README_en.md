# Interesting translation about chinese tech posts



> 我很高兴搜索时意外地发现了英文翻译版。要知道，我的英文是很糟糕的。
>
> 
>
> 下面副本一下，不过这一次我不标注来源了，如果有疑问的话，issue我取消也没问题。
>
> 
>
> 其实，我就是觉得吧，这本来就是译本，反向翻译回去是不是有点多余？





## origin

About the installation of [docker-compose](https://developpaper.com/tag/docker-compose/), the basic introduction of [docker](https://developpaper.com/tag/docker/) is not within the scope of this article.

This article is basically a strict English translation of docker-compose YAML file format. That’s because yesterday I thought about scanning docker-compose orchestration.`${PWD}`As a result, Chinese is not helpful, or the official website has finally solved my ambiguity. So I think we should do a more rigorous translation and explanation to explain the details of docker-compose arrangement.

Following, we mainly introduce the details of docker-compose format version 3.

Reading this article, you should have a basic understanding of docker-compose, at least the basic early (version 2) format.

### About authorization

The translation is subordinate to the original https://docs.docker.com/compo…

The translation https://github.com/hedzr/docker-compose-file-format itself is distributed in MIT mode.

## Arrangement Format Version 3

### History

Version 3 is a format supported by docker-compose since the launch of docker-engine 1.13. Before that, docker introduced swarm mode in 1.12 to build virtual computing resources in a virtual network, and greatly improved the network and storage support of docker.

For the relationship between docker-compose format and docker-engine, the following table (extracted from the official website) has a clear contrast.

| **Compose file format** | **Docker Engine release** |
| :---------------------- | :------------------------ |
| 3.7                     | 18.06.0+                  |
| 3.6                     | 18.02.0+                  |
| 3.5                     | 17.12.0+                  |
| 3.4                     | 17.09.0+                  |
| 3.3                     | 17.06.0+                  |
| 3.2                     | 17.04.0+                  |
| 3.1                     | 1.13.1+                   |
| 3.0                     | 1.13.0+                   |
| 2.4                     | 17.12.0+                  |
| 2.3                     | 17.06.0+                  |
| 2.2                     | 1.13.0+                   |
| 2.1                     | 1.12.0+                   |
| 2.0                     | 1.10.0+                   |
| 1.0                     | 1.9.1.+                   |

### Arrangement file structure and examples

This is a typical file structure sample of Version 3+:

```
version: "3.7"
services:

  redis:
    image: redis:alpine
    ports:
      - "6379"
    networks:
      - frontend
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure

  db:
    image: postgres:9.4
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    deploy:
      placement:
        constraints: [node.role == manager]

  vote:
    image: dockersamples/examplevotingapp_vote:before
    ports:
      - "5000:80"
    networks:
      - frontend
    depends_on:
      - redis
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
      restart_policy:
        condition: on-failure

  result:
    image: dockersamples/examplevotingapp_result:before
    ports:
      - "5001:80"
    networks:
      - backend
    depends_on:
      - db
    deploy:
      replicas: 1
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure

  worker:
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 1
      labels: [APP=VOTING]
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
        window: 120s
      placement:
        constraints: [node.role == manager]

  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    stop_grace_period: 1m30s
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]

networks:
  frontend:
  backend:

volumes:
  db-data:
```

In this sample, the top-level structure is determined by`version`，`services`，`networks`，`volumes`And so on label composition. This is not much different from Version 2.

stay`services`In this chapter, you can define several services, each of which usually runs a container. These services form a whole stack of facilities, or a service group.

Generally speaking, we will arrange a bunch of miscellaneous things, such as a bunch of micro-services, into a service stack, so that they can serve the outside world as a whole, thus avoiding the exposure of details. We can also enhance the flexibility of architecture design and scale the whole service stack (instead of dealing with a large number of micro-services one by one).

## Format Manual-`service` 

Next comes the chapter structure that a reference manual should have. We list the instructions for service choreography in alphabetical order, such as`ports`，`volumes`，`cmd`，`entry`Wait.

### `build`

This option is used for construction.

`build`It can be a path string pointing to the construction context, such as:

```
version: "3.7"
services:
  webapp:
    build: ./dir
```

It can also be a more detailed definition. This includes`context`Path specified by item, and optional`dockerfile`File and build parameters`args`：

```
version: "3.7"
services:
  webapp:
    build:
      context: ./dir
      dockerfile: Dockerfile-alternate
      args:
        buildno: 1
```

If you are appointing`build`It is also specified.`image`Then the result of the build will be marked with the corresponding name, as if`docker build -t container-name:tag dir`Do as follows:

```
    build: "./dir"
    image: "company/webapp:v1.1.9"
```

> For YAML, the safe way to avoid ambiguity is to surround the string with quotation marks.

The example above will be found.`./dir`Build context in folders (by default, find`Dockerfile`) And complete the build, and finally mark it as`company/webapp`Name, and`v1.1.9`Tag.

#### `context`

It can be a inclusion`Dockerfile`A folder can also be a URL to git repository.

If a relative path is specified, the path is relative to`docker-compose.yml`Documentation. This path will also be sent to Docker daemon for construction.

Docker-compose initiates build actions and tags build results (as per`image`After that, use it according to the corresponding name.

#### `dockerfile`

You can specify a different name from the default`Dockerfile`Other filenames are used for building. Note that you must also specify a path to`context`：

```
    build:
      context: .
      dockerfile: Dockerfile-alternate
```

#### `args`

Specify build parameters. Usually refers to the parameters used for construction (see Dockerfile)`ARG`）。

The following is a brief overview:

First, specify parameters in Dockerfile:

```
ARG buildno
ARG gitcommithash

RUN echo "Build number: $buildno"
RUN echo "Based on commit: $gitcommithash"
```

Then specify the actual value of the build parameter (either an incoming Map or an array is possible):

```
  build:
    context: .
    args:
      buildno: 1
      gitcommithash: cdc3b19
```

Or:

```
build:
  context: .
  args:
    - buildno=1
    - gitcommithash=cdc3b19
```

> **NOTE**In Dockerfile, if`FROM`Previously specified`ARG`Well, this one`ARG`For the following`FROM`Closures are invalid.
>
> Multiple`FROM`Several constructed closures were cut out.
>
> To want to`ARG`In each`FROM`It works in closures, and you need to specify it in each closure.
>
> More detailed discussions are included in Understand how ARGS and FROM interact.

You can skip specifying build parameters. At this point, the actual value of this parameter depends on the environment at build time.

```
  args:
    - buildno
    - gitcommithash
```

> **NOTE**Boolean quantity of YAML（`true`, `false`, `yes`, `no`, `on`, `off`) Quotation marks must be surrounded for docker-compose to handle correctly.

#### `cache_from`

> since v3.2

Specifies a list of images for cache resolution.

```
build:
  context: .
  cache_from:
    - alpine:latest
    - corp/web_app:3.14
```

#### `labels`

> since v3.3

Adding metadata labels to the built image can be an array or a dictionary.

We recommend the use of reverse DNS annotative prefixes to prevent conflicts between your label and the user’s label:

```
build:
  context: .
  labels:
    com.example.description: "Accounting webapp"
    com.example.department: "Finance"
    com.example.label-with-empty-value: ""

# anothor example
build:
  context: .
  labels:
    - "com.example.description=Accounting webapp"
    - "com.example.department=Finance"
    - "com.example.label-with-empty-value"
```

#### `shm_size`

> since v3.5

Setting up when building containers`/dev/shm`Partition size. Integer format is expressed in bytes, but byte value can also be used:

```
build:
  context: .
  shm_size: '2gb'

build:
  context: .
  shm_size: 10000000
```

#### `target`

> since v3.4

Build definitions and specific steps in Dockerfile (Stage), refer to multi-stage build docs:

```
build:
  context: .
  target: prod
```

> Multiple builds are typically used for CI/CD.
>
> For example, step 0 can be named`builder`Step 1 extracts the target file from Step 0 for deployment packaging and generates the final container image. Then the middle layer of Step 0 is discarded. These middle layers will not appear in the final container image, thus effectively reducing the size of the final container image. The result is also semantically and logically consistent.
>
> ```
> FROM golang:1.7.3 AS builder
> WORKDIR /go/src/github.com/alexellis/href-counter/
> RUN go get -d -v golang.org/x/net/html  
> COPY app.go    .
> RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .
> 
> FROM alpine:latest  
> RUN apk --no-cache add ca-certificates
> WORKDIR /root/
> COPY --from=builder /go/src/github.com/alexellis/href-counter/app .
> CMD ["./app"]  
> ```
>
> 

### `cap_add`, `cap_drop` 

Add or remove the Linux capabilities of containers. A complete list can be consulted.`man 7 capabilities`。

```
cap_add:
  - ALL

cap_drop:
  - NET_ADMIN
  - SYS_ADMIN
```

> **NOTE**These options are ignored when deploying a stack to swarm mode.
>
> See also deploying a stack in swarm mode.

Linux capability mechanism is largely a security mechanism. The specific meaning, usage and extension belong to the category of Linux operating system, and will not be further elaborated.

### `cgroup_parent`

Optionally assign a superior to the container`cgroup`。`cgroup`It is also one of the most important basic concepts of Linux container implementation.

```
cgroup_parent: m-executor-abcd
```

> **NOTE**These options are ignored when deploying a stack to swarm mode.
>
> See also deploying a stack in swarm mode.

### `command`

Overlay the default in the container`command`.

```
command: bundle exec thin -p 3000
```

`command`It can also be specified as a list. In fact, it’s also a more recommended approach, unambiguous and secure, and consistent with the format in [dockerfile]:

```
command: ["bundle", "exec", "thin", "-p", "3000"]
```

### configs

Provide specific access to each service`config`Permissions.

One`config`Contains a series of configuration information that may be created in a variety of ways. When the deployment of containers refers to these configurations, problems such as production environment parameters can be better partitioned. On the other hand, sensitive information can be separated into a secure area, which reduces the possibility of leakage to a certain extent.

> **NOTE**The specified configuration must already exist or be defined at the top level`configs`Defined in the top-level`configs`Configuration). Otherwise, the deployment of the entire container stack will fail.

Two different grammatical variants are supported. More detailed information should refer to configs.

#### Short format

Specify only the configuration name. Containers therefore have access to the configuration`/<config_name`And mount it (both source and target mounted are the configuration name).

```
version: "3.7"
services:
  redis:
    image: redis:latest
    deploy:
      replicas: 1
    configs:
      - my_config
      - my_other_config
configs:
  my_config:
    file: ./my_config.txt
  my_other_config:
    external: true
```

The example above uses a short format in`redis`Container services are defined`my_config`and`my_other_config`Quotation. There`my_config`Specify as a host file`./my_config.txt`And`my_other_config`Designated as external (resources), which means that the corresponding resources have been defined in Docker, perhaps through`docker config create`Established or deployed by other container stacks.

If external resources are not found, the deployment of the container stack will fail and throw one`config not found`Mistakes.

> **Note**: `config`Definitions are supported only in the docker-compose format of v3.3 and later.

#### Long format

Long format provides more information to express one`config`Where, how to be found, how to be used:

- `source`Configuration name

- `target`The configuration will be mounted to the path in the container. Default is`/<source>`

- `uid` & `gid`Linux/Unix for digital values`UID`and`GID`If not specified, 0. Windows does not support it.

- ```
  mode
  ```

  8-digit file permissions. The default value is

  ```
  0444
  ```

  。

  

  Configurations are not writable because they are mounted on temporary file systems. So if you set a write license, it will be ignored.

  Executable bits can be set.

The following example is similar to the short format example:

```
version: "3.7"
services:
  redis:
    image: redis:latest
    deploy:
      replicas: 1
    configs:
      - source: my_config
        target: /redis_config
        uid: '103'
        gid: '103'
        mode: 0440
configs:
  my_config:
    file: ./my_config.txt
  my_other_config:
    external: true
```

Ad locum,`redis`Container services are not accessed`my_other_config`。

You can authorize a service to access multiple configurations, or you can mix long and short formats.

Define a configuration (at the top level)（`config`) It does not imply that a service can be accessed.

### `container_name`

Specify a custom container name instead of a default generated by docker-compose itself.

```
container_name: my-web-container
```

Because the Docker container name must be unique, you cannot scale a service that customizes the container name.

> **NOTE**These options are ignored when deploying a stack to swarm mode.
>
> See also deploying a stack in swarm mode.

### `credential_spec`

> since v3.3
>
> Since v3.8, support has been provided for the gMSA (group Managed Service Account) approach used for group management service accounts.

Configure credentials for controlled service accounts. This option is only used for Windows Container Services.`credential_spce`Format only`file://<filename>` or `registry://<value-name>`。

When used`file:`When the reference file must be placed in the Docker data folder (usually`C:\ProgramData\Docker\`）的`CredentialSpec`Under the subdirectory. The following example will be from`C:\ProgramData\Docker\CredentialSpecs\my-credential-sp`Load credential information:

```
credential_spec:
  file: my-credential-spec.json
```

When used`registry:`Credential information will be read from the Windows Registry of the Docker daemon host. A registry entry must be located at:

```
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\Containers\CredentialSpecs
```

In

The following example is read in`my-credential-spec`Registry key values:

```
credential_spec:
  registry: my-credential-spec
```

#### GMSA configuration example

When configuring gMSA credentials for a service, refer to the following example:

```
version: "3.8"
services:
  myservice:
    image: myimage:latest
    credential_spec:
      config: my_credential_spec

configs:
  my_credentials_spec:
    file: ./my-credential-spec.json|
```

### `depends_on`

Represents the dependencies between services. Service dependency triggers the following behavior:

- `docker-compose up`Start the service in sequence of dependencies. In the following example,`db`and`redis`Precede`web`Be activated.
- `docker-compose up SERVICE`Automatically included`SERVICE`Dependencies of the ___________. In the following example,`docker-compose up web`Will start automatically`db`and`redis`。
- `docker-compose stop`Stop the service in order of dependency. In the following example,`web`Will be preceded by`db`and`redis`Be stopped.

A simple example is as follows:

```
version: "3.7"
services:
  web:
    build: .
    depends_on:
      - db
      - redis
  redis:
    image: redis
  db:
    image: postgres
```

> Use`depends_on`Several things should be paid attention to:
>
> - `depends_on`It doesn’t mean waiting.`db`and`redis`Start after you are ready`web`It starts after they are started.`web`。 If you want to wait until the service is ready to be available, you should refer to Controlling startup order.
> - Version 3 is no longer supported`condition`Expression.
> - `depends_on`Options are ignored when deployed to swarm mode.
>
> See also deploying a stack in swarm mode.

### `deploy`

> **Version 3 only.**

Specify and deploy and run related configurations.

It only affects the deployment to a swarm using docker stack deployment.

stay`docker-compose up`and`docker-compose run`It was overlooked.

```
version: "3.7"
services:
  redis:
    image: redis:alpine
    deploy:
      replicas: 6
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure
```

Several sub-options are available:

#### `endpoint_mode`

swarm.

> **Version 3.3 only.**

- ```
  endpoint_mode: vip
  ```

  – Docker requests a virtual IP for the service（

  ```
  VIP
  ```

  ) Used for access.

  

  Docker routes requests automatically between the client and the service’s valid working nodes. The client does not need to know how many nodes are available for the service, nor does it need to know the IP address and port number of the service node.

  This is the default way.

- `endpoint_mode: dnsrr`– DNS round-robin (DNSRR) algorithm is used for service discovery. Docker sets up a DNS entry for the service, so a list of IP addresses is returned through the service name when the corresponding DNS resolution is performed. Clients therefore directly select a specific endpoint for access.

```
version: "3.7"

services:
  wordpress:
    image: wordpress
    ports:
      - "8080:80"
    networks:
      - overlay
    deploy:
      mode: replicated
      replicas: 2
      endpoint_mode: vip

  mysql:
    image: mysql
    volumes:
       - db-data:/var/lib/mysql/data
    networks:
       - overlay
    deploy:
      mode: replicated
      replicas: 2
      endpoint_mode: dnsrr

volumes:
  db-data:

networks:
  overlay:
```

`endpoint_mode`The option of swarm mode is also used as the command line option (see`docker service create`) For a quick list of docker swarm commands, you can refer to Swarm mode CLI commands.

To learn more about swarm mode’s network model and service discovery mechanism, see Configure service discovery.

#### `labels`

Specify labels for services. These tags are only applied to the corresponding service, not to the container or container instance of the service.

```
version: "3.7"
services:
  web:
    image: web
    deploy:
      labels:
        com.example.description: "This label will appear on the web service"
```

To set labels for containers, the`deploy`Specify services beyond`labels`：

```
version: "3.7"
services:
  web:
    image: web
    labels:
      com.example.description: "This label will appear on all containers for the web service"
```

#### `mode`

Could be`global`or`replicated`。`global`Represents strictly a swarm node running a service.`replicated`Represents that multiple container instances can be run. The default is`replicated`。

Refer to Replicated and Global Services under the swarm theme.

```
version: "3.7"
services:
  worker:
    image: dockersamples/examplevotingapp_worker
    deploy:
      mode: global
```

#### `placement`

Specify constraints and preferences.

Refer to the documentation of docker service establishment for more information about constraints and preferences, including the corresponding grammar, available types, and so on.

```
version: "3.7"
services:
  db:
    image: postgres
    deploy:
      placement:
        constraints:
          - node.role == manager
          - engine.labels.operatingsystem == ubuntu 14.04
        preferences:
          - spread: node.labels.zone
```

#### `replicas`

If the service is`replicated`,`replicas`Specifies a value for it, which indicates how many container instances can be run on a swarm node at most.

```
version: "3.7"
services:
  worker:
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 6
```

#### `resources`

Configuration resource constraints.

> **NOTE**For non-swarm mode, this table entry replaces older resource constraint options (such as`cpu_shares`, `cpu_quota`, `cpuset`, `mem_limit`, `memswap_limit`, `mem_swappiness`Table entries waiting before version 3.
>
> It is described in Upgrading version 2.x to 3.x.

These resource constraint table entries all have a single value, equivalent to`docker service create`The equivalents in the.

In the following example,`redis`Services are constrained to not use more than 50M of memory, 50% CPU usage per single core, while retaining 20M of memory and 25% CPU usage as benchmarks.

```
version: "3.7"
services:
  redis:
    image: redis:alpine
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 50M
        reservations:
          cpus: '0.25'
          memory: 20M
```

The following topics describe the available options for service or container resource constraints in a swarm scenario.

##### Out Of Memory Exceptions (OOME)

If you attempt to use more memory than the system has in your service and container instances, you will get Out of Memory Exception (OOME). At this point, a container instance, or Docker daemon, may be cleaned up by the OOM manager of the kernel.

To prevent this from happening, make sure that your application uses memory legally and efficiently. For such risks, consult Understand the risks of running out of memory for further assessment instructions.

#### `restart_policy`

Indicates how to restart a container instance when it exits. replace`restart`：

- `condition`It can be`none`, `on-failure`or`any`(by default)`any`)
- `delay`Waiting time before attempting to restart (default is 0). A duration should be specified for it.
- `max_attempts`Trying to restart how many times and then giving up the attempt to restart. The default is not to give up.
- `window`To determine whether a reboot is successful, you need to wait a long time. The default is that no waiting is immediately recognized as successful. A duration should be specified for it.

```
version: "3.7"
services:
  redis:
    image: redis:alpine
    deploy:
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
```

#### `rollback_config`

> Version 3.7 file format and up

How should the service roll back in a scenario where rolling updates fail:

- `parallelism`Number of containers rolled back at the same time. If set to 0, all containers will be rolled back at the same time.
- `delay`Waiting time before each container group is rolled back (default is 0)
- `failure_action`An action that should be performed when a rollback fails. Could be`continue`or`pause`(by default)`pause`）
- `monitor`The failed rollback status is updated to the monitor cycle（`ns|us|ms|s|m|h`Default is`0s`。
- `max_failure_ratio`Tolerable percentage of failures when rollback occurs (default is 0)
- `order`Rollback operation sequence. Can be`stop-first`or`start-first`(by default)`stop-first`）

#### `update_config`

Indicates how the service should be updated. This is useful for configuring scrolling updates:

- `parallelism`Number of containers updated at the same time. If set to 0, all containers will be rolled back at the same time.
- `delay`Waiting time before each container group is updated (default is 0)
- `failure_action`An action that should be performed when an update fails. Could be`continue`or`pause`(by default)`pause`）
- `monitor`The failed update status is updated to the monitor cycle（`ns|us|ms|s|m|h`Default is`0s`。
- `max_failure_ratio`Tolerable percentage of failures when updating (default 0)
- `order`Update the order of operation. Can be`stop-first`or`start-first`(by default)`stop-first`）

> **NOTE**：`order`Valid only after v3.4.

```
version: "3.7"
services:
  vote:
    image: dockersamples/examplevotingapp_vote:before
    depends_on:
      - redis
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
        delay: 10s
        order: stop-first
```

#### NOT SUPPORTED FOR `DOCKER STACK DEPLOY` 

The following sub-options (for`docker-compose up`and`docker-compose run`Supported)`docker stack deploy`Unsupported:

- build
- cgroup_parent
- container_name
- devices
- tmpfs
- external_links
- links
- network_mode
- restart
- security_opt
- sysctls
- userns_mode

> **Tip:** See the section on how to configure volumes for services, swarms, and docker-stack.yml files. Volumes *are* supported but to work with swarms and services, they must be configured as named volumes or associated with services that are constrained to nodes with access to the requisite volumes.

### `devices`

List of devices to be mapped. Its usage and docker command`--device`The same.

```
devices:
  - "/dev/ttyUSB0:/dev/ttyUSB0"
```

> **NOTE**These options are ignored when deploying a stack to swarm mode.
>
> See also deploying a stack in swarm mode.

### `dns`

Customize DNS server list. You can specify a single value or a list.

```
dns: 8.8.8.8
dns:
  - 8.8.8.8
  - 9.9.9.9
```

### `dns_search`

Customize DNS search domain name. You can specify a single value or a list.

```
dns_search: example.com
dns_search:
  - dc1.example.com
  - dc2.example.com
```

### `entrypoint`

Override the default entrypoint value defined in the dockerfile.

```
entrypoint: /code/entrypoint.sh
```

The entry point can also be a list:

```
entrypoint:
    - php
    - -d
    - zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20100525/xdebug.so
    - -d
    - memory_limit=-1
    - vendor/bin/phpunit
```

> **NOTE**Set up a`entrypoint`Not only does it cover anything in Dockerfile`ENTRYPOINT`Default value, also cleans up any of the Dockerfile`CMD`Default value. So in Dockerfile`CMD`It will be ignored.

### `env_file`

Introduce environment variable values from a given file. It can be a single value or a list.

```
env_file: .env
env_file:
  - ./common.env
  - ./apps/web.env
  - /opt/secrets.env
```

about`docker-compose -f FILE`For example,`env_file`The path is relative to`FILE`The one in the folder.

stay`environment`The environment variables declared in this statement will override the values introduced here.

In the corresponding file, each line should be used`VAR=VAL`Format defines an environment variable. The first line is`#`Represents a comment line, which is ignored as a blank line.

```
# Set Rails/Rack environment
RACK_ENV=development
```

> **NOTE**If the service is defined`build`Items, in the construction process, are`env_file`The environment variables defined are not visible. Only use`build`Suboptions`args`Define the value of the environment variable at build time.

`VAL`The value is used as it is and cannot be modified. For example, if the value is surrounded by quotation marks, then quotation marks are also included in the representation of the value.

The order of environment variable files also needs to be noted. The value of the variable defined in the environment variable file at the back of the location overrides the old value defined earlier.

### `environment`

Add environment variables. You can use an array or a dictionary. Any Boolean quantities: true, false, yes, no, etc. must be surrounded by quotation marks as string literals.

Value values of environment variables with only key values depend on the host environment of the docker-compose runtime, which is useful for preventing sensitive information leakage.

```
environment:
  RACK_ENV: development
  SHOW: 'true'
  SESSION_SECRET:
environment:
  - RACK_ENV=development
  - SHOW=true
  - SESSION_SECRET
```

> **NOTE**If the service is defined`build`Items, in the construction process, are`env_file`The environment variables defined are not visible. Only use`build`Suboptions`args`Define the value of the environment variable at build time.

### `expose`

Expose ports to linked services. These ports will not be published to the host. Only internal ports can be specified for exposure.

```
expose:
 - "3000"
 - "8000"
```

### `external_links`

Will be in`docker-compose.yml`Containers started outside are linked to a given service.

And legacy options`links`It has similar semantics.

```
external_links:
 - redis_1
 - project_db_1:mysql
 - project_db_1:postgresql
```

> **NOTE**These options are ignored when deploying a stack to swarm mode.
>
> See also deploying a stack in swarm mode.

The more recommended approach is through`networks`Construct a subnet to link containers.

### `extra_hosts`

Add host name mapping. These mappings will be added`/etc/hosts`Medium. This function is equivalent to command line parameters`--add-host`。

```
extra_hosts:
 - "somehost:162.242.195.82"
 - "otherhost:50.31.209.229"
```

### `healthcheck`

> since v2.1

Used to confirm whether a service is “healthy”. See HEALTHCHECK Docker file instruction.

```
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost"]
  interval: 1m30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

`interval`, `timeout`and`start_period`It should be designated durations.

> **Note**: `start_period`Only available in v3.4 and beyond.

`test`Must be a single string value or a list. If it’s a list, the first item must be`NONE`, `CMD`, `CMD-SHELL`One of. If it’s a string, it implicitly represents a string`CMD-SHELL`Prefix.

```
# Hit the local web app
test: ["CMD", "curl", "-f", "http://localhost"]
```

As in the above example, but implicitly invoked`/bin/sh`It is equivalent to the following form.

```
test: ["CMD-SHELL", "curl -f http://localhost || exit 1"]
test: curl -f https://localhost || exit 1
```

To disable any default health check directions specified in the image, use`disable: true`。 This and specify`test: ["NONE"]`It is equivalent.

```
healthcheck:
  disable: true
```

### `image`

Specify the name of the image.

```
image: redis
image: ubuntu:14.04
image: tutum/influxdb
image: example-registry.com:4000/postgresql
image: a4bc65fd
```

If the image does not exist on the host, Compose will try to drop it down unless you specify it as well.`build`Item.

### `init`

> since v3.7

Run an init process in the container and forward the signal. Set to`true`Enabling this feature for service.

```
version: "3.7"
services:
  web:
    image: alpine:latest
    init: true
```

> The default init process uses the binary execution file Tini, which will be installed in the location of the daemon host as needed`/usr/libexec/docker-init`。 You can also configure daemon to use a different binary file by`init-path`Refer to configuration option.

### `isolation`

Specify the isolation level/technology for a container. In Linux, only support`default`Value. In Windows, acceptable values are:`default`, `process`and`hyperv`。

### `labels`

Add metadata labels to the container, refer to Docker labels. You can specify an array or a dictionary for it.

We recommend that you use reverse DNS tagging to define your tags, which can effectively avoid tag name conflicts.

```
labels:
  com.example.description: "Accounting webapp"
  com.example.department: "Finance"
  com.example.label-with-empty-value: ""
labels:
  - "com.example.description=Accounting webapp"
  - "com.example.department=Finance"
  - "com.example.label-with-empty-value"
```

### `links`

> It’s already a legacy feature. It will be removed in the near future.

Link another service to this container. Service names and link aliases can be developed simultaneously（`SERVICE:ALIAS`You can also skip the link alias.

```
web:
  links:
   - db
   - db:database
   - redis
```

The service that has been chained in will be the host name (that is, the link alias).`ALIAS`) Accessible.

Links are not necessary for inter-service communication. By default, any service can access other services by service name. See Links topics in Networking in Compose.

Links also indicate a dependency, but this is already the case`depends_on`Tasks, so links are not necessary.

### `logging`

Specify the log forwarding configuration for the service.

```
logging:
  driver: syslog
  options:
    syslog-address: "tcp://192.168.0.42:123"
```

`driver`The driver name is specified. This and`--log-driver`It is equivalent. The default value is`json-file`。

```
driver: "json-file"
driver: "syslog"
driver: "none"
```

The available forwarding drivers can be referred to at https://docs.docker.com/confi…

Use`option`Specify driver options as follows`--log-opt`That way. For example`syslog`This specifies:

```
driver: "syslog"
options:
  syslog-address: "tcp://192.168.0.42:123"
```

The default log forwarding driver is`json-file`。 For this purpose, you can specify the log cutting size and the maximum number of log history files to maintain:

```
version: "3.7"
services:
  some-service:
    image: some-service
    logging:
      driver: "json-file"
      options:
        max-size: "200k"
        max-file: "10"
```

### `network_mode`

Network model.

and`--network`The values are the same. But additional support`service:[service name]`Pattern.

```
network_mode: "bridge"
network_mode: "host"
network_mode: "none"
network_mode: "service:[service name]"
network_mode: "container:[container name/id]"
```

> **NOTE**These options are ignored when deploying a stack to swarm mode.
>
> See also deploying a stack in swarm mode.
>
> **NOTE**: `network_mode: "host"`You can’t mix it with links.

### `networks`

The network to join. The target network is`docker-compose.yml`Top-level`networks`Defined in the item.

```
services:
  some-service:
    networks:
     - some-network
     - other-network
```

#### ALIASES

Specify an alias for the service (that is, the host name) in the network. Other containers in the same network can use service names or service aliases to connect to container instances of the service.

Since`aliases`Is within the scope of the network, the same service in different networks can have different aliases.

```
services:
  some-service:
    networks:
      some-network:
        aliases:
         - alias1
         - alias3
      other-network:
        aliases:
         - alias2
```

A more complex and complete example:

```
version: "3.7"

services:
  web:
    image: "nginx:alpine"
    networks:
      - new

  worker:
    image: "my-worker-image:latest"
    networks:
      - legacy

  db:
    image: mysql
    networks:
      new:
        aliases:
          - database
      legacy:
        aliases:
          - mysql

networks:
  new:
  legacy:
```

#### IPV4_ADDRESS, IPV6_ADDRESS

Specify a static IP address.

Note that in the corresponding top-level network configuration, there must be`ipam`The block configures the subnet and the static IP address conforms to the definition of the subnet.

> If IPv6 addressing is desired, the `enable_ipv6` option must be set, and you must use a version 2.x Compose file. *IPv6 options do not currently work in swarm mode*.

An example is:

```
version: "3.7"

services:
  app:
    image: nginx:alpine
    networks:
      app_net:
        ipv4_address: 172.16.238.10
        ipv6_address: 2001:3984:3989::10

networks:
  app_net:
    ipam:
      driver: default
      config:
        - subnet: "172.16.238.0/24"
        - subnet: "2001:3984:3989::/64"
```

### `pid`

```
pid: "host"
```

Set up the service to use the host’s PID mode. This enables the service process in the container and the host operating system level to share the PID address space. This is a typical Linux/Unix operating system concept, so it’s not covered here. Such sharing can enable secure IPC communication with the help of PID address space.

### `ports`

Expose the port to the host.

> **Note**Port Exposure Function and`network_mode: host`Not compatible.

### Short format

Host and container ports can be specified at the same time（`HOST:CONTAINER`) To complete the mapping, you can also specify only container ports to automatically map to~~Same host port~~A temporary port (from 32768).

```
ports:
 - "3000"
 - "3000-3005"
 - "8000:8000"
 - "9090-9091:8080-8081"
 - "49100:22"
 - "127.0.0.1:8001:8001"
 - "127.0.0.1:5000-5010:5000-5010"
 - "6060:6060/udp"
```

#### Long format

Lengthy definitions are allowed:

```
ports:
  - target: 80
    published: 8080
    protocol: tcp
    mode: host
```

> The significance is obvious, so skip the explanation.
>
> **NOTE**Long format is valid only after v3.2.

### `restart`

`no`It is the default restart policy. No matter how the container exits or fails, it will not be restarted automatically.

Appoint`always`In any case, the container will be restarted.

`on-failure`Policies can be restarted only when the container fails to exit.

```
restart: "no"
restart: always
restart: on-failure
restart: unless-stopped
```

> **NOTE**These options are ignored when deploying a stack to swarm mode. (At this point, you can use`restart_policy`To achieve the goal)
>
> See also deploying a stack in swarm mode.

### `secrets`

From each service configuration, authorize access to the top level`secrets`Defined table entries. Supports two formats, length and length.

#### Short format

Short formats specify only the names of sensitive content. This enables the container to mount the corresponding content to`/run/secrets/<secret_name>`Location and access it.

The following example uses a short format to let`redis`Can access`my_secret`and`my_other_secret`。`my_secret`Specific content is defined in`./my_secret.txt`，`my_other_secret`Defined as external resources, such as through`docker secret create`The way is predefined. If no corresponding external resource is found, stack deployment will fail and throw one`secret not found`Mistake.

```
version: "3.7"
services:
  redis:
    image: redis:latest
    deploy:
      replicas: 1
    secrets:
      - my_secret
      - my_other_secret
secrets:
  my_secret:
    file: ./my_secret.txt
  my_other_secret:
    external: true
```

#### Long format

Long formats can define more precisely how sensitive content is used in stack contexts.

- `source`Names of sensitive content defined in Docker.
- `target`To be mounted in a container`/run/secrets/`File name in. Use if not specified`source`Name.
- `uid` & `gid`The UID and GID of the files mounted in the container. If not specified, 0. Invalid in Windows.
- `mode`Octal permissions for files mounted in containers. Default value in Docker 1.13.1`0000`But in the updated version`0444`。 The mounted file is not writable. Execution bits can be set, but in general they don’t make sense.

Here is an example:

```
version: "3.7"
services:
  redis:
    image: redis:latest
    deploy:
      replicas: 1
    secrets:
      - source: my_secret
        target: redis_secret
        uid: '103'
        gid: '103'
        mode: 0440
secrets:
  my_secret:
    file: ./my_secret.txt
  my_other_secret:
    external: true
```

Long and short formats can be mixed up if you define multiple sensitive content.

### `security_opt`

Override the default tag semantics for each container.

```
security_opt:
  - label:user:USER
  - label:role:ROLE
```

Usually this is related to seccomp, which is a lengthy topic related to security configuration, so don’t expand here.

> **NOTE**These options are ignored when deploying a stack to swarm mode. (At this point, you can use`restart_policy`To achieve the goal)
>
> See also deploying a stack in swarm mode.

### stop_grace_period

Specify a waiting time if the container fails to block`SIGTERM`Signal (or through)`stop_signal`The other signals defined) shut themselves down normally, and then force the removal of the corresponding process of the container instance long after that time (via`SIGKILL`Signal).

```
stop_grace_period: 1s
stop_grace_period: 1m30s
```

By default, it will wait 10 seconds.

### `stop_signal`

Set an alternate signal to close the container instance normally. Use by default`SIGTERM`Signal.

```
stop_signal: SIGUSR1
```

### `sysctls`

Set the kernel parameters for the container. You can use an array or dictionary.

```
sysctls:
  net.core.somaxconn: 1024
  net.ipv4.tcp_syncookies: 0
sysctls:
  - net.core.somaxconn=1024
  - net.ipv4.tcp_syncookies=0
```

> **NOTE**These options are ignored when deploying a stack to swarm mode. (At this point, you can use`restart_policy`To achieve the goal)
>
> See also deploying a stack in swarm mode.

### `tmpfs`

> since v2

Mount a temporary file system into the container. It can be a single value or a list.

```
tmpfs: /run
tmpfs:
  - /run
  - /tmp
```

> **NOTE**These options are ignored when deploying a stack to swarm mode. (At this point, you can use`restart_policy`To achieve the goal)
>
> See also deploying a stack in swarm mode.

> since v3.6

Mount a temporary file system into the container. The Size parameter specifies the byte size of the file system size. The default value is infinite.

```
 - type: tmpfs
     target: /app
     tmpfs:
       size: 1000
```

### `ulimits`

Overrides the default ulimits value specified in the container. You can specify an integer as a single limit limit or a mapping to represent soft / hard limit limits, respectively.

```
ulimits:
  nproc: 65535
  nofile:
    soft: 20000
    hard: 40000
```

### `userns_mode`

```
userns_mode: "host"
```

Disable user namespace. If Docker daemon is configured to run in a user namespace.

> **NOTE**These options are ignored when deploying a stack to swarm mode. (At this point, you can use`restart_policy`To achieve the goal)
>
> See also deploying a stack in swarm mode.

### `volumes`

Mount the host path or named volume.

You can mount a host path to a service without having to be at the top level`volumes`It is defined.

If you want to reuse one volume to multiple services, you should be at the top level`volumes`Define it and name it.

Named volumes can be used in services, swarms, and stack files.

> **NOTE**At the top`volumes`Define a named volume in a service`volumes`Refer to it in the list.
>
> Early`volumes_from`No longer in use.
>
> Refer to Use volumes and Volume Plugins.

The following example illustrates a named volume`my_data`And used for`web`Service. stay`web`A host folder is also used in the`./static`To mount in a container; to mount in a container.`db`It mounts a host file to the corresponding file in the container and uses another named volume.`dbdata`。

```
version: "3.7"
services:
  web:
    image: nginx:alpine
    volumes:
      - type: volume
        source: mydata
        target: /data
        volume:
          nocopy: true
      - type: bind
        source: ./static
        target: /opt/app/static

  db:
    image: postgres:latest
    volumes:
      - "/var/run/postgres/postgres.sock:/var/run/postgres/postgres.sock"
      - "dbdata:/var/lib/postgresql/data"

volumes:
  mydata:
  dbdata:
```

#### Short format

have access to`HOST:CONTAINER`Format, or with an access mode`HOST:CONTAINER:ro`。

Relative paths in a host can be mounted.

```
volumes:
  # Just specify a path and let the Engine create a volume
  - /var/lib/mysql

  # Specify an absolute path mapping
  - /opt/data:/var/lib/mysql

  # Path on the host, relative to the Compose file
  - ./cache:/tmp/cache

  # User-relative path
  - ~/configs:/etc/configs/:ro

  # Named volume
  - datavolume:/var/lib/mysql
```

#### Long format

Long formats can be controlled more finely.

- `type`The mount type is`volume`, `bind`, `tmpfs`and`npipe`
- `source`The source location of the mount. It can be a host path, a volume name defined in top-level volumes, and so on. If mounted`tmpfs`This parameter is meaningless.
- `target`The mount point path in the container.
- `read_only`Boolean values to set the writability of volumes.
- `bind`Configure additional bind options.
  - `propagation`Communication mode for bind.
- `volume`Configure additional volume options
  - `nocopy`Boolean Quantity to disable data replication (by default, when the volume is first created, the contents of the container will be replicated into the volume)
- `tmpfs`Configure additional TMPFS options
  - `size`The capacity of tmpfs, in bytes.
- `consistency`Consistency requirements for mounting:`consistent`Host and container have the same view.`cached`The read operation is buffered and the host view is the main body.`delegated`Read and write operations are buffered and container views are the main body.

```
version: "3.7"
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - type: volume
        source: mydata
        target: /data
        volume:
          nocopy: true
      - type: bind
        source: ./static
        target: /opt/app/static

networks:
  webnet:

volumes:
  mydata:
```

> Long formats are available after v3.2

#### VOLUMES FOR SERVICES, SWARMS, AND STACK FILES

When working in services, swarms, or`docker-stack.yml`In this scenario, it is important to note that a service may be deployed to any node in swarm and may no longer be on the original node whenever the service is restarted after being updated.

When a volume with a specified name does not exist, Docker automatically creates an anonymous volume for a reference service. Anonymous volumes are not persistent, so when the associated container instance exits and is removed, the anonymous volumes are destroyed.

If you want to persist your data, use named volumes and choose the appropriate volume driver. This driver should be cross-host so that data can roam between different hosts. Otherwise, you should set constraints on the service so that it can only be deployed to specific nodes where the corresponding volume service is working correctly.

As an example, votingapp sample in Docker Labs`docker-stack.yml`File definition`db`Service, running postgresql. It uses a named volume`db-data`To persist database data, this volume is constrained by swarm to run only in`manager`On this node, so no problem exists. The following is the source code:

```
version: "3.7"
services:
  db:
    image: postgres:9.4
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    deploy:
      placement:
        constraints: [node.role == manager]
```

#### CACHING OPTIONS FOR VOLUME MOUNTS (DOCKER DESKTOP FOR MAC)

In Docker 17.04 CE Edge and later versions (even 17.06CE Edge and Stable versions), you can configure consistency constraints on how volumes between containers and hosts are synchronized. These signs include:

- `consistent`It’s exactly the same. Host and container have the same view, which is the default policy.
- `cached`Host is the best. The read operation of the volume is buffered and the host view is the main body.
- `delegated`Containers shall prevail. Read and write operations on volumes are buffered, with container views as the main body.

This is designed for Docker Desktop for Mac. Because of what we already know.`osxfx`Regarding the reasons for file sharing characteristics, reasonable setting of consistency flags can improve the performance problems when accessing mounted volumes inside and outside containers.

Here’s one`cached`Examples of volumes:

```
version: "3.7"
services:
  php:
    image: php:7.1-fpm
    ports:
      - "9000"
    volumes:
      - .:/var/www/project:cached
```

For the case where both read and write operations are buffered, even if any modifications occur in the container (for a typical architecture like PHP Website,. / config. PHP is often written), they will not immediately be reflected in the host, and the writes in the container will be accumulated.

Performance tuning for volume mounts (shared filesystems) should be referred to for consistency issues inside and outside containers.

> I have not been able to translate it as it is, because it will bring a long space, and I have not yet been able to organize the language on this issue.

### `domainname`, `hostname`, `ipc`, `mac_address`, `privileged`, `read_only`, `shm_size`, `stdin_open`, `tty`, `user`, `working_dir` 

These configurations have a single value. and`docker run`The corresponding command line parameters correspond.`mac_address`It has been abandoned.

```
user: postgresql
working_dir: /code

domainname: foo.com
hostname: foo
ipc: host
mac_address: 02:42:ac:11:65:43

privileged: true


read_only: true
shm_size: 64M
stdin_open: true
tty: true
```

## Specified duration

Some configuration options, such as`interval`perhaps`timeout`(all are`check `Suboption, which accepts a string-style parameter value for a time period or period. They should have such formats:

```
2.5s
10s
1m30s
2h32m
5h34m56s
```

Suffix units that can be added to values are`us`, `ms`, `s`, `m`As well as`h`。

The meaning is self-evident.

## Specify byte values

Some configuration options, such as`build`Suboptions`shm_size`Accepts a string-separated capacity size parameter value. They should have such formats:

```
2b
1024kb
2048k
300m
1gb
```

Valid suffix units include`b`, `k`, `m`and`g`。 Besides,`kb`, `mb`and`gb`It’s also legal. Pure decimal values are not legal.

## Volume Format Manual-`volumes` 

Top-level volumes chapters can declare and create named volumes (no need to use them)`volume_from`These volumes can be used for reference in the volume section under the service section. So we can reuse them, even across multiple services. The docker volume subcommand of the docker command has more reference information.

For volume usage, you can also refer to Use volumes and Volume Plugins.

Here is an example, which contains two services. The data storage folder of the database is shared between the two services, so the database can use the storage folder, and the backup service can also operate it to complete the backup task:

```
version: "3.7"

services:
  db:
    image: db
    volumes:
      - data-volume:/var/lib/db
  backup:
    image: backup-service
    volumes:
      - data-volume:/var/lib/backup/data

volumes:
  data-volume:
```

top-level`volumes`The entries under the chapters can be empty without specifying details, so that the default volume driver will be applied (usually`local`Volume drive).

But you can also customize it with the following parameters:

### `driver`

Specify which volume driver will be adopted. Generally speaking, the default value will be`local`。 If the volume driver is invalid or does not work, the`docker-compose up`Docker Engine will return an error.

```
driver: foobar
```

### `driver_opts`

Optionally specify a set of key-value pair parameters that will be passed to the volume driver. So these parameter sets are related to the volume driver, please refer to the relevant documentation of the volume driver.

```
volumes:
  example:
    driver_opts:
      type: "nfs"
      o: "addr=10.40.0.199,nolock,soft,rw"
      device: ":/docker/example"
```

### `external`

If set to`true`That means that the corresponding volume is created outside the compose orchestration file. here`docker-compse up`No attempt will be made to create the volume, and an error will be returned if the volume does not yet exist.

For v3.3 and lower compose format versions,`external`Can not be used in combination with other volume configuration parameters, such as`driver`, `driver_opts`, `labels`Wait. But for v3.4 and later versions, there is no longer such restriction.

In the following example, Compose finds a name named`data`External volume and mount it to`db`In the service, instead of trying to create a name`[projectname]_data`New volume.

```
version: "3.7"

services:
  db:
    image: postgres
    volumes:
      - data:/var/lib/postgresql/data

volumes:
  data:
    external: true
```

> `external.name`After v3.4 + has been discarded, it can be used directly.`name`。

You can also specify the volume name separately.`data`The volume alias is considered when the volume is referenced in the current orchestration file:

```
volumes:
  data:
    external:
      name: actual-name-of-volume
```

> **External volumes are always created with docker stack deploy**
>
> When deployed to swarm using docker stack deployment, external volumes are always created automatically if they do not exist. For further information, please refer to moby/moby_976,

### `labels`

Use Docker labels to add metadata to the container. It can be in array format or dictionary format.

We recommend that you use reverse DNS annotation to add reverse domain name prefixes to your metadata table keys to avoid potential conflicts with table keys with the same name as other applications:

```
labels:
  com.example.description: "Database volume"
  com.example.department: "IT/Ops"
  com.example.label-with-empty-value: ""
labels:
  - "com.example.description=Database volume"
  - "com.example.department=IT/Ops"
  - "com.example.label-with-empty-value"
```

### `name`

> since v3.4+

Specify a custom name for the volume. The value of a name can be used to solve volumes with special character names. Note that the value is used as it is, quotation marks will not be ignored, nor will they be prefixed with the name of the upper stack.

```
version: "3.7"
volumes:
  data:
    name: my-app-data
```

`name`Can be associated with`external`Facies combination:

```
version: "3.7"
volumes:
  data:
    external: true
    name: my-app-data
```

## Network Format Manual-`networks` 

Top level chapters`networks`This allows you to configure the network you want to create and use (Compose Intranet).

- For a complete description of the features of using Docker network environment in Compose and all network driver options, please refer to the Networking Guide.
- For Docker Labs’network-related tutorial cases, read Designing Scalable, Portable Docker Container Networks carefully.

### `driver`

Specify the driver for the network.

The default driver is specified by the Docker Engine startup parameter. Usually, the startup parameters are built-in for use on a single-node host`bridge`Drive, while`swarm mode`Use in`overlay`Drive.

If the driver is not available, Docker Engine will return an error.

```
driver: overlay
```

#### bridge

By default, Docker is used on each host node`bridge`Drive. For information on how bridging networks work, you can refer to Docker Labs’network-related tutorial case: Bridge networking.

#### overlay

`overlay`Driver in multiple`swarm mode`A named subnet is established between nodes, which is a virtual network across hosts.

- stay`swarm mode`How to Establish in China`overlay`In order to make the service work correctly across hosts, please refer to Docker Labs’tutorial case: Overlay networking and service discovery.
- If you want to go deep into it`overlay`How to build a virtual network across hosts and how to transfer messages can be referred to Overlay Driver Network Architecture.

#### host or none

Use the host network stack or not use the network.

And command line parameters`--net=host`as well as`--net=none`It’s equivalent.

These two drivers and network models can only be used`docker stack`In If you are using it`docker compose`Relevant instructions, please use`network_mode`To specify them.

If you want to use a particular network on a common build, use [network] as mentioned in the second yaml file example.

Use built-in network models, such as`host`and`none`There’s a little grammatical point to pay attention to: if you use`host`or`none`Such names define an external network (note that you don’t really need to create them, both of which belong to Docker’s built-in network model), so you need to use them when referring to them in Compose orchestration files`hostnet`or`nonet`Like this:

```
version: "3.7"
services:
  web:
    networks:
      hostnet: {}

networks:
  hostnet:
    external: true
    name: host

---
services:
  web:
    ...
    build:
      ...
      network: host
      context: .
      ...
services:
  web:
    ...
    networks:
      nonet: {}

networks:
  nonet:
    external: true
    name: none
```

### `driver_opts`

Specifies the set of options represented by a set of key-value pairs to be passed to the network driver. They are closely related to drivers, so specific available parameters should refer to the corresponding driver documentation.

```
driver_opts:
  foo: "bar"
  baz: 1
```

### `attachable`

> since v3.2+

Can only be used`driver: overlay`Scene.

If set to`true`Independently running containers can also be attached to the network. If a container instance running independently is attached to an overlay network, services in the container can communicate with individual container instances. Note that you can even attach container instances from other Docker daemons to this overlay network.

```
networks:
  mynet1:
    driver: overlay
    attachable: true
```

### `enable_ipv6`

IPv6 is enabled in this network/subnet.

> Not supported in V3 +.
>
> `enable_ipv6`You need to use the V2 format, and it can’t be used in swarm mode.

### `ipam`

Customize IPAM configuration. Each subconfiguration is an optional parameter.

- `driver`Customize IPAM drivers without using default values
- `config`A list containing one or more configuration blocks. Each configuration block has the following sub-parameters:
  - `subnet`Subnet definition in CIDR format to delimit a segment.

A complete example:

```
ipam:
  driver: default
  config:
    - subnet: 172.28.0.0/16
```

> **NOTE**Additional IPAM such as`gateway`Only available in v2.

### `internal`

By default, Docker will also connect to a bridged network to provide external connectivity. If you want to build an external isolated overlay network, set this option to`true`。

### `labels`

Use Docker labels to add metadata to the container. It can be in array format or dictionary format.

We recommend that you use reverse DNS annotation to add reverse domain name prefixes to your metadata table keys to avoid potential conflicts with table keys with the same name as other applications:

```
labels:
  com.example.description: "Financial transaction network"
  com.example.department: "Finance"
  com.example.label-with-empty-value: ""
labels:
  - "com.example.description=Financial transaction network"
  - "com.example.department=Finance"
  - "com.example.label-with-empty-value"
```

### `external`

If set to`true`Then the network is created and managed outside of Compose choreography files. here`dockercompose up`No attempt will be made to create it, and an error will be returned if the network does not exist.

For v3.3 and lower versions,`external`Not to be associated with`driver`, `driver_opts`, `ipam`, `internal`And so on. This restriction was removed after v3.4 +.

In the following example,`proxy`It’s a gateway in the outside world, and Compose will find its way through it.`docker network create outside`Established`outside`External networks, rather than trying to automatically create a name`[projectname]_outside`New networks:

```
version: "3.7"

services:
  proxy:
    build: ./proxy
    networks:
      - outside
      - default
  app:
    build: ./app
    networks:
      - default

networks:
  outside:
    external: true
```

> `external.name`It has been discarded since v3.5. Please use it instead.`name`。

You can also specify a separate network name to be referenced in the Compose orchestration file.

### `name`

> since v3.5

Set a custom name for the network. The value of a name can be used to solve volumes with special character names. Note that the value is used as it is, quotation marks will not be ignored, nor will they be prefixed with the name of the upper stack.

```
version: "3.7"
networks:
  network1:
    name: my-app-net
```

`name`Can and`external`Use it together:

```
version: "3.7"
networks:
  network1:
    external: true
    name: my-app-net
```

## Configuration Item Arrangement Format Manual-`configs` 

Top-level`configs`Chapter Statement defines a configuration item or its reference that can be authorized for use by in-stack services. The source of the configuration item can be`file`or`external`。

- `file`The content of the configuration item is in a host file.
- `external`If set to`true`Represents that the configuration item is ready to be created. Docker will not attempt to build it, but will generate one when it does not exist.`config not found`Mistake.
- `name`The name of the configuration item in Docker. The value of a name can be used to solve volumes with special character names. Note that the value is used as it is, quotation marks will not be ignored, nor will they be prefixed with the name of the upper stack.

In the following example, when deployed as part of the stack,`my_first_config`It will be automatically created and named`<stack_name>_my_first_config`As for`my_second_config`It already exists.

```
configs:
  my_first_config:
    file: ./config_data
  my_second_config:
    external: true
```

Another change is that external configuration items have`name`In the case defined, the configuration item can be used in Compose as`redis_config`Reference and use for name:

```
configs:
  my_first_config:
    file: ./config_data
  my_second_config:
    external:
      name: redis_config
```

You still need to declare each service on the stack`configs`Chapter to gain access to configuration items, refer to grant access to the config.

## Handbook for Formatting Sensitive Information Items-`secrets` 

Top-level`secrets`Chapter declaration defines a sensitive information item or its reference, which can be authorized for use by in-stack services. The source of sensitive information items can be`file`or`external`。

- `file`The contents of sensitive information items are in a host file.
- `external`If set to`true`Indicates that the sensitive information item is ready to be created. Docker will not attempt to build it, but will generate one when it does not exist.`secret not found`Mistake.
- `name`The name of the sensitive information item in Docker. The value of a name can be used to solve volumes with special character names. Note that the value is used as it is, quotation marks will not be ignored, nor will they be prefixed with the name of the upper stack.

In the following example, when deployed as part of the stack,`my_first_secret`It will be automatically created and named`<stack_name>_my_first_secret`As for`my_second_secret`It already exists.

```
secrets:
  my_first_secret:
    file: ./secret_data
  my_second_secret:
    external: true
```

Another change is that external configuration items have`name`In the case defined, the configuration item can be used in Compose as`redis_secret`Reference and use for name.

#### Compose File v3.5 and later

```
secrets:
  my_first_secret:
    file: ./secret_data
  my_second_secret:
    external: true
    name: redis_secret
```

### Compose File v3.4 and lower

```
my_second_secret:
    external:
      name: redis_secret
```

You still need to declare each service on the stack`secret`Chapter to gain access to sensitive information items, refer to grant access to the secret.

## Variable substitution

Environment variables can be used in Compose orchestration files. When`docker-compose`At runtime, Compose extracts variable values from shell environment variables. For example, suppose that the operating system environment variables contain`POSTGRES_VERSION=9.3`Definition, then the following definition

```
db:
  image: "postgres:${POSTGRES_VERSION}"
```

Equivalent to

```
db:
  image: "postgres:9.3"
```

If the environment variable does not exist or is an empty string, it is treated as an empty string.

You can go through it.`.env`The file sets default values for environment variables. Compose will automatically find the current folder`.env`File to get the value of the environment variable.

> **IMPORTANT**Attention`.env`File only`docker-compose up`It works in the scenario, but it works in the scenario.`docker stack deploy`It will not be used.

Two kinds of grammar`$VARIABLE`and`${VARIABLE}`All are available. In addition, in v2.1 format, the following forms similar to shell grammar can also be used:

- `${VARIABLE:-default}`Will return`default`If the environment variable`VARIABLE`If it is an empty string or not set.
- `${VARIABLE-default}`Will return`default`If the environment variable`VARIABLE`If not set.

Similarly, the following syntax helps to specify a clear value:

- `${VARIABLE:?err}`Error messages will be generated`err`If the environment variable`VARIABLE`If it is empty or not set.
- `${VARIABLE?err}`Error messages will be generated`err`If the environment variable`VARIABLE`If not set.

Other shell syntax features are not supported, such as`${VARIABLE/foo/bar}`。

If you need a dollar sign, use`$`. At this time, $$`No longer participate in the interpretation of environmental variable substitution. The following example:

```
web:
  build: .
  command: "$$VAR_NOT_INTERPOLATED_BY_COMPOSE"
```

If you forget this rule and use one`$`Compose warns you if it’s a single character:

```
The VAR_NOT_INTERPOLATED_BY_COMPOSE is not set. Substituting an empty string.
```

## Extended field

> since v3.4

By extending fields, you can reuse the orchestration configuration fragments. They can be in a free format, provided you define them at the top level of the yaml document, and the chapter names are as follows`x-`Start:

```
version: '3.4'
x-custom:
  items:
    - a
    - b
  options:
    max-size: '12m'
  name: "custom"
```

> **NOTE**
>
> Starting with V3.7 (for 3.x series), or starting with V2.4 (for 2.x series), extended fields can also be placed at the first level under the top chapters of services, volumes, networks, configuration items, and sensitive information items.
>
> As such:
>
> ```
> version: '3.7'
> services:
> redis:
>  # ...
> x-custom:
>  items:
>       - a
>       - b
>  options:
>    max-size: '12m'
>  name: "custom"
> ```

The so-called free format means that these definitions are not interpreted by Compose. However, when you insert their references somewhere, they are expanded to the insertion point and then interpreted by Compose in terms of context. This uses the YAML anchors grammar.

For example, if you use the same logging option for multiple services:

```
logging:
  options:
    max-size: '12m'
    max-file: '5'
  driver: json-file
```

You can define it as follows:

```
x-logging:
  &default-logging
  options:
    max-size: '12m'
    max-file: '5'
  driver: json-file

services:
  web:
    image: myapp/web:latest
    logging: *default-logging
  db:
    image: mysql:latest
    logging: *default-logging
```

With the YAML merge type grammar, you can also insert extended field definitions that override certain sub-options. For example:

```
version: '3.4'
x-volumes:
  &default-volume
  driver: foobar-storage

services:
  web:
    image: myapp/web:latest
    volumes: ["vol1", "vol2", "vol3"]
volumes:
  vol1: *default-volume
  vol2:
    << : *default-volume
    name: volume02
  vol3:
    << : *default-volume
    driver: default
    name: volume-local
```

## Compose Document Reference

- User guide
- Installing Compose
- Compose file versions and upgrading
- Get started with Docker
- Samples
- Command line reference

## End

- Original: https://docs.docker.com/compo…
- Https://github.com/hedzr/docker-compose-file-format.

