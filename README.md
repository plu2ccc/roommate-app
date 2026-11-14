# 合租生活管家 · 部署指南

一个纯静态网页，不需要安装任何开发环境。数据存在 Supabase（免费额度够用），网站托管在 Vercel（免费）。

```
index.html            网站本体
config.js             填 Supabase 地址和密钥的地方
schema.sql            数据库建表脚本
```

## 第一步：创建 Supabase 数据库（约 5 分钟）

1. 打开 https://supabase.com ，用 GitHub 账号登录，点 **New project**，名字随意，地区选离你和室友最近的（在澳洲选 Sydney）。数据库密码自己记好。
2. 项目创建好后，左侧点 **SQL Editor** → **New query**，把 `schema.sql` 的全部内容粘贴进去，点 **Run**。看到 Success 即可。
3. 左侧点 **Authentication** → **Sign In / Providers**，找到 **Anonymous sign-ins**，打开并保存。
   （室友不用注册账号，打开链接就能用，靠的就是这个。）
4. 左侧点 **Project Settings** → **API**，复制两样东西：**Project URL**，以及 **anon public** key（新项目里可能叫 **Publishable key**，以 `sb_publishable_` 开头，二者用哪个都行）。

> 控制台菜单名称可能随 Supabase 更新略有变化，找对应的功能即可。

## 第二步：填配置

打开 `config.js`，把上一步复制的两项填进去：

```js
window.ROOMIE_CONFIG = {
  supabaseUrl: "https://xxxx.supabase.co",
  supabaseAnonKey: "eyJhbGciOi..."
};
```

anon key 本来就是给前端公开用的，可以放心提交到 GitHub；真正保护数据的是建表脚本里的权限规则：只有加入了同一个合租屋的人才能读写这个屋的数据。

## 第三步：把代码放到 GitHub

1. 登录 https://github.com ，右上角 **+** → **New repository**，名字如 `roommate-app`，点 **Create repository**。
2. 在新仓库页面点 **uploading an existing file**，把 `index.html`、`config.js`、`schema.sql`、`README.md`拖进去，点 **Commit changes**。

## 第四步：用 Vercel 部署

1. 打开 https://vercel.com ，用 GitHub 账号登录，点 **Add New… → Project**，选择 `roommate-app` 仓库，点 **Import**。
2. Framework Preset 选 **Other**，其他都不用填，点 **Deploy**。
3. 一分钟左右得到 `https://roommate-app-xxx.vercel.app`，这就是你的线上地址。

以后修改代码：在 GitHub 上编辑或重新上传文件，Vercel 会自动重新部署。

## 第五步：开始用

1. 打开网站 → **创建我的合租屋** → 填合租屋名称和你的昵称。
2. 首页点 **邀请室友** → **复制邀请链接**，发到微信合租群。
3. 室友点开链接 → 填昵称 → 阅读并签署室友约定书 → 进入合租屋。之后任何人记账、打卡、投票，其他人的页面都会实时更新。

## 上线前检查清单

- [ ] 用两个不同的浏览器（或一台电脑一部手机）分别打开，一个创建、一个用邀请链接加入，确认能互相看到对方的操作
- [ ] 手机上打开，界面正常
- [ ] 找 1–2 个室友真实走一遍流程，看他们在哪里卡住

## 需要知道的限制

- **身份绑定在浏览器上**：室友用的是免注册的匿名身份，清除浏览器数据或换手机后，会变成一个新身份，需要重新用邀请链接加入。之后可以升级为手机号或邮箱登录。
- **同时修改**：两个人在同一秒修改同一个模块（例如同时记账），后保存的会覆盖先保存的。合租场景下很少发生；需要时可以把账单改成一条记录一行。
- **中国大陆访问**：`vercel.app` 域名在大陆可能打不开。室友都在国内的话，需要绑定自己的域名（Vercel → Project Settings → Domains）。
- **拍照识别账单**仍是演示效果，接入真实识别需要单独的 OCR 服务。
- 不填 `config.js` 时，网站自动以演示模式运行，可以随时拿来展示。
