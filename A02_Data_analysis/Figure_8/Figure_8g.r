# ============================================================================
# Concordance scatter plot: LIA vs 2D-VSR
# Includes identity line, regression line with CI, and statistics
# Output: PDF
# ============================================================================

library(readxl)
library(ggplot2)

# --- Read data ---
df <- read_excel("parameters.xlsx", sheet = 1)

if (!all(c("LIA", "2D_VSR") %in% names(df))) {
  stop("Sheet1 must contain columns 'LIA' and '2D_VSR'.")
}

aa <- df$LIA
bb <- df$`2D_VSR`
n <- length(aa)

# --- Statistics ---
residuals <- bb - aa
rmse <- sqrt(mean(residuals^2))
mae  <- mean(abs(residuals))
bias <- mean(residuals)

# Lin's Concordance Correlation Coefficient (CCC)
r  <- cor(aa, bb)
s1 <- sd(aa)
s2 <- sd(bb)
m1 <- mean(aa)
m2 <- mean(bb)
ccc <- (2 * r * s1 * s2) / (s1^2 + s2^2 + (m1 - m2)^2)

# Regression
fit_reg <- lm(bb ~ aa)
slope <- coef(fit_reg)[2]
int   <- coef(fit_reg)[1]
r2    <- summary(fit_reg)$r.squared

# --- Plot ---
p <- ggplot(df, aes(x = LIA, y = `2D_VSR`)) +
  geom_abline(intercept = 0, slope = 1,
              linetype = "dashed", color = "black", linewidth = 0.4) +
  geom_smooth(method = "lm", se = TRUE, color = "#0072B2",
              linewidth = 0.7, fill = "#0072B2", alpha = 0.12) +
  geom_point(size = 2.5, shape = 21, fill = "#C57189",
             color = "black", stroke = 0.3, alpha = 0.6) +
  annotate("text", x = 0.05, y = 0.98,
           label = paste0("italic(n) == ", n),
           parse = TRUE, size = 3.0, hjust = 0, vjust = 1) +
  annotate("text", x = 0.05, y = 0.91,
           label = paste0("RMSE == ", round(rmse, 3)),
           parse = TRUE, size = 3.0, hjust = 0, vjust = 1) +
  annotate("text", x = 0.05, y = 0.84,
           label = paste0("MAE == ", round(mae, 3)),
           parse = TRUE, size = 3.0, hjust = 0, vjust = 1) +
  annotate("text", x = 0.05, y = 0.77,
           label = paste0("Meanbias == ", round(bias, 3)),
           parse = TRUE, size = 3.0, hjust = 0, vjust = 1) +
  annotate("text", x = 0.05, y = 0.70,
           label = paste0("CCC == ", round(ccc, 3)),
           parse = TRUE, size = 3.0, hjust = 0, vjust = 1) +
  labs(x = "LIA", y = "2D-VSR") +
  coord_fixed(ratio = 1, xlim = c(0, 1), ylim = c(0, 1)) +
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
    plot.margin = margin(10, 10, 10, 10)
  )

print(p)

# --- Save PDF ---
ggsave("Figure_8g.pdf", plot = p, device = cairo_pdf,
       width = 8.5, height = 7.5, units = "cm", dpi = 300)
cat("PDF saved: Figure_8g.pdf\n")

cat("\n=== Statistical summary ===\n")
cat(paste0("n = ", n, "\n"))
cat(paste0("RMSE = ", round(rmse, 4), "\n"))
cat(paste0("MAE = ", round(mae, 4), "\n"))
cat(paste0("Bias = ", round(bias, 4), "\n"))
cat(paste0("CCC = ", round(ccc, 4), "\n"))
cat(paste0("R^2 = ", round(r2, 4), "\n"))
cat(paste0("Regression: y = ", round(slope, 4), " x + ", round(int, 4), "\n"))