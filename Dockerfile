FROM centos:latest
#########################################################################
# Don't forget to run docker image with: -v /proc:/host_proc
#########################################################################

EXPOSE 161 161/udp
WORKDIR /tmp

RUN yum -y update
RUN > /var/log/yum.log && \
    yum install -y make \
    gcc \
    gcc-c++ \
    zlib-devel \
    perl-ExtUtils-Embed \
    perl-devel \
    file

RUN curl -L -o net-snmp-5.9.tar.gz 'https://sourceforge.net/projects/net-snmp/files/net-snmp/5.9/net-snmp-5.9.tar.gz' && \
    tar zxf net-snmp-5.9.tar.gz

ADD apply_patch.sh /tmp/apply_patch.sh

RUN cd net-snmp-5.9 && \
    ../apply_patch.sh && \
    ./configure --prefix=/usr/local --disable-ipv6 --disable-snmpv1 --with-defaults && \
    make && \
    make install

ADD snmpd.conf /usr/local/etc/snmpd.conf

CMD [ "/usr/local/sbin/snmpd", "-f", "-c", "/usr/local/etc/snmpd.conf" ]
