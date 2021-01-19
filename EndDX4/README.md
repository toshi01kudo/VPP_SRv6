# VPP_SRv6_End.DX4機能検証

## 各ファイル説明
* setup.cfg: VPPのstartup-config。```機器名_setup.cfg``` の形式で保存していますが、```setup.cfg```に名前変更してください。
* create-ns.sh: Network Namespaceを設定するシェルスクリプト。```sudo bash create-ns.sh``` で実行することを想定。```機器名_create-ns.sh``` の形式で保存していますが、```create-ns.sh```に名前変更してください。
* startup.conf: ```/etc/vpp/startup.conf```にデフォルトで保存してあるファイル。下記のstartup-configとインターフェース設定の項目を追加している。
```
unix {
  startup-config /home/ubuntu/setup.cfg
}
dpdk {
  dev 0000:00:04.0
}
```

## 設定解説

## 検証結果

### 疎通確認
* BSIDでポリシーを指定しているためNamespaceからのPingやTraceは可能。Traceは途中のSRv6区間の経路は表示されないらしい。
```
// Namespaceへログイン
ubuntu@ubuntu-kudo-01:~$ sudo ip netns exec RT1 bash

// Namespaceから対向へPing
root@ubuntu-kudo-01:~# ping 172.24.62.100
PING 172.24.62.100 (172.24.62.100) 56(84) bytes of data.
64 bytes from 172.24.62.100: icmp_seq=1 ttl=62 time=5.86 ms
64 bytes from 172.24.62.100: icmp_seq=2 ttl=62 time=0.767 ms
64 bytes from 172.24.62.100: icmp_seq=3 ttl=62 time=0.712 ms
64 bytes from 172.24.62.100: icmp_seq=4 ttl=62 time=0.463 ms
^C
--- 172.24.62.100 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3050ms
rtt min/avg/max/mdev = 0.463/1.951/5.865/2.262 ms

// Namespaceから対向へTrace (途中経路のIPv4アドレスを設定しないと表示されない)
root@ubuntu-kudo-01:~# traceroute 172.24.62.100
traceroute to 172.24.62.100 (172.24.62.100), 30 hops max, 60 byte packets
 1  * * *
 2  * * *
 3  172.24.62.100 (172.24.62.100)  1.798 ms  1.843 ms  1.891 ms
```

* VPPからのPingは失敗する。BSIDのポリシーに合わないため。
```
ubuntu@ubuntu-kudo-01:~$ sudo vppctl ping 172.24.62.100
Failed: no egress interface
Failed: no egress interface
Failed: no egress interface
Failed: no egress interface
Failed: no egress interface

Statistics: 0 sent, 0 received, 0% packet loss
```

### showコマンド出力確認

