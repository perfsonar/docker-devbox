#
# User customizations for DDB containers
#
# Install this file or one like it in ~/.ddb/prep-steps-user.m4
#
# Documentation on M4, which is used to process this file, may be
# found at https://pubs.opengroup.org/onlinepubs/9699919799/utilities/m4.html
#

# This gets us install_pkg inside the container.
. "$(dirname $0)/common"

install_pkg \
    emacs-nox \
    git \
    htop \
    make \
    man \
    man-db \
    screen \
    tree \
    wget

ifelse(__FAMILY,RedHat,
    install_pkg \
        bind-utils \
        man-pages \
        which
      )
