FROM ccr.ccs.tencentyun.com/qcloud/centos:latest
RUN rm /etc/yum.repos.d/CentOS-Epel.repo
RUN --mount=type=bind,source=Centos-7.repo,target=Centos-7.repo \
    cp Centos-7.repo /etc/yum.repos.d/CentOS-Base.repo
RUN yum install -y epel-release
RUN yum install -y protobuf-devel lua-devel libevent-devel \
        hiredis-devel log4cplus-devel boost-devel jsoncpp-devel \
        libuuid-devel openssl-devel libcurl-devel mariadb-devel \
        gcc python-devel make perl-IPC-Cmd \
        bzip2-devel ncurses-devel lz4-devel sqlite-devel \
        tk-devel readline-devel
RUN mkdir -p /home/python
ADD ./requirement.txt /home/python
RUN cd /home/python && \
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py && \
        python get-pip.py && \
        pip install --upgrade pip && \
        pip install --upgrade setuptools==44.1.1 && \
        pip install --upgrade wheel && \
        pip install -r requirement.txt
RUN mkdir -p /home/software
ADD ./libevent-2.0.22-stable.tar /home/software
RUN cd /home/software && cd libevent-2.0.22-stable && CFLAGS=-fPIC ./configure --prefix=/home/software/libevent && make && make install
ADD ./python-libevent-0.9.2.tar /home/software
RUN cd /home/software && cd python-libevent-0.9.2 && \
        sed -i "s/LIBEVENT_ROOT = os.environ.get('LIBEVENT_ROOT')/LIBEVENT_ROOT = '\/home\/software\/libevent'/g" setup.py && \
        sed -i "s/os.path.join(LIBEVENT_ROOT, '.libs', 'libevent.a')/os.path.join(LIBEVENT_ROOT, 'lib', 'libevent.a')/g" setup.py && \
        sed -i "s/os.path.join(LIBEVENT_ROOT, '.libs', 'libevent_pthreads.a')/os.path.join(LIBEVENT_ROOT, 'lib', 'libevent_pthreads.a')/g" setup.py && \
        cat setup.py && \
        python setup.py build && \
        python setup.py install
ADD ./openssl-3.1.1.tar /home/software
RUN cd /home/software/openssl-3.1.1 && CFLAGS=-fPIC ./config --prefix=/usr/duole  && make && make install
RUN echo "/usr/local/lib64" >> /etc/ld.so.conf && echo "/usr/duole/lib64" >> /etc/ld.so.conf && ldconfig
ADD ./Python-3.10.12.tar /home/software
RUN yum install -y libffi-devel
RUN cd /home/software/Python-3.10.12 && \
        ./configure --enable-optimizations --with-lto --with-openssl=/usr/duole --with-openssl-rpath=/usr/duole/lib64 && \
        sed -i '207s/.*/OPENSSL_LDFLAGS=-L\/usr\/duole\/lib64/' Makefile && \
        make && \
        make install
ADD ./cert.pem /usr/duole/ssl
RUN mkdir -p /var/baohuang
CMD ["tail", "-f", "/dev/null"]