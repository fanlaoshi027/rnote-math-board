# 墨算：第一阶段手感调校

目标：先把“拿笔写数学题”的手感调出来，暂不开发 AI、复杂功能或最终 UI。

## 调校顺序

1. 输入延迟：起笔立即响应，尽量减少可感知拖尾。
2. 压感：轻压明显变细，正常压力稳定，重压自然增粗；避免一开始就把压力曲线压得过硬。
3. 快速书写：高速连续笔画不能出现明显“断成一节一节”的感觉。
4. 平滑：消除抖动，但不能为了平滑产生明显拖笔。
5. 转弯：括号、数字、字母、圆弧快速转向时保持自然。
6. 收笔：快速抬笔时不出现异常拉长、尖刺或明显滞后。
7. 高频采样/预测：只在确认能降低延迟而不改变书写轨迹的前提下调整。

## 当前 Rnote 手写链路

Rnote 当前使用 `PenPathModeledBuilder` 和 `ink-stroke-modeler-rs` 处理建模笔迹；输入中的位置、时间和 pressure 会送入 `StrokeModeler`，模型器输出重新采样后的元素。当前上游还使用预测缓冲来改善实时显示。

重点参数入口：

- `crates/rnote-compose/src/builders/penpathmodeledbuilder.rs`
- `crates/rnote-compose/src/style/smooth/`
- `crates/rnote-compose/src/penpath/`
- `crates/rnote-engine/src/pens/brush.rs`
- `crates/rnote-engine/src/pens/pensconfig/brushconfig.rs`
- `crates/rnote-ui/src/canvas/input.rs`

## 第一轮原则

不要同时修改多个变量。每一轮只改变一组参数，然后在 Mac 上实际测试：

- 慢写汉字
- 快写汉字
- 数字 0~9
- `x y a b`
- 括号 `()`
- 快速圆圈
- 长直线
- 连续波浪线
- 轻压 → 正常 → 重压

确认结果后再进入下一轮。

## 当前基线

Rnote upstream commit：`bbc5354502ba2fc83eec2670b535348825e679a6`

第一阶段暂不修改 UI，不加入 AI，不加入题库，不加入复杂数学工具。
