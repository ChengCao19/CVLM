# ============================================================================
# Training loss and metric curves for TVDs (Box Loss, Class Loss, Dist. Focal Loss,
# plus mAP, Precision, Recall)
# Output: PDF (cairo)
# ============================================================================

library(ggplot2)
library(reshape2)

load("data1.RData")

# ---------- Loss plot ----------
loss_df <- data1[, c("Epochs", "Box.Loss", "Class.Loss", "Distribution.Focal.Loss")]
colnames(loss_df) <- c("Epochs", "Box Loss", "Class Loss", "Distribution Focal Loss")
loss_long <- melt(loss_df, id.vars = "Epochs", variable.name = "Metric")

my_loss_colors <- c(
  "Box Loss"                = "#93C8C0",
  "Class Loss"              = "#CA8BA8",
  "Distribution Focal Loss" = "#8583A9"
)

p_loss <- ggplot(loss_long, aes(x = Epochs, y = value, color = Metric)) +
  geom_line(linewidth = 0.8, alpha = 0.9) +
  geom_point(size = 2.2, shape = 19, alpha = 0.6) +
  scale_x_continuous(
    breaks = seq(0, max(data1$Epochs), by = 25),
    limits = c(0, max(data1$Epochs)),
    expand = c(0.02, 0),
    labels = scales::number_format(accuracy = 1)
  ) +
  scale_y_continuous(
    breaks = seq(0, ceiling(max(loss_long$value)), by = 1),
    limits = c(0, ceiling(max(loss_long$value))),
    expand = c(0.05, 0),
    labels = scales::number_format(accuracy = 1)
  ) +
  scale_color_manual(values = my_loss_colors) +
  labs(x = "Epochs", y = "Training loss in TVDs") +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid        = element_blank(),
    panel.border      = element_rect(color = "#333333", fill = NA, linewidth = 0.4),
    axis.ticks        = element_line(color = "#333333", linewidth = 0.3),
    axis.ticks.length = unit(2.5, "mm"),
    axis.text         = element_text(size = 9, color = "#333333"),
    axis.title        = element_text(size = 11, color = "#111111"),
    legend.position   = c(0.78, 0.82),
    legend.background = element_rect(fill = "white", color = "#CCCCCC", linewidth = 0.5),
    legend.text       = element_text(size = 8),
    legend.title      = element_blank(),
    legend.key.size   = unit(0.3, "cm"),
    legend.margin     = margin(3, 3, 3, 3),
    plot.margin       = margin(6, 6, 6, 6)
  )

p_loss

ggsave(
  "loss_T.pdf",
  plot   = p_loss,
  width  = 8,
  height = 8,
  units  = "cm",
  dpi    = 300,
  device = cairo_pdf
)

# ---------- Metric plot ----------
metric_df <- data1[, c("Epochs", "mAP.50", "mAP.50.95", "Precision", "Recall")]
colnames(metric_df) <- c("Epochs", "mAP 50", "mAP 50-95", "Precision", "Recall")
metric_long <- melt(metric_df, id.vars = "Epochs", variable.name = "Metric")

my_metric_colors <- c(
  "mAP 50"    = "#76BCA3",
  "mAP 50-95" = "#CE6476",
  "Precision" = "#7C6CAA",
  "Recall"    = "#4DBBD5"
)

p_metric <- ggplot(metric_long, aes(x = Epochs, y = value, color = Metric)) +
  geom_line(linewidth = 0.8, alpha = 0.9) +
  geom_point(size = 2.2, shape = 19, alpha = 0.6) +
  scale_x_continuous(
    breaks = seq(0, max(data1$Epochs), by = 25),
    limits = c(0, max(data1$Epochs)),
    expand = c(0.02, 0),
    labels = scales::number_format(accuracy = 1)
  ) +
  scale_y_continuous(
    breaks = seq(0, 1, by = 0.2),
    limits = c(0, 1),
    expand = c(0.05, 0),
    labels = scales::percent_format(accuracy = 1)
  ) +
  scale_color_manual(values = my_metric_colors) +
  labs(x = "Epochs", y = "Training metrics in TVDs") +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid        = element_blank(),
    panel.border      = element_rect(color = "#333333", fill = NA, linewidth = 0.4),
    axis.ticks        = element_line(color = "#333333", linewidth = 0.3),
    axis.ticks.length = unit(2.5, "mm"),
    axis.text         = element_text(size = 9, color = "#333333"),
    axis.title        = element_text(size = 11, color = "#111111"),
    legend.position   = c(0.88, 0.18),
    legend.justification = c(1, 0),
    legend.background = element_rect(fill = "white", color = "#CCCCCC", linewidth = 0.5),
    legend.text       = element_text(size = 8),
    legend.title      = element_blank(),
    legend.key.size   = unit(0.3, "cm"),
    legend.margin     = margin(3, 3, 3, 3),
    plot.margin       = margin(6, 6, 6, 6)
  )

p_metric

ggsave(
  "metric_T.pdf",
  plot   = p_metric,
  width  = 9,
  height = 9,
  units  = "cm",
  dpi    = 300,
  device = cairo_pdf
)