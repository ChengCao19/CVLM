rm(list = ls())

library(ggplot2)
library(ggsci)
library(ggpubr)
library(ggExtra)
library(broom)
library(ggthemes)
library(tidyverse)
library(zoo)    # 用于移动平均计算
library(dplyr)  # 用于数据处理


# dataall = read.table("clipboard",sep = "\t",header = TRUE)
# save(dataall, file = "dataall.RData", compress = "xz")
load("dataall.RData")
load("data3.RData")

#----
aa = dataJC$LIA
bb = dataJC$X2D_PA
cc = dataJC$X2D_LAR
dd = dataJC$X2D_LIA
ee = dataJC$X2D_VAR

# 创建基础数据框
n <- length(aa)
df_z <- data.frame(
  time = 1:n,
  LIA = aa,
  X2D_PA = bb,
  X2D_LAR = cc,
  X2D_LIA = dd,
  X2D_VAR = ee
) %>% 
  tidyr::pivot_longer(
    cols = -time,
    names_to = "variable",
    values_to = "z_score"
  ) %>%
  # 添加移动平均平滑 (窗口大小k=3)
  group_by(variable) %>%
  mutate(
    z_smooth = zoo::rollmean(z_score, 
                             k = 3, 
                             fill = "extend", 
                             align = "center")
  ) %>%
  ungroup()

# 时间区间背景处理（假设dataJC与df_z时间索引一致）
dataJC$Time_L <- as.POSIXct(data3$Time_L, format = "%H:%M:%S")
dataJC$time_period <- ifelse(
  format(dataJC$Time_L, "%H:%M:%S") >= "20:00:00" | 
    format(dataJC$Time_L, "%H:%M:%S") < "06:00:00", 
  "night", "day"
)

# 创建背景矩形数据（使用与df_z相同的time索引）
night_intervals <- dataJC %>%
  mutate(time_index = 1:n()) %>%  # 假设时间顺序与df_z一致
  filter(time_period == "night") %>%
  group_by(grp = cumsum(c(1, diff(time_index) > 1))) %>%
  summarise(
    xmin = min(time_index),
    xmax = max(time_index),
    .groups = "drop"
  ) %>%
  select(-grp)

# 绘图
p1 <- ggplot(df_z, aes(x = time)) +
  # 先绘制背景矩形
  geom_rect(
    data = night_intervals,
    aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
    fill = "grey70", alpha = 0.5, inherit.aes = FALSE
  ) +
  # 绘制原始数据点
  geom_point(
    aes(y = z_score, color = variable),
    shape = 19, size = 4, alpha = 0.8
  ) +
  # 绘制平滑线
  geom_line(
    aes(y = z_smooth, color = variable),
    linewidth = 1.5, alpha = 0.8
  ) +
  # 添加垂直虚线（新增部分）
  geom_vline(
    xintercept = 28, linetype = "dashed", color = "black", linewidth = 1.5)+   # 9:30
  geom_vline(
    xintercept = 40, linetype = "dashed", color = "black", linewidth = 1.5)+   # 14:30
  geom_vline(
    xintercept = 72, linetype = "dashed", color = "black", linewidth = 1.5)+   # 3.50
  # 样式设置
  labs(x = "Time", y = "Velocity", color = "Parameters") +
  theme_bw() +
  theme(
    panel.grid = element_blank(),
    legend.position = c(0.88, 0.82),
    legend.justification = c(1, 1),
    legend.background = element_rect(fill = alpha("white", 0.7)),
    legend.key.size = unit(0.4, "cm"),
    legend.text = element_text(size = 8)
  ) +
  scale_color_npg()

p1

# p1 = ggMarginal(p1,type="density",xparams = list(fill = scales::alpha("#3A968B", alpha = 0.5)),size = 12,
#            yparams = list(fill = scales::alpha("#3A968B", alpha = 0.5)))

ggsave("Line.pdf", p1, width = 10, height = 6, unit = "in", dpi = 900)

