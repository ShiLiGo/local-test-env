FROM ccr.ccs.tencentyun.com/qcloud/centos:latest
RUN rm /etc/yum.repos.d/CentOS-Epel.repo
WORKDIR /app
COPY Centos-7.repo cert.pem libevent-2.0.22-stable.tar openssl-3.1.1.tar Python-3.10.12.tar python-libevent-0.9.2.tar requirement.txt uwsgi-2.0.20.tar /app/
RUN cp Centos-7.repo /etc/yum.repos.d/CentOS-Base.repo
RUN yum install -y epel-release
RUN yum install -y protobuf-devel lua-devel libevent-devel \
        hiredis-devel log4cplus-devel boost-devel jsoncpp-devel \
        libuuid-devel openssl-devel libcurl-devel mariadb-devel \
        gcc python-devel make perl-IPC-Cmd \
        bzip2-devel ncurses-devel lz4-devel sqlite-devel \
        tk-devel readline-devel libffi-devel \
        cmake gcc-c++
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py && \
        python get-pip.py && \
        pip install --upgrade pip && \
        pip install --upgrade setuptools==44.1.1 && \
        pip install --upgrade wheel && \
        pip install -r requirement.txt
RUN tar -xvf libevent-2.0.22-stable.tar && \
        cd libevent-2.0.22-stable && \
        CFLAGS=-fPIC ./configure --prefix=/app/libevent && \
        make && \
        make install
RUN tar -xvf python-libevent-0.9.2.tar && cd python-libevent-0.9.2 && \
        sed -i "s/LIBEVENT_ROOT = os.environ.get('LIBEVENT_ROOT')/LIBEVENT_ROOT = '\/app\/libevent'/g" setup.py && \
        sed -i "s/os.path.join(LIBEVENT_ROOT, '.libs', 'libevent.a')/os.path.join(LIBEVENT_ROOT, 'lib', 'libevent.a')/g" setup.py && \
        sed -i "s/os.path.join(LIBEVENT_ROOT, '.libs', 'libevent_pthreads.a')/os.path.join(LIBEVENT_ROOT, 'lib', 'libevent_pthreads.a')/g" setup.py && \
        python setup.py build && \
        python setup.py install
RUN tar -xvf openssl-3.1.1.tar && \
        cd /app/openssl-3.1.1 && \
        CFLAGS=-fPIC ./config --prefix=/usr/duole && \
        make && \
        make install
RUN cp /app/cert.pem /usr/duole/ssl
RUN echo "/usr/local/lib64" >> /etc/ld.so.conf && echo "/usr/duole/lib64" >> /etc/ld.so.conf && ldconfig
RUN tar -xvf Python-3.10.12.tar && \
        cd /app/Python-3.10.12 && \
        ./configure --enable-optimizations --with-lto --with-openssl=/usr/duole --with-openssl-rpath=/usr/duole/lib64 && \
        sed -i '207s/.*/OPENSSL_LDFLAGS=-L\/usr\/duole\/lib64/' Makefile && \
        make && \
        make install
RUN tar -xvf uwsgi-2.0.20.tar && \
        cd /app/uwsgi-2.0.20 && \
        sed -i -e '1300a\                    self.cflags.append("-I/usr/duole/include")\n                    self.libs.append("-L/usr/duole/lib64")' uwsgiconfig.py && \
        sed -i -e '1309a\                self.cflags.append("-I/usr/duole/include")\n                self.libs.append("-L/usr/duole/lib64")' uwsgiconfig.py && \
        python3 setup.py install
COPY libwebsockets.tar.gz /app/
RUN tar -xvf libwebsockets.tar.gz && \
        cd /app/libwebsockets/build && \
        rm -rf * && \
        cmake .. \
                -DLWS_WITHOUT_TEST_SERVER=ON \
                -DLWS_WITHOUT_TESTAPPS=ON && \
        make && \
        make install
COPY protobuf-all-3.20.3.tar /app/
RUN tar -xvf protobuf-all-3.20.3.tar && \
        cd /app/protobuf-3.20.3/ && \
        CFLAGS=-fPIC ./configure --prefix=/usr/duole && \
        make && \
        make install
COPY rocksdb-6.22.1.tar /app/
RUN yum install -y which
RUN tar -xvf rocksdb-6.22.1.tar && \
        cd /app/rocksdb-6.22.1/ && \
        make shared_lib && \
        cp -r include/rocksdb/ /usr/local/include/ && \
        cp librocksdb.so.6.22.1 /usr/local/lib/ && \
        cd /usr/local/lib && \
        ln -s librocksdb.so.6.22.1 librocksdb.so
RUN mkdir -p /var/baohuang/bin_ai && \
        mkdir -p /var/baohuang/bin_conn && \
        mkdir -p /var/baohuang/bin_game && \
        mkdir -p /var/baohuang/bin_gameinfo && \
        mkdir -p /var/baohuang/bin_mail && \
        mkdir -p /var/baohuang/bin_prematch && \
        mkdir -p /var/baohuang/bin_room && \
        mkdir -p /var/baohuang/bin_team && \
        mkdir -p /var/baohuang/bin_teamarbiter && \
        mkdir -p /var/baohuang/bin_bc && \
        mkdir -p /var/baohuang/bin_log && \
        mkdir -p /var/baohuang/bin_playback && \
        mkdir -p /var/baohuang/bin_proxy && \
        mkdir -p /var/baohuang/bin_subscription && \
        mkdir -p /var/baohuang/bin_tier && \
        mkdir -p /var/baohuang/venv_bc && \
        mkdir -p /var/baohuang/venv_log && \
        mkdir -p /var/baohuang/venv_playback && \
        mkdir -p /var/baohuang/venv_proxy && \
        mkdir -p /var/baohuang/venv_ai && \
        mkdir -p /var/baohuang/venv_tier && \
        mkdir -p /var/baohuang/venv_subscription && \
        mkdir -p /var/www/apps/baohuang
CMD ["tail", "-f", "/dev/null"]