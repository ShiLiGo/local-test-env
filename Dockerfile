FROM centos:7.9.2009
WORKDIR /app
COPY Centos-7.repo cert.pem libevent-2.0.22-stable.tar openssl-3.1.1.tar Python-3.10.12.tar python-libevent-0.9.2.tar requirement.txt uwsgi-2.0.20.tar /app/
RUN rm /etc/yum.repos.d/*
RUN cp Centos-7.repo /etc/yum.repos.d/CentOS-Base.repo
RUN yum install -y epel-release
RUN yum install -y protobuf-devel lua-devel libevent-devel \
        hiredis-devel log4cplus-devel boost-devel jsoncpp-devel \
        libuuid-devel openssl-devel libcurl-devel mariadb-devel \
        gcc python-devel make perl-IPC-Cmd \
        bzip2-devel ncurses-devel lz4-devel sqlite-devel \
        tk-devel readline-devel libffi-devel \
        cmake gcc-c++ libffi-devel python3-devel \
        which crontab nginx redis git htop
RUN tar -xvf libevent-2.0.22-stable.tar && \
        cd libevent-2.0.22-stable && \
        CFLAGS=-fPIC ./configure --prefix=/app/libevent && \
        make && \
        make install
RUN tar -xvf openssl-3.1.1.tar && \
        cd /app/openssl-3.1.1 && \
        CFLAGS=-fPIC ./config --prefix=/usr/duole && \
        make && \
        make install
RUN cp /app/cert.pem /usr/duole/ssl
RUN echo "/usr/local/lib64" >> /etc/ld.so.conf && echo "/usr/duole/lib" >> /etc/ld.so.conf && ldconfig
RUN tar -xvf Python-3.10.12.tar && \
        cd /app/Python-3.10.12 && \
        ./configure --enable-optimizations --with-lto --with-openssl=/usr/duole --with-openssl-rpath=/usr/duole/lib && \
        sed -i '207s/.*/OPENSSL_LDFLAGS=-L\/usr\/duole\/lib/' Makefile && \
        make && \
        make install
RUN tar -xvf uwsgi-2.0.20.tar && \
        cd /app/uwsgi-2.0.20 && \
        sed -i -e '1300a\                    self.cflags.append("-I/usr/duole/include")\n                    self.libs.append("-L/usr/duole/lib")' uwsgiconfig.py && \
        sed -i -e '1309a\                self.cflags.append("-I/usr/duole/include")\n                self.libs.append("-L/usr/duole/lib")' uwsgiconfig.py && \
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
        make -j8 && \
        make install
COPY rocksdb-6.22.1.tar /app/
RUN tar -xvf rocksdb-6.22.1.tar && \
        cd /app/rocksdb-6.22.1/ && \
        make shared_lib && \
        cp -r include/rocksdb/ /usr/local/include/ && \
        cp librocksdb.so.6.22.1 /usr/local/lib/ && \
        cd /usr/local/lib && \
        ln -s librocksdb.so.6.22.1 librocksdb.so
CMD ["tail", "-f", "/dev/null"]