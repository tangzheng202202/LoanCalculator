# LoanCalculator - 贷款计算器

iOS/macOS SwiftUI 贷款计算工具，支持多种还款方式计算与导出。

## 功能

- ✅ **等额本息** - 月供相同，总利息高
- ✅ **等额本金** - 首月高，逐月递减
- ✅ **先息后本** - 每月还息，到期还本
- ✅ 每月还款明细（支持按月搜索）
- ✅ CSV 导出
- ✅ PDF 导出
- ✅ 完整单元测试覆盖

## 运行

```bash
cd LoanCalculator
xcodebuild test -scheme LoanCalculator -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 技术栈

- SwiftUI
- Swift Testing (@Test)
- UIKit (PDF 导出、分享)

## 项目结构

```
LoanCalculator/
├── LoanCalculator/
│   ├── Models/
│   │   ├── LoanModel.swift          # 数据模型
│   │   └── CalculationEngine.swift  # 计算引擎
│   ├── Views/
│   │   ├── ContentView.swift        # Tab 入口
│   │   ├── CalculatorView.swift     # 输入页
│   │   ├── ResultView.swift         # 结果页
│   │   └── MonthlyDetailView.swift  # 明细页
│   └── Utils/
│       ├── Formatters.swift         # 格式化工具
│       ├── ExportManager.swift      # 导出（CSV/PDF）
│       └── ShareSheet.swift         # 分享组件
├── LoanCalculatorTests/             # 单元测试
└── LoanCalculatorUITests/           # UI 测试
```

## 版本历史

- v1.0 (2026-03-29) - 完成核心功能，修复 NavigationView 兼容性，添加完整单元测试
- v0.1 (2026-03-14) - Initial Commit