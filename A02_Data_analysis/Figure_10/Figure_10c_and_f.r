# ============================================================================
# Time series plots for LMT and VMT (X and Y components)
# Includes night shading, time markers, and custom x-axis labels
# Output: PDF (13 × 7.5 cm)
# ============================================================================

library(ggplot2)
library(tidyverse)

load("dataall.RData")
load("data3.RData")

# ---- LMT ----
aa <- dataall$LMT_X
bb <- dataall$LMT_Y
n <- length(aa)

df <- data.frame(
  x = rep(1:n, 2),
  value = c(aa, bb),
  group = rep(c("LMT_X", "LMT_Y"), each = n)
)

dataall$Time_L <- as.POSIXct(data3$Time_L, format = "%H:%M:%S")
dataall$time_period <- ifelse(
  format(dataall$Time_L, "%H:%M:%S") >= "20:00:00" | 
    format(dataall$Time_L, "%H:%M:%S") < "06:00:00", 
  "night", "day"
)

night_intervals <- dataall %>%
  mutate(time_index = 1:n()) %>%
  filter(time_period == "night") %>%
  group_by(grp = cumsum(c(1, diff(time_index) > 1))) %>%
  summarise(
    xmin = min(time_index),
    xmax = max(time_index),
    .groups = "drop"
  ) %>%
  select(-grp)

p1 <- ggplot(df, aes(x = x, y = value, color = group)) +
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
  geom_vline(
    xintercept = 28, linetype = "dashed", color = "black", linewidth = 0.5) +
  geom_vline(
    xintercept = 40, linetype = "dashed", color = "black", linewidth = 0.5) +
  geom_vline(
    xintercept = 72, linetype = "dashed", color = "black", linewidth = 0.5) +
  annotate("text", x = 28, y = 0.82, label = "9:30",  size = 2.5, color = "#666666", fontface = "bold") +
  annotate("text", x = 40, y = 0.82, label = "15:00", size = 2.5, color = "#666666", fontface = "bold") +
  annotate("text", x = 72, y = 0.82, label = "4:00",  size = 2.5, color = "#666666", fontface = "bold") +
  labs(x = "Time", y = "Normalized coordinate values", color = "Parameters") +
  theme_bw(base_size = 10) +
  theme(
    axis.text = element_text(size = 9, color = "black"),
    axis.title = element_text(size = 11, color = "black"),
    panel.grid = element_blank(),
    legend.position = "inside",
    legend.position.inside = c(1, 0.95),
    legend.justification = c(1, 1),
    legend.background = element_rect(fill = alpha("white", 0.7)),
    legend.key.size = unit(0.4, "cm"),
    legend.text = element_text(size = 8)
  ) +
  scale_color_npg() +
  scale_x_continuous(
    breaks = c(20, 52, 75),
    labels = c("6:00", "20:00", "6:00")
  ) +
  scale_y_continuous(
    limits = c(0.2, 0.85),
    breaks = seq(0.2, 0.8, 0.2)      
  ) 

p1
ggsave("LMT.pdf", p1, width = 13, height = 7.5, unit = "cm", dpi = 900)

# ---- VMT ----
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

night_intervals <- dataall %>%
  mutate(time_index = 1:n()) %>%
  filter(time_period == "night") %>%
  group_by(grp = cumsum(c(1, diff(time_index) > 1))) %>%
  summarise(
    xmin = min(time_index),
    xmax = max(time_index),
    .groups = "drop"
  ) %>%
  select(-grp)

p2 <- ggplot(df, aes(x = x, y = value, color = group)) +
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
  geom_vline(
    xintercept = 28, linetype = "dashed", color = "black", linewidth = 0.5) +
  geom_vline(
    xintercept = 40, linetype = "dashed", color = "black", linewidth = 0.5) +
  geom_vline(
    xintercept = 72, linetype = "dashed", color = "black", linewidth = 0.5) +
  annotate("text", x = 28, y = 0.82, label = "9:30",  size = 2.5, color = "#666666", fontface = "bold") +
  annotate("text", x = 40, y = 0.82, label = "15:00", size = 2.5, color = "#666666", fontface = "bold") +
  annotate("text", x = 72, y = 0.82, label = "4:00",  size = 2.5, color = "#666666", fontface = "bold") +
  labs(x = "Time", y = "Normalized coordinate values", color = "Parameters") +
  theme_bw(base_size = 10) +
  theme(
    axis.text = element_text(size = 9, color = "black"),
    axis.title = element_text(size = 11, color = "black"),
    panel.grid = element_blank(),
    legend.position = "inside",
    legend.position.inside = c(0.95, 0.95),
    legend.justification = c(1, 1),
    legend.background = element_rect(fill = alpha("white", 0.7)),
    legend.key.size = unit(0.4, "cm"),
    legend.text = element_text(size = 8)
  ) +
  scale_color_npg() +
  scale_x_continuous(
    breaks = c(20, 52, 75),
    labels = c("6:00", "20:00", "6:00")
  ) +
  scale_y_continuous(
    limits = c(0.2, 0.85),
    breaks = seq(0.2, 0.8, 0.2)      
  ) 

p2
ggsave("VMT.pdf", p2, width = 13, height = 7.5, unit = "cm", dpi = 900)