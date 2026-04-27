# DecoSentryPro
Advanced mesh-network monitoring system with WPF GUI and automated reporting. Optimized for infrastructure automation.
# Deco Sentry Pro v4.0

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)
![UI](https://img.shields.io/badge/UI-WPF%20%2F%20XAML-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## 📌 Overview
**Deco Sentry Pro** is an infrastructure automation tool designed to monitor large-scale TP-Link Deco mesh networks (90+ nodes). Unlike standard monitoring tools, it provides a lightweight, standalone solution with a custom WPF interface, real-time logging, and automated reporting for administrative departments.

![DecoSentryPro Demo](assets/demo.gif)

## 🚀 Key Features
* **Real-time Monitoring:** Multi-threaded node availability checks.
* **Infrastructure as Code (IaC) approach:** Configuration-driven architecture via `config.json`.
* **Disaster Recovery Ready:** Integrated logging system for post-incident analysis.
* **Custom UI:** Modern "Neon" WPF dashboard for high-visibility status tracking.
* **Data Export:** Automated CSV generation for inventory and audit compliance.

## 🛠 Technical Stack
* **Language:** PowerShell (Core Logic)
* **Frontend:** XAML / WPF (Windows Presentation Foundation)
* **Data Format:** JSON (Configuration), CSV (Export)
* **Architecture:** Event-driven UI updates, modular script structure.

## 📂 Project Structure
* `main.ps1` — Core application logic and UI event handlers.
* `config.json` — Network topology and node definitions.
* `DecoSentryPro_v4.exe` — Compiled standalone binary for deployment.

## 🔧 Installation & Usage
1. Clone the repository.
2. Configure your network nodes in `config.json`.
3. Run `main.ps1` or the compiled `.exe`.

---
**Developed by Chuvilev M.M. as part of Infrastructure Automation Project at CSSV #11.**
