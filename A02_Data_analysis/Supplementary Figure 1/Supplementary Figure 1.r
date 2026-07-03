# ============================================================================
# Bland‑Altman analysis: 2D‑VSR vs LIA
# Includes proportional bias regression (with 95% CI)
# Output: PDF
# ============================================================================

library(readxl)
library(ggplot2)
library(dplyr)

# --- Read data ---
df <- read_excel("parameters.xlsx", sheet = 1)

required_cols <- c("2D_VSR", "LIA")
if (!all(required_cols %in% names(df))) {
  stop("Sheet1 must contain columns '2D_VSR' and 'LIA'.")
}

method1 <- df$`2D_VSR`
method2 <- df$LIA
valid_idx <- complete.cases(method1, method2)
method1 <- method1[valid_idx]
method2 <- method2[valid_idx]

n <- length(method1)
cat("Effective sample size n =", n, "\n")

# --- Statistics ---
mean_vals <- (method1 + method2) / 2
diff_vals <- method1 - method2

bias      <- mean(diff_vals)
sd_diff   <- sd(diff_vals)
loa_lower <- bias - 1.96 * sd_diff
loa_upper <- bias + 1.96 * sd_diff

# Proportional bias regression (difference ~ mean)
fit_ba <- lm(diff_vals ~ mean_vals)
slope_ba <- coef(fit_ba)[2]
p_ba     <- summary(fit_ba)$coefficients[2, 4]
r2_ba    <- summary(fit_ba)$r.squared

cat(sprintf("Bias: %.4f, SD: %.4f\n", bias, sd_diff))
cat(sprintf("95%% LoA: [%.4f, %.4f]\n", loa_lower, loa_upper))
cat(sprintf("Proportional bias: Slope = %.4f, p = %.4f, R2 = %.4f\n",
            slope_ba, p_ba, r2_ba))

# --- Data frame for plotting ---
ba_data <- data.frame(Mean = mean_vals, Difference = diff_vals)

# --- Colors ---
color_point <- "#2563EB"
color_bias  <- "#DC2626"
color_loa   <- "#059669"
color_zero  <- "#BBBBBB"
color_reg   <- "#DD6E42"

# --- Plot ---
x_max <- max(mean_vals)
x_min <- min(mean_vals)
x_range <- x_max - x_min

p <- ggplot(ba_data, aes(x = Mean, y = Difference)) +
  geom_point(alpha = 0.55, size = 2.1, color = color_point, shape = 16) +
  geom_hline(yintercept = 0, linetype = "dotted", color = color_zero, linewidth = 0.14) +
  geom_hline(yintercept = bias, linetype = "solid", color = color_bias, linewidth = 0.32) +
  geom_hline(yintercept = loa_lower, linetype = "dashed", color = color_loa, linewidth = 0.32) +
  geom_hline(yintercept = loa_upper, linetype = "dashed", color = color_loa, linewidth = 0.32) +
  geom_smooth(method = "lm", se = TRUE, color = color_reg,
              linetype = "dotdash", linewidth = 0.32,
              fill = color_reg, alpha = 0.12) +
  
  annotate("text",
           x = x_max + 0.03 * x_range,
           y = bias,
           label = paste0("Bias = ", round(bias, 3)),
           hjust = 0, vjust = -0.7,
           size = 2.5, color = color_bias, fontface = "bold") +
  annotate("text",
           x = x_max + 0.03 * x_range,
           y = loa_upper,
           label = paste0("+1.96 SD = ", round(loa_upper, 3)),
           hjust = 0, vjust = -0.7,
           size = 2.5, color = color_loa) +
  annotate("text",
           x = x_max + 0.03 * x_range,
           y = loa_lower,
           label = paste0("-1.96 SD = ", round(loa_lower, 3)),
           hjust = 0, vjust = 1.5,
           size = 2.5, color = color_loa) +
  annotate("text",
           x = x_max + 0.03 * x_range,
           y = loa_lower - 0.08 * x_range,
           label = paste0("Slope = ", round(slope_ba, 3), 
                          ", p < 0.001, R2 = ", round(r2_ba, 3)),
           hjust = 0, vjust = 1.5,
           size = 2.5, color = color_reg, fontface = "bold") +
  
  labs(x = "Mean of 2D-VSR and LIA",
       y = "Difference (2D-VSR vs. LIA)") +
  
  expand_limits(x = x_max + 0.12 * x_range) +
  
  theme_bw(base_size = 10) +
  theme(
    panel.border = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "#333333", linewidth = 0.21),
    axis.title = element_text(size = 11, color = "black"),
    axis.text = element_text(size = 9, color = "black"),
    axis.ticks = element_line(color = "#333333", linewidth = 0.18),
    axis.ticks.length = unit(2, "mm"),
    plot.title = element_blank(),
    plot.margin = margin(8, 8, 8, 8)
  )

print(p)

# --- Save PDF ---
ggsave("Bland_Altman_CNS_final.pdf", plot = p, device = cairo_pdf,
       width = 7.5, height = 7, units = "cm", dpi = 300)
cat("PDF saved: Bland_Altman_CNS_final.pdf\n")