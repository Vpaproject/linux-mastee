#!/bin/bash
# Ubuntu VPS Installer
# Script by Bonveio Abitona

MyScriptName='KinGmapua'

# OpenSSH Ports
SSH_Port1='22'
SSH_Port2='225'

# Your SSH Banner
SSH_Banner='https://pastebin.com/raw/CnKVT3de'

# Dropbear Ports
Dropbear_Port1='800'
Dropbear_Port2='442'

# Stunnel Ports
Stunnel_Port1='143' # through Dropbear
Stunnel_Port2='144' # through OpenSSH

# OpenVPN Ports
OpenVPN_Port1='1103'
OpenVPN_Port3='25222'
OpenVPN_Port2='69' # take note when you change this port, openvpn sun noload config will not work

# Privoxy Ports (must be 1024 or higher)
Privoxy_Port1='6969'
Privoxy_Port2='9696'
# OpenVPN Config Download Port
OvpnDownload_Port='86' # Before changing this value, please read this document. It contains all unsafe ports for Google Chrome Browser, please read from line #23 to line #89: https://chromium.googlesource.com/chromium/src.git/+/refs/heads/master/net/base/port_util.cc

# Server local time
MyVPS_Time='Asia/Kuala_Lumpur'
#############################


#############################
#############################
## All function used for this script
#############################
## WARNING: Do not modify or edit anything
## if you did'nt know what to do.
## This part is too sensitive.
#############################
#############################

 apt-get update
 apt-get upgrade -y
 
 # Removing some firewall tools that may affect other services
 #apt-get remove --purge ufw firewalld -y

 
 # Installing some important machine essentials
 apt-get install nano wget curl zip unzip tar gzip p7zip-full bc rc openssl cron net-tools dnsutils dos2unix screen bzip2 ccrypt -y
 
 # Now installing all our wanted services
 apt-get install dropbear stunnel4 privoxy ca-certificates nginx ruby apt-transport-https lsb-release squid screenfetch -y

 # Installing all required packages to install Webmin
 apt-get install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python dbus libxml-parser-perl -y
 apt-get install shared-mime-info jq -y
 
 # Installing a text colorizer
 gem install lolcat

 # Trying to remove obsolette packages after installation
 apt-get autoremove -y
 
 # Installing OpenVPN by pulling its repository inside sources.list file 
 #rm -rf /etc/apt/sources.list.d/openvpn*
 echo "deb http://build.openvpn.net/debian/openvpn/stable $(lsb_release -sc) main" >/etc/apt/sources.list.d/openvpn.list && apt-key del E158C569 && wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -
 wget -qO security-openvpn-net.asc "https://keys.openpgp.org/vks/v1/by-fingerprint/F554A3687412CFFEBDEFE0A312F5F7B42F2B01E7" && gpg --import security-openvpn-net.asc
 apt-get update -y
 apt-get install openvpn -y

function InstSSH(){
 # Removing some duplicated sshd server configs
 rm -f /etc/ssh/sshd_config*
 
# Creating a SSH server config using cat eof tricks
 cat <<'MySSHConfig' > /etc/ssh/sshd_config
# My OpenSSH Server config
Port myPORT1
AddressFamily inet
ListenAddress 0.0.0.0
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin yes
MaxSessions 1024
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
ClientAliveInterval 240
ClientAliveCountMax 2
UseDNS no
Banner /etc/banner
AcceptEnv LANG LC_*
Subsystem   sftp  /usr/lib/openssh/sftp-server
MySSHConfig

 # Now we'll put our ssh ports inside of sshd_config
 sed -i "s|myPORT1|$SSH_Port1|g" /etc/ssh/sshd_config

 # Download our SSH Banner
 rm -f /etc/banner
 wget -qO /etc/banner "$SSH_Banner"
 dos2unix -q /etc/banner

 # My workaround code to remove `BAD Password error` from passwd command, it will fix password-related error on their ssh accounts.
 sed -i '/password\s*requisite\s*pam_cracklib.s.*/d' /etc/pam.d/common-password
 sed -i 's/use_authtok //g' /etc/pam.d/common-password

 # Some command to identify null shells when you tunnel through SSH or using Stunnel, it will fix user/pass authentication error on HTTP Injector, KPN Tunnel, eProxy, SVI, HTTP Proxy Injector etc ssh/ssl tunneling apps.
 sed -i '/\/bin\/false/d' /etc/shells
 sed -i '/\/usr\/bin\/nologin/d' /etc/shells
 echo '/bin/false' >> /etc/shells
 echo '/usr/bin/nologin' >> /etc/shells
 
 # Restarting openssh service
 systemctl restart ssh
 
 # Creating dropbear config using cat
 cat <<'MyDropbear' > /etc/default/dropbear
# My Dropbear Config
NO_START=0
DROPBEAR_PORT=Dropbear_Port1
DROPBEAR_EXTRA_ARGS="-p Dropbear_Port2"
DROPBEAR_BANNER="/etc/banner"
DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"
DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"
DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"
DROPBEAR_RECEIVE_WINDOW=65536
MyDropbear

 # Setting dropbear ports
 sed -i "s|Dropbear_Port1|$Dropbear_Port1|g" /etc/default/dropbear
 sed -i "s|Dropbear_Port2|$Dropbear_Port2|g" /etc/default/dropbear

 # Restarting dropbear service
 systemctl restart dropbear
}

function InsStunnel(){
wget https://raw.githubusercontent.com/Vpaproject/KinGmapua/master/s4 && bash s4

 # Restarting stunnel service
 systemctl restart $StunnelDir
 # Restarting stunnel service
 systemctl restart $StunnelDir

}

function InsOpenVPN(){
 # Checking if openvpn folder is accidentally deleted or purged
 if [[ ! -e /etc/openvpn ]]; then
  mkdir -p /etc/openvpn
 fi

 # Removing all existing openvpn server files
 rm -rf /etc/openvpn/*

 # Creating server.conf, ca.crt, server.crt and server.key
 cat <<'myOpenVPNconf1' > /etc/openvpn/server_tcp.conf

# KinGmapua
port MyOvpnPort1
port MyOvpnPort3
proto tcp
dev tun
dev-type tun
sndbuf 0
rcvbuf 0
crl-verify crl.pem
ca ca.crt
cert server.crt
key server.key
tls-auth ta.key 0
dh dh.pem
topology subnet
server 10.9.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
auth SHA256
comp-lzo
user nobody
group nogroup
persist-tun
status openvpn-status.log
verb 2
mute 3
plugin /etc/openvpn/openvpn-auth-pam.so /etc/pam.d/login
verify-client-cert none
username-as-common-name
myOpenVPNconf1
cat <<'myOpenVPNconf2' > /etc/openvpn/server_udp.conf
# KinGmapua

port MyOvpnPort2
proto udp
dev tun
user nobody
group nogroup
persist-key
persist-tun
keepalive 10 120
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "dhcp-option DNS 1.0.0.1"
push "dhcp-option DNS 1.1.1.1"
push "redirect-gateway def1 bypass-dhcp" 
crl-verify crl.pem
ca ca.crt
cert server.crt
key server.key
tls-auth tls-auth.key 0
dh dh.pem
auth SHA256
cipher AES-128-CBC
tls-server
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-128-GCM-SHA256
status openvpn.log
verb 3
plugin /etc/openvpn/openvpn-auth-pam.so /etc/pam.d/login
verify-client-cert none
username-as-common-name
myOpenVPNconf2
 cat <<'EOF7'> /etc/openvpn/ca.crt
-----BEGIN CERTIFICATE-----
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
-----END CERTIFICATE-----
EOF7
 cat <<'EOF9'> /etc/openvpn/client.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 2 (0x2)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=KG, ST=NA, L=BISHKEK, O=OpenVPN-TEST/emailAddress=me@myhost.mydomain
        Validity
            Not Before: Oct 22 21:59:53 2014 GMT
            Not After : Oct 19 21:59:53 2024 GMT
        Subject: C=KG, ST=NA, O=OpenVPN-TEST, CN=Test-Client/emailAddress=me@myhost.mydomain
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:ec:65:8f:e9:12:c2:1a:5b:e6:56:2a:08:a9:82:
                    3a:2d:44:78:a3:00:3b:b0:9f:e7:27:10:40:93:ef:
                    f1:cc:3e:a0:aa:04:a2:80:1b:13:a9:e6:fe:81:d6:
                    70:90:a8:d8:d4:de:30:d8:35:00:d2:be:62:f0:48:
                    da:fc:15:8d:c4:c6:6d:0b:99:f1:2b:83:00:0a:d3:
                    2a:23:0b:e5:cd:f9:35:df:43:61:15:72:ad:95:98:
                    f6:73:21:41:5e:a0:dd:47:27:a0:d5:9a:d4:41:a8:
                    1c:1d:57:20:71:17:8f:f7:28:9e:3e:07:ce:ec:d5:
                    0e:42:4f:1e:74:47:8e:47:9d:d2:14:28:27:2c:14:
                    10:f5:d1:96:b5:93:74:84:ef:f9:04:de:8d:4a:6f:
                    df:77:ab:ea:d1:58:d3:44:fe:5a:04:01:ff:06:7a:
                    97:f7:fd:e3:57:48:e1:f0:df:40:13:9f:66:23:5a:
                    e3:55:54:3d:54:39:ee:00:f9:12:f1:d2:df:74:2e:
                    ba:d7:f0:8d:c6:dd:18:58:1c:93:22:0b:75:fa:a8:
                    d6:e0:b5:2f:2d:b9:d4:fe:b9:4f:86:e2:75:48:16:
                    60:fb:3f:c9:b4:30:42:29:fb:3b:b3:2b:b9:59:81:
                    6a:46:f3:45:83:bf:fd:d5:1a:ff:37:0c:6f:5b:fd:
                    61:f1
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Subject Key Identifier: 
                D2:B4:36:0F:B1:FC:DD:A5:EA:2A:F7:C7:23:89:FA:E3:FA:7A:44:1D
            X509v3 Authority Key Identifier: 
                keyid:2B:40:E5:C9:7D:F5:F4:96:38:E9:2F:E3:2F:D9:40:64:C9:8E:05:9B
                DirName:/C=KG/ST=NA/L=BISHKEK/O=OpenVPN-TEST/emailAddress=me@myhost.mydomain
                serial:A1:4E:DE:FA:90:F2:AE:81

    Signature Algorithm: sha256WithRSAEncryption
         7f:e0:fe:84:a7:ec:df:62:a5:cd:3c:c1:e6:42:b1:31:12:f0:
         b9:da:a7:9e:3f:bd:96:52:b6:fc:55:74:64:3e:e4:ff:7e:aa:
         f7:3e:06:18:5f:73:85:f8:c8:e0:67:1b:4d:97:ca:05:d0:37:
         07:33:64:9b:e6:78:77:14:9a:55:bb:2a:ac:c3:7f:c9:15:08:
         83:5c:c8:c2:61:d3:71:4c:05:0b:2b:cb:a3:87:6d:a0:32:ed:
         b0:b3:27:97:4a:55:8d:01:2a:30:56:68:ab:f2:da:5c:10:73:
         c9:aa:0a:9c:4b:4c:a0:5b:51:6e:0a:7e:6c:53:80:b0:00:e1:
         1e:9a:4c:0a:37:9e:20:89:bc:c5:e5:79:58:b7:45:ff:d3:c4:
         a1:fd:d9:78:3d:45:16:74:df:82:44:1d:1d:81:50:5a:b9:32:
         4c:e2:4f:3f:0e:3a:65:5a:64:83:3b:29:31:c4:99:88:bc:c5:
         84:39:f2:19:12:e1:66:d0:ea:fb:75:b1:d2:27:be:91:59:a3:
         2b:09:d5:5c:bf:46:8e:d6:67:d6:0b:ec:da:ab:f0:80:19:87:
         64:07:a9:77:b1:5e:0c:e2:c5:1d:6a:ac:5d:23:f3:30:75:36:
         4e:ca:c3:4e:b0:4d:8c:2c:ce:52:61:63:de:d5:f5:ef:ef:0a:
         6b:23:25:26:3c:3a:f2:c3:c2:16:19:3f:a9:32:ba:68:f9:c9:
         12:3c:3e:c6:1f:ff:9b:4e:f4:90:b0:63:f5:d1:33:00:30:5a:
         e8:24:fa:35:44:9b:6a:80:f3:a6:cc:7b:3c:73:5f:50:c4:30:
         71:d8:74:90:27:0a:01:4e:a5:5e:b1:f8:da:c2:61:81:11:ae:
         29:a3:8f:fa:7e:4c:4e:62:b1:00:de:92:e3:8f:6a:2e:da:d9:
         38:5d:6b:7c:0d:e4:01:aa:c8:c6:6d:8b:cd:c0:c8:6e:e4:57:
         21:8a:f6:46:30:d9:ad:51:a1:87:96:a6:53:c9:1e:c6:bb:c3:
         eb:55:fe:8c:d6:5c:d5:c6:f3:ca:b0:60:d2:d4:2a:1f:88:94:
         d3:4c:1a:da:0c:94:fe:c1:5d:0d:2a:db:99:29:5d:f6:dd:16:
         c4:c8:4d:74:9e:80:d9:d0:aa:ed:7b:e3:30:e4:47:d8:f5:15:
         c1:71:b8:c6:fd:ee:fc:9e:b2:5f:b5:b7:92:ed:ff:ca:37:f6:
         c7:82:b4:54:13:9b:83:cd:87:8b:7e:64:f6:2e:54:3a:22:b1:
         c5:c1:f4:a5:25:53:9a:4d:a8:0f:e7:35:4b:89:df:19:83:66:
         64:d9:db:d1:61:2b:24:1b:1d:44:44:fb:49:30:87:b7:49:23:
         08:02:8a:e0:25:f3:f4:43
-----BEGIN CERTIFICATE-----
MIIFFDCCAvygAwIBAgIBAjANBgkqhkiG9w0BAQsFADBmMQswCQYDVQQGEwJLRzEL
MAkGA1UECBMCTkExEDAOBgNVBAcTB0JJU0hLRUsxFTATBgNVBAoTDE9wZW5WUE4t
VEVTVDEhMB8GCSqGSIb3DQEJARYSbWVAbXlob3N0Lm15ZG9tYWluMB4XDTE0MTAy
MjIxNTk1M1oXDTI0MTAxOTIxNTk1M1owajELMAkGA1UEBhMCS0cxCzAJBgNVBAgT
Ak5BMRUwEwYDVQQKEwxPcGVuVlBOLVRFU1QxFDASBgNVBAMTC1Rlc3QtQ2xpZW50
MSEwHwYJKoZIhvcNAQkBFhJtZUBteWhvc3QubXlkb21haW4wggEiMA0GCSqGSIb3
DQEBAQUAA4IBDwAwggEKAoIBAQDsZY/pEsIaW+ZWKgipgjotRHijADuwn+cnEECT
7/HMPqCqBKKAGxOp5v6B1nCQqNjU3jDYNQDSvmLwSNr8FY3Exm0LmfErgwAK0yoj
C+XN+TXfQ2EVcq2VmPZzIUFeoN1HJ6DVmtRBqBwdVyBxF4/3KJ4+B87s1Q5CTx50
R45HndIUKCcsFBD10Za1k3SE7/kE3o1Kb993q+rRWNNE/loEAf8Gepf3/eNXSOHw
30ATn2YjWuNVVD1UOe4A+RLx0t90LrrX8I3G3RhYHJMiC3X6qNbgtS8tudT+uU+G
4nVIFmD7P8m0MEIp+zuzK7lZgWpG80WDv/3VGv83DG9b/WHxAgMBAAGjgcgwgcUw
CQYDVR0TBAIwADAdBgNVHQ4EFgQU0rQ2D7H83aXqKvfHI4n64/p6RB0wgZgGA1Ud
IwSBkDCBjYAUK0DlyX319JY46S/jL9lAZMmOBZuhaqRoMGYxCzAJBgNVBAYTAktH
MQswCQYDVQQIEwJOQTEQMA4GA1UEBxMHQklTSEtFSzEVMBMGA1UEChMMT3BlblZQ
Ti1URVNUMSEwHwYJKoZIhvcNAQkBFhJtZUBteWhvc3QubXlkb21haW6CCQChTt76
kPKugTANBgkqhkiG9w0BAQsFAAOCAgEAf+D+hKfs32KlzTzB5kKxMRLwudqnnj+9
llK2/FV0ZD7k/36q9z4GGF9zhfjI4GcbTZfKBdA3BzNkm+Z4dxSaVbsqrMN/yRUI
g1zIwmHTcUwFCyvLo4dtoDLtsLMnl0pVjQEqMFZoq/LaXBBzyaoKnEtMoFtRbgp+
bFOAsADhHppMCjeeIIm8xeV5WLdF/9PEof3ZeD1FFnTfgkQdHYFQWrkyTOJPPw46
ZVpkgzspMcSZiLzFhDnyGRLhZtDq+3Wx0ie+kVmjKwnVXL9GjtZn1gvs2qvwgBmH
ZAepd7FeDOLFHWqsXSPzMHU2TsrDTrBNjCzOUmFj3tX17+8KayMlJjw68sPCFhk/
qTK6aPnJEjw+xh//m070kLBj9dEzADBa6CT6NUSbaoDzpsx7PHNfUMQwcdh0kCcK
AU6lXrH42sJhgRGuKaOP+n5MTmKxAN6S449qLtrZOF1rfA3kAarIxm2LzcDIbuRX
IYr2RjDZrVGhh5amU8kexrvD61X+jNZc1cbzyrBg0tQqH4iU00wa2gyU/sFdDSrb
mSld9t0WxMhNdJ6A2dCq7XvjMORH2PUVwXG4xv3u/J6yX7W3ku3/yjf2x4K0VBOb
g82Hi35k9i5UOiKxxcH0pSVTmk2oD+c1S4nfGYNmZNnb0WErJBsdRET7STCHt0kj
CAKK4CXz9EM=
-----END CERTIFICATE-----
EOF9
 cat <<'EOF10'> /etc/openvpn/client.key
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDsZY/pEsIaW+ZW
KgipgjotRHijADuwn+cnEECT7/HMPqCqBKKAGxOp5v6B1nCQqNjU3jDYNQDSvmLw
SNr8FY3Exm0LmfErgwAK0yojC+XN+TXfQ2EVcq2VmPZzIUFeoN1HJ6DVmtRBqBwd
VyBxF4/3KJ4+B87s1Q5CTx50R45HndIUKCcsFBD10Za1k3SE7/kE3o1Kb993q+rR
WNNE/loEAf8Gepf3/eNXSOHw30ATn2YjWuNVVD1UOe4A+RLx0t90LrrX8I3G3RhY
HJMiC3X6qNbgtS8tudT+uU+G4nVIFmD7P8m0MEIp+zuzK7lZgWpG80WDv/3VGv83
DG9b/WHxAgMBAAECggEBAIOdaCpUD02trOh8LqZxowJhBOl7z7/ex0uweMPk67LT
i5AdVHwOlzwZJ8oSIknoOBEMRBWcLQEojt1JMuL2/R95emzjIKshHHzqZKNulFvB
TIUpdnwChTKtH0mqUkLlPU3Ienty4IpNlpmfUKimfbkWHERdBJBHbtDsTABhdo3X
9pCF/yRKqJS2Fy/Mkl3gv1y/NB1OL4Jhl7vQbf+kmgfQN2qdOVe2BOKQ8NlPUDmE
/1XNIDaE3s6uvUaoFfwowzsCCwN2/8QrRMMKkjvV+lEVtNmQdYxj5Xj5IwS0vkK0
6icsngW87cpZxxc1zsRWcSTloy5ohub4FgKhlolmigECgYEA+cBlxzLvaMzMlBQY
kCac9KQMvVL+DIFHlZA5i5L/9pRVp4JJwj3GUoehFJoFhsxnKr8HZyLwBKlCmUVm
VxnshRWiAU18emUmeAtSGawlAS3QXhikVZDdd/L20YusLT+DXV81wlKR97/r9+17
klQOLkSdPm9wcMDOWMNHX8bUg8kCgYEA8k+hQv6+TR/+Beao2IIctFtw/EauaJiJ
wW5ql1cpCLPMAOQUvjs0Km3zqctfBF8mUjdkcyJ4uhL9FZtfywY22EtRIXOJ/8VR
we65mVo6RLR8YVM54sihanuFOnlyF9LIBWB+9pUfh1/Y7DSebh7W73uxhAxQhi3Y
QwfIQIFd8OkCgYBalH4VXhLYhpaYCiXSej6ot6rrK2N6c5Tb2MAWMA1nh+r84tMP
gMoh+pDgYPAqMI4mQbxUmqZEeoLuBe6VHpDav7rPECRaW781AJ4ZM4cEQ3Jz/inz
4qOAMn10CF081/Ez9ykPPlU0bsYNWHNd4eB2xWnmUBKOwk7UgJatVPaUiQKBgQCI
f18CVGpzG9CHFnaK8FCnMNOm6VIaTcNcGY0mD81nv5Dt943P054BQMsAHTY7SjZW
HioRyZtkhonXAB2oSqnekh7zzxgv4sG5k3ct8evdBCcE1FNJc2eqikZ0uDETRoOy
s7cRxNNr+QxDkyikM+80HOPU1PMPgwfOSrX90GJQ8QKBgEBKohGMV/sNa4t14Iau
qO8aagoqh/68K9GFXljsl3/iCSa964HIEREtW09Qz1w3dotEgp2w8bsDa+OwWrLy
0SY7T5jRViM3cDWRlUBLrGGiL0FiwsfqiRiji60y19erJgrgyGVIb1kIgIBRkgFM
2MMweASzTmZcri4PA/5C0HYb
-----END PRIVATE KEY-----
EOF10
 cat <<'EOF18'> /etc/openvpn/tls-auth.key
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
bdcfd0846a6e313b81166314b6b3837c
b4860c3d84ac2f17fcf26a7ca090974c
97ec8395c67b98090560e82120b16eb0
d3f237fb7d5033985db907a3e3fce5ab
ee5bad86b77a36166f80b594aa3b53db
87863f3250e931d37a1b66703d7691b7
88c4e0e648fa278da3c883247daa3c38
379a26c262ed37a6ee1ec7ba826e703b
e9f4a494f89b253499e0b64f20250157
cb182c932bdd916de5aef07ff6e5a4ee
b3eb7aec6a058785ff771d2c18432790
195eae67a96f383be5931c1356734a6b
f4c619cb97094fd337f971b340bad41b
bb774d630c2eb24fd0057785d505afee
6a2749f79febf7bdb1e5a6c62f250c55
2f2448e5be01abb287151073d53f3996
-----END OpenVPN Static key V1-----
EOF18
 cat <<'EOF107'> /etc/openvpn/server.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 1 (0x1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=KG, ST=NA, L=BISHKEK, O=OpenVPN-TEST/emailAddress=me@myhost.mydomain
        Validity
            Not Before: Oct 22 21:59:52 2014 GMT
            Not After : Oct 19 21:59:52 2024 GMT
        Subject: C=KG, ST=NA, O=OpenVPN-TEST, CN=Test-Server/emailAddress=me@myhost.mydomain
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:a5:b8:a2:ee:ce:b1:a6:0f:6a:b2:9f:d3:22:17:
                    79:de:09:98:71:78:fa:a7:ce:36:51:54:57:c7:31:
                    99:56:d1:8a:d6:c5:fd:52:e6:88:0e:7b:f9:ea:27:
                    7a:bf:3f:14:ec:aa:d2:ff:8b:56:58:ac:ca:51:77:
                    c5:3c:b6:e4:83:6f:22:06:2d:5b:eb:e7:59:d4:ab:
                    42:c8:d5:a9:87:73:b3:73:36:51:2f:a5:d0:90:a2:
                    87:64:54:6c:12:d3:b8:76:47:69:af:ae:8f:00:b3:
                    70:b9:e7:67:3f:8c:6a:3d:79:5f:81:27:a3:0e:aa:
                    a7:3d:81:48:10:b1:18:6c:38:2e:8f:7a:7b:c5:3d:
                    21:c8:f9:a0:7f:17:2b:88:4f:ba:f2:ec:6d:24:8e:
                    6c:f1:0a:5c:d9:5b:b1:b0:fc:49:cb:4a:d2:58:c6:
                    2a:25:b0:97:84:c3:9e:ff:34:8c:10:46:7f:0f:fb:
                    3c:59:7a:a6:29:0c:ae:8e:50:3a:f2:53:84:40:2d:
                    d5:91:7b:0a:37:8e:82:77:ce:66:2f:34:77:5c:a5:
                    45:3b:00:19:a7:07:d1:92:e6:66:b9:3b:4e:e9:63:
                    fc:33:98:1a:ae:7b:08:7d:0a:df:7a:ba:aa:59:6d:
                    86:82:0a:64:2b:da:59:a7:4c:4e:ef:3d:bd:04:a2:
                    4b:31
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            Netscape Cert Type: 
                SSL Server
            Netscape Comment: 
                OpenSSL Generated Server Certificate
            X509v3 Subject Key Identifier: 
                B3:9D:81:E6:16:92:64:C4:86:87:F5:29:10:1B:5E:2F:74:F7:ED:B1
            X509v3 Authority Key Identifier: 
                keyid:2B:40:E5:C9:7D:F5:F4:96:38:E9:2F:E3:2F:D9:40:64:C9:8E:05:9B
                DirName:/C=KG/ST=NA/L=BISHKEK/O=OpenVPN-TEST/emailAddress=me@myhost.mydomain
                serial:A1:4E:DE:FA:90:F2:AE:81

            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Key Usage:
                Digital Signature, Key Encipherment
    Signature Algorithm: sha256WithRSAEncryption
         4e:25:80:1b:cb:b0:42:ff:bb:3f:e8:0d:58:c1:80:db:cf:d0:
         90:df:ca:c1:e6:41:e1:48:7f:a7:1e:c7:35:9f:9c:6d:7c:3e:
         82:e8:de:7e:ae:82:16:00:33:0f:02:23:f1:9d:fe:2b:06:16:
         05:55:16:89:dc:63:ac:5f:1a:31:13:79:21:a3:6e:60:28:e8:
         e7:6b:54:00:22:a1:b7:69:5a:17:31:ce:0f:c2:a6:dd:a3:6f:
         de:ea:19:6c:d2:d2:cb:35:9d:dd:87:51:33:68:cd:c3:9b:90:
         55:f1:80:3d:5c:b8:09:b6:e1:3c:13:a4:5d:4a:ce:a5:11:9e:
         f9:08:ee:be:e3:54:1d:06:4c:bb:1b:72:13:ee:7d:a0:45:cc:
         fe:d1:3b:02:03:c1:d4:ea:45:2d:a8:c9:97:e7:f3:8a:7a:a0:
         2f:dd:48:3a:75:c9:42:28:94:fc:af:44:52:16:68:98:d6:ad:
         a8:65:b1:cd:ac:60:41:70:e5:44:e8:5a:f2:e7:fc:3b:fe:45:
         89:17:1d:6d:85:c6:f0:fc:69:87:d1:1d:07:f3:cb:7b:54:8d:
         aa:a3:cc:e3:c6:fc:d6:05:76:35:d0:26:63:8e:d1:a8:b7:ff:
         61:42:8a:2c:63:1f:d4:ec:14:47:6b:1e:e3:81:61:12:3b:8c:
         16:b5:cf:87:6a:2d:42:21:83:9c:0e:3a:90:3a:1e:c1:36:61:
         41:f9:fb:4e:5d:ea:f4:df:23:92:33:2b:9b:14:9f:a0:f5:d3:
         c4:f8:1f:2f:9c:11:36:af:2a:22:61:95:32:0b:c4:1c:2d:b1:
         c1:0a:2a:97:c0:43:4a:6c:3e:db:00:cd:29:15:9e:7e:41:75:
         36:a8:56:86:8c:82:9e:46:20:e5:06:1e:60:d2:03:5f:9f:9e:
         69:bb:bf:c2:b4:43:e2:7d:85:17:83:18:41:b0:cb:a9:04:1b:
         18:52:9f:89:8b:76:9f:94:59:81:4f:60:5b:33:18:fc:c7:52:
         d0:d2:69:fc:0b:a2:63:32:75:43:99:e9:d7:f8:6d:c7:55:31:
         0c:f3:ef:1a:71:e1:0a:57:e1:9d:13:b2:1e:fe:1d:ef:e4:f1:
         51:d9:95:b3:fd:28:28:93:91:4a:29:c5:37:0e:ab:d8:85:6a:
         fe:a8:83:1f:7b:80:5d:1f:04:79:b7:a9:08:6e:0d:d6:2e:aa:
         7c:f6:63:7d:41:de:70:13:32:ce:dd:58:cc:a6:73:d4:72:7e:
         d7:ac:74:a8:35:ba:c3:1b:2a:64:d7:5a:37:97:56:94:34:2b:
         2a:71:60:bc:69:ab:00:85:b9:4f:67:32:17:51:c3:da:57:3a:
         37:89:66:c4:7a:51:da:5f
-----BEGIN CERTIFICATE-----
MIIFgDCCA2igAwIBAgIBATANBgkqhkiG9w0BAQsFADBmMQswCQYDVQQGEwJLRzEL
MAkGA1UECBMCTkExEDAOBgNVBAcTB0JJU0hLRUsxFTATBgNVBAoTDE9wZW5WUE4t
VEVTVDEhMB8GCSqGSIb3DQEJARYSbWVAbXlob3N0Lm15ZG9tYWluMB4XDTE0MTAy
MjIxNTk1MloXDTI0MTAxOTIxNTk1MlowajELMAkGA1UEBhMCS0cxCzAJBgNVBAgT
Ak5BMRUwEwYDVQQKEwxPcGVuVlBOLVRFU1QxFDASBgNVBAMTC1Rlc3QtU2VydmVy
MSEwHwYJKoZIhvcNAQkBFhJtZUBteWhvc3QubXlkb21haW4wggEiMA0GCSqGSIb3
DQEBAQUAA4IBDwAwggEKAoIBAQCluKLuzrGmD2qyn9MiF3neCZhxePqnzjZRVFfH
MZlW0YrWxf1S5ogOe/nqJ3q/PxTsqtL/i1ZYrMpRd8U8tuSDbyIGLVvr51nUq0LI
1amHc7NzNlEvpdCQoodkVGwS07h2R2mvro8As3C552c/jGo9eV+BJ6MOqqc9gUgQ
sRhsOC6PenvFPSHI+aB/FyuIT7ry7G0kjmzxClzZW7Gw/EnLStJYxiolsJeEw57/
NIwQRn8P+zxZeqYpDK6OUDryU4RALdWRewo3joJ3zmYvNHdcpUU7ABmnB9GS5ma5
O07pY/wzmBquewh9Ct96uqpZbYaCCmQr2lmnTE7vPb0EoksxAgMBAAGjggEzMIIB
LzAJBgNVHRMEAjAAMBEGCWCGSAGG+EIBAQQEAwIGQDAzBglghkgBhvhCAQ0EJhYk
T3BlblNTTCBHZW5lcmF0ZWQgU2VydmVyIENlcnRpZmljYXRlMB0GA1UdDgQWBBSz
nYHmFpJkxIaH9SkQG14vdPftsTCBmAYDVR0jBIGQMIGNgBQrQOXJffX0ljjpL+Mv
2UBkyY4Fm6FqpGgwZjELMAkGA1UEBhMCS0cxCzAJBgNVBAgTAk5BMRAwDgYDVQQH
EwdCSVNIS0VLMRUwEwYDVQQKEwxPcGVuVlBOLVRFU1QxITAfBgkqhkiG9w0BCQEW
Em1lQG15aG9zdC5teWRvbWFpboIJAKFO3vqQ8q6BMBMGA1UdJQQMMAoGCCsGAQUF
BwMBMAsGA1UdDwQEAwIFoDANBgkqhkiG9w0BAQsFAAOCAgEATiWAG8uwQv+7P+gN
WMGA28/QkN/KweZB4Uh/px7HNZ+cbXw+gujefq6CFgAzDwIj8Z3+KwYWBVUWidxj
rF8aMRN5IaNuYCjo52tUACKht2laFzHOD8Km3aNv3uoZbNLSyzWd3YdRM2jNw5uQ
VfGAPVy4CbbhPBOkXUrOpRGe+QjuvuNUHQZMuxtyE+59oEXM/tE7AgPB1OpFLajJ
l+fzinqgL91IOnXJQiiU/K9EUhZomNatqGWxzaxgQXDlROha8uf8O/5FiRcdbYXG
8Pxph9EdB/PLe1SNqqPM48b81gV2NdAmY47RqLf/YUKKLGMf1OwUR2se44FhEjuM
FrXPh2otQiGDnA46kDoewTZhQfn7Tl3q9N8jkjMrmxSfoPXTxPgfL5wRNq8qImGV
MgvEHC2xwQoql8BDSmw+2wDNKRWefkF1NqhWhoyCnkYg5QYeYNIDX5+eabu/wrRD
4n2FF4MYQbDLqQQbGFKfiYt2n5RZgU9gWzMY/MdS0NJp/AuiYzJ1Q5np1/htx1Ux
DPPvGnHhClfhnROyHv4d7+TxUdmVs/0oKJORSinFNw6r2IVq/qiDH3uAXR8Eebep
CG4N1i6qfPZjfUHecBMyzt1YzKZz1HJ+16x0qDW6wxsqZNdaN5dWlDQrKnFgvGmr
AIW5T2cyF1HD2lc6N4lmxHpR2l8=
-----END CERTIFICATE-----
EOF107
 cat <<'EOF113'> /etc/openvpn/server.key
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCluKLuzrGmD2qy
n9MiF3neCZhxePqnzjZRVFfHMZlW0YrWxf1S5ogOe/nqJ3q/PxTsqtL/i1ZYrMpR
d8U8tuSDbyIGLVvr51nUq0LI1amHc7NzNlEvpdCQoodkVGwS07h2R2mvro8As3C5
52c/jGo9eV+BJ6MOqqc9gUgQsRhsOC6PenvFPSHI+aB/FyuIT7ry7G0kjmzxClzZ
W7Gw/EnLStJYxiolsJeEw57/NIwQRn8P+zxZeqYpDK6OUDryU4RALdWRewo3joJ3
zmYvNHdcpUU7ABmnB9GS5ma5O07pY/wzmBquewh9Ct96uqpZbYaCCmQr2lmnTE7v
Pb0EoksxAgMBAAECggEAPMOMin+jR75TYxeTNObiunVOPh0b2zeTVxLT9KfND7ZZ
cBK8pg79SEJRCnhbW5BnvbeNEkIm8PC6ZlDCM1bkRwUStq0fDUqQ95esLzOYq5/S
5qW98viblszhU/pYfja/Zi8dI1uf96PT63Zbt0NnGQ9N42+DLDeKhtTGdchZqiQA
LeSR0bQanY4tUUtCNYvBT8E3pzhoIsUzVwzIK53oovRpcOX3pMXVYZsmNhXdFFRy
YkjMXpj7fGyaAJK0QsC+PsgrKuhXDzDttsG2lI/mq9+7RXB3d/pzhmBVWynVH2lw
iQ7ONkSz7akDz/4I4WmxJep+FfQJYgK6rnLAlQqauQKBgQDammSAprnvDvNhSEp8
W+xt7jQnFqaENbGgP0/D/OZMXc4khgexqlKFmSnBCRDmQ6JvLTWqDXC4+aqAbFQz
zAIjiKaT+so8xvFRob+rBMJY5JLYKNa+zUUanfORUNYLFJPvFqnrWGaJ9uufdaM7
0a5bu95PN74NXee3DBbpBv8HLwKBgQDCEk+IjNbjMT+Neq0ywUeM5rFrUKi92abe
AgsVpjbighRV+6jA2lZFJcize+xYJ9wiOR1/TEI9PZ2OtBkqpwVdvTEHTagRLcvd
NfGcptREDnNLoNWA22buQpztiEduutACWQsrd+JQmqbUicUdW4zw86/oCMbYCW3V
QmYOLns7nwKBgHHUX20WZE91S4pmqFKlUzHTDdkk1ESX6Qx2q0R01j8BwawHFs6O
0DW9EZ7w55nfsh+OPRl1sjK/3ubMgfQO0TZLm+IGf3Sya0qEnVeiPMkpDMX+TgRA
wzEe+ou6uho+9uFSvdxMxeglaYA5M2ycvNwLsbEyZ4ZyVYxdgTiKahYFAoGAcIfP
iD0qKQiYcj/tB94cz+3AeJqHjbYT1O1YYhBECOkmQ4kuG80+cs/q5W/45lEOiuWV
Xgfo7Lu6jVGOujWoneci87oqtvNYH4e09oGh2WiLoBG9Wv9dWtBTUERSLzmxfXsG
SAk2uEhEbj8IhfJc8iZLHH9iVUh6YEslBBodqL8CgYEAlAhvcqAvw5SzsfBR5Mcu
4Nql6mXEVhHCvS4hdFCGaNF0z9A6eBORKJpdLWnqhpquDQDsghWE+Ga4QKSNFIi1
fnAaykmZuY3ToqNOIaVlYM6HpMEz0wHQbTWfDLGcTFcElLZgMAk7VlDyiYVOco+E
QX9lXOO1PGpLzXhlDxSe63Y=
-----END PRIVATE KEY-----
EOF113
 cat <<'EOF13'> /etc/openvpn/dh.pem
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA2w2E4Ppnc89jXP4tBsMizxtRPmpwJkYoBpF9EVN5QO/ws96/x8Te
hAg2mD6ZzoPFm4KhjD9YrD+M3c05j2kCLMnPc81i+EQ6M+xG6hzbPl5D8upe3W3/
RoYadS85yIEJPs+SFToO3tXZlCklbU9+MVm8FaWohC32j4O3dNTDvKIQtSWjU0WC
m1OVQAgdv4TZtcF5/FSGFbbcGY1arrrX0JK4+0ThW9XktTL9LPCNM/0UqSAqSB89
LvFFlL47ek5JPMh76ulEBxWco2FHbnSsIWd12rYMGRn7G/EqbR1pQi+3UNMQpAIz
5JnupCKu4GFS6KU5q1WKg0q1IBvhNroRwwIBAg==
-----END DH PARAMETERS-----
EOF13
 cat <<'EOF103'> /etc/openvpn/crl.pem
-----BEGIN X509 CRL-----
MIIBvDCBpQIBATANBgkqhkiG9w0BAQsFADAZMRcwFQYDVQQDDA52cG4uZjVsYWJz
LmRldhcNMjEwMTE0MDI1MTIzWhcNMzEwMTEyMDI1MTIzWqBYMFYwVAYDVR0jBE0w
S4AU/Ga3V1iPk7I6YR5DeNQuQ+9e5DWhHaQbMBkxFzAVBgNVBAMMDnZwbi5mNWxh
YnMuZGV2ghRRnHaHIWPU0/8eVLJ7jd8THvVqrDANBgkqhkiG9w0BAQsFAAOCAQEA
qv7+B4WNPqRI4WAiTnCtE/vQlQeKnn39NvDEbjfpJjNZAadQxaTeYtO58TOCu5R4
qwF42g0E2mUQvwUEmUeVulnDjEz5e6KOkgllWsrZGwlUObuKNNKrCHqvXxbH/rHk
76/4Jfu7IvqTk4a9c+MV5r5eSA7plRzdJhqgkBWCmD/46UlP2imkgNGg4FeAamuc
kiLEVXPwjRK30L3uUcWXzvXmXtLlvaadPHKPS5YA41WKS0xZ9iELIz0eUHXl8pgd
jrZFH4tMHWZ+mBTRA/76xsbBGWtkxND932g1vAc281EHv9+4iyW1SdvUTJNzZObh
6GJJ6ESQE6h3vJJpVeoFCg==
-----END X509 CRL-----
EOF103
 cat <<'EOF122'> /etc/openvpn/ta.key
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
bc9d409e9a4df82007b978554f6bc974
b360b2ff4f6d00ab0756b5df091d59e2
f349b570c670b618755d8afeb54bbb6e
2b9c78c08e2eb77d7d14a445d90cb59c
ecd86a1c0c37c065cd88116a482310d8
443fd165fe89ce0632823a09e6eb601b
58144f16288426c10790d23f2a64c704
7a3d935e5d72c9cc0e8ae9dfe8d6aba7
9e14e8852757410836d05adaa82c227c
3bf1a2e3f81fbcb7cae591c43ddd4f55
3a2531faff9826fabb658fe9f4932857
ad8a3fb591b103280dab6de8700810b6
1f02645ae953b08e5f6c8fe107ac84ad
fdd665b9706c06d6f053bbb68cfcef55
afb0eff582231b8d7c640d85b6981b1f
f9ad3c476af859c708825b5212cc94df
-----END OpenVPN Static key V1-----
EOF122

 # Getting all dns inside resolv.conf then use as Default DNS for our openvpn server
 #grep -v '#' /etc/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read -r line; do
	#echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server_tcp.conf
#done
 #grep -v '#' /etc/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read -r line; do
	#echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server_udp.conf
#done

 # setting openvpn server port
 sed -i "s|MyOvpnPort1|$OpenVPN_Port1|g" /etc/openvpn/server_tcp.conf
 sed -i "s|MyOvpnPort3|$OpenVPN_Port3|g" /etc/openvpn/server_tcp.conf
 sed -i "s|MyOvpnPort2|$OpenVPN_Port2|g" /etc/openvpn/server_udp.conf
 
 # Generating openvpn dh.pem file using openssl
 #openssl dhparam -out /etc/openvpn/dh.pem 1024
 
 # Getting some OpenVPN plugins for unix authentication
 wget -qO /etc/openvpn/b.zip 'https://raw.githubusercontent.com/Bonveio/BonvScripts/master/openvpn_plugin64'
 unzip -qq /etc/openvpn/b.zip -d /etc/openvpn
 rm -f /etc/openvpn/b.zip
 
 # Some workaround for OpenVZ machines for "Startup error" openvpn service
 if [[ "$(hostnamectl | grep -i Virtualization | awk '{print $2}' | head -n1)" == 'openvz' ]]; then
 sed -i 's|LimitNPROC|#LimitNPROC|g' /lib/systemd/system/openvpn*
 systemctl daemon-reload
fi

 # Allow IPv4 Forwarding
 echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/20-openvpn.conf && sysctl --system &> /dev/null && echo 1 > /proc/sys/net/ipv4/ip_forward

 # Iptables Rule for OpenVPN server
 #PUBLIC_INET="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
 #IPCIDR='10.200.0.0/16'
 #iptables -I FORWARD -s $IPCIDR -j ACCEPT
 #iptables -t nat -A POSTROUTING -o $PUBLIC_INET -j MASQUERADE
 #iptables -t nat -A POSTROUTING -s $IPCIDR -o $PUBLIC_INET -j MASQUERADE
 
 # Installing Firewalld
 apt install firewalld -y
 systemctl start firewalld
 systemctl enable firewalld
 firewall-cmd --quiet --set-default-zone=public
 firewall-cmd --quiet --zone=public --permanent --add-port=1-65534/tcp
 firewall-cmd --quiet --zone=public --permanent --add-port=1-65534/udp
 firewall-cmd --quiet --reload
 firewall-cmd --quiet --add-masquerade
 firewall-cmd --quiet --permanent --add-masquerade
 firewall-cmd --quiet --permanent --add-service=ssh
 firewall-cmd --quiet --permanent --add-service=openvpn
 firewall-cmd --quiet --permanent --add-service=http
 firewall-cmd --quiet --permanent --add-service=https
 firewall-cmd --quiet --permanent --add-service=privoxy
 firewall-cmd --quiet --permanent --add-service=squid
 firewall-cmd --quiet --reload
 
 # Enabling IPv4 Forwarding
 echo 1 > /proc/sys/net/ipv4/ip_forward
 
 # Starting OpenVPN server
 systemctl start openvpn@server_tcp
 systemctl start openvpn@server_udp
 systemctl enable openvpn@server_tcp
 systemctl enable openvpn@server_udp
 systemctl restart openvpn@server_tcp
 systemctl restart openvpn@server_udp
 
 # Pulling OpenVPN no internet fixer script
 #wget -qO /etc/openvpn/openvpn.bash "https://raw.githubusercontent.com/Bonveio/BonvScripts/master/openvpn.bash"
 #0chmod +x /etc/openvpn/openvpn.bash
}

function InsProxy(){
 # I'm setting Some Squid workarounds to prevent Privoxy's overflowing file descriptors that causing 50X error when clients trying to connect to your proxy server(thanks for this trick @homer_simpsons)
 apt remove --purge squid -y
 rm -rf /etc/squid/sq*
 apt install squid -y
 
# Squid Ports (must be 1024 or higher)
 Proxy_Port1='8000'
 Proxy_Port2='8888'
 cat <<mySquid > /etc/squid/squid.conf
acl VPN dst $(wget -4qO- http://ipinfo.io/ip)/32
http_access allow VPN
http_access deny all 
http_port 0.0.0.0:$Proxy_Port1
http_port 0.0.0.0:$Proxy_Port2
coredump_dir /var/spool/squid
dns_nameservers 1.1.1.1 1.0.0.1
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname localhost
mySquid

 sed -i "s|SquidCacheHelper|$Privoxy_Port1|g" /etc/squid/squid.conf

 # Starting Proxy server
 echo -e "Restarting proxy server.."
 systemctl restart privoxy
 systemctl restart squid
}

function OvpnConfigs(){
 # Creating nginx config for our ovpn config downloads webserver
 cat <<'myNginxC' > /etc/nginx/conf.d/bonveio-ovpn-config.conf
# My OpenVPN Config Download Directory
server {
 listen 0.0.0.0:myNginx;
 server_name localhost;
 root /var/www/openvpn;
 index index.html;
}
myNginxC

 # Setting our nginx config port for .ovpn download site
 sed -i "s|myNginx|$OvpnDownload_Port|g" /etc/nginx/conf.d/bonveio-ovpn-config.conf

 # Removing Default nginx page(port 80)
 rm -rf /etc/nginx/sites-*

 # Creating our root directory for all of our .ovpn configs
 rm -rf /var/www/openvpn
 mkdir -p /var/www/openvpn

 # Now creating all of our OpenVPN Configs 
cat <<EOF152> /var/www/openvpn/tcp.ovpn
# OpenVPN Server build v2.5.4
# Server Location: SG, Singapore
# Server ISP: DigitalOcean, LLC
#
# Experimental Config only
# Examples demonstrated below on how to Play with OHPServer
# Credits to kinGmapua

client
dev tun
proto tcp
remote $IPADDR $OpenVPN_Port1
http-proxy $(curl -s http://ipinfo.io/ip || wget -q http://ipinfo.io/ip) $Proxy_Port1
resolv-retry infinite
route-method exe
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo
cipher AES-256-CBC
auth SHA256
push "redirect-gateway def1 bypass-dhcp"
verb 3
push-peer-info
ping 10
ping-restart 60
hand-window 70
server-poll-timeout 4
reneg-sec 2592000
sndbuf 0
rcvbuf 0
remote-cert-tls server
key-direction 1
<auth-user-pass>
sam
sam
</auth-user-pass>
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/client.crt)
</cert>
<key>
$(cat /etc/openvpn/client.key)
</key>
<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
EOF152

cat <<EOF16> /var/www/openvpn/udp.ovpn
# OpenVPN Server build v2.5.4
# Server Location: SG, Singapore
# Server ISP: DigitalOcean, LLC
#
# Experimental Config only
# Examples demonstrated below on how to Play with OHPServer
# Credits to kinGmapua

client
dev tun
proto udp
remote $IPADDR $OpenVPN_Port2
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verify-x509-name server_ADBtkp0yL46HLXPb name
auth SHA256
auth-nocache
cipher AES-128-CBC
tls-client
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-128-GCM-SHA256
setenv opt block-outside-dns
verb 3
auth-user-pass
key-direction 1
<auth-user-pass>
sam
sam
</auth-user-pass>
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/client.crt)
</cert>
<key>
$(cat /etc/openvpn/client.key)
</key>
<tls-auth>
$(cat /etc/openvpn/tls-auth.key)
</tls-auth>
EOF16

cat <<EOF160> /var/www/openvpn/ssl.ovpn
# OpenVPN Server build v2.5.4
# Server Location: SG, Singapore
# Server ISP: DigitalOcean, LLC
#
# Experimental Config only
# Examples demonstrated below on how to Play with OHPServer
# Credits to kinGmapua

client
dev tun
proto tcp
remote 127.0.0.1 $OpenVPN_Port1
route $IPADDR 255.255.255.255 net_gateway 
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
comp-lzo
cipher AES-256-CBC
auth SHA256
push "redirect-gateway def1 bypass-dhcp"
verb 3
push-peer-info
ping 10
ping-restart 60
hand-window 70
server-poll-timeout 4
reneg-sec 2592000
sndbuf 0
rcvbuf 0
remote-cert-tls server
key-direction 1
<auth-user-pass>
sam
sam
</auth-user-pass>
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/client.crt)
</cert>
<key>
$(cat /etc/openvpn/client.key)
</key>
<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
EOF160

cat <<EOF17> /var/www/openvpn/ohp.ovpn
# OpenVPN Server build vOPENVPN_SERVER_VERSION
# Server Location: OPENVPN_SERVER_LOCATION
# Server ISP: OPENVPN_SERVER_ISP
#
# Experimental Config only
# Examples demonstrated below on how to Play with OHPServer
# Credits to kinGmapua

client
dev tun
proto tcp

# We can play this one, put any host on the line
# remote anyhost.com anyport
# remote www.google.com.ph 443
#
# We can also play with CRLFs
#remote "HEAD https://ajax.googleapis.com HTTP/1.1/r/n/r/n"
# Every types of Broken remote line setups/crlfs/payload are accepted, just put them inside of double-quotes
remote "https://www.phcorner.net"
## use this line to modify OpenVPN remote port (this will serve as our fake ovpn port)
port 443

# This proxy uses as our main forwarder for OpenVPN tunnel.
http-proxy $IPADDR $Ohp_Port

# We can also play our request headers here, everything are accepted, put them inside of a double-quotes.
http-proxy-option VERSION 1.1
http-proxy-option CUSTOM-HEADER ""
http-proxy-option CUSTOM-HEADER "Host: www.phcorner.net%2F"
http-proxy-option CUSTOM-HEADER "X-Forwarded-Host: www.digicert.net%2F"
http-proxy-option CUSTOM-HEADER ""
http-proxy-retry
route-method exe
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo
cipher AES-256-CBC
auth SHA256
push "redirect-gateway def1 bypass-dhcp"
verb 3
push-peer-info
ping 10
ping-restart 60
hand-window 70
server-poll-timeout 4
reneg-sec 2592000
sndbuf 0
rcvbuf 0
remote-cert-tls server
key-direction 1
<auth-user-pass>
sam
sam
</auth-user-pass>
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/client.crt)
</cert>
<key>
$(cat /etc/openvpn/client.key)
</key>
<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
EOF17

 # Creating OVPN download site index.html
cat <<'mySiteOvpn' > /var/www/openvpn/index.html
<!DOCTYPE html>
<html lang="en">

<!-- OVPN Download site by XAMJYSS -->

<head><meta charset="utf-8" /><title>MyScriptName OVPN Config Download</title><meta name="description" content="MyScriptName Server" /><meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport" /><meta name="theme-color" content="#000000" /><link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.2/css/all.css"><link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet"><link href="https://cdnjs.cloudflare.com/ajax/libs/mdbootstrap/4.8.3/css/mdb.min.css" rel="stylesheet"></head><body><div class="container justify-content-center" style="margin-top:9em;margin-bottom:5em;"><div class="col-md"><div class="view"><img src="https://openvpn.net/wp-content/uploads/openvpn.jpg" class="card-img-top"><div class="mask rgba-white-slight"></div></div><div class="card"><div class="card-body"><h5 class="card-title">Config List</h5><br /><ul class="list-group"><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>For Globe/TM <span class="badge light-blue darken-4">Android/iOS</span><br /><small> For EZ/GS Promo with WNP freebies</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/tcp.ovpn" style="float:right;"><i class="fa fa-download"></i> Download</a></li><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>For Sun <span class="badge light-blue darken-4">Android/iOS/PC/Modem</span><br /><small> For TU/CTC UDP Promos</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/udp.ovpn" style="float:right;"><i class="fa fa-download"></i> Download</a></li><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>For Sun <span class="badge light-blue darken-4">Android/iOS/PC/MODEM</span><br /><small> TNT GIGASTORIES</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/ssl.ovpn" style="float:right;"><i class="fa fa-download"></i> Download</a></li></ul></div></div></div></div></body></html>
mySiteOvpn
 
 # Setting template's correct name,IP address and nginx Port
 sed -i "s|MyScriptName|$MyScriptName|g" /var/www/openvpn/index.html
 sed -i "s|NGINXPORT|$OvpnDownload_Port|g" /var/www/openvpn/index.html
 sed -i "s|IP-ADDRESS|$IPADDR|g" /var/www/openvpn/index.html

 # Restarting nginx service
 systemctl restart nginx
 
 # Creating all .ovpn config archives
 cd /var/www/openvpn
 zip -qq -r Configs.zip *.ovpn
 cd
}

function ip_address(){
  local IP="$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipv4.icanhazip.com )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipinfo.io/ip )"
  [ ! -z "${IP}" ] && echo "${IP}" || echo
} 
IPADDR="$(ip_address)"

function ConfStartup(){
 # Daily reboot time of our machine
 # For cron commands, visit https://crontab.guru
 echo -e "0 0 * * * /sbin/reboot >/dev/null 2>&1" >> /etc/cron.d/mdadm

 # Creating directory for startup script
 rm -rf /etc/barts
 mkdir -p /etc/barts
 chmod -R 755 /etc/barts
 
 # Creating startup script using cat eof tricks
 cat <<'EOFSH' > /etc/barts/startup.sh
#!/bin/bash
# Setting server local time
ln -fs /usr/share/zoneinfo/MyVPS_Time /etc/localtime

# Prevent DOS-like UI when installing using APT (Disabling APT interactive dialog)
export DEBIAN_FRONTEND=noninteractive

# Allowing ALL TCP ports for our machine (Simple workaround for policy-based VPS)
iptables -A INPUT -s $(wget -4qO- http://ipinfo.io/ip) -p tcp -m multiport --dport 1:65535 -j ACCEPT

# Allowing OpenVPN to Forward traffic
/bin/bash /etc/openvpn/openvpn.bash

# Deleting Expired SSH Accounts
/usr/local/sbin/delete_expired &> /dev/null
EOFSH
 chmod +x /etc/barts/startup.sh
 
 # Setting server local time every time this machine reboots
 sed -i "s|MyVPS_Time|$MyVPS_Time|g" /etc/barts/startup.sh

 # 
 rm -rf /etc/sysctl.d/99*

 # Setting our startup script to run every machine boots 
 echo "[Unit]
Description=Barts Startup Script
Before=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash /etc/barts/startup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/barts.service
 chmod +x /etc/systemd/system/barts.service
 systemctl daemon-reload
 systemctl start barts
 systemctl enable barts &> /dev/null

 # Rebooting cron service
 systemctl restart cron
 systemctl enable cron
 
}

function ConfMenu(){
echo -e " Creating Menu scripts.."

cd /usr/local/sbin/
rm -rf {accounts,base-ports,base-ports-wc,base-script,bench-network,clearcache,connections,create,create_random,create_trial,delete_expired,diagnose,edit_dropbear,edit_openssh,edit_openvpn,edit_ports,edit_squid3,edit_stunnel4,locked_list,menu,options,ram,reboot_sys,reboot_sys_auto,restart_services,server,set_multilogin_autokill,set_multilogin_autokill_lib,show_ports,speedtest,user_delete,user_details,user_details_lib,user_extend,user_list,user_lock,user_unlock}
wget -q 'https://raw.githubusercontent.com/Barts-23/menu1/master/menu.zip'
unzip -qq menu.zip
rm -f menu.zip
chmod +x ./*
dos2unix ./* &> /dev/null
sed -i 's|/etc/squid/squid.conf|/etc/privoxy/config|g' ./*
sed -i 's|http_port|listen-address|g' ./*
cd ~

echo 'clear' > /etc/profile.d/barts.sh
echo 'echo '' > /var/log/syslog' >> /etc/profile.d/barts.sh
echo 'screenfetch -p -A Android' >> /etc/profile.d/barts.sh
chmod +x /etc/profile.d/barts.sh
}

function ScriptMessage(){
 echo -e " (｡◕‿◕｡) $MyScriptName Ubuntu VPS Installer"
 echo -e " Open release version"
 echo -e ""
 echo -e " Script created by Bonveio"
 echo -e " Edited by XAMJYSS"
}


#############################
#############################
## Installation Process
#############################
## WARNING: Do not modify or edit anything
## if you did'nt know what to do.
## This part is too sensitive.
#############################
#############################

 # First thing to do is check if this machine is Debian
 source /etc/os-release
if [[ "$ID" != 'ubuntu' ]]; then
 ScriptMessage
 echo -e "[\e[1;31mError\e[0m] This script is for Ubuntu only, exting..." 
 exit 1
fi

 # Now check if our machine is in root user, if not, this script exits
 # If you're on sudo user, run `sudo su -` first before running this script
 if [[ $EUID -ne 0 ]];then
 ScriptMessage
 echo -e "[\e[1;31mError\e[0m] This script must be run as root, exiting..."
 exit 1
fi

 # (For OpenVPN) Checking it this machine have TUN Module, this is the tunneling interface of OpenVPN server
 if [[ ! -e /dev/net/tun ]]; then
 echo -e "[\e[1;31m×\e[0m] You cant use this script without TUN Module installed/embedded in your machine, file a support ticket to your machine admin about this matter"
 echo -e "[\e[1;31m-\e[0m] Script is now exiting..."
 exit 1
fi

 # Begin Installation by Updating and Upgrading machine and then Installing all our wanted packages/services to be install.
 ScriptMessage
 sleep 2
 
 # Configure OpenSSH and Dropbear
 echo -e "Configuring ssh..."
 InstSSH
 
 # Configure Stunnel
 echo -e "Configuring stunnel..."
 InsStunnel
 
 # Configure Privoxy and Squid
 echo -e "Configuring proxy..."
 InsProxy
 
 # Configure OpenVPN
 echo -e "Configuring OpenVPN..."
 InsOpenVPN
 
 # Configuring Nginx OVPN config download site
 OvpnConfigs

 # Some assistance and startup scripts
 ConfStartup

 # VPS Menu script v1.0
 ConfMenu
 
 # Setting server local time
 ln -fs /usr/share/zoneinfo/$MyVPS_Time /etc/localtime
 
 clear
 cd ~

 # Running sysinfo 
 bash /etc/profile.d/barts.sh
 
 # Showing script's banner message
 ScriptMessage
 
 # Showing additional information from installating this script
 echo -e ""
 echo -e " Success Installation"
 echo -e ""
 echo -e " Service Ports: "
 echo -e " OpenSSH: $SSH_Port1, $SSH_Port2"
 echo -e " Stunnel: $Stunnel_Port1, $Stunnel_Port2"
 echo -e " DropbearSSH: $Dropbear_Port1, $Dropbear_Port2"
 echo -e " Privoxy: $Privoxy_Port1, $Privoxy_Port2"
 echo -e " Squid: $Proxy_Port1, $Proxy_Port2"
 echo -e " OpenVPN: $OpenVPN_Port1, $OpenVPN_Port2, $OpenVPN_Port3"
 echo -e " NGiNX: $OvpnDownload_Port"
 echo -e " Webmin: 10000"
 #echo -e " L2tp IPSec Key: xjvpn13"
 echo -e ""
 echo -e ""
 echo -e " OpenVPN Configs Download site"
 echo -e " http://$IPADDR:$OvpnDownload_Port"
 echo -e ""
 echo -e " All OpenVPN Configs Archive"
 echo -e " http://$IPADDR:$OvpnDownload_Port/Configs.zip"
 echo -e ""
 echo -e ""
 echo -e " [Note] DO NOT RESELL THIS SCRIPT"

 # Clearing all logs from installation
 rm -rf /root/.bash_history && history -c && echo '' > /var/log/syslog

rm -f b*
exit 1
