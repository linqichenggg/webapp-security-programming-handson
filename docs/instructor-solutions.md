# 講師用ヒントと解答例

このファイルは講師向けです。受講者へそのまま配布するのではなく、詰まったときのヒント、答え合わせ、発展課題のレビューに使ってください。

## 使い方

- 初心者には、答えを見せる前に「どの文脈でデータがコードになったか」を質問する
- 経験者には、修正後に同じ攻撃入力で再テストさせる
- コード修正は一度に全部入れず、1つの脆弱性ごとに観察と確認を行う
- 受講者が外部サイトや第三者サービスで試さないよう、演習前後で明確に確認する

## 演習0: 起動確認

期待する状態:

- `http://localhost:8086` が開ける
- `koide` / `password` でログインできる
- BBSに投稿できる
- `app/data.db` が作られる

よくある詰まり:

- 仮想環境を有効にしていない
- すでにポート8086が使われている
- `localhost` と別ポートを取り違えている

## 演習1: Bottle

確認したい理解:

- `@get("/hello/<name>")` がURLと関数を結びつけている
- `<name>` の値が関数引数 `name` になる
- `template()` はHTML文字列を生成して返している

追加質問:

- `http://localhost:8086/hello/alice` と `/hello/bob` で何が変わるか
- HTMLを返す関数と、DBを操作する関数はどこで分かれているか

## 演習2: PeeweeとSQLite

期待する観察:

- `users` と `comments` テーブルがある
- `users.password` に平文パスワードが保存されている
- `comments.user_id` が投稿者を参照している

講師メモ:

- 初心者には、Model定義と `.schema` の対応を1行ずつ見せる
- 経験者には、平文パスワードをハッシュ化する設計へ進ませる

## 演習3: セッションハイジャック

期待する観察:

- `/cookies` でブラウザ保存値と署名検証後の値を比較できる
- 署名付きCookieの生値は長い文字列になる
- アプリ内部では `user1` のような値に復元される
- Cookieをコピーするとログイン状態を再現できる

講師メモ:

- `secret=COOKIE_SECRET` があるため、任意の `user1` を手で入れても通らない
- 署名は改ざん検知であり、Cookie漏えいそのものを防ぐものではない
- `HttpOnly` はJavaScriptからの読み取りを抑えるが、リクエスト送信時のCookie自動送信は止めない

## 演習4: XSS

期待する観察:

- BBS投稿がHTMLとして解釈される
- 補助サーバにCookie文字列が届く
- 原因箇所は `app/views/bbs.tpl` の `{{!comment.comment}}`

修正例:

```html
{{comment.comment}}
```

再テスト:

- `<script>alert(1)</script>` を投稿する
- スクリプトが実行されず、文字として表示されることを確認する

講師メモ:

- 「入力を消す」より「出力時に文脈に合わせてエスケープする」を強調する
- `HttpOnly` はCookie漏えいの被害を減らすが、XSSの根本対策ではない

## 演習5: CSRF

期待する観察:

- ログイン済みブラウザで補助サーバの `/csrf` を開く
- ボタンを押すとBBSに投稿される
- 固定のhidden tokenは守りになっていない

修正例:

```python
import secrets

def ensure_csrf_token(user):
    if not user.session:
        user.session = secrets.token_urlsafe(32)
        user.save()
    return user.session
```

GET `/bbs`:

```python
token = ensure_csrf_token(user)
return template("bbs", username=user.username, comments=comments, token=token)
```

POST `/bbs`:

```python
token = request.forms.decode().get("token", "")
if not user.session or token != user.session:
    return error_page("CSRF token is invalid.", status=403)
```

テンプレート:

```html
<input type="hidden" name="token" value="{{token}}">
```

再テスト:

- BBS画面からの投稿は成功する
- `http://localhost:8090/csrf` からの投稿は403になる

## 演習6: SQLインジェクション

期待する観察:

- 画面に表示されたSQLのWHERE句が壊れる
- `' or 'a'='a` によって条件が常に真になる
- ユーザ入力がSQL構造として解釈されている

修正例:

```python
records = cursor.execute(
    "SELECT * FROM users WHERE username=? and password=?;",
    (username, password),
)
record = records.fetchone()
```

再テスト:

| username | password | 期待結果 |
| --- | --- | --- |
| `koide` | `password` | ログイン成功 |
| `koide` | `' or 'a'='a` | ログイン失敗 |
| `koide' --` | `anything` | ログイン失敗 |

講師メモ:

- サニタイズだけで説明しない
- 「SQL構造」と「値」を分ける、と言う方が伝わりやすい

## 演習7: コマンドインジェクション

期待する観察:

- `/contact` の入力値がシェルコマンドへ連結される
- `"; /bin/echo injected > command_injection_result.txt; #` により別コマンドが実行される
- 原因箇所は `os.system(command)`

修正例:

```python
with OUTBOX_FILE.open("a", encoding="utf-8") as outbox:
    outbox.write(f"From: {address}\n")
    outbox.write(comment)
    outbox.write("\n---\n")
```

再テスト:

- 通常の問い合わせ送信が成功する
- コマンドインジェクション用の文字列を入力しても `command_injection_result.txt` が作られない
- `app/mail_outbox.txt` に入力が文字として保存される

講師メモ:

- `subprocess.run(..., shell=False)` も選択肢だが、この機能では外部コマンド自体が不要
- 「使わなくてよいシェルを使わない」が最も強い対策

## 演習8: Pico.css

期待する観察:

- `base.tpl` に共通ナビゲーションを集約できる
- `login.tpl` はフォーム構造が読みやすくなる
- Pico.cssはclassを大量に覚えなくても見た目が整う

レビュー観点:

- セキュリティ修正とUI修正が混ざりすぎていないか
- テンプレート内で `{{! ... }}` を安易に増やしていないか
- CDNが使えない環境でどうするか説明できるか

## 発展課題の採点観点

| 観点 | 十分な状態 |
| --- | --- |
| 原因説明 | 危険なコード位置と、なぜ危険かを説明できる |
| 修正 | 入力値をコードとして解釈させない方向へ直している |
| 再テスト | 修正前に成功した攻撃入力が、修正後に失敗する |
| 副作用確認 | 通常のログイン、投稿、問い合わせが動く |
| 表現 | 「サニタイズすればOK」で止まらず、文脈を説明できる |

## レベル別の声かけ

初心者向け:

- 「どの画面で、何を入力して、何が変わったか」を言葉にしてもらう
- まずはコード行番号より、画面とHTTPの流れを追わせる
- `/cookies`、画面上のSQL表示、補助サーバのログを使って観察を支援する

標準レベル向け:

- 脆弱なコード箇所を自分で探させる
- 修正前後の差分を説明させる
- 1つの対策について再テストまで実施させる

経験者向け:

- 複数の対策を組み合わせたときの残るリスクを説明させる
- パスワードハッシュ、CSRFトークン、Cookie属性まで実装させる
- テストコードや小さなリファクタリングまで進ませる

## 最終発表テンプレート

受講者に短く発表してもらう場合は、次の形が扱いやすいです。

```text
担当した脆弱性:
原因となる実装:
試した入力:
観察できた現象:
修正した内容:
再テスト結果:
まだ残るリスク:
```

講師は「攻撃できたか」ではなく、「原因、文脈、対策、再確認」を説明できているかを見ると、レベル差があっても評価しやすくなります。
