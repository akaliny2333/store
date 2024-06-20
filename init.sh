#!/usr/bin/env bash
echo=echo
for cmd in echo /bin/echo; do
    $cmd >/dev/null 2>&1 || continue

    if ! $cmd -e "" | grep -qE '^-e'; then
        echo=$cmd
        break
    fi
done

CSI=$($echo -e "\033[")
CEND="${CSI}0m"
CYELLOW="${CSI}1;33m"
CGREEN="${CSI}1;32m"

OUT_ALERT() {
    echo -e "${CYELLOW}$1${CEND}"
}
OUT_FINISH() {
    echo -e "${CGREEN}$1${CEND}"
}

OUT_ALERT "----------设置SSH密钥登录----------"
mkdir -p /root/.ssh
cat > /root/.ssh/authorized_keys << EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKimEFDgD84/JsD1eNOWF84cS/vuwe+adEA2Sn48Mdgi
EOF
chmod 600 /root/.ssh/authorized_keys
chmod 700 /root/.ssh
sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
service ssh restart
OUT_FINISH "----------设置密钥登录完成----------"
OUT_ALERT "----------系统参数调优----------"
chattr -i /etc/sysctl.conf
cat > /etc/sysctl.conf << EOF
# CloudFlare缓冲区调优
net.ipv4.tcp_rmem=8192 262144 536870912
net.ipv4.tcp_wmem=4096 16384 536870912
net.ipv4.tcp_adv_win_scale=-2
net.ipv4.tcp_notsent_lowat=131072

# TCP缓冲区内存设置
net.ipv4.tcp_mem=262144 2097152 16777216

# 套接字相关
net.core.optmem_max=102400
net.ipv4.tcp_max_orphans=262144
net.unix.max_dgram_qlen=65535

# 提升吞吐量
net.ipv4.tcp_slow_start_after_idle=0

# 支持超过64KB的TCP窗口
net.ipv4.tcp_window_scaling=1

# 文件描述符的最大值
fs.file-max=10485760

# 监视文件数量
fs.inotify.max_user_instances=65535

# 连接复用
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_local_port_range=1024 65535

# 增大缓冲队列
net.core.somaxconn=65535
net.ipv4.tcp_abort_on_overflow=1
net.ipv4.tcp_max_tw_buckets=65535
net.core.netdev_max_backlog=65535
net.ipv4.tcp_max_syn_backlog=65535

# TCP连接相关
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_retries1=3
net.ipv4.tcp_retries2=5
net.ipv4.neigh.default.gc_stale_time=120
net.ipv4.neigh.default.gc_thresh1=1024
net.ipv4.neigh.default.gc_thresh2=4096
net.ipv4.neigh.default.gc_thresh3=8192
net.netfilter.nf_conntrack_max=1048576
net.netfilter.nf_conntrack_buckets=262144
net.netfilter.nf_conntrack_tcp_timeout_established=300

# 停用SWAP
vm.swappiness=0

# 开启IPV4转发
net.ipv4.ip_forward=1

# 开启BBR
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
cat > /etc/security/limits.conf << EOF
root    -    nofile      1048576
root    -    nproc       1048576
root    -    core        unlimited
root    -    data        unlimited
root    -    fsize       unlimited
root    -    memlock     unlimited
root    -    rss         unlimited
root    -    stack       unlimited
root    -    cpu         unlimited
root    -    as          unlimited
root    -    locks       unlimited
root    -    sigpending  unlimited
root    -    msgqueue    unlimited
*    -    nofile      1048576
*    -    nproc       1048576
*    -    core        unlimited
*    -    data        unlimited
*    -    fsize       unlimited
*    -    memlock     unlimited
*    -    rss         unlimited
*    -    stack       unlimited
*    -    cpu         unlimited
*    -    as          unlimited
*    -    locks       unlimited
*    -    sigpending  unlimited
*    -    msgqueue    unlimited
EOF
cat > /etc/systemd/system.conf <<EOF
[Manager]
DefaultLimitCPU=infinity
DefaultLimitFSIZE=infinity
DefaultLimitDATA=infinity
DefaultLimitSTACK=infinity
DefaultLimitCORE=infinity
DefaultLimitRSS=infinity
DefaultLimitNOFILE=1048576
DefaultLimitAS=infinity
DefaultLimitNPROC=1048576
DefaultLimitMEMLOCK=infinity
DefaultLimitLOCKS=infinity
DefaultLimitSIGPENDING=infinity
DefaultLimitMSGQUEUE=infinity
EOF
cat > /etc/systemd/user.conf <<EOF
[Manager]
DefaultLimitCPU=infinity
DefaultLimitFSIZE=infinity
DefaultLimitDATA=infinity
DefaultLimitSTACK=infinity
DefaultLimitCORE=infinity
DefaultLimitRSS=infinity
DefaultLimitNOFILE=1048576
DefaultLimitAS=infinity
DefaultLimitNPROC=1048576
DefaultLimitMEMLOCK=infinity
DefaultLimitLOCKS=infinity
DefaultLimitSIGPENDING=infinity
DefaultLimitMSGQUEUE=infinity
EOF
cat > /etc/systemd/journald.conf <<EOF
[Journal]
SystemMaxUse=384M
SystemMaxFileSize=128M
ForwardToSyslog=no
EOF
ulimit -SHn 1048576
ulimit -SHu 1048576
systemctl daemon-reload
modprobe ip_conntrack
sysctl -p
timedatectl set-timezone Asia/Shanghai
OUT_FINISH "----------系统调优完成----------"
exit 0
