# Crawler

起点となるURLは「*******」でマスクしている。

docker環境で以下のコマンドを実行する。
もしくは、docker-compose　コマンドを無視してローカルでrailsプロジェクトを作成して、lib/batch配下にこのファイルを置いて実行。

```
$ docker-compose exec api bin/rails runner lib/batch/crawler.rb
```
