#!/bin/bash 

if [ -n "${DOMAIN_NAME}" ]; then
 sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/postfix/main.cf
 sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/postfix/local-host-names
 sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/postfix/helo_check 
 sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/postfix/domains
 sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/opendkim/opendkim.conf
 sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/opendkim/TrustedHosts
 sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/opendkim/SigningTable
 sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/opendkim/KeyTable
 sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/openldap/docker-compose.yml
 
fi

if [ -n "${HOST_NAME}" ]; then
 sed -i "s/HOST_NAME/${HOST_NAME}/g" /etc/postfix/main.cf
 sed -i "s/HOST_NAME/${HOST_NAME}/g" /etc/postfix/local-host-names
 sed -i "s/HOST_NAME/${HOST_NAME}/g" /etc/dovecot/conf.d/10-ssl.conf
 sed -i "s/HOST_NAME/${HOST_NAME}/g" /etc/opendkim/TrustedHosts

fi

if [ -n "${SEARCH_BASE}" ]; then
 sed -i "s/SEARCH_BASE/${SEARCH_BASE}/g" /etc/postfix/ldap-users.cf
 sed -i "s/SEARCH_BASE/${SEARCH_BASE}/g" /etc/postfix/ldap-aliases.cf
 sed -i "s/SEARCH_BASE/${SEARCH_BASE}/g" /etc/postfix/saslauthd.conf 
 sed -i "s/SEARCH_BASE/${SEARCH_BASE}/g" /etc/dovecot/dovecot-ldap.conf.ext 
 sed -i "s/SEARCH_BASE/${SEARCH_BASE}/g" /etc/dovecot/dovecot-ldap2.conf.ext 
fi

if [ -n "${HOST_IP}" ]; then
 sed -i "s/HOST_IP/${HOST_IP}/g" /etc/postfix/ldap-users.cf
 sed -i "s/HOST_IP/${HOST_IP}/g" /etc/postfix/ldap-aliases.cf
 sed -i "s/HOST_IP/${HOST_IP}/g" /etc/postfix/saslauthd.conf 
 sed -i "s/HOST_IP/${HOST_IP}/g" /etc/dovecot/dovecot-ldap.conf.ext 
 sed -i "s/HOST_IP/${HOST_IP}/g" /etc/dovecot/dovecot-ldap2.conf.ext 
 
fi

if [ -n "${BIND_DN}" ]; then
 sed -i "s/BIND_DN/${BIND_DN}/g" /etc/postfix/ldap-users.cf
 sed -i "s/BIND_DN/${BIND_DN}/g" /etc/postfix/ldap-aliases.cf
 sed -i "s/BIND_DN/${BIND_DN}/g" /etc/postfix/saslauthd.conf
 sed -i "s/BIND_DN/${BIND_DN}/g" /etc/dovecot/dovecot-ldap.conf.ext 
 sed -i "s/BIND_DN/${BIND_DN}/g" /etc/dovecot/dovecot-ldap2.conf.ext 
fi

if [ -n "${BIND_PW}" ]; then
 sed -i "s/BIND_PW/${BIND_PW}/g" /etc/postfix/ldap-users.cf
 sed -i "s/BIND_PW/${BIND_PW}/g" /etc/postfix/ldap-aliases.cf
 sed -i "s/BIND_PW/${BIND_PW}/g" /etc/postfix/saslauthd.conf
 sed -i "s/BIND_PW/${BIND_PW}/g" /etc/dovecot/dovecot-ldap.conf.ext 
 sed -i "s/BIND_PW/${BIND_PW}/g" /etc/dovecot/dovecot-ldap2.conf.ext 
 sed -i "s/BIND_PW/${BIND_PW}/g" /etc/openldap/docker-compose.yml
fi

if [ -n "${ALIASES}" ]; then
 sed -i "s/ALIASES/${ALIASES}/g" /etc/postfix/ldap-aliases.cf
else
 sed -i "s/\,ldap\:\/etc\/postfix\/ldap-aliases\.cf/ /g" /etc/postfix/main.cf
fi

if [ -n "${MY_NETWORKS}" ]; then
 sed -i "s/MY_NETWORKS/${MY_NETWORKS}/g" /etc/postfix/main.cf
else
 sed -i "s/\,MY_NETWORKS/ /g" /etc/postfix/main.cf
fi

if [[ "${ENABLE_QUOTA}" == "true" ]]; then
  sed -i "s/QUOTA_MAIN/check_policy_service inet\:localhost\:12340/g" /etc/postfix/main.cf
  sed -i "s/QUOTA_MAIL/quota/g" /etc/dovecot/conf.d/10-mail.conf
  sed -i "s/QUOTA_IMAP/imap_quota/g" /etc/dovecot/conf.d/20-imap.conf
else
  sed -i "s/QUOTA_MAIN/#check_policy_service inet\:localhost\:12340/g" /etc/postfix/main.cf
  sed -i "s/QUOTA_MAIL/ /g" /etc/dovecot/conf.d/10-mail.conf
  sed -i "s/QUOTA_IMAP/ /g" /etc/dovecot/conf.d/20-imap.conf  
fi

if [ -n "${TZ}" ] ; then
 TZ="${TZ}"; export TZ ;
else
 TZ="Asia/Taipei"; export TZ ;
fi 

if [ ! -f "/etc/opendkim/keys/default.private" ];  then
  /usr/sbin/opendkim-genkey -d "${DOMAIN_NAME}" ;
  /usr/bin/cp default.* /etc/opendkim/keys
  /usr/bin/mkdir -p  /var/lib/rspamd/dkim
  /usr/bin/cp default.private /var/lib/rspamd/dkim/${DOMAIN_NAME}.dkim.key
fi

/usr/bin/chown -R vmail:vmail /home/vmail
chown -R opendkim:opendkim /etc/opendkim
postmap /etc/postfix/helo_check
postmap /etc/postfix/sender_bcc
postmap /etc/postfix/recipient_bcc

if grep -Fq "ntpdate" /etc/crontab 
then
  echo "na" 
else
  echo "0 0 * * * root /usr/bin/freshclam" >> /etc/crontab
  /usr/bin/crontab /etc/crontab
fi
chown -R _rspamd:_rspamd /etc/rspamd/override.d  
chown -R _rspamd:_rspamd /var/lib/rspamd
/usr/bin/supervisord -c /etc/supervisord.conf
