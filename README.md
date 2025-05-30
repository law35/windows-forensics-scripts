# windows-forensics-scripts
PowerShell scripts used for local forensic analysis and system auditing.

# 🕵️ Windows Forensics PowerShell Toolkit

A collection of PowerShell scripts used during a real-world forensic analysis of a Windows 10 system. This toolkit enables system admins, blue teamers, and curious power users to extract vital system and network data for audit, incident response, and forensic preservation.

> All scripts in this repository were used in conjunction with [https://medium.com/@clawshea/i-turned-my-laptop-into-a-forensics-case-study-heres-what-i-found-df3b8635c66b], where I turned my own laptop into a full forensic case study.

---
 How to Use
These scripts are designed to be run manually or as part of a collection.

🐚 Prerequisites
PowerShell 5.1+ or PowerShell Core (7.x)

Admin privileges for certain scripts (e.g., firewall, netstat)

🏃 Execution
From an elevated PowerShell session

---
🔍 forensic_collector.ps1 — Forensic Snapshot Collector
Purpose:
This PowerShell script gathers a comprehensive forensic snapshot of a Windows machine by exporting key system, user, and network artifacts. It's ideal for baseline assessments, incident response, or routine system auditing.

✅ Key Features
This script collects and logs the following data points:

🖧 Network Information
ARP Table — Reveals IP-to-MAC mappings in your local network.

DNS Cache — Displays recently resolved domains.

Netstat Connections — Shows active and listening connections (TCP/UDP).

UDP Endpoints — Lists currently open UDP ports.

Network Interfaces — Uses ipconfig /all to display all adapter details.

Proxy Settings — Reveals any configured HTTP/SOCKS proxies.

Wi-Fi Profiles — Shows saved wireless profiles and their SSIDs.

🔐 Security Configuration
Firewall Rules — Exports current firewall rules across profiles.

Hosts File — Reads the contents of C:\Windows\System32\drivers\etc\hosts.

🧠 User Activity & Persistence Clues
Prefetch Files — Lists entries in the Prefetch directory to show recently run programs.

AppCompat Cache — Provides application execution history.

Installed Drivers — Queries all installed drivers for review.

Logged-in Users and Session Info — Captures current session and user data.

📁 File Output
Data is exported to plain text (.txt) and CSV (.csv) files.

Each file is timestamped and saved in the script directory for later analysis or ingestion into a SIEM.

🛠 Example Use Case
You're doing a forensic sweep on a potentially compromised laptop. Before diving into memory forensics or log analysis, you want to:

Document the current network state.

Identify running or recently executed applications.

Export potential persistence mechanisms (like prefetch, DNS, firewall rules).

Running forensic_collector.ps1 provides a foundational forensic report that can be used for later comparison or escalation.

---
***I named the rest of the scripts in this reprository after its function***

---
🔐 Legal & Ethical Use
This toolkit is intended for educational, auditing, and blue-team use on systems you own or have explicit permission to investigate. Unauthorized use may violate terms of service, employment contracts, or privacy laws.

---
🤝 Contributing
Feel free to fork, open issues, or submit pull requests to enhance script logic, portability, or OS compatibility.

---
📜 License
MIT License — Free to use, modify, and distribute with attribution.

---

🔗 Follow My Work
Medium: [https://clawshea.medium.com]
