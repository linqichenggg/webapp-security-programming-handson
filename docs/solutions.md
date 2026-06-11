# 解答例

このファイルは講師または発展課題の答え合わせ用です。受講者へ最初から配布する場合は、演習の観察フェーズが短くなりすぎないよう注意してください。講師用の声かけや詰まりどころは `docs/instructor-hints.md` に分離しています。

## 基本演習1: 起動確認

期待する状態:

- `http://localhost:8086` が開ける
- `koide` / `password` でログインできる
- BBSに投稿できる
- `app/data.db` が作られる

確認コマンド:

```bash
. .venv/bin/activate
python app/main.py --reset-db
```

## 基本演習2: Bottleのルーティング

確認ポイント:

- `@get("/hello/<name>")` がURLと関数を結びつけている
- `<name>` の値が関数引数 `name` になる
- `template()` はHTML文字列を生成して返している

確認URL:

```text
http://localhost:8086/hello/security
http://localhost:8086/hello/alice
```

## 基本演習3: PeeweeとSQLite

期待する観察:

- `users` と `comments` テーブルがある
- `users.password` に平文パスワードが保存されている
- `comments.user_id` が投稿者を参照している

確認SQL:

```sql
.tables
.schema users
.schema comments
select userid, username, password, cookie from users;
select commentid, user_id, comment, datetime from comments;
```

## 基本演習4: セッションハイジャック

期待する観察:

- `/cookies` でブラウザ保存値と署名検証後の値を比較できる
- `/cookies` でブラウザ保存値を貼り替えられる
- `/cookies` で `user1` などの内部値を署名付きCookieとして保存できる
- 署名付きCookieの生値は長い文字列になる
- アプリ内部では `user1` のような値に復元される
- Cookieをコピーするとログイン状態を再現できる

補足:

- `secret=COOKIE_SECRET` があるため、ブラウザ保存値として任意の `user1` を手で入れても通らない
- 署名は改ざん検知であり、Cookie漏えいそのものを防ぐものではない
- `/cookies` の変更フォームは演習補助機能であり、実サービスに置くべきものではない

## 発展演習5: 署名付きCookieの比較

期待する説明:

- `secret=COOKIE_SECRET` を外すと、Cookie値をアプリ内部値としてそのまま扱いやすくなる
- 署名付きCookieは改ざんを検知するが、Cookieが盗まれた後のなりすましは防げない
- 署名の有無と、セッションIDの推測しやすさは別の問題として説明できる

## 基本演習6: XSS

原因箇所:

```html
{{!comment.comment}}
```

修正例:

```html
{{comment.comment}}
```

再テスト:

- `<script>alert(1)</script>` を投稿する
- スクリプトが実行されず、文字として表示されることを確認する

## 発展演習7: XSSを説明する

期待する説明:

- 投稿内容はDBに保存され、表示時に `bbs.tpl` でHTMLとして解釈された
- `HttpOnly` はJavaScriptからのCookie読み取りを抑えるが、HTMLとしての実行そのものは止めない
- 根本対策は、表示時に `{{comment.comment}}` のようにエスケープすること

## 基本演習8: CSRF

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

## 基本演習9: SQLインジェクション

原因箇所:

```python
sql = "SELECT * FROM users WHERE username='" + username + "' and password='" + password + "';"
records = cursor.execute(sql)
```

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

## 基本演習10: コマンドインジェクション

原因箇所:

```python
command = f'/bin/echo "From: {address}\n{comment}" >> "{OUTBOX_FILE}"'
exit_code = os.system(command)
```

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

## 基本演習11: Pico.cssでシンプルに整える

期待する状態:

- `base.tpl` に共通ナビゲーションを集約できる
- `login.tpl` はフォーム構造が読みやすくなる
- Pico.cssにより、`label`、`input`、`button`、`nav` が少ないCSSで整う

サンプル:

- `examples/pico-css/views/base.tpl`
- `examples/pico-css/views/login.tpl`
- `examples/pico-css/static/app.css`
- `examples/pico-css/main_snippet.py`

## 発展演習12-18: 改修課題

受け入れ条件:

| 課題 | 再テスト |
| --- | --- |
| 発展演習12: SQLi修正 | `' or 'a'='a` でログインできない |
| 発展演習13: XSS修正 | `<script>` が文字として表示される |
| 発展演習14: Cookie属性追加 | `HttpOnly` と `SameSite` を説明できる |
| 発展演習15: CSRF修正 | 補助サーバ `/csrf` からの投稿が失敗する |
| 発展演習16: コマンドインジェクション修正 | `command_injection_result.txt` が作られない |
| 発展演習17: パスワードハッシュ化 | DB上に平文パスワードが見えない |

発表テンプレート:

```text
担当した脆弱性:
原因となる実装:
試した入力:
観察できた現象:
修正した内容:
再テスト結果:
まだ残るリスク:
```
