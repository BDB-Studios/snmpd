ARG BUILD_IMAGE="rockylinux:8"

FROM ${BUILD_IMAGE} as BASE
RUN > /var/log/dnf.log && \
    dnf -y update && \
    dnf install -y perl-ExtUtils-Embed && \
    rm -rf /var/log/* && \
    rm -rf /var/cache/dnf/*


FROM BASE as BUILDER
ARG SNMP_VERSION="5.9.3"
WORKDIR /tmp

RUN > /var/log/dnf.log && \
    dnf install -y make \
    gcc \
    gcc-c++ \
    zlib-devel \
    perl-devel \
    file

RUN curl -L -o "net-snmp-${SNMP_VERSION}.tar.gz" "https://sourceforge.net/projects/net-snmp/files/net-snmp/${SNMP_VERSION}/net-snmp-${SNMP_VERSION}.tar.gz" && \
    tar zxf "net-snmp-${SNMP_VERSION}.tar.gz"

ADD apply_patch.sh /tmp/apply_patch.sh

RUN cd "net-snmp-${SNMP_VERSION}" && \
    ../apply_patch.sh && \
    ./configure --prefix=/usr/local --disable-ipv6 --disable-snmpv1 --with-defaults && \
    make && \
    make install && \
    rm -rf *

#########################################################################
# Don't forget to run docker image with: -v /proc:/host_proc
#########################################################################
FROM BASE
EXPOSE 161 161/udp
WORKDIR /usr/local

COPY --from=BUILDER /usr/local/sbin/ /usr/local/sbin/
COPY --from=BUILDER /usr/local/lib/ /usr/local/lib/

ADD snmpd.conf /usr/local/etc/snmpd.conf

RUN rm -rf /tmp/* && \
    rm -rf /lib/rpm/*

CMD [ "/usr/local/sbin/snmpd", "-f", "-c", "/usr/local/etc/snmpd.conf" ]
