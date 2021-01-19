# VPP_SRv6

UbuntuへVPPをインストールし、SRv6環境を構築する際のConfig等を保管するリポジトリ。

## リポジトリの構成
このrootディレクトリではインストール方法や検証構成の作り方を解説し、配下のディレクトリで検証用のConfig等を保管し、結果を説明する。

## 使用機器
* Ubuntu 18.4 LTS x 2台

## 検証構成
Network Namespaceを利用し、仮想的に4台構成として検証を行う。\
ホストOSのみVPP上でSRv6を動作させ、両端の機器はPC相当として動作させるので、Namespaceの機能のみで十分。

![NWD](./VPP_SRv6_NWDv4.png)

* RT1 - VPP1(ubuntu-01): ```172.24.61.0/24``` : IPv4区間
* SRv6区間: ```fd60:60::/64``` : IPv6で構築 (```172.24.60.0/24```をアサインしていたが、SRv6区間はIPv6で構成する必要があるため、リリース)
* RT2 - VPP2(ubuntu-02): ```172.24.62.0/24``` : IPv4区間


## 検証内容
* End.DX4
* End.DT4


## VPPのインストール方法
参考URL: [Installing_VPP_binaries_from_packages - FD.io](https://wiki.fd.io/view/VPP/Installing_VPP_binaries_from_packages#Ubuntu.2FDebian)

```
curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | sudo bash
sudo apt-get update
sudo apt-get install vpp vpp-plugin-dpdk vpp-plugin-core
```

## VPPの仕組みと初期設定

### VPPはサービスとして動作
下記コマンドでvpp.serviceの状態がわかる。
```
sudo service vpp status
```
初期設定などを変更した場合には、下記でVPPを再起動する必要あり。
```
sudo service vpp restart
```

### VPPを操作
* VPPの操作画面への移動方法: ```sudo vppctl``` 
* Linuxのbashから直接操作: ```sudo vppctl <command>``` 
  * 例: 
    * ```sudo vppctl show version```: VPPのバージョンを確認
    * ```sudo vppctl show interface```: VPPのinterfaceを確認

### VPP上へのinterface生成方法
* ```sudo lshw -class network -businfo``` にて追加予定のPCIの```@```以降を確認。
  * 追加予定のinterfaceはリンクダウンしている必要があるので```ip link```で確認し、UPだったらDownさせる。（Interfaceの設定を削除し、再起動が必要な場合あり）
* ```/etc/vpp/startup.conf``` (VPPの初期設定ファイル) の ```dpdk``` 配下に先ほどのPCIの値を追加。
* VPPサービスを再起動すると、interfaceが追加される。
```
ubuntu@ubuntu-kudo-01:~$ sudo lshw -class network -businfo
Bus info          Device     Class      Description
===================================================
pci@0000:00:03.0             network    Virtio network device
virtio@0          ens3       network    Ethernet interface
pci@0000:00:04.0             network    Virtio network device

ubuntu@ubuntu-kudo-01:~$ sudo vi /etc/vpp/startup.conf
...
dpdk {
	dev 0000:00:04.0
}
...
ubuntu@ubuntu-kudo-01:~$ sudo service vpp restart
ubuntu@ubuntu-kudo-01:~$ sudo vppctl show interface
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
GigabitEthernet0/4/0              1     down         9000/0/0/0
local0                            0     down          0/0/0/0
```

### VPP の Startup-configの作成
VPPの初期設定ファイル ```/etc/vpp/startup.conf``` にStartup-configを読み込むようにすることが可能。\
※下記の```userid```は自身のディレクトリに適宜変更すること。ちなみにファイルを置く場所はどこでもよいので、適宜パス自体も変更のこと。
```
unix {
	...
	startup-config /home/userid/setup.cfg
	...
}
```

記載方法は```vppctl```の状態で入力するコマンドをそのまま記載するだけ。コメントアウトの方法がわかってないので、要確認。


## VPPとNetwork Namespaceの結合方法
参考URL: [Configure_VPP_As_A_Router_Between_Namespaces - FD.io](https://wiki.fd.io/view/VPP/Configure_VPP_As_A_Router_Between_Namespaces)

### Network Namespace の作成

#### 機器構成
[R1] <===(veth_RT1)===> [VPP1]

```R1```がNamespaceで```veth_RT1```がVPPと接続

#### Namespaceの設定
1. 仮想ルータR1作成: ```ip netns add RT1```
2. RT1とつながるケーブルveth_RT1作成: ```ip link add veth_RT1 type veth peer name RT1```
3. RT1とケーブルveth_RT1を接続: 
```
ip link set dev veth_RT1 up netns RT1
ip link set dev RT1 up
```
4. RT1にIPアドレス割り当て: ```ip netns exec RT1 ip addr add 172.24.61.100/24 dev veth_RT1```
5. RT1のループバックを開放する（送受信に必須）: ```ip netns exec RT1 ip link set lo up```
6. RT1からVPP向けにデフォルトルート設定: ```ip netns exec RT1 ip route add 0.0.0.0/0 via 172.24.61.5```

上記は、シェルスクリプトにて実行することが可能で、参照URLに例が存在。\
本検証で利用するシェルスクリプトは、各検証構成のディレクトリに保管。End.DX4のファイルはこちら: [ubuntu-01_create-ns.sh](./EndDX4/ubuntu-01_create-ns.sh)

#### VPP側の設定
ホストから直接設定する場合のコマンド\
※```sudo vppctl```でVPP内で設定する場合は下記では```sudo vppctl```は不要。
1. VPPのホストインターフェース```host-RT1```を作成: ```sudo vppctl create host-interface name RT1```
2. ホストインターフェース```host-RT1```をリンクアップ: ```sudo vppctl set int state host-RT1 up```
3. ホストインターフェース```host-RT1```にIP割り当て: ```sudo vppctl set int ip address host-RT1 172.24.61.5/24```

上記は、VPPのstartup-configに記載しておくとよい。End.DX4のファイルはこちら: [ubuntu-01_setup.cfg](./EndDX4/ubuntu-01_setup.cfg)
