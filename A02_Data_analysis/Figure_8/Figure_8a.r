# ============================================================================
# Scatter plot: LIA vs 2D-LAR with marginal histograms
# Output: PDF
# ============================================================================

library(ggplot2)
library(ggExtra)

load("dataJC.RData")

aa <- dataJC$LIA
bb <- dataJC$X2D_LAR

model <- lm(bb ~ aa)
summary_model <- summary(model)

intercept <- round(coef(model)[1], 3)
slope     <- round(coef(model)[2], 3)
r_squared <- round(summary_model$r.squared, 2)
f_stat    <- round(summary_model$fstatistic[1], 2)
p_value   <- pf(f_stat, summary_model$fstatistic[2], summary_model$fstatistic[3], lower.tail = FALSE)
if (p_value < 0.001) p_value <- "< 0.001" else p_value <- round(p_value, 3)

equation <- paste("y =", slope, "x +", intercept)

main_color <- "#2E6B5E"

p1 <- ggplot(dataJC, aes(x = aa, y = bb)) +
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
  labs(x = "LIA", y = "2D-LAR") +
  annotate("text",
           x = min(aa) + 0.2 * diff(range(aa)),
           y = max(bb) - 0.08 * diff(range(bb)),
           label = paste(equation, "\nR² =", r_squared,
                         "\nF-statistic =", f_stat,
                         "\np-value =", p_value),
           hjust = 0, vjust = 1, size = 3.0, color = "#333333")

p1 <- ggMarginal(p1,
                 type = "histogram",
                 xparams = list(fill = scales::alpha(main_color, 0.5), color = NA),
                 yparams = list(fill = scales::alpha(main_color, 0.5), color = NA),
                 size = 10)

ggsave("LIA_2DLAR.pdf", p1,
       width = 8, height = 8, unit = "cm",
       dpi = 900, device = cairo_pdf)