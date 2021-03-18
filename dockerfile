FROM python:3.8.0-slim-buster

# So that STDOUT/STDERR is printed
ENV PYTHONUNBUFFERED="1"

# We create the default user and group to run unprivileged
WORKDIR /srv/hunter/
RUN groupadd --gid 8192 hunter && \
    useradd --uid 8192 --shell /bin/false --create-home --no-log-init --gid hunter hunter && \
    chown hunter:hunter /srv/hunter/


# First let's just get things updated.

# Install System dependencies
RUN apt-get update --assume-yes && \
    apt-get install -o 'Dpkg::Options::=--force-confnew' -y --force-yes -q \
    git \
    openssh-client \
    gcc \
    libpq-dev \
    python-dev \
    clang \
    libncurses5-dev \
    libncursesw5-dev \
    build-essential \
    software-properties-common \
    make \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Get poetry package
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python

# Adding poetry to PATH
ENV PATH="/root/.poetry/bin:$PATH"

# Copy the rest of the program over
COPY --chown=hunter:hunter . /srv/hunter/

# Add the github key to known_hosts so we can clone repos as root
RUN mkdir -m=0700 ~/.ssh
RUN touch ~/.ssh/known_hosts
RUN chmod 0600 ~/.ssh/known_hosts

# Taken from https://help.github.com/en/github/authenticating-to-github/testing-your-ssh-connection
ARG github_host_key_fingerprint="SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8"


# Mostly copied from https://serverfault.com/a/971922/41102
RUN if [ "$(ssh-keyscan -H -t rsa github.com 2>/dev/null | \
            tee -a ~/.ssh/known_hosts | \
            ssh-keygen -lf - | \
            cut -d' ' -f 2)" != "${github_host_key_fingerprint}" ]; then \
        echo "Bad github host key" 1>&2; \
        exit 1; \
    fi



# Copy the rest of the program over
COPY --chown=hunter:hunter . /srv/hunter/


ENV HUNTER_HOME /srv/hunter

WORKDIR ${HUNTER_HOME}


# Defaults
RUN python -m pip install --upgrade pip \
    && poetry install -vvv
