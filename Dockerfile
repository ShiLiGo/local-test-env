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
RUN mkdir -p /var/baohuang
CMD ["tail", "-f", "/dev/null"]