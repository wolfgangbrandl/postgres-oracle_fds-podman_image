# Get the baseimage from an external registry
#FROM registry.access.redhat.com/ubi8/ubi geht nicht da irgendwo cgroup verwendet wird
FROM registry.redhat.io/rhel8/postgresql-12 AS builder
ENV POSTGRESQL_VERSION=13 \
    HOME=/var/lib/pgsql \
    PGUSER=postgres \
    APP_DATA=/opt/app-root

LABEL summary="BRZ PaaS Database Image Postgresl 13 with oracle_fdw. No maintenance from PaaS Team! Use this as a base or deploy your own base without any support!"\
      maintainer="cp Admins <cpadm@brz.gv.at>" \
      vendor="BRZ GmbH" \
      at.cna.cp.baseversion="1.0" \
      at.cna.cp.imagename="brz-cp-rhel8-postgresql-13.3" \
      io.k8s.display-name="BRZ PaaS Database Image Postgresl 13.3"

# Comment
USER root:root
RUN yum -y install  --skip-broken --allowerasing --nobest unzip.x86_64 make.x86_64 gcc.x86_64 bison flex readline.x86_64 readline-devel.x86_64 zlib.x86_64 zlib-devel.x86_64 openssl-devel libxml2-devel git wget libnsl2 libaio
RUN yum -y remove postgresql-contrib postgresql-server
RUN  mkdir -p $APP_DATA/src 
ADD ./postgres.tar.gz $APP_DATA/src
RUN  ls -l $APP_DATA/src && mkdir -p $APP_DATA/usr
RUN  cd $APP_DATA/src/postgresql && ./configure --prefix=$APP_DATA/usr --disable-rpath --with-openssl --with-libxml && \
     gmake -f Makefile clean all install && \
     cd contrib && \
     gmake -f Makefile clean all install
ADD ./instantclient-basic-linux.x64-19.14.0.0.0dbru.zip $APP_DATA/src
ADD ./instantclient-sqlplus-linux.x64-19.14.0.0.0dbru.zip $APP_DATA/src
ADD ./instantclient-sdk-linux.x64-19.14.0.0.0dbru.zip $APP_DATA/src
RUN cd $APP_DATA/src && unzip instantclient-basic-linux.x64-19.14.0.0.0dbru.zip && unzip instantclient-sqlplus-linux.x64-19.14.0.0.0dbru.zip && \
    unzip instantclient-sdk-linux.x64-19.14.0.0.0dbru.zip && rm -f *.zip
RUN  ls -l $APP_DATA/src
RUN  ls -l $APP_DATA/usr
RUN  ls -Rl $APP_DATA/usr/share
RUN cp $APP_DATA/src/instantclient_19_14/*.so* $APP_DATA/usr/lib
RUN pwd && ls -l
ADD ./oracle_fdw.tar.gz $APP_DATA/src/postgresql/contrib
RUN cd $APP_DATA/src/postgresql/contrib/oracle_fdw && export ORACLE_HOME=$APP_DATA/src/instantclient_19_14; export NO_PGXS=1;gmake clean all install
RUN cd $APP_DATA/src && rm -rf postgresql &&  rm -rf instantclient_19_14  
RUN cd $APP_DATA/usr && tar cvf ../post.tar ./lib ./share ./bin && gzip ../post.tar
# build image without build library just runtime
FROM registry.redhat.io/rhel8/postgresql-12
ENV POSTGRESQL_VERSION=13 \
    HOME=/var/lib/pgsql \
    PGUSER=postgres \
    APP_DATA=/opt/app-root

LABEL summary="BRZ PaaS Database Image Postgresl 13 with oracle_fdw. No maintenance from PaaS Team! Use this as a base or deploy your own base without any support!"\
      maintainer="cp Admins <cpadm@brz.gv.at>" \
      vendor="BRZ GmbH" \
      at.cna.cp.baseversion="1.0" \
      at.cna.cp.imagename="brz-cp-rhel8-postgresql-13.3" \
      io.k8s.display-name="BRZ PaaS Database Image Postgresl 13.3"
# Comment
USER root:root
RUN yum -y install  --skip-broken --allowerasing --nobest readline.x86_64 zlib.x86_64 openssl libxml2 libnsl2 libaio && \
    yum -y remove postgresql-contrib postgresql-server
COPY --from=builder $APP_DATA/post.tar.gz $APP_DATA
RUN cd /usr && \
    tar xvf $APP_DATA/post.tar.gz && \
    rm -f $APP_DATA/post.tar.gz
RUN dnf clean all && dnf -y update && dnf clean all
RUN mkdir -p /var/lib/pgsql/data && \
    mkdir -p /usr/libexec/s2i && \
    mkdir -p /var/run/postgresql && \
    mkdir -p /usr/share/container-scripts/postgresql && \
    chmod 750 /usr/share/container-scripts && \
    chmod 750 /usr/share/container-scripts/postgresql
ADD ./run/run-postgresql /usr/bin/run-postgresql
ADD ./run/container-entrypoint /usr/bin/container-entrypoint
ADD run/container-scripts/postgresql /usr/share/container-scripts/postgresql
COPY root /
RUN mkdir -p /var/lib/pgsql/data && \
    mkdir -p /var/run/postgresql && \
    /usr/libexec/fix-permissions /var/lib/pgsql && \
    /usr/libexec/fix-permissions /var/run/postgresql

# Get prefix path and path to scripts rather than hard-code them in scripts
ENV CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/postgresql \
    ENABLED_COLLECTIONS=\
    LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH


USER 26

ENTRYPOINT ["container-entrypoint"]
CMD ["run-postgresql"]

