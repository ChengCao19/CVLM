# ============================================================================
# Validation loss curves for Box Loss, Class Loss, Distribution Focal Loss on SVDs
# Output: PDF (cairo)
# ============================================================================

library(ggplot2)
library(reshape2)

load("data4.RData")

# --- Data preparation ---
loss_df <- data4[, c("Epochs", "Box.Loss", "Class.Loss", "Distribution.Focal.Loss")]
colnames(loss_df) <- c("Epochs", "Box Loss", "Class Loss", "Distribution Focal Loss")
loss_long <- melt(loss_df, id.vars = "Epochs", variable.name = "Metric")

# --- Colors ---
my_loss_colors <- c(
  "Box Loss"                = "#93C8C0",
  "Class Loss"              = "#CA8BA8",
  "Distribution Focal Loss" = "#8583A9"
)

# --- Plot ---
p <- ggplot(loss_long, aes(x = Epochs, y = value, color = Metric)) +
  geom_line(linewidth = 0.8, alpha = 0.9) +
  geom_point(size = 2.2, shape = 19, alpha = 0.6) +
  scale_x_continuous(
    breaks = seq(0, max(data4$Epochs), by = 25),
    limits = c(0, max(data4$Epochs)),
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
  labs(x = "Epochs", y = "Validation loss in SVDs") +
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

p

ggsave(
  "loss_S_val.pdf",
  plot   = p,
  width  = 8,
  height = 8,
  units  = "cm",
  dpi    = 300,
  device = cairo_pdf
)