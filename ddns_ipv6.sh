#!/bin/bash

# DNSPod API Token (Url: https://www.dnspod.cn/console/user/security)
# IPv6 reocrd must be added first.
DNSPOD_API_TOKEN='9***4,8755*********fa39';
DOMAIN_HOST='example.com'
DOMAIN_SUB='ddns'
DNSPOD_API_HOST='https://dnsapi.cn/'

BIN_JQ='/usr/bin/jq'

#=========== Configuration End ===========

get_ip() {
    LOCAL_IP=`ip -6 addr| grep -o 'inet6 240e[a-fA-F0-9:]\+' | cut -d ' ' -f2`
}

api_send() {
    API_URL="${DNSPOD_API_HOST}${1}"
    POST_DATA="login_token=${DNSPOD_API_TOKEN}&format=json&lang=cn&${2}";

    result=`/usr/bin/curl -s -X POST "${API_URL}" -d "${POST_DATA}"`;
    return_id=`echo ${result} | ${BIN_JQ} -r '.status.code'`;

    if [ ${return_id} != 1 ]; then
        echo "Failure(${return_id}): `echo ${result} | ${BIN_JQ} -r '.status.message'`";
        echo -e "Url: ${API_URL}\nData: ${POST_DATA}\nResult: ${result}\n";
        exit ${return_id};
    fi

    return $return_id;
}

check_update_ip() {
    date

    api_send 'Info.Version'
    echo "DNSPod API Version: `echo ${result} | ${BIN_JQ} -r '.status.message'`"

    api_send 'Record.List' "domain=${DOMAIN_HOST}&sub_domain=${DOMAIN_SUB}&record_type=AAAA"

    get_ip

    DDNS_IP=`echo ${result} | ${BIN_JQ} -r '.records[0].value'`

    echo -e "Local IP = '${LOCAL_IP}'\n DDNS IP = '${DDNS_IP}'";

    if [ ${LOCAL_IP} != ${DDNS_IP} ]; then
        record_id=`echo ${result} | ${BIN_JQ} -r '.records[0].id'`
        record_line_id=`echo ${result} | ${BIN_JQ} -r '.records[0].line_id'`
        api_send 'Record.Modify' "domain=${DOMAIN_HOST}&record_id=${record_id}&sub_domain=${DOMAIN_SUB}&record_type=AAAA&record_line_id=${record_line_id}&value=${LOCAL_IP}"
        echo -e "Sccuess: `echo ${result} | ${BIN_JQ} -r '.status.message'`\n";
    else
        echo -e 'None: IP has not changed.\n'
    fi;
}

install() {

    if [ ! `id -u` -eq '0' ]; then
        echo "Plase use root user.";
        exit 1;
    fi

    ${BIN_JQ} --version
    if [ $? != 0 ]; then
        echo "Please install jq.";
        exit 0;
    fi

    mkdir -p /etc/cron.d/
    cp $0 /etc/cron.d/ddns_ipv6.sh
    chmod +x /etc/cron.d/ddns_ipv6.sh

    mkdir -p /usr/local/var/log/ddns_ipv6/

    tmp_file=$(mktemp) || exit 1

    crontab -l > "${tmp_file}" && echo "*/2 * * * * /etc/cron.d/ddns_ipv6.sh check >> /usr/local/var/log/ddns_ipv6/logs.log" >> "${tmp_file}" && crontab "${tmp_file}" && rm -f "${tmp_file}"

    echo 'Successfully installed'
}

if [ "check" == "$1" ]; then
    check_update_ip;
    exit;
fi

install;
