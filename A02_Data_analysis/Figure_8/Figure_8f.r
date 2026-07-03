# ============================================================================
# Scatter plot: 2D-LARV (×10⁴) vs 2D-VARV (×10⁴) with marginal histograms
# Output: PDF
# ============================================================================

library(ggplot2)
library(ggExtra)

load("data3.RData")

gg <- data3$X2D_LARV * 10^4
hh <- data3$X2D_VARV * 10^4

model <- lm(hh ~ gg)
summary_model <- summary(model)

intercept <- round(coef(model)[1], 3)
slope     <- round(coef(model)[2], 3)
r_squared <- round(summary_model$r.squared, 2)
f_stat    <- round(summary_model$fstatistic[1], 2)
p_value   <- pf(f_stat, summary_model$fstatistic[2], summary_model$fstatistic[3], lower.tail = FALSE)
if (p_value < 0.001) p_value <- "< 0.001" else p_value <- round(p_value, 3)

equation <- paste("y =", slope, "x +", intercept)

main_color <- "#2E6B5E"

plot_data <- data.frame(gg = gg, hh = hh)

p <- ggplot(plot_data, aes(x = gg, y = hh)) +
  geom_point(shape = 21, size = 2.0,
             fill = main_color,
             color = "#2C3E50",
             position = "jitter", alpha = 0.7) +
  stat_smooth(method = "lm", formula = y ~ x,
              size = 0.8, linetype = 1,
              color = "#1F4E79",
              fill = "#D0D0D0", alpha = 0.3) +
  geom_rug(color = "#666666", size = 0.3, alpha = 0.3,
           position = "jitter", show.legend = FALSE) +
  theme_classic(base_size = 10) +
  theme(
    axis.text  = element_text(size = 9, color = "#333333"),
    axis.title = element_text(size = 11, color = "#111111"),
    axis.line  = element_line(color = "#333333", linewidth = 0.4),
    axis.ticks = element_line(color = "#333333", linewidth = 0.3),
    axis.ticks.length = unit(2.5, "mm"),
    panel.grid = element_blank(),
    plot.margin = margin(6, 6, 6, 6)
  ) +
  labs(x = "2D-LARV (x 10-4)", y = "2D-VARV (x 10-4)") +
  annotate("text",
           x = min(gg) + 0.2 * diff(range(gg)),
           y = max(hh) - 0.08 * diff(range(hh)),
           label = paste(equation, "\nR² =", r_squared,
                         "\nF-statistic =", f_stat,
                         "\np-value =", p_value),
           hjust = 0, vjust = 1, size = 3.0, color = "#333333")

p <- ggMarginal(p,
                type = "histogram",
                xparams = list(fill = scales::alpha(main_color, 0.5), color = NA),
                yparams = list(fill = scales::alpha(main_color, 0.5), color = NA),
                size = 10)

ggsave("LARV_VARV.pdf", p,
       width = 8, height = 8, unit = "cm",
       dpi = 900, device = cairo_pdf)