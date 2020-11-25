# ddns_ipv6.sh
基于 DNSPod 实现的 IPv6的 DDNS 动态更新

解析 json 需要安装 jq
apt/brew/yum install jq

自行安装，没有做太多兼容判断。
自行配置 API Token 与域名信息。

子域名请先自行创建 AAAA 记录。

# 更新

基于 Ubuntu 20.04 系统，仅适合中国 IPv6 地址使用。

1. 删除大部分注释，防止命令行中文乱码。
2. 修改 IP 获取命令，非中国 IPv6 地址无法使用
3. 修改 jq 路径

已知问题：空白的 Crontab 无法自动添加，需要手动添加。