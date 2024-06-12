# docker-devbox

Docker-Devbox (DDB) is a set of utilities that allow easy setup, login
and teardown of Docker containers, much in the vein of Vagrant.  In
addition, it provides per-user container customization, systemd and shares the
invoking user's account and home directory into the containers for a
consistent user experience.


## Important Caveats

DDB is intended for use in expendable development systems.  **It is
not for use in production.**

Because DDB depends on a user's ability to become the superuser,
containers being run by one user are accessible to any other user with
the same rights.  The separation between users provided is for
convenience, not security.


## Installation and Setup

### Prerequisites

DDB has been tested on several distributions of Linux and macOS but
should work on any operating system that can provide the following:

 * A POSIX-compliant shell and standard utilities, including `m4`.

 * functioning instance of Docker or Podman with the latter configured
   to behave like Docker (i.e., it responds to `docker` commands).

 * An account that is the superuser or can become the superuser via
   `sudo(8)`.  For low-friction operation, it is recommended that
   `sudo` be configured to allow repeated use after providing a
   password or invocation of Docker (usually `/bin/docker`) without
   requiring a password.

### Installation

Clone this repository into a convenient place, such as
`/opt/docker-devbox`, which will be used in subsequent examples.

In your shell's `rc` (note that only Bourne-like, POSIX shells are
supported), add the following:

```eval $(/opt/docker-devbox/setup) ```

To add convenience aliases (described below):

```eval $(/opt/docker-devbox/setup --aliases)```


## Quick Start

```
# Set up Docker DevBox
you@host$ eval $(/opt/docker-devbox/setup --aliases)

# Build a customized-for-you image of EL7 plus Unibuild
you@host$ ddb build el7u

# Start that image in a container
you@host$ ddb boot tester el7u
Starting tester as el7u
f245ebc74207b5485a80602e4b676bd98443cdba2bb11cb8310ac7331eba555a

# Log into the container and do your business
you@host$ ddb login tester

you@tester$ ...do things...
you@tester$ exit

# Destroy the container
you@host$ ddb halt tester
```


## Commands

### `build BASE` - Build a container image

The process of using DDB begins with creating a container from an
existing Docker image such as `almalinux:8` or `debian:10`.  Any
container that Docker can `pull` can be used.

The `BASE` parameter names one of the base containers listed in
`/opt/docker-devbox/etc/bases` to be used as the basis for the
DBB-customized container.  The contents of that file may be customized
as needed.  Note that DDB is built to support most currently-supported
variants of Red Hat and Debian Linux; running containers with other
distributions will require customization.

DDB will build a new image from the base, apply its own customizations
and then run the script found in `~/.ddb/prep.m4` if it exists.  The
file is processed using M4 with the following macros made available
for making decisions about what to do:

| Macro | Description | Example |
|-------|-------------|---------|
| `__OS` | Operating system as reported by `uname(1)` | `Linux` |
| `__DISTRO` | Operating system distribution, empty of not applicable | `CentOS` |
| `__FAMILY` | Operating system family, empty where not applicable | `RedHat` |
| `__RELEASE` | Operating system release | `7.9.2009` |
| `__CODENAME` | Codename of operating system release | `Core` |
| `__MAJOR` | Major version of `RELEASE`, empty if not present | `7` |
| `__MINOR` | Minor version of `RELEASE`, empty if not present | `9` |
| `__PATCH` | Patch version of `RELEASE`, empty if not present | `2009` |
| `__PACKAGING` | Type of packaging used by this system (Currently `deb` or `rpm`) | `rpm` |
| `__ARCH` | Machine architecture as reported by `uname(1)` | `x86_64` |

A sample of this file can be found in
`/opt/docker-devbox/etc/prep-example.m4`.

Example:
```
[yourlogin@host ~]$ ddb build el8

... (Much Output Deleted) ...

Complete!
COMMIT ddb__yourlogin__el8
--> 65bce79d0be
Successfully tagged localhost/ddb__yourlogin__el8:latest
65bce79d0be3049a6f955e31c4b12fefebfe64606998c4be5af0cdcf5b4f0d90

[yourlogin@host ~]$
```

**NOTE:** The actual name of the image within Docker will be
`ddb__USERNAME__BASE`, where `USERNAME` is the invoking user's login
and `BASE` is the shorthand for the base image provided when `build`
was invoked (e.g., `ddb__steveb__el8`).  This allows for multiple
users on the same system to have their own customized containers.


#### User-Supplied Macros

Additional macros may be supplied to the build process two ways:

On the command line, one or more instances of `--define MACRO=VALUE`
may be used when invoking `build`, e.g.:
```
ddb build --define FOO=bar --define BAZ=quux
```

In the bases file (`etc/bases`), macros can be defined after the name
of the base image, e.g.:
```
nine-plus almalinux:9 FOO=bar BAZ=quux
```

**Note:** All user-defined macros are, like those provided by
Unibuild, prefixed with a double underscore to prevent them from
colliding with useful words (e.g., `FOO` will become `__FOO`).


### `boot NAME IMAGE` - Start a container

Once an image has been built, it can be instantiated as a container by
booting it.

Example:
```
[yourlogin@host ~]$ ddb boot devel el8

[yourlogin@host ~]$
```

Aliases:
  * `ddbb` = `ddb boot`
  * `ddbbl` = `ddb boot --login`

**NOTE:** The actual name of the Docker container will be
`ddb__USERNAME__NAME`, where `USERNAME` is the invoking user's login
and `NAME` is the `NAME` parameter provided when `boot` was invoked
(e.g., `ddb__steveb__devel`).  This allows for multiple users on the
same system to have their own same-named containers.


**NOTE:** The container is started in privileged mode.  This will
  change in the near future.


### `login NAME` - Log into a container

This command starts a login shell in the container using your account.

Example:
```
[yourlogin@host ~]$ ddb login devel

[yourlogin@devel ~]$

... Do some things ...

[yourlogin@devel ~]$ exit

[yourlogin@host ~]$
```

Aliases:
  * `ddbl` = `ddb login`


## `ps` - Show a list of running containers.

This command lists the containers running on your behalf.

```
[yourlogin@host ~]$ ddb ps
devel
test
issue-1234

[yourlogin@host ~]$
```


### `quick IMAGE` - Run an itinerant container

This command boots a container based on `IMAGE`, logs into it and then
destroys it once the login session has exited.

Example:
```
[yourlogin@host ~]$ ddb ps
(No output)
[yourlogin@host ~]$ ddb quick el9u
Starting quick-GQTXmh6T from image el9u
b6067fd9d973c17b83c1ced2a8519d6ea40140eb15a438145c35be46f9707fc1
[yourlogin@quick-GQTXmh6T]$
[yourlogin@quick-GQTXmh6T]$ exit
logout
[yourlogin@host ~]$ ddb ps
(No output)
[yourlogin@host ~]$
```

Aliases:
  * `ddbq` = `ddb quick`


### `halt [ --all ] NAME [ NAME ... ]` - Stop and destroy a container

This command halts and destroys running containers.

If given the `--all` switch, all containers being run on the invoking
user's behalf will be destroyed.


Example:
```
[yourlogin@host ~]$ ddb halt devel
Powering off.

[yourlogin@host ~]$
```

Aliases:
  * `ddbh` = `ddb halt`


## Everything Else

Some of the ideas for docker-devbox came from Akihiro Suda's
[containerized
systemd](https://github.com/AkihiroSuda/containerized-systemd).
