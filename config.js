// 合租生活管家 · 配置
// 填入 Supabase 项目的 Project URL 和 anon public key（或 sb_publishable_ 开头的 Publishable key）（Supabase 控制台 → Project Settings → API）。
// 两项都留空时，网站以「演示模式」运行（数据只存在本机浏览器）。
// anon key 本身就是设计给前端公开使用的，数据安全由 schema.sql 里的行级权限（RLS）保证。
window.ROOMIE_CONFIG = {
  supabaseUrl: "https://xlswkmqmevxtpddcuywq.supabase.co",
  supabaseAnonKey: "sb_publishable_euCmRPRS6HYl7A7y2Gj-CA_A_EKM-7l"
};
