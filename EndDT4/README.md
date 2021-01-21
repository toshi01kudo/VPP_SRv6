# VPP_SRv6_End.DT4機能検証

End Functionのうち、End.DT4の検証をまとめる。\
End.DT4 はSRv6区間から出るタイミングで、VRFを指定して送信する機能。\

[End.DX4](https://github.com/toshi01kudo/VPP_SRv6/tree/main/EndDX4)の説明と重複する箇所は説明しないので、先にEnd.DX4を確認のこと。

## 機器構成
![NWD](../VPP_SRv6_NWDv4.png)

## 設定解説

 - VRFの指定
    - VRFの作成: ```ip table add 10```
    - InterfaceへのVRF適用: ```set interface ip table host-RT1 10```
 - Node SID と End Function設定: ```sr localsid address fd60:5::5 behavior end.dt4 10```
    - Node SID宛に着信したパケットについて、End Functionに基づいて処理。今回はEnd.DT4なので、VRF番号のみを指定。

## 検証結果

### 疎通確認

```
// Namespaceへログイン
ubuntu@ubuntu-kudo-01:~$ sudo ip netns exec RT1 bash

// Namespaceから対向へPing
root@ubuntu-kudo-01:~# ping 172.24.62.100
PING 172.24.62.100 (172.24.62.100) 56(84) bytes of data.
64 bytes from 172.24.62.100: icmp_seq=1 ttl=62 time=1.48 ms
64 bytes from 172.24.62.100: icmp_seq=2 ttl=62 time=0.642 ms
64 bytes from 172.24.62.100: icmp_seq=3 ttl=62 time=0.600 ms
64 bytes from 172.24.62.100: icmp_seq=4 ttl=62 time=0.609 ms
64 bytes from 172.24.62.100: icmp_seq=5 ttl=62 time=0.650 ms
^C
--- 172.24.62.100 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4064ms
rtt min/avg/max/mdev = 0.600/0.797/1.488/0.347 ms

// 上記パケットの受信側のBSIDのポリシーに合致していることの確認
ubuntu@ubuntu-kudo-02:~$ sudo vppctl show sr localsid
SRv6 - My LocalSID Table:
=========================
        Address:        fd60:10::10/128
        Behavior:       DT4 (Endpoint with decapsulation and specific IPv4 table lookup)
        Table:  10
        Good traffic:   [15 packets : 1260 bytes]
        Bad traffic:    [0 packets : 0 bytes]
--------------------


// Namespace RT1からのTraceではIPv6区間は表示されない
root@ubuntu-kudo-01:~# traceroute 172.24.62.100
traceroute to 172.24.62.100 (172.24.62.100), 30 hops max, 60 byte packets
 1  * * *
 2  * * *
 3  * * *
 4  * * *
 5  * * *
 6  * 172.24.62.100 (172.24.62.100)  2.948 ms  3.433 ms

ubuntu@ubuntu-kudo-02:~$ sudo vppctl show sr localsid
SRv6 - My LocalSID Table:
=========================
        Address:        fd60:10::10/128
        Behavior:       DT4 (Endpoint with decapsulation and specific IPv4 table lookup)
        Table:  10
        Good traffic:   [34 packets : 2400 bytes]
        Bad traffic:    [0 packets : 0 bytes]
--------------------


// VPPからの直接のPingは不可。# SR Policyで定義してないため。（Staticも定義していない）
ubuntu@ubuntu-kudo-01:~$ sudo vppctl ping 172.24.62.100
Failed: no egress interface
Failed: no egress interface
Failed: no egress interface
Failed: no egress interface
Failed: no egress interface

Statistics: 0 sent, 0 received, 0% packet loss
ubuntu@ubuntu-kudo-01:~$



// Namespace RT2からもOK (反対方向)
ubuntu@ubuntu-kudo-02:~$ sudo ip netns exec RT2 bash
root@ubuntu-kudo-02:~# ping 172.24.61.100
PING 172.24.61.100 (172.24.61.100) 56(84) bytes of data.
64 bytes from 172.24.61.100: icmp_seq=1 ttl=62 time=5.28 ms
64 bytes from 172.24.61.100: icmp_seq=2 ttl=62 time=0.597 ms
64 bytes from 172.24.61.100: icmp_seq=3 ttl=62 time=0.653 ms
64 bytes from 172.24.61.100: icmp_seq=4 ttl=62 time=0.593 ms
64 bytes from 172.24.61.100: icmp_seq=5 ttl=62 time=0.475 ms
^C
--- 172.24.61.100 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4064ms
rtt min/avg/max/mdev = 0.475/1.519/5.280/1.881 ms
// 上記パケットの受信側のBSIDのポリシーに合致していることの確認
ubuntu@ubuntu-kudo-01:~$ sudo vppctl show sr localsid
SRv6 - My LocalSID Table:
=========================
        Address:        fd60:5::5/128
        Behavior:       DT4 (Endpoint with decapsulation and specific IPv4 table lookup)
        Table:  10
        Good traffic:   [22 packets : 1860 bytes]
        Bad traffic:    [0 packets : 0 bytes]
--------------------

// IPv4が設定されていないとIPv6では応答せず、表示されない。
root@ubuntu-kudo-02:~# traceroute 172.24.61.100
traceroute to 172.24.61.100 (172.24.61.100), 30 hops max, 60 byte packets
 1  * * *
 2  * * *
 3  * * *
 4  * * *
 5  * * *
 6  * 172.24.61.100 (172.24.61.100)  3.258 ms  3.760 ms

ubuntu@ubuntu-kudo-01:~$ sudo vppctl show sr localsid
SRv6 - My LocalSID Table:
=========================
        Address:        fd60:5::5/128
        Behavior:       DT4 (Endpoint with decapsulation and specific IPv4 table lookup)
        Table:  10
        Good traffic:   [41 packets : 3000 bytes]
        Bad traffic:    [0 packets : 0 bytes]
--------------------
```


