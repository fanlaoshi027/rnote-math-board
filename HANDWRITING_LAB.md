# 手感实验室

本阶段只研究手写体验，不做 AI、复杂功能或 UI 重构。

## 当前基线

基于 Rnote 上游当前版本的 modeled pen path：

- `sampling_min_output_rate`: 120 Hz
- `sampling_end_of_stroke_stopping_distance`: 0.01
- `sampling_end_of_stroke_max_iterations`: 20
- `sampling_max_outputs_per_call`: 200
- `stylus_state_modeler_max_input_samples`: 20
- 使用 `StrokeModeler` 实时建模
- 使用 `StrokeModeler::predict()` 做实时预测

## 调校顺序

1. 压感响应
2. 起笔与落笔
3. 快速书写连续性
4. 跟手与延迟
5. 平滑与抖动
6. 快速直线
7. 快速圆弧/转弯
8. 收笔

## 测试原则

一次只改变一组参数；每次在 Mac 实机上测试后记录结果。

重点测试：

- 慢速写字
- 中速写字
- 快速连续书写
- 快速横线、竖线、斜线
- 小圆、大圆
- 数学公式中的括号、根号、分数线
- 轻压、正常压力、重压

## 第一原则

不为了“更平滑”牺牲跟手性；不为了“更粗细变化”牺牲稳定性。
