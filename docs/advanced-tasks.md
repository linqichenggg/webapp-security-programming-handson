# 発展課題

経験者や早く終わった受講者向けの課題です。目的は、攻撃を成功させることではなく、脆弱な実装を安全な実装へ直し、同じ手順で攻撃が通らなくなったことを確認することです。

このファイルでは、基本演習の続きとして発展演習12-18を扱います。教材全体で同じ演習番号は使いません。

| 番号 | 内容 |
| --- | --- |
| 発展演習12 | SQLインジェクションを防ぐ |
| 発展演習13 | XSSを防ぐ |
| 発展演習14 | Cookie属性を追加する |
| 発展演習15 | CSRFトークンを実装する |
| 発展演習16 | コマンドインジェクションを防ぐ |
| 発展演習17 | パスワードをハッシュ化する |
| 発展演習18 | レベル別レポート |

## 進め方

1. まず脆弱な状態で現象を再現する
2. コードを最小限だけ変更する
3. 同じ入力をもう一度試す
4. 攻撃が失敗した理由を説明する
5. 変更による副作用がないか確認する

各課題は独立して進められます。複数人で分担する場合は、担当ファイルと担当機能を分けてください。

## 発展演習12: SQLインジェクションを防ぐ

対象:

- `app/main.py` の `/login`

現状:

```python
sql = "SELECT * FROM users WHERE username='" + username + "' and password='" + password + "';"
records = cursor.execute(sql)
```

やること:

- SQL文字列への連結をやめる
- プレースホルダを使う
- ログイン失敗時に例外で落ちないことを確認する

受け入れ条件:

- `koide` / `password` ではログインできる
- `koide` / `' or 'a'='a` ではログインできない
- `koide' --` / `anything` ではログインできない
- 画面に表示されるSQLやメッセージが受講者に誤解を与えない

ヒント:

```python
records = cursor.execute(
    "SELECT * FROM users WHERE username=? and password=?;",
    (username, password),
)
```

## 発展演習13: XSSを防ぐ

対象:

- `app/views/bbs.tpl`

現状:

```html
{{!comment.comment}}
```

やること:

- コメント表示時のエスケープを有効にする
- 投稿内容が文字として表示されることを確認する
- BBSの通常投稿が壊れていないことを確認する

受け入れ条件:

- `<script>alert(1)</script>` を投稿してもJavaScriptとして実行されない
- 投稿一覧には文字として表示される
- 既存コメントも表示できる

ヒント:

```html
{{comment.comment}}
```

## 発展演習14: Cookie属性を追加する

対象:

- `app/main.py` の `/login`

やること:

- `response.set_cookie()` に属性を追加する
- `/cookies` でログイン状態を確認する
- XSS演習の結果がどう変わるか確認する

受け入れ条件:

- ログインできる
- `/mypage` と `/bbs` に入れる
- Cookieに `HttpOnly` と `SameSite` を指定している
- JavaScriptから `cookie_id` が読めるかどうかを説明できる

ヒント:

```python
response.set_cookie(
    "cookie_id",
    cookie_id,
    secret=COOKIE_SECRET,
    httponly=True,
    samesite="Lax",
)
```

注意:

- `Secure=True` はHTTPS前提です。ローカルHTTP演習では設定するとCookieが送られない場合があります。

## 発展演習15: CSRFトークンを実装する

対象:

- `app/main.py` の `/bbs`
- `app/views/bbs.tpl`

やること:

- ログインユーザごとに予測しにくいCSRFトークンを持たせる
- フォームにトークンを埋め込む
- POST時にトークンを検証する
- 固定トークンをやめる

受け入れ条件:

- BBS画面からの正規投稿は成功する
- `http://localhost:8090/csrf` からの投稿は失敗する
- 失敗時に理由がわかるエラーを表示する

ヒント:

```python
import secrets

def ensure_csrf_token(user):
    if not user.session:
        user.session = secrets.token_urlsafe(32)
        user.save()
    return user.session
```

POST時:

```python
token = request.forms.decode().get("token", "")
if not user.session or token != user.session:
    return error_page("CSRF token is invalid.", status=403)
```

## 発展演習16: コマンドインジェクションを防ぐ

対象:

- `app/main.py` の `/contact`

現状:

```python
command = f'/bin/echo "From: {address}\n{comment}" >> "{OUTBOX_FILE}"'
exit_code = os.system(command)
```

やること:

- `os.system()` を使わない
- シェルを経由せずに問い合わせ内容を保存する
- 既存の問い合わせフォームの機能を維持する

受け入れ条件:

- 通常の問い合わせ送信が成功する
- `"; /bin/echo injected > command_injection_result.txt; #` を入力してもファイルが作られない
- 保存された問い合わせ内容に、入力文字列が文字として残る

ヒント:

```python
with OUTBOX_FILE.open("a", encoding="utf-8") as outbox:
    outbox.write(f"From: {address}\n{comment}\n---\n")
```

## 発展演習17: パスワードをハッシュ化する

対象:

- `Users.password`
- `/register`
- `/login`
- `initialize_database()`

やること:

- 平文パスワード保存をやめる
- ハッシュ化した値をDBに保存する
- ログイン時に照合する

受け入れ条件:

- `select username, password from users;` で平文パスワードが見えない
- 初期ユーザでログインできる
- 新規登録ユーザでログインできる

ヒント:

標準ライブラリだけで最小実装するなら、`hashlib.pbkdf2_hmac()` を使えます。実サービスではArgon2、bcrypt、scryptなどのパスワード保存向け方式を検討してください。

## 発展演習18: レベル別レポート

最後に、1つ以上の脆弱性について次をまとめてください。

| 項目 | 書くこと |
| --- | --- |
| 原因 | どの実装が危険だったか |
| 観察 | どの入力で何が起きたか |
| 修正 | どのコードをどう変えたか |
| 再テスト | 同じ入力で攻撃が失敗したか |
| 残るリスク | まだ足りない対策は何か |

経験者は、複数の対策を組み合わせたときの副作用も確認してください。たとえば、`HttpOnly` を付けるとXSSでCookieは読みにくくなりますが、XSSそのものがなくなるわけではありません。
