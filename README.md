# Dockerの使い方 (初心者向け) 

## システム運用の方針
各自のノートPCなどからGPU等の計算サーバにリモートアクセスをし、仮想環境でGPUを使ったプログラムの実行することを想定しています.  
Google ColabのようにリモートＰＣのブラウザからjupyter notebookを手軽に利用することを目標としています.  
今回構築するシステムの概要図です。これ以降2台のPCをリモートPC、ホストPCと表します。

...   

## Dockerの大まかな説明
QiitaにDockerの分かりやすいイントロダクションがありますので、[こちら](https://qiita.com/etaroid/items/b1024c7d200a75b992fc#%E4%B8%AD%E7%B7%A8%E3%81%AB%E7%B6%9A%E3%81%8F)を参考にしてください。(全３章)

* 仮想化/仮想環境: ホストPCの上に別のOSを持ったマシンを構築すること  
* Dockerイメージ: 仮想環境のベース。イメージからコンテナを起動する。[DockerHub](https://hub.docker.com/)  
* コンテナ: Docker仮想環境の実行環境。イメージから起動される
* DockerFile: イメージ/コンテナの設計図
* Docker compose: コンテナの起動や複数のコンテナのネットワークを管理する

Dockerを使うメリットは以下
1. CUDAのバージョン, Tensorflow/kerasの同居などの問題を管理することが容易になる
2. 共有サーバの環境を汚すことなく各自の実行環境を作れる
3. プログラムの実行環境をそのまま配布・共有することが出来る

## Dockerによる仮想環境の構築
### Dockerのインストールとコマンド利用
Dockerは仮想環境を構築したいホストPCにインストールします。Dockerのインストール方法はOSによって様々です。各サイトを参照してください [linux](https://docs.docker.jp/engine/installation/linux/index.html)  
共有サーバなどでは既にインストールされている可能性がありますので、以下で確認できます（恐らくsudo権限が必要です）
```shell
# dockerの有無の確認
$ sudo docker -v
```
Dockerをsudo権限なしで実行出来るようにするにはdockerというグループを作成し、ユーザを追加する必要があります。
```shell
# dockerグループの有無の確認
$ cat /etc/group | grep docker
# グループが無ければ作成
$ sudo groupadd docker
# グループにユーザーを追加
$ sudo gpasswd -a $USER docker
# この後、dockerの再起動/ユーザーの再ログインが必要になることがあります OSなどの環境によります
```
dockerをsudo無しで利用できるようになりました。

### ベースとなるDockerイメージの取得
Dockerはイメージの作成・出力から始まります。DockerHUBなどで公開されているイメージは様々ですが、[初心者向けバージョンの選び方]も参考にしてください  
今回はTransformer利用を目的にUbuntu=20.04, CUDA=11.8, python=3.9.5, torch=2.0.1 の環境構築をしてみます 

[こちら](https://hub.docker.com/r/nvidia/cuda/tags?page=1&name=11.8)から目的に合ったイメージのレポジトリを見つけました. このイメージファイルの有無の確認と無い場合は取得をします。
```shell
# dockerイメージの有無の確認
$ docker images
# 無い場合はdockerイメージの取得(pull)
$ docker pull nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04
```
Dockerfileからも先頭行に今回利用するイメージを確認出来ます。
```
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04
```
これでdockerイメージを取得出来ました。

### Dockerfile
DockerfileはDocker仮想環境の設計図です。共通の環境を作りたい場合はこのDockerfileを共有します. 各サイトを参考に記述してみてください  

今回のDockerfileのポイントを説明します
* CUDAイメージをベースに、python3.9をインストールしています
* pytorchのインストールコマンドは[公式](https://pytorch.org/)を参考に変更してください 今回は最新版をインストールしています
* python関連のライブラリは requirement.txt からインストールしています 適宜追記してください
* OS関連は #apt-get install 適宜追記してください
* rootにはパスワード"root"で入れるようにしています
* ログインユーザとしてホストＰＣのユーザ名で作成し、sudo権限を付与しています
* ファイル所有や権限の為に、ログインユーザのuser_id, group_idはホストPCユーザと同じものを設定します
* 設定ファイルが置かれたscriptディレクトリをコンテナ内の/home/$USER/scriptsにコピーしています
* メインディレクトリは/home/$USER/workであり、ホストPCのworkディレクトリをマウント（共有）することを想定しています

### Dockerfileからイメージ・コンテナを作成
容易に実行する方法は後述するcomposeを利用してください  
build オプションでDockerfileからイメージを作成することが出来ます。引数などによって複雑になるのでshファイルにまとめて実行します
```shell
$ ./docker_build.sh
```
run オプションでイメージからを作成し起動することが出来ます。引数などによって複雑になるのでshファイルにまとめて実行します  
```shell
$ ./docker_run.sh
```
デフォルトではコンテナのターミナルでexitをするとコンテナは消去されるので注意です
実行時は任意のimage_name/tag_name, container_nameを設定してください

### Docker compose
Dockerでは複数のコンテナを使うことがあります(e.g. データサーバ、計算サーバ、アプリケーション …) Docker composeを使うことでそれらを容易に制御することが出来ます。  
１つのコンテナ（仮想環境）を利用する場合でもcomposeは便利なので使います。 上記のbuildとrunの操作を行うことが出来ます。  
必要なものは以下
* compose_up.sh (docker composeの実行ファイル)
* compose.yml (buildやrunの設定ファイル)
* .env (デフォルトで読み込まれる環境変数ファイル)
* Dockerfile (イメージ/コンテナの設定ファイル)

今回の設定のポイントは以下です
* ホストPCのユーザ名、ユーザID、グループIDを渡す為に、compose.shで環境変数として設定し、compose.ymlのbuild-argsでDockerfileに渡します
* GPUを使うように設定しています
* workディレクトリのマウントをしています
* ポートの解放には幅を持たせています(jupyter_notebook, Tensor_board)

docker composeは以下のファイルでイメージの作成、コンテナの作成、コンテナの起動をすることが出来ます。
```shell
$ ./compose_up.sh
```
内部ではdocker compose up というコマンドが働いています

### 構築される環境の階層
/root/home/hattori/  
├── .jupyter  
├── ├── jupyter_notebook_config.py  
├── ├── jupyter_notebook_config.py.old  
├── .vscode-server  
├── scripts (設定ファイルのコピー)  
├── ├── jupyter_notebook_config.py  
├── ├── set_passwd.sh  
├── work (ホストPCとDockerコンテナのマウントディレクトリ)  
├── ├── test.ipynb 

## Dockerによる仮想環境の利用

...  

## 初回設定(パスワードを変えたい時)
jupyter notebookにブラウザでリモートアクセスするために初期設定スクリプトを組んでいます
```shell
$ ./scripts/set_passwd.sh
```
jupyter notebook設定ファイルの生成と保存、Jupyter notebookのパスワードを設定しています.  
jupyter notebookの接続ポートは"8888"に設定しています.  
パスワードの入力は2回要求されます。Enter2回で飛ばすことも可能です.  
登録が成功すると'DONE'が出力されます. 'RETRY'が出力されたらもう一度shファイルを実行してください.
(一度の実行であまりにも間違えるとpythonエラーが発生するので注意。エラー処理はしていません)

## jupyter notebook の実行
Google colabを利用するようにブラウザで容易にpython/shellを実行出来ることを想定
```shell
$ jupyter notebook
```
起動が成功したらリモートPCのブラウザから、http://[GPU_IP_adress]:8888, または http://localhost:8888 にアクセス  
パスワードが要求されたら設定したパスワードを入力。Enterで飛ばした場合は空白で良い

パスワード設定等をしないアドホックな起動方法:  
```shell
$ jupyter notebook --ip=* --no-browser
```

## vscodeでの実行(リモートコンテナへの接続)
ipyndファイルを開いてvscode内で実行することを想定
1. SSH接続後、GPUサーバでコンテナを起動
2. VScodeのリモート接続(左下, 青色, ><)から'Attach to Running Container'を選択し、任意のコンテナに接続  
途中で、VScodeの拡張機能のインストールを要求されることがあります