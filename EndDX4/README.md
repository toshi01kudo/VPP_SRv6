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

## 検証結果

### 疎通確認


### showコマンド出力確認

