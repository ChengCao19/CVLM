# ============================================================================
# First‑order difference concordance: 2D‑VSR vs LIA
# Scatter plot of delta values with quadrant shading, regression line, and time color gradient
# Output: PDF
# ============================================================================

library(readxl)
library(ggplot2)
library(dplyr)
library(RColorBrewer)

# --- Read data ---
df <- read_excel("parameters.xlsx", sheet = 1)

if (!all(c("2D_VSR", "LIA", "Time") %in% names(df))) {
  stop("Sheet1 must contain columns '2D_VSR', 'LIA', and 'Time'.")
}

lia  <- df$LIA
vsr  <- df$`2D_VSR`
time <- df$Time

# --- First differences ---
delta_lia  <- diff(lia)
delta_vsr  <- diff(vsr)
delta_time <- time[-1]
n_delta    <- length(delta_lia)

# --- Statistics ---
pearson_r  <- cor(delta_lia, delta_vsr, method = "pearson")
spearman_r <- cor(delta_lia, delta_vsr, method = "spearman")

# Directional agreement (same sign, excluding zero)
sign_lia <- sign(delta_lia)
sign_vsr <- sign(delta_vsr)
agree_idx <- (sign_lia == sign_vsr) & (sign_lia != 0) & (sign_vsr != 0)
dir_agree <- sum(agree_idx) / n_delta * 100

# Regression
fit_reg <- lm(delta_vsr ~ delta_lia)
slope_d <- coef(fit_reg)[2]
int_d   <- coef(fit_reg)[1]
r2_d    <- summary(fit_reg)$r.squared

# --- Plot data ---
plot_df <- data.frame(
  delta_LIA  = delta_lia,
  delta_VSR  = delta_vsr,
  Time       = delta_time
)

# --- Colors ---
color_concord <- "#059669"
color_discord <- "#DC2626"
color_45      <- "#333333"
color_reg     <- "#0072B2"

# --- Plot ---
p <- ggplot() +
  # Quadrant background shading
  annotate("rect", xmin = 0, xmax = Inf, ymin = 0, ymax = Inf,
           fill = color_concord, alpha = 0.04) +
  annotate("rect", xmin = -Inf, xmax = 0, ymin = -Inf, ymax = 0,
           fill = color_concord, alpha = 0.04) +
  annotate("rect", xmin = -Inf, xmax = 0, ymin = 0, ymax = Inf,
           fill = color_discord, alpha = 0.04) +
  annotate("rect", xmin = 0, xmax = Inf, ymin = -Inf, ymax = 0,
           fill = color_discord, alpha = 0.04) +
  
  # Reference lines at zero
  geom_hline(yintercept = 0, color = "gray60", linewidth = 0.3) +
  geom_vline(xintercept = 0, color = "gray60", linewidth = 0.3) +
  
  # Identity line (y = x)
  geom_abline(intercept = 0, slope = 1,
              linetype = "dashed", color = color_45, linewidth = 0.5) +
  
  # Regression line with 95% CI
  geom_smooth(data = plot_df, aes(x = delta_LIA, y = delta_VSR),
              method = "lm", se = TRUE, color = color_reg,
              linewidth = 0.7, fill = color_reg, alpha = 0.12) +
  
  # Scatter points colored by time
  geom_point(data = plot_df, aes(x = delta_LIA, y = delta_VSR, color = Time),
             size = 2.5, shape = 21, fill = NA, stroke = 0.9, alpha = 0.85) +
  scale_color_gradientn(colors = rev(brewer.pal(11, "RdYlBu")), name = "Time") +
  
  # Statistical annotations (ordered: directional agreement, Pearson r, Spearman rho, R²)
  annotate("text", x = -Inf, y = Inf,
           label = "Directional~agreement == 70.1~'%'",
           parse = TRUE, size = 3.0, hjust = -0.02, vjust = 1.8) +
  annotate("text", x = -Inf, y = Inf,
           label = "Pearson*italic(r) == 0.612",
           parse = TRUE, size = 3.0, hjust = -0.02, vjust = 3.0) +
  annotate("text", x = -Inf, y = Inf,
           label = "Spearman*italic(rho) == 0.558",
           parse = TRUE, size = 3.0, hjust = -0.02, vjust = 4.2) +
  annotate("text", x = -Inf, y = Inf,
           label = "italic(R)^2 == 0.375",
           parse = TRUE, size = 3.0, hjust = -0.02, vjust = 5.4) +
  
  labs(
    x = expression(paste(Delta, " LIA  (", "LIA"[t], " - ", "LIA"[t-1], ")")),
    y = expression(paste(Delta, " 2D-VSR  (", "2D-VSR"[t], " - ", "2D-VSR"[t-1], ")"))
  ) +
  
  theme_bw(base_size = 10) +
  theme(
    panel.border = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "#333333", linewidth = 0.25),
    axis.title = element_text(size = 11, face = "plain", color = "black"),
    axis.text = element_text(size = 9, color = "black"),
    axis.ticks = element_line(color = "#333333", linewidth = 0.18),
    axis.ticks.length = unit(2, "mm"),
    plot.margin = margin(10, 10, 10, 10),
    legend.position = "right",
    legend.key.size = unit(0.35, "cm"),
    legend.title = element_text(size = 9, face = "bold"),
    legend.text = element_text(size = 8)
  )

print(p)

# --- Save PDF ---
ggsave("Delta_Concordance.pdf", plot = p, device = cairo_pdf,
       width = 8.5, height = 7.5, units = "cm", dpi = 300)
cat("PDF saved: Delta_Concordance.pdf\n")

# --- Print summary statistics ---
cat("\n=== Statistical summary ===\n")
cat(paste0("Directional agreement = ", round(dir_agree, 1), "%\n"))
cat(paste0("Pearson r = ", round(pearson_r, 4), "\n"))
cat(paste0("Spearman rho = ", round(spearman_r, 4), "\n"))
cat(paste0("R^2 = ", round(r2_d, 4), "\n"))
cat(paste0("Regression: delta_VSR = ", round(slope_d, 3), " * delta_LIA + ", round(int_d, 4), "\n"))