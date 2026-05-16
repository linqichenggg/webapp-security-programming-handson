# 脆弱性と対策の対応表

| テーマ | 教材内の場所 | 脆弱な実装 | 観察できること | 主な対策 |
| --- | --- | --- | --- | --- |
| セッション管理 | `app/main.py` の `/login`, `/mypage` | DBに `user1` のような推測可能な値を保存する | 盗まれたCookieをコピーするとログイン状態を再現できる | 十分にランダムなセッションID、短い有効期限、再認証、Cookie属性 |
| XSS | `app/views/bbs.tpl` | `{{!comment.comment}}` でエスケープを無効化 | 投稿したJavaScriptが他ユーザのブラウザで実行される | 出力時エスケープ、入力検証、CSP、`HttpOnly` Cookie |
| CSRF | `app/main.py` の `/bbs` | 固定トークンを置くだけで検証しない | 別サイトからログイン中ユーザの権限で投稿できる | セッションごとのCSRFトークン、Origin/Referer検証、SameSite Cookie |
| SQLインジェクション | `app/main.py` の `/login` | SQL文字列にユーザ入力を連結する | パスワードを知らなくてもログインできる | プレースホルダ、ORMの安全なAPI、最小権限 |
| コマンドインジェクション | `app/main.py` の `/contact` | `os.system()` にユーザ入力を連結する | 任意のOSコマンドが実行される | `os.system()` を避ける、`subprocess.run(..., shell=False)`、専用ライブラリ |
| パスワード管理 | `Users.password` | 平文保存 | DB流出時にパスワードが直接漏れる | Argon2/bcrypt/scryptなどのパスワードハッシュ |

## 改修例の方向性

### SQLインジェクション

脆弱な例:

```python
sql = "SELECT * FROM users WHERE username='" + username + "' and password='" + password + "';"
cursor.execute(sql)
```

安全な方向:

```python
cursor.execute(
    "SELECT * FROM users WHERE username=? and password=?;",
    (username, password),
)
```

### XSS

脆弱な例:

```html
{{!comment.comment}}
```

安全な方向:

```html
{{comment.comment}}
```

### コマンドインジェクション

脆弱な例:

```python
os.system('/bin/echo "' + comment + '"')
```

安全な方向:

```python
from pathlib import Path

Path("mail_outbox.txt").write_text(comment, encoding="utf-8")
```

メール送信をしたい場合は、シェルコマンドではなく `smtplib` などの専用ライブラリを使います。

### パスワードハッシュ化

パスワードは平文のままDBに保存しません。DBが漏えいしたときに、保存値から元のパスワードを直接読めないようにします。

実装では、単なるSHA-256ではなく、ソルト付きで計算コストのある方式を使います。実務ではArgon2、bcrypt、scrypt、またはそれらを扱うライブラリを優先します。この演習で外部ライブラリを増やさずに最小構成で試すなら、標準ライブラリの `hashlib.pbkdf2_hmac()` を使えます。

保存値は、アルゴリズム名、反復回数、ソルト、ハッシュ値をまとめて1つの文字列にしておくと、あとで検証や方式変更がしやすくなります。

```python
import base64
import hashlib
import hmac
import secrets

ITERATIONS = 200_000


def b64encode(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        ITERATIONS,
    )
    return f"pbkdf2_sha256${ITERATIONS}${b64encode(salt)}${b64encode(digest)}"
```

ログイン時は、DBからユーザー名でユーザーを取得し、入力されたパスワードを同じ条件でハッシュ化して比較します。比較には `==` ではなく `hmac.compare_digest()` を使うと、タイミング差による情報漏えいを避けやすくなります。

```python
def verify_password(password: str, stored: str) -> bool:
    try:
        method, iterations, salt_text, digest_text = stored.split("$")
    except ValueError:
        return False

    if method != "pbkdf2_sha256":
        return False

    salt = base64.b64decode(salt_text)
    expected = base64.b64decode(digest_text)
    actual = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        int(iterations),
    )
    return hmac.compare_digest(actual, expected)
```

演習アプリでは、初期ユーザー作成と新規登録の両方で `hash_password()` を通して保存し、ログイン処理ではSQLの条件にパスワードを直接含めず、取得後に `verify_password()` で確認します。
