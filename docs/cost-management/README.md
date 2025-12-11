# Tổng quan : Azure Cost Management (tương đương AWS CE/Budgets)

## Mục tiêu
- Phân tích chi phí qua Azure Cost Analysis (thay cho AWS Cost Explorer).
- Chuẩn hóa tagging để phân bổ chi phí theo service/team.
- Thiết lập ngân sách và cảnh báo (Azure Budgets) ở mức 10 USD/tháng với ngưỡng 50/80/100%.
- Phạm vi: riêng cho 1 resource group.

## Kiến trúc Terraform (folder `cost-management`)
- Resource Group `rg-demo-cost` (mặc định) kèm bộ tag chuẩn.
- Policy custom: buộc 5 tag `Service, Owner, Environment, CostCenter, Project` (effect = Deny).
- Budget theo tháng cho resource group với alert 50/80/100% (Actual) gửi email.

## Chuẩn tag đề xuất
- Key: `Service`, `Owner`, `Environment`, `CostCenter`, `Project`.
- Giá trị mẫu (override trong `variables.tf`): `Service=cost-demo`, `Owner=student`, `Environment=demo`, `CostCenter=demo`, `Project=cost-visibility`.
- Quy tắc: key PascalCase, value dạng kebab-case hoặc từ đơn; không để trống.

## Các file chính
- `cost-management/versions.tf`: version Terraform + provider azurerm.
- `cost-management/variables.tf`: cấu hình RG, tags, ngân sách, email, thời gian hiệu lực.
- `cost-management/main.tf`: RG + policy enforce tag + budget 10 USD/tháng với alert 50/80/100%.

## Ghi chú
- Budget đang dùng số liệu Actual; có thể thêm Forecast bằng cách đặt `threshold_type = "Forecasted"` cho một notification block.
- Thời gian hiệu lực budget mặc định: bắt đầu đầu tháng hiện tại, kết thúc sau ~1 năm; tùy chỉnh qua biến `budget_start_date` và `budget_end_date`.
