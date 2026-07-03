# ============================================================================
# Trend consistency analysis: LIA, 2D-VSR, and 2D-LSR
# Overlay of Z‑standardized time series with L‑shaped axes (linewidth 0.25)
# Output: PDF
# ============================================================================

library(readxl)
library(ggplot2)
library(dplyr)

# --- Read data ---
df <- read_excel("parameters.xlsx", sheet = 1)

lia  <- df$LIA
vsr  <- df$`2D_VSR`
lsr  <- df$`2D_LSR`
time <- df$Time
n    <- length(lia)

# --- Z-score standardization ---
lia_z <- scale(lia)[,1]
vsr_z <- scale(vsr)[,1]
lsr_z <- scale(lsr)[,1]

# --- Long-format data frame ---
ts_data <- data.frame(
  Time   = rep(time, 3),
  Value  = c(lia_z, vsr_z, lsr_z),
  Method = factor(rep(c("LIA", "2D-VSR", "2D-LSR"), each = n),
                  levels = c("LIA", "2D-VSR", "2D-LSR"))
)

# --- Correlation statistics ---
rho_lia_vsr <- cor(lia, vsr, method = "spearman")
rho_lia_lsr <- cor(lia, lsr, method = "spearman")
rho_vsr_lsr <- cor(vsr, lsr, method = "spearman")

cat("=== Trend Consistency Statistics ===\n")
cat(sprintf("Spearman LIA vs 2D-VSR:  %.4f\n", rho_lia_vsr))
cat(sprintf("Spearman LIA vs 2D-LSR:  %.4f\n", rho_lia_lsr))
cat(sprintf("Spearman 2D-VSR vs 2D-LSR: %.4f\n", rho_vsr_lsr))

# --- Plot ---
color_lia <- "#1A1A1A"   # near‑black
color_vsr <- "#2563EB"   # blue
color_lsr <- "#DC2626"   # red

p <- ggplot(ts_data, aes(x = Time, y = Value, color = Method)) +
  geom_line(linewidth = 0.9) +
  geom_hline(yintercept = 0, color = "#BBBBBB", linewidth = 0.3) +
  
  annotate(
    "text",
    x = max(time) - 0.02 * diff(range(time)),
    y = max(c(lia_z, vsr_z, lsr_z)) * 0.95,
    label = paste0("rho (LIA-2D-VSR) = ", round(rho_lia_vsr, 3), "\n",
                   "rho (LIA-2D-LSR) = ", round(rho_lia_lsr, 3), "\n",
                   "rho (2D-VSR-2D-LSR) = ", round(rho_vsr_lsr, 3)),
    hjust = 1, vjust = 1,
    size = 2.5, color = "#333333"
  ) +
  
  scale_color_manual(values = c("LIA" = color_lia, "2D-VSR" = color_vsr, "2D-LSR" = color_lsr)) +
  
  labs(
    x = "Time (sequential)",
    y = "Standardized value (Z-score)",
    color = NULL
  ) +
  
  theme_bw(base_size = 10) +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border     = element_blank(),
    
    axis.line        = element_line(color = "#333333", linewidth = 0.25),
    axis.line.x.top  = element_blank(),
    axis.line.y.right = element_blank(),
    
    axis.title       = element_text(size = 11, color = "black"),
    axis.text        = element_text(size = 9, color = "black"),
    axis.ticks       = element_line(color = "#333333", linewidth = 0.5),
    axis.ticks.length = unit(2, "mm"),
    axis.ticks.x.top  = element_blank(),
    axis.ticks.y.right = element_blank(),
    
    legend.position      = c(0.02, 0.98),
    legend.justification = c(0, 1),
    legend.background    = element_rect(fill = "white", color = "#CCCCCC", linewidth = 0.5),
    legend.text          = element_text(size = 8, color = "black"),
    legend.key           = element_rect(fill = "white", color = NA),
    legend.key.size      = unit(0.45, "cm"),
    legend.key.width     = unit(0.8, "cm"),
    legend.spacing.y     = unit(0.05, "cm"),
    legend.margin        = margin(3, 3, 3, 3),
    
    plot.title = element_blank(),
    plot.margin = margin(10, 8, 8, 8)
  )

print(p)

# --- Save PDF ---
ggsave(
  filename = "Trend_Consistency_CNS_v3.pdf",
  plot     = p,
  device   = cairo_pdf,
  width    = 9.5,
  height   = 7,
  units    = "cm",
  dpi      = 300
)

cat("PDF saved: Trend_Consistency_CNS_v3.pdf\n")