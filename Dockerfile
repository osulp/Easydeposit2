FROM registry.library.oregonstate.edu/centos7-systemd:latest
# Install build tools, mysql libs, nodejs, npm, libffi
# set default timezone to America/Los_Angeles
RUN yum -y install make gcc gcc-c++ mysql-devel git && \
  yum -y update && yum -y clean all

# download and install node 10
# download and install yarn
RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash - && \
  curl -sL https://dl.yarnpkg.com/rpm/yarn.repo > /etc/yum.repos.d/yarn.repo &&\
  yum -y install nodejs npm yarn && yum -y clean all

# Download, build and install libffi 3.3 with 2 workers
RUN curl -sL https://gcc.gnu.org/pub/libffi/libffi-3.3.tar.gz | \
  tar -xzf - && cd libffi-3.3 && ./configure --prefix=/usr/local && \
  make -j 2 && make install && rm -rf libffi-3.3 && \
  echo "/usr/local/lib" >> /etc/ld.so.conf.d/local.conf && \
  echo "/usr/local/lib64" >> /etc/ld.so.conf.d/local.conf && ldconfig

# Download, build and install ruby 2.5.1 and rubygems with 2 workers
# Create /data
RUN curl -sL https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.1.tar.gz | \
  tar -xzf - && cd ruby-2.5.1 && ./configure --prefix=/usr/local \
  --disable-install-doc --disable-install-rdoc --disable-install-capi && \
  make -j 2 && make install && rm -rf ruby-2.5.1 && mkdir /data


# Add the Gemfile and Gemfile.lock to /data
# Add the entrypoint scripts to /
ADD Gemfile /data/Gemfile
ADD Gemfile.lock /data/Gemfile.lock
COPY ed2-entrypoint.sh /ed2-entrypoint.sh
COPY sidekiq-entrypoint.sh /sidekiq-entrypoint.sh
ADD . /data
WORKDIR /data

# Run yarn install
# install bundler 1.17.3
# cleanup /data
RUN yarn install && /usr/local/bin/gem install -v "1.17.3" bundler && \
  rm -f /data/docker-compose.* /data/*.sh /data/Dockerfile*

# Run bundle install with 2 workers
RUN /usr/local/bin/bundle update sassc ffi && \ 
  /usr/local/bin/bundle -j 2 --binstubs install

# Expose the Rails port
EXPOSE 3000

# Set /ed2-entrypoint.sh as the default command to boot the container
# and startup services
CMD ["/ed2-entrypoint.sh"]
