# 事前知識

このページは、演習に入る前の足場です。すべてを暗記する必要はありません。演習中に迷ったら、このページへ戻って用語と流れを確認してください。

## この演習で使うもの

| 分野 | 使う場面 | 最低限わかればよいこと |
| --- | --- | --- |
| ターミナル | アプリ起動、DB確認、補助サーバ起動 | コマンドを1行ずつ実行する |
| Python | Bottleアプリの実行 | `python app/main.py` でサーバを起動する |
| HTTP | ブラウザとWebサーバの通信 | リクエストとレスポンスがある |
| HTML | 画面表示、XSS | ブラウザはHTMLタグを解釈して表示する |
| Cookie | ログイン状態、セッション | ブラウザが値を保存し、次のリクエストで送る |
| SQL | ユーザとコメントの保存 | DBに問い合わせるための言語 |
| シェル | コマンドインジェクション | `;` や `"` などに構文上の意味がある |

## ターミナルの基本

リポジトリのルートへ移動します。

```bash
cd webapp-security-programming-handson
```

仮想環境を有効にします。

```bash
. .venv/bin/activate
```

Webアプリを起動します。

```bash
python app/main.py --reset-db
```

補助サーバを起動します。別ターミナルで実行してください。

```bash
python tools/attacker_server.py
```

起動中のサーバを止めるには、サーバを起動したターミナルで `Ctrl-C` を押します。

## HTTPの基本

ブラウザでURLを開くと、ブラウザはWebサーバへHTTPリクエストを送ります。WebサーバはHTTPレスポンスを返します。

よく見るHTTPメソッド:

| メソッド | この教材での例 | 役割 |
| --- | --- | --- |
| GET | `/login`, `/bbs`, `/cookies` | ページや情報を取得する |
| POST | `/login`, `/register`, `/bbs`, `/contact` | フォーム内容を送る |

演習では「フォームから送った値が、どこでコードとして解釈されるか」を観察します。

## Cookieとセッション

HTTPは、そのままでは前回のリクエストを覚えていません。ログイン状態を扱うため、WebアプリはCookieを使います。

この教材では、ログイン後に `cookie_id` が発行されます。

確認方法:

1. `koide` / `password` でログインする
2. `http://localhost:8086/cookies` を開く
3. ブラウザに保存されている値と、アプリが使う値を見比べる

重要な観点:

- Cookieはブラウザに保存される
- ブラウザは同じサイトへのリクエストにCookieを付ける
- Cookieを盗まれるとログイン状態を再現されることがある
- `HttpOnly`、`SameSite`、`Secure` などの属性で守れる範囲が変わる

## HTMLエスケープ

HTMLでは `<script>` のような文字列がタグとして解釈されます。

ユーザ入力:

```html
<script>alert(1)</script>
```

安全に表示したい場合は、タグとしてではなく文字として表示する必要があります。

```html
&lt;script&gt;alert(1)&lt;/script&gt;
```

この教材のBBSでは、XSSを観察するために `{{!comment.comment}}` でエスケープを無効にしています。

## SQLの基本

SQLiteに保存されたユーザを検索するSQLの例です。

```sql
select * from users where username='koide';
```

危険なのは、ユーザ入力をSQL文字列へそのまま連結することです。

```python
sql = "SELECT * FROM users WHERE username='" + username + "';"
```

安全な方向は、SQL構造と入力値を分けることです。

```python
cursor.execute("SELECT * FROM users WHERE username=?;", (username,))
```

## シェルの基本

シェルでは、次のような文字に構文上の意味があります。

| 文字 | 意味の例 |
| --- | --- |
| `"` | 文字列の区切り |
| `;` | コマンドの区切り |
| `#` | コメント開始 |
| `|` | 前のコマンドの出力を次へ渡す |

ユーザ入力をシェルコマンドに連結すると、意図しないコマンドとして解釈されることがあります。

この教材では、ローカルファイル作成だけを使って安全に現象を観察します。

## 自分で確認するチェックリスト

演習前に次を確認してください。

- `python --version` または `python3 --version` が実行できる
- `python app/main.py --reset-db` でWebアプリが起動する
- `http://localhost:8086` をブラウザで開ける
- `koide` / `password` でログインできる
- `http://localhost:8086/cookies` でCookie確認ページを開ける
- 別ターミナルで `python tools/attacker_server.py` を起動できる
- `http://localhost:8090` をブラウザで開ける
