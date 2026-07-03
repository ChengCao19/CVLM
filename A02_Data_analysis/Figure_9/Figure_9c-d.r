# ============================================================================
# Combined time series: parameters (c) and velocities (d)
# Shared x-axis with night shading, dashed markers, and 3-point moving average
# Output: PDF (17 × 12 cm)
# ============================================================================

library(ggplot2)
library(tidyverse)
library(zoo)
library(patchwork)

load("dataall.RData")
load("data3.RData")

# ---- Parameter data ----
aa = dataall$LIA
bb = dataall$X2D_PA
dd = dataall$X2D_LAR
ee = dataall$X2D_LIA
gg = dataall$X2D_VAR

n <- length(aa)
df_param <- data.frame(
  time = 1:n,
  LIA = aa,
  X2D_PA = bb,
  X2D_LAR = dd,
  X2D_LIA = ee,
  X2D_VAR = gg
) %>% 
  pivot_longer(cols = -time, names_to = "variable", values_to = "z_score") %>%
  group_by(variable) %>%
  mutate(z_smooth = zoo::rollmean(z_score, k = 3, fill = "extend", align = "center")) %>%
  ungroup()

df_param$variable <- recode(df_param$variable,
                            "X2D_PA"  = "2D-LSR", "X2D_LIA" = "2D-VSR",
                            "X2D_LAR" = "2D-LAR", "X2D_VAR" = "2D-VAR", "LIA" = "LIA"
)

# ---- Velocity data ----
aa_v = dataall$LIAV
bb_v = dataall$X2D_PAV
dd_v = dataall$X2D_LARV
ee_v = dataall$X2D_LIAV
gg_v = dataall$X2D_VARV

n_v <- length(aa_v)
df_vel <- data.frame(
  time = 1:n_v,
  LIAV = scale(aa_v),
  X2D_PAV = scale(bb_v),
  X2D_LARV = scale(dd_v),
  X2D_LIAV = scale(ee_v),
  X2D_VARV = scale(gg_v)
) %>% 
  pivot_longer(cols = -time, names_to = "variable", values_to = "z_score") %>%
  group_by(variable) %>%
  mutate(z_smooth = zoo::rollmean(z_score, k = 3, fill = "extend", align = "center")) %>%
  ungroup()

df_vel$variable <- recode(df_vel$variable,
                          "X2D_PAV"  = "2D-LSRV", "X2D_LIAV" = "2D-VSRV",
                          "X2D_LARV" = "2D-LARV", "X2D_VARV" = "2D-VARV", "LIAV" = "LIAV"
)

# ---- Night intervals ----
night_intervals <- dataall %>%
  mutate(time_index = 1:n()) %>%
  filter(format(as.POSIXct(data3$Time_L, format = "%H:%M:%S"), "%H:%M:%S") >= "20:00:00" | 
           format(as.POSIXct(data3$Time_L, format = "%H:%M:%S"), "%H:%M:%S") < "06:00:00") %>%
  group_by(grp = cumsum(c(1, diff(time_index) > 1))) %>%
  summarise(xmin = min(time_index), xmax = max(time_index), .groups = "drop") %>%
  select(-grp)

# ---- Color map ----
color_map <- c(
  "LIA" = "#1A1A1A", "2D-VSR" = "#2E6099", "2D-LAR" = "#2E9970", 
  "2D-LSR" = "#994A5A", "2D-VAR" = "#8B7A3A",
  "LIAV" = "#1A1A1A", "2D-VSRV" = "#2E6099", "2D-LARV" = "#2E9970", 
  "2D-LSRV" = "#994A5A", "2D-VARV" = "#8B7A3A"
)

# ---- Theme ----
theme_cns <- theme_bw(base_size = 10) +
  theme(
    panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "#333333", linewidth = 0.5),
    axis.text = element_text(size = 9, color = "black"),
    axis.title = element_text(size = 11, color = "black"),
    axis.line = element_line(color = "#333333", linewidth = 0.4),
    axis.ticks = element_line(color = "#333333", linewidth = 0.3),
    axis.ticks.length = unit(2.5, "mm"),
    plot.margin = margin(10, 12, 8, 10)
  )

# ---- Parameter plot (c) ----
plot_param <- ggplot(df_param, aes(x = time)) +
  geom_rect(data = night_intervals, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
            fill = "#E0E0E0", alpha = 0.55, inherit.aes = FALSE) +
  geom_point(aes(y = z_score, color = variable), shape = 19, size = 2.2, alpha = 0.35) +
  geom_line(aes(y = z_smooth, color = variable), linewidth = 0.7, alpha = 0.85) +
  geom_vline(xintercept = 28, linetype = "dashed", color = "#999999", linewidth = 0.3) +
  geom_vline(xintercept = 40, linetype = "dashed", color = "#999999", linewidth = 0.3) +
  geom_vline(xintercept = 64, linetype = "dashed", color = "#999999", linewidth = 0.3) +
  geom_vline(xintercept = 72, linetype = "dashed", color = "#999999", linewidth = 0.3) +
  annotate("text", x = 28, y = 1.22, label = "9:30",  size = 2.5, color = "#666666", fontface = "bold") +
  annotate("text", x = 40, y = 1.22, label = "14:30", size = 2.5, color = "#666666", fontface = "bold") +
  annotate("text", x = 64, y = 1.22, label = "1:00",  size = 2.5, color = "#666666", fontface = "bold") +
  annotate("text", x = 72, y = 1.22, label = "4:00",  size = 2.5, color = "#666666", fontface = "bold") +
  labs(x = NULL, y = "Parameters value", color = "Parameters") +
  scale_color_manual(values = color_map) +
  scale_y_continuous(limits = c(-0.15, 1.25), breaks = seq(0, 1, 0.25)) +
  theme_cns +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        legend.position = "right",
        legend.background = element_rect(fill = alpha("white", 0.9), color = "#CCCCCC", linewidth = 0.5),
        legend.key.size = unit(0.4, "cm"), legend.text = element_text(size = 8),
        legend.title = element_text(size = 9, face = "bold"))

# ---- Velocity plot (d) ----
plot_vel <- ggplot(df_vel, aes(x = time)) +
  geom_rect(data = night_intervals, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
            fill = "#E0E0E0", alpha = 0.55, inherit.aes = FALSE) +
  geom_line(aes(y = z_smooth, color = variable), linewidth = 0.7, alpha = 0.85) +
  geom_vline(xintercept = 28, linetype = "dashed", color = "#999999", linewidth = 0.3) +
  geom_vline(xintercept = 40, linetype = "dashed", color = "#999999", linewidth = 0.3) +
  geom_vline(xintercept = 64, linetype = "dashed", color = "#999999", linewidth = 0.3) +
  geom_vline(xintercept = 72, linetype = "dashed", color = "#999999", linewidth = 0.3) +
  annotate("text", x = 28, y = 3.7, label = "9:30",  size = 2.5, color = "#666666", fontface = "bold") +
  annotate("text", x = 40, y = 3.7, label = "14:30", size = 2.5, color = "#666666", fontface = "bold") +
  annotate("text", x = 64, y = 3.7, label = "1:00",  size = 2.5, color = "#666666", fontface = "bold") +
  annotate("text", x = 72, y = 3.7, label = "4:00",  size = 2.5, color = "#666666", fontface = "bold") +
  labs(x = "Time", y = "Velocity", color = "Parameters") +
  scale_color_manual(values = color_map) +
  scale_x_continuous(breaks = c(20, 52, 75), labels = c("6:00", "20:00", "6:00")) +
  scale_y_continuous(limits = c(-2, 4), breaks = seq(-2, 4, 2)) +
  theme_cns +
  theme(legend.position = "right",
        legend.background = element_rect(fill = alpha("white", 0.9), color = "#CCCCCC", linewidth = 0.5),
        legend.key.size = unit(0.4, "cm"), legend.text = element_text(size = 8),
        legend.title = element_text(size = 9, face = "bold"))

# ---- Combine ----
combined <- plot_param / plot_vel +
  plot_layout(heights = c(1, 1)) +
  plot_annotation(tag_levels = list(c("c", "d"))) &
  theme(plot.tag = element_text(size = 14, face = "plain", colour = "black"))

print(combined)
ggsave("Figure_9c-d.pdf", combined, width = 17, height = 12, unit = "cm", dpi = 900, device = cairo_pdf)