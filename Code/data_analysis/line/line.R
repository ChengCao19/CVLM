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


# dataJC = read.table("clipboard",sep = "\t",header = TRUE)
# save(dataJC, file = "dataJC.RData", compress = "xz")
load("dataall.RData")
load("data3.RData")

#----
aa = dataall$LIA
bb = dataall$X2D_PA
cc = dataall$X2D_LA*0.000001
dd = dataall$X2D_LAR
ee = dataall$X2D_LIA
ff = dataall$X2D_VA*0.000001
gg = dataall$X2D_VAR

# 创建基础数据框
n <- length(aa)
df_z <- data.frame(
  time = 1:n,
  LIA = aa,
  X2D_PA = bb,
  X2D_LA = cc,
  X2D_LAR = dd,
  X2D_LIA = ee,
  X2D_VA = ff,
  X2D_VAR = gg
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

# 时间区间背景处理（假设dataall与df_z时间索引一致）
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

# 绘图
p1 = ggplot(df_z, aes(x = time)) +
  # 先绘制背景矩形
  geom_rect(
    data = night_intervals,
    aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
    fill = "grey70", alpha = 0.4, inherit.aes = FALSE
  ) +
  # 绘制原始数据点
  geom_point(
    aes(y = z_score, color = variable),
    shape = 19, size = 3, alpha = 0.4
  ) +
  # 绘制平滑线
  geom_line(
    aes(y = z_smooth, color = variable),
    linewidth = 1, alpha = 0.8
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
    legend.position = "inside",                # 声明图例在绘图区域内
    legend.position.inside = c(1, 0.8),       # 指定具体坐标
    legend.justification = c(1, 1),
    legend.background = element_rect(fill = alpha("white", 0.7)),
    legend.key.size = unit(0.4, "cm"),
    legend.text = element_text(size = 8)
  ) +
  scale_color_npg()+
  scale_y_continuous(
    limits = c(-0.15, 1.2),
    breaks = seq(0, 1, 0.25)
  )

p1

# p1 = ggMarginal(p1,type="density",xparams = list(fill = scales::alpha("#3A968B", alpha = 0.5)),size = 12,
#            yparams = list(fill = scales::alpha("#3A968B", alpha = 0.5)))

ggsave("Line.pdf", p1, width = 6, height = 6, unit = "in", dpi = 900)

