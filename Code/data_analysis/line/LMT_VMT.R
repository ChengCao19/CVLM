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

#----LMT----
aa <- dataall$LMT_X
bb <- dataall$LMT_Y
n <- length(aa)

df <- data.frame(
  x = rep(1:n, 2),           # 横坐标：1到n，重复两次
  value = c(aa, bb),         # 合并aa和bb的值
  group = rep(c("LMT_X", "LMT_Y"), each = n)  # 分组标签
)
dataall$Time_L <- as.POSIXct(data3$Time_L, format = "%H:%M:%S")
dataall$time_period <- ifelse(
  format(dataall$Time_L, "%H:%M:%S") >= "20:00:00" | 
    format(dataall$Time_L, "%H:%M:%S") < "06:00:00", 
  "night", "day"
)

# 创建背景矩形数据（使用与df_z相同的time索引）
night_intervals <- dataall %>%
  mutate(time_index = 1:n()) %>%  # 假设时间顺序与df_z一致
  filter(time_period == "night") %>%
  group_by(grp = cumsum(c(1, diff(time_index) > 1))) %>%
  summarise(
    xmin = min(time_index),
    xmax = max(time_index),
    .groups = "drop"
  ) %>%
  select(-grp)

p1 = ggplot(df, aes(x = x, y = value, color = group)) +
  geom_rect(
    data = night_intervals,
    aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
    fill = "grey70", alpha = 0.5, inherit.aes = FALSE
  ) +
  geom_point(
    aes(y = value, color = group),
    shape = 19, size = 4, alpha = 0.8
  ) +
  # 绘制平滑线
  geom_line(
    aes(y = value, color = group),
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
  labs(x = "Time", y = "Normalized coordinate values", color = "Parameters") +
  theme_bw() +
  theme(
    panel.grid = element_blank(),
    legend.position = "inside",
    legend.position.inside = c(1, 0.95),
    legend.justification = c(1, 1),
    legend.background = element_rect(fill = alpha("white", 0.7)),
    legend.key.size = unit(0.4, "cm"),
    legend.text = element_text(size = 8)
  ) +
  scale_color_npg()+
  scale_y_continuous(
    limits = c(0.2, 0.8),          # 设置 y 轴范围（强制截断数据）
    breaks = seq(0.2, 0.8, 0.2)      
  ) 
p1

ggsave("LMT.pdf", p1, width = 10, height = 6, unit = "in", dpi = 900)

#----VMT----

cc <- dataall$VMT_X
dd <- dataall$VMT_Y
n <- length(cc)

df <- data.frame(
  x = rep(1:n, 2),
  value = c(cc, dd),
  group = rep(c("VMT_X", "VMT_Y"), each = n)
)
dataall$Time_L <- as.POSIXct(data3$Time_L, format = "%H:%M:%S")
dataall$time_period <- ifelse(
  format(dataall$Time_L, "%H:%M:%S") >= "20:00:00" | 
    format(dataall$Time_L, "%H:%M:%S") < "06:00:00", 
  "night", "day"
)

# 创建背景矩形数据（使用与df_z相同的time索引）
night_intervals <- dataall %>%
  mutate(time_index = 1:n()) %>%  # 假设时间顺序与df_z一致
  filter(time_period == "night") %>%
  group_by(grp = cumsum(c(1, diff(time_index) > 1))) %>%
  summarise(
    xmin = min(time_index),
    xmax = max(time_index),
    .groups = "drop"
  ) %>%
  select(-grp)

p2 = ggplot(df, aes(x = x, y = value, color = group)) +
  geom_rect(
    data = night_intervals,
    aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
    fill = "grey70", alpha = 0.5, inherit.aes = FALSE
  ) +
  geom_point(
    aes(y = value, color = group),
    shape = 19, size = 4, alpha = 0.8
  ) +
  geom_line(
    aes(y = value, color = group),
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
  labs(x = "Time", y = "Normalized coordinate values", color = "Parameters") +
  theme_bw() +
  theme(
    panel.grid = element_blank(),
    legend.position = "inside",
    legend.position.inside = c(0.95, 0.95),
    legend.justification = c(1, 1),
    legend.background = element_rect(fill = alpha("white", 0.7)),
    legend.key.size = unit(0.4, "cm"),
    legend.text = element_text(size = 8)
  ) +
  scale_color_npg()+
  scale_y_continuous(
    limits = c(0.2, 0.8),
    breaks = seq(0.2, 0.8, 0.2)      
  ) 
p2

ggsave("VMT.pdf", p2, width = 10, height = 6, unit = "in", dpi = 900)




