#!/usr/bin/env python3
"""
aeo_report_gen.py — Vercel Observability(Bot Name) 데이터로 AEO 지표 리포트 HTML 생성.

/aeo_report 커맨드가 호출한다. Playwright 로 추출한 봇 표를 JSON 으로 넘기면
봇을 AI/검색/SEO/소셜/기타로 분류하고 AEO 지표를 계산해 고정 템플릿을 채운다.

사용:
  python3 aeo_report_gen.py \
    --data <extracted.json> \
    --template <aeo_report_template.html> \
    --out <report.html> \
    [--chart <chart.png>]

extracted.json 형식:
{
  "scope": "rebstudios / reb-platform-frontend",
  "title": "Edge Requests — AEO Bot Metrics",      # 선택
  "env": "Production",
  "period_label": "Last 30 days",
  "period_range": "2026-06-28 09:35 ~ 2026-07-28 09:35 (KST)",
  "total_edge": "146K",                             # 상단 Edge Requests 총계(표시값)
  "source_url": "https://vercel.com/.../edge-requests?tab=botName&period=30d",
  "generated": "2026-07-28 09:40",                  # 선택(없으면 실행시각)
  "bots": [ {"name": "gptbot", "requests": "1.6K", "cached": "38.7%"}, ... ]
}
"""
import argparse
import base64
import html
import json
import re
from datetime import datetime

# ── 봇 분류 (순서대로 substring 매칭, 먼저 걸리는 것 우선) ──────────────────
# (token, category, vendor). category: ai / search / seo / social
# AI(=AEO 답변엔진) 토큰을 검색엔진보다 앞에 둔다 (예: google-read-aloud 가 googlebot 보다 먼저).
CLASSIFY = [
    # OpenAI
    ("gptbot", "ai", "OpenAI"),
    ("oai-searchbot", "ai", "OpenAI"),
    ("chatgpt", "ai", "OpenAI"),
    ("gpt-actions", "ai", "OpenAI"),
    ("openai", "ai", "OpenAI"),
    # Anthropic
    ("claudebot", "ai", "Anthropic"),
    ("claude-user", "ai", "Anthropic"),
    ("anthropic", "ai", "Anthropic"),
    ("claude", "ai", "Anthropic"),
    # Perplexity
    ("perplexity", "ai", "Perplexity"),
    # Google AI (googlebot 보다 먼저)
    ("google-extended", "ai", "Google"),
    ("google-read-aloud", "ai", "Google"),
    ("googleother", "ai", "Google"),
    ("gemini", "ai", "Google"),
    # Meta AI
    ("meta-externalagent", "ai", "Meta AI"),
    ("meta-ai", "ai", "Meta AI"),
    # Apple AI
    ("applebot-extended", "ai", "Apple"),
    # 기타 AI/LLM 크롤러
    ("amazonbot", "ai", "Amazon"),
    ("bytespider", "ai", "ByteDance"),
    ("cohere", "ai", "Cohere"),
    ("ccbot", "ai", "Common Crawl"),
    ("youbot", "ai", "You.com"),
    ("duckassist", "ai", "DuckDuckGo AI"),
    ("diffbot", "ai", "Diffbot"),
    ("timpibot", "ai", "Timpi"),
    ("omgili", "ai", "Webz.io"),
    ("webzio", "ai", "Webz.io"),
    # 검색엔진
    ("googlebot", "search", "Google Search"),
    ("google-inspectiontool", "search", "Google Search"),
    ("storebot-google", "search", "Google Search"),
    ("bingbot", "search", "Bing"),
    ("bingpreview", "search", "Bing"),
    ("msnbot", "search", "Bing"),
    ("naverbot", "search", "Naver"),
    ("yeti", "search", "Naver"),
    ("yandex", "search", "Yandex"),
    ("baidu", "search", "Baidu"),
    ("duckduckbot", "search", "DuckDuckGo"),
    ("applebot", "search", "Apple (Siri/Spotlight)"),
    ("petalbot", "search", "Petal (Huawei)"),
    ("seznam", "search", "Seznam"),
    ("sogou", "search", "Sogou"),
    ("coccoc", "search", "Coccoc"),
    ("mojeek", "search", "Mojeek"),
    # SEO / 분석 도구
    ("ahrefs", "seo", "Ahrefs"),
    ("semrush", "seo", "Semrush"),
    ("seranking", "seo", "SE Ranking"),
    ("dataforseo", "seo", "DataForSEO"),
    ("mj12bot", "seo", "Majestic"),
    ("dotbot", "seo", "Moz"),
    ("rogerbot", "seo", "Moz"),
    ("screaming", "seo", "Screaming Frog"),
    ("sistrix", "seo", "Sistrix"),
    ("barkrowler", "seo", "Babbar"),
    ("blexbot", "seo", "BLEXBot"),
    ("serpstat", "seo", "Serpstat"),
    ("awariobot", "seo", "Awario"),
    # 소셜 / 링크 미리보기 / 메신저
    ("facebookexternalhit", "social", "Facebook"),
    ("facebookbot", "social", "Facebook"),
    ("meta-externalads", "social", "Meta (Ads)"),
    ("twitterbot", "social", "X (Twitter)"),
    ("linkedinbot", "social", "LinkedIn"),
    ("pinterest", "social", "Pinterest"),
    ("slackbot", "social", "Slack"),
    ("telegrambot", "social", "Telegram"),
    ("discordbot", "social", "Discord"),
    ("whatsapp", "social", "WhatsApp"),
    ("redditbot", "social", "Reddit"),
    ("kakao", "social", "Kakao"),
    ("skypeuripreview", "social", "Skype"),
    ("vkshare", "social", "VK"),
    ("line-poker", "social", "LINE"),
]

CAT_LABEL = {"ai": "AI", "search": "Search", "seo": "SEO", "social": "Social", "other": "Other"}


def classify(name: str) -> tuple[str, str]:
    low = name.lower()
    for token, cat, vendor in CLASSIFY:
        if token in low:
            return cat, vendor
    return "other", "Other"


def parse_num(s: str) -> float:
    """'2.9K' -> 2900, '1.2M' -> 1200000, '921' -> 921, '146K' -> 146000."""
    if s is None:
        return 0.0
    t = str(s).strip().replace(",", "").replace(" ", "")
    m = re.match(r"^([\d.]+)\s*([KkMmBb]?)$", t)
    if not m:
        digits = re.sub(r"[^\d.]", "", t)
        return float(digits) if digits else 0.0
    val = float(m.group(1))
    unit = m.group(2).lower()
    return val * {"": 1, "k": 1e3, "m": 1e6, "b": 1e9}[unit]


def parse_pct(s: str) -> float:
    if s is None:
        return 0.0
    digits = re.sub(r"[^\d.]", "", str(s))
    return float(digits) if digits else 0.0


def fmt_k(n: float) -> str:
    if n >= 1e6:
        return f"{n/1e6:.1f}M"
    if n >= 1e3:
        return f"{n/1e3:.1f}K"
    return f"{int(round(n))}"


def cached_color(p: float) -> str:
    if p >= 70:
        return "#2e7d5b"
    if p >= 40:
        return "#b8860b"
    return "#b23a48"


def render_repeat(tpl: str, name: str, blocks: list[str]) -> str:
    start = f"<!-- REPEAT {name} -->"
    end = f"<!-- /REPEAT {name} -->"
    i, j = tpl.index(start), tpl.index(end)
    inner = tpl[i + len(start):j]  # noqa: E203  (unused, blocks are pre-rendered)
    return tpl[:i] + "".join(blocks) + tpl[j + len(end):]


def block_inner(tpl: str, name: str) -> str:
    start = f"<!-- REPEAT {name} -->"
    end = f"<!-- /REPEAT {name} -->"
    return tpl[tpl.index(start) + len(start):tpl.index(end)]


def fill(tpl: str, mapping: dict) -> str:
    for k, v in mapping.items():
        tpl = tpl.replace("{{" + k + "}}", str(v))
    return tpl


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--template", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--chart", default=None)
    args = ap.parse_args()

    with open(args.data, encoding="utf-8") as f:
        d = json.load(f)
    with open(args.template, encoding="utf-8") as f:
        tpl = f.read()

    bots = []
    for b in d["bots"]:
        name = b["name"]
        req = parse_num(b.get("requests"))
        cached = parse_pct(b.get("cached"))
        cat, vendor = classify(name)
        bots.append({"name": name, "disp": str(b.get("requests", "")), "req": req,
                     "cached": cached, "cached_disp": str(b.get("cached", "")),
                     "cat": cat, "vendor": vendor})
    bots.sort(key=lambda x: x["req"], reverse=True)

    bot_total = sum(b["req"] for b in bots)
    ai_bots = [b for b in bots if b["cat"] == "ai"]
    ai_total = sum(b["req"] for b in ai_bots)
    total_edge_num = parse_num(d.get("total_edge", "0"))
    max_req = max((b["req"] for b in bots), default=1) or 1

    # AI 벤더별 집계
    vend: dict[str, dict] = {}
    for b in ai_bots:
        v = vend.setdefault(b["vendor"], {"req": 0.0, "names": [], "cw": 0.0})
        v["req"] += b["req"]
        v["names"].append(b["name"])
        v["cw"] += b["req"] * b["cached"]
    vendors = sorted(vend.items(), key=lambda kv: kv[1]["req"], reverse=True)
    max_vreq = max((v["req"] for _, v in vendors), default=1) or 1

    share_bots = (ai_total / bot_total * 100) if bot_total else 0
    share_total = (ai_total / total_edge_num * 100) if total_edge_num else 0
    top_ai = ai_bots[0] if ai_bots else None

    # ── 타일 ──
    tiles = {
        "TILE1_LABEL": "Total Edge Requests", "TILE1_VAL": d.get("total_edge", "-"),
        "TILE1_SUB": "전체 (모든 트래픽)",
        "TILE2_LABEL": "AI Crawler Requests", "TILE2_VAL": f"≈{fmt_k(ai_total)}",
        "TILE2_SUB": "AEO 답변엔진 봇 합계",
        "TILE3_LABEL": "AI Share", "TILE3_VAL": f"{share_bots:.0f}%",
        "TILE3_SUB": f"봇 트래픽 중 · 전체의 {share_total:.1f}%",
        "TILE4_LABEL": "Top AI Crawler",
        "TILE4_VAL": html.escape(top_ai["name"]) if top_ai else "-",
        "TILE4_SUB": (f"{top_ai['disp']} · {top_ai['cached']:.0f}% cached" if top_ai else "AI 봇 없음"),
    }

    # ── 헤더/푸터 ──
    head = {
        "SCOPE": html.escape(d.get("scope", "")),
        "TITLE": html.escape(d.get("title", "Edge Requests — AEO Bot Metrics")),
        "ENV": html.escape(d.get("env", "Production")),
        "PERIOD_LABEL": html.escape(d.get("period_label", "")),
        "PERIOD_RANGE": html.escape(d.get("period_range", "")),
        "BOT_COUNT": str(len(bots)),
        "SOURCE_URL": html.escape(d.get("source_url", "")),
        "GENERATED": html.escape(d.get("generated") or datetime.now().strftime("%Y-%m-%d %H:%M")),
        "NOTE": ("Requests 값은 Vercel 표기(반올림) 기준. AI/봇 합계는 표시값의 단순 합으로 근사치이며, "
                 "봇 분류는 User-Agent 토큰 기준 휴리스틱임."),
    }

    # ── 차트 (선택) ──
    if args.chart:
        with open(args.chart, "rb") as f:
            b64 = base64.b64encode(f.read()).decode()
        head["CHART_IMG"] = f"data:image/png;base64,{b64}"
        tpl = tpl.replace("<!-- BEGIN chart -->", "").replace("<!-- END chart -->", "")
    else:
        i = tpl.index("<!-- BEGIN chart -->")
        j = tpl.index("<!-- END chart -->") + len("<!-- END chart -->")
        tpl = tpl[:i] + tpl[j:]

    # ── 벤더 행 ──
    vinner = block_inner(tpl, "vendor")
    vblocks = []
    for name, v in vendors:
        cavg = (v["cw"] / v["req"]) if v["req"] else 0
        vblocks.append(fill(vinner, {
            "V_NAME": html.escape(name),
            "V_BOTS": html.escape(", ".join(sorted(v["names"]))),
            "V_REQ": fmt_k(v["req"]),
            "V_BAR": f"{max(2.0, v['req']/max_vreq*100):.1f}",
            "V_SHARE": f"{(v['req']/ai_total*100 if ai_total else 0):.1f}%",
            "V_CACHED": f"{cavg:.1f}%",
            "V_CACHED_W": f"{cavg:.0f}",
            "V_CACHED_COLOR": cached_color(cavg),
        }))
    tpl = render_repeat(tpl, "vendor", vblocks)

    # ── 봇 행 ──
    binner = block_inner(tpl, "bot")
    bblocks = []
    for i, b in enumerate(bots, 1):
        bblocks.append(fill(binner, {
            "RANK": i,
            "BOT": html.escape(b["name"]),
            "CAT": b["cat"],
            "CAT_LABEL": CAT_LABEL[b["cat"]],
            "REQ": html.escape(b["disp"]),
            "BAR": f"{max(2.0, b['req']/max_req*100):.1f}",
            "CACHED": f"{b['cached']:.1f}%",
            "CACHED_W": f"{b['cached']:.0f}",
            "CACHED_COLOR": cached_color(b["cached"]),
        }))
    tpl = render_repeat(tpl, "bot", bblocks)

    tpl = fill(tpl, {**head, **tiles})

    with open(args.out, "w", encoding="utf-8") as f:
        f.write(tpl)

    # 요약 (stdout)
    print(f"[aeo] bots={len(bots)} bot_total≈{fmt_k(bot_total)} "
          f"ai_total≈{fmt_k(ai_total)} ai_share_bots={share_bots:.0f}% "
          f"ai_share_total={share_total:.1f}% vendors={len(vendors)}")
    for name, v in vendors:
        print(f"[aeo]   {name}: {fmt_k(v['req'])}")
    left = tpl.count("{{")
    if left:
        print(f"[aeo] WARNING: {left} unfilled '{{{{' token(s) remain")
    print(f"[aeo] wrote {args.out}")


if __name__ == "__main__":
    main()
