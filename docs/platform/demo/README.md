# 🎓 Demo & Presentation - Self-Service Platform

Hướng dẫn demo và presentation về Self-Service Platform, từ lúc **chưa có hạ tầng Azure**.

## 📚 Tài Liệu Demo

### Main Guide
- **[Demo Guide](DEMO_GUIDE.md)**: Hướng dẫn demo chi tiết từng bước, bắt đầu từ chưa có hạ tầng

### Supporting Materials
- **[Troubleshooting](TROUBLESHOOTING.md)**: Giải quyết vấn đề thường gặp trong demo
- **[Presentation Outline](PRESENTATION_OUTLINE.md)**: Outline cho presentation
- **[Checklist](CHECKLIST.md)**: Checklist chuẩn bị demo

## 🎬 Demo Scripts

### Full Demo (15-20 phút)
```bash
./scripts/demo-for-teacher.sh
```

### Quick Demo (5 phút)
```bash
./scripts/demo-quick.sh
```

### Prepare Environment
```bash
./scripts/prepare-demo.sh
```

## 📋 Demo Flow

1. **Setup Terraform Backend** (1-2 phút) - Lần đầu tiên
2. **Setup Infrastructure** (5-10 phút) - Tạo hạ tầng Azure
3. **Create Service** (2 phút) - Tạo service mới
4. **Deploy** (3 phút) - Deploy qua GitHub Actions
5. **Verify** (2 phút) - Kiểm tra deployment

## 🎯 Key Points to Highlight

1. **Automation**: Từ code đến production chỉ với `git push`
2. **Safety**: Multi-level validation và testing
3. **Modularity**: Terraform modules có thể tái sử dụng
4. **Developer Experience**: Dev mới chỉ cần 3 bước
5. **Cost Optimization**: Scale-to-zero, pay-per-use

## 📖 More Information

- **[Demo Guide](DEMO_GUIDE.md)**: Hướng dẫn chi tiết từ đầu
- **[Troubleshooting](TROUBLESHOOTING.md)**: Xử lý vấn đề
- **[Presentation Outline](PRESENTATION_OUTLINE.md)**: Structure cho presentation

---

**Ready to demo?** → [Demo Guide](DEMO_GUIDE.md)
