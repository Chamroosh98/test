<div align="center">

# DayPass

**A Minimalist & High-Performance Network & System Utility for OpenWrt**

*Fast · Lightweight · Dependency-free · Built with pure POSIX Shell for OpenWrt devices.*

[![ci](https://img.shields.io/badge/ci-passing-brightgreen?style=flat-square&logo=github-actions)](https://github.com/Chamroosh98)
[![release](https://img.shields.io/badge/release-v1.0.0-purple?style=flat-square)](https://github.com/Chamroosh98)
[![shell](https://img.shields.io/badge/shell-POSIX%20ash-blue?style=flat-square&logo=gnu-bash)](https://www.openwrt.org)
[![platform](https://img.shields.io/badge/platform-OpenWrt-darkgreen?style=flat-square&logo=openwrt)](https://openwrt.org)

---

[**English**](#-what-is-this) · [**فارسی**](#-درباره-پروژه-persian) · [**Quick Start**](#-quick-start) · [**Features**](#-key-features)

</div>

> 💡 **Note:** The CLI tool lives in the root directory. A complete Persian summary (`درباره پروژه`) is provided at the bottom of this page.

---

## 📑 Contents

- [DayPass](#daypass)
  - [📑 Contents](#-contents)
  - [🚀 What is this?](#-what-is-this)
  - [✨ Key Features](#-key-features)
  - [⚡ Quick Start](#-quick-start)

---

## 🚀 What is this?

**DayPass** is a lightweight, responsive terminal interface designed specifically for OpenWrt routers and embedded Linux systems. It provides real-time system diagnostics, ISP network details, DNS/latency health checking, and live speed monitoring—all wrapped in a clean, ANSI-aligned terminal UI without the bloat of heavy external dependencies.

---

## ✨ Key Features

* **🖥 System Overview:** Instant view of architecture, OpenWrt release version, RAM usage, and overlay storage with visual progress bars.
* **🌐 Network Diagnostics:** Detailed public IP discovery, geolocation lookup, ISP name, and ASN identifier using fast failover APIs.
* **🔎 Health Checker:** Concurrent DNS resolution, Ping loss evaluation, and HTTPS latency testing across major edge nodes (`google.com`, `cloudflare.com`, etc.).
* **📊 Live Speed Monitor:** Real-time WAN interface bandwidth monitoring (`KB/s` / `MB/s`) with zero terminal flickering.
* **🧰 Package Manager Integration:** Interactive CLI menu to streamline custom package installations.

---

## ⚡ Quick Start

Run the one-liner command directly on your OpenWrt SSH terminal:

```bash
sh -c "$(curl -fsSL [https://raw.githubusercontent.com/Chamroosh98/DayPass/main/install.sh](https://raw.githubusercontent.com/Chamroosh98/DayPass/main/install.sh))"


درباره پروژه (Persian)
DayPass یک ابزار ترمینال (CLI) سبُک، سریع و مدرن برای روترهای OpenWrt و سیستم‌عامل‌های لینوکس تعبیه‌شده است. این ابزار به شما این امکان را می‌دهد تا بدون نیاز به پکیج‌های سنگین جانبی، وضعیت سخت‌افزار، سلامت شبکه، پینگ، وضعیت DNS و سرعت لحظه‌ای دانلود/آپلود ارتباط اینترنت خود را در یک رابط کاربری ترمینالی شیک بررسی کنید.

🌟 ویژگی‌های کلیدی
نمایش مشخصات سیستم: میزان مصرف رم، حافظه ذخیره‌سازی، معماری پردازنده و نسخه OpenWrt.

اطلاعات کامل شبکه: تشخیص آی‌پی عمومی، کشور، شهر، ISP و شماره ASN.

تست سلامت اینترنت: بررسی هم‌زمان DNS ،Ping و ارتباط امن HTTPS.

مانیتور سرعت لحظه‌ای: نمایش زنده سرعت دانلود و آپلود بر روی رابط WAN.

طراحی بهینه: سازگار با شل استاندارد POSIX (ash) در OpenWrt.