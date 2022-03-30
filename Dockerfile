# Get the baseimage from an external registry
FROM registry.redhat.io/rhel8/postgresql-12
#FROM registry.access.redhat.com/ubi8:8.5-226.1645809065
ENV POSTGRESQL_VERSION=13 \
    HOME=/var/lib/pgsql \
    PGUSER=postgres \
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_DATA=/opt/app-root

LABEL summary="BRZ PaaS Database Image Postgresl 13 with oracle_fdw. No maintenance from PaaS Team! Use this as a base or deploy your own base without any support!"\
      maintainer="cp Admins <cpadm@brz.gv.at>" \
      vendor="BRZ GmbH" \
      at.cna.cp.baseversion="1.0" \
      at.cna.cp.imagename="brz-cp-rhel8-postgresql-13.3" \
      io.k8s.display-name="BRZ PaaS Database Image Postgresl 13.3"
EXPOSE 5432

COPY root/usr/libexec/fix-permissions /usr/libexec/fix-permissions
# Comment
USER root:root
RUN yum -y install make.x86_64 unzip gcc.x86_64 bison flex readline.x86_64 readline-devel.x86_64 zlib.x86_64 zlib-devel.x86_64 openssl-devel libxml2 libxml2-devel git wget libnsl libaio glibc-langpack-en glibc-common.x86_64 langpacks-en.noarch glibc-locale-source nss_wrapper.x86_64 gettext

#RUN yum -y remove postgresql-contrib postgresql-server
RUN git clone git://git.postgresql.org/git/postgresql.git && cd postgresql && pwd &&  git checkout REL_13_STABLE && \
#    ./configure --prefix=/usr --disable-rpath --with-openssl --with-libxml && \
    ./configure --prefix=/usr --disable-rpath && \
    gmake -f Makefile clean all install && \
    cd contrib && \
    gmake -f Makefile clean all install
RUN wget https://download.oracle.com/otn_software/linux/instantclient/1914000/instantclient-basic-linux.x64-19.14.0.0.0dbru.zip && \
    unzip instantclient-basic-linux.x64-19.14.0.0.0dbru.zip && \
    rm -f instantclient-basic-linux.x64-19.14.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/1914000/instantclient-sqlplus-linux.x64-19.14.0.0.0dbru.zip && \
    unzip instantclient-sqlplus-linux.x64-19.14.0.0.0dbru.zip && \
    rm -f instantclient-sqlplus-linux.x64-19.14.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/1914000/instantclient-sdk-linux.x64-19.14.0.0.0dbru.zip && \
    unzip instantclient-sdk-linux.x64-19.14.0.0.0dbru.zip && \
    rm -f instantclient-sdk-linux.x64-19.14.0.0.0dbru.zip && \
    cp instantclient_19_14/*.so* /usr/lib
RUN cd postgresql/contrib;git clone https://github.com/laurenz/oracle_fdw.git && export ORACLE_HOME=/instantclient_19_14;cd oracle_fdw; export NO_PGXS=1;gmake clean all install
RUN rm -rf postgresql
RUN rm -rf /opt/app-root/src/instantclient_19_14

# add default user
#RUN adduser default -p xxx

# put our repo in the right place and move the other out of way
#ADD resources/repositories/subscription-manager.conf /etc/yum/pluginconf.d/
#RUN rm /etc/yum.repos.d/ubi.repo
#ADD resources/repositories/yum.repos.d/*.repo /etc/yum.repos.d/
#ADD resources/repositories/yum.repos.d/RPM* /etc/pki/rpm-gpg/

# include BRZ CA certificate 
#ADD resources/ca/brz-stamm-2.crt /etc/pki/ca-trust/source/anchors/
#RUN update-ca-trust
RUN groupadd -g 26 postgres
RUN useradd -u 26 -g 26 -G postgres postgres 

RUN test "$(id postgres)" = "uid=26(postgres) gid=26(postgres) groups=26(postgres)" && \
    mkdir -p /var/lib/pgsql/data
# update
RUN dnf clean all && dnf -y update && dnf clean all
RUN localedef -f UTF-8 -i en_US en_US.UTF-8
#    useradd -u 26 -g 26 postgres && \
#    test "$(id postgres)" = "uid=26(postgres) gid=26(postgres) groups=26(postgres)"
RUN    mkdir -p /var/lib/pgsql/data && mkdir -p /usr/libexec/s2i && mkdir -p /var/run/postgresql && mkdir -p /usr/share/container-scripts/postgresql && chmod 750 /usr/share/container-scripts && chmod 750 /usr/share/container-scripts/postgresql 
ADD ./run/run-postgresql /usr/bin/run-postgresql
ADD run/container-scripts/postgresql /usr/share/container-scripts/postgresql
RUN  ls -l /usr/share/container-scripts
RUN  ls -l /usr/share/container-scripts/postgresql
RUN  chmod 750 /usr/share/container-scripts/postgresql/common.sh
RUN    /usr/libexec/fix-permissions /var/lib/pgsql
RUN    /usr/libexec/fix-permissions /var/run/postgresql

# Get prefix path and path to scripts rather than hard-code them in scripts
ENV CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/postgresql \
    ENABLED_COLLECTIONS=\
    LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH

COPY root /
COPY ./s2i/bin/ /usr/libexec/s2i
RUN chmod 750 /usr/bin/run-postgresql


#RUN /usr/libexec/fix-permissions ${APP_DATA} && \
RUN  usermod -a -G root postgres

USER 26

#ENTRYPOINT ["run-postgresql"]
CMD /usr/bin/run-postgresql
