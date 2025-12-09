# 🚀 Self-Service Platform

Nền tảng Self-Service cho phép developer deploy service một cách **an toàn** và **nhanh chóng** chỉ với vài bước đơn giản.

## 📚 Documentation Structure

```
docs/platform/
├── README.md              # This file - Overview
├── demo/                  # Demo & Presentation guides
│   ├── DEMO_GUIDE.md     # Hướng dẫn demo từ đầu (chưa có hạ tầng)
│   ├── TROUBLESHOOTING.md # Giải quyết vấn đề trong demo
│   ├── PRESENTATION_OUTLINE.md # Outline cho presentation
│   └── CHECKLIST.md      # Checklist chuẩn bị demo
└── components/           # Platform components & architecture
    └── ARCHITECTURE.md   # Kiến trúc và các thành phần
```

## 🎓 Demo Guide

Hướng dẫn demo từ đầu đến cuối, bắt đầu từ lúc **chưa có hạ tầng Azure**.

👉 **[Xem Demo Guide](demo/DEMO_GUIDE.md)**

### Quick Links
- **[Demo Guide](demo/DEMO_GUIDE.md)**: Hướng dẫn demo chi tiết từng bước
- **[Troubleshooting](demo/TROUBLESHOOTING.md)**: Giải quyết vấn đề thường gặp
- **[Presentation Outline](demo/PRESENTATION_OUTLINE.md)**: Outline cho presentation
- **[Checklist](demo/CHECKLIST.md)**: Checklist chuẩn bị demo

## 🏗️ Components & Architecture

Tài liệu về kiến trúc và các thành phần của platform.

👉 **[Xem Architecture](components/ARCHITECTURE.md)**

### Nội dung bao gồm:
- Deployment Flow
- Terraform Modules Structure
- Security Architecture
- Monitoring & Observability
- Scaling Strategy
- Rollback Strategy

## 🚀 Quick Start Demo

```bash
# 1. Setup Terraform backend (lần đầu tiên)
./scripts/setup-terraform-backend.sh

# 2. Chạy demo script
./scripts/demo-for-teacher.sh
```

## 📖 More Information

- **[Demo Guide](demo/DEMO_GUIDE.md)**: Hướng dẫn demo từ đầu
- **[Architecture](components/ARCHITECTURE.md)**: Kiến trúc và components
- **[Troubleshooting](demo/TROUBLESHOOTING.md)**: Xử lý vấn đề

---

**Platform Status**: ✅ Production Ready
