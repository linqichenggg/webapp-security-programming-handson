<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Security Camp in Kyushu</title>
  <style>
    body { font-family: system-ui, sans-serif; line-height: 1.7; margin: 0 auto 2rem; max-width: 860px; padding: 0 1rem; }
    header { border-bottom: 1px solid #ddd; margin-bottom: 1.5rem; padding: 1rem 0; }
    nav { display: flex; flex-wrap: wrap; gap: .5rem; }
    nav a { border: 1px solid #ccc; border-radius: .35rem; color: inherit; padding: .35rem .65rem; text-decoration: none; }
    nav a:hover { background: #f5f5f5; }
    textarea { box-sizing: border-box; max-width: 100%; width: 100%; }
    button { cursor: pointer; font: inherit; margin: .25rem; padding: .35rem .75rem; }
    .marked-font { font-weight: 700; }
    #comment-list { margin: 2em 0; padding-left: 1.5rem; }
    #comment-list li { border: solid 1px #ccc; margin: 1rem 0; padding: .75rem; }
  </style>
</head>
<body>
  <header>
    <nav aria-label="Main navigation">
      <a href="/signup">Signup</a>
      <a href="/login">Login</a>
      <a href="/mypage">MyPage</a>
      <a href="/cookies">Cookie</a>
      <a href="/bbs">BBS</a>
      <a href="/contact">Contact</a>
      <a href="/logout">Logout</a>
    </nav>
  </header>

  <main>
    <h1>こんにちは，<span id="hello-user">{{username}}</span>さん</h1>
    <h2>ここは，<span class="marked-font">みんなの掲示板</span>用のページです。</h2>

    <ol id="comment-list">
      % for comment in comments:
        <li>
          {{comment.user.username}} : {{comment.datetime}}<br>
          {{comment.comment}}
        </li>
      % end
    </ol>

    <form action="/bbs" method="post">
      <input type="hidden" name="token" value="{{token}}">
      <textarea name="comment" rows="5" cols="70" placeholder="何か書いてください"></textarea>
      <button type="submit">書き込む</button>
    </form>

    <a href="/mypage"><button type="button">マイページに戻る</button></a>
    <a href="/cookies"><button type="button">Cookieを確認する</button></a>
    <a href="/login"><button type="button">ログイン画面に戻る</button></a>
    <a href="/logout"><button type="button">ログアウトする</button></a>
  </main>
</body>
</html>
