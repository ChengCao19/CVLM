# ============================================================================
# Training loss curves for Deeplabv3+, U-Net, PSPNet, HRNet on SVDs
# Output: PDF (cairo)
# ============================================================================

library(ggplot2)
library(reshape2)

load("S_tra.RData")

# --- Data preparation ---
loss_df <- S_tra[, c("Step", "Deeplabvplus", "Unet", "PSPNet", "HRNet")]
colnames(loss_df) <- c("Epochs", "Deeplabv3plus", "UNet", "PSPNet", "HRNet")
loss_long <- melt(
  loss_df,
  id.vars = "Epochs",
  variable.name = "Model",
  value.name = "Loss"
)

# --- Colors and labels ---
my_colors <- c(
  "Deeplabv3plus" = "#76BCA3",
  "UNet"          = "#CE6476",
  "PSPNet"        = "#7C6CAA",
  "HRNet"         = "#4DBBD5"
)

legend_labels <- c(
  "Deeplabv3plus" = "Deeplabv3+",
  "UNet"          = "U-Net",
  "PSPNet"        = "PSPNet",
  "HRNet"         = "HRNet"
)

# --- Plot ---
p <- ggplot(loss_long, aes(x = Epochs, y = Loss, color = Model)) +
  geom_line(linewidth = 0.8, alpha = 0.9) +
  geom_point(size = 2.2, shape = 19, alpha = 0.6) +
  scale_x_continuous(
    breaks = seq(0, max(S_tra$Step), by = 25),
    limits = c(0, max(S_tra$Step)),
    expand = c(0.02, 0),
    labels = scales::number_format(accuracy = 1)
  ) +
  scale_y_continuous(
    breaks = seq(0, ceiling(max(loss_long$Loss)), by = 0.2),
    limits = c(0, ceiling(max(loss_long$Loss))),
    expand = c(0.05, 0),
    labels = scales::number_format(accuracy = 0.1)
  ) +
  scale_color_manual(
    values = my_colors,
    labels = legend_labels
  ) +
  labs(x = "Epochs", y = "Training loss in SVDs") +
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
    legend.title      = element_text(size = 8, face = "bold"),
    legend.key.size   = unit(0.3, "cm"),
    legend.margin     = margin(3, 3, 3, 3),
    plot.margin       = margin(6, 6, 6, 6)
  )

p

ggsave(
  "S_tra.pdf",
  plot   = p,
  width  = 8,
  height = 8,
  units  = "cm",
  dpi    = 300,
  device = cairo_pdf
)