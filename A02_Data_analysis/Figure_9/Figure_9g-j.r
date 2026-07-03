# ============================================================================
# ACF and CCF analysis with Nature-style plots
# ACF: achromatic bars; CCF: warm amber bars
# Output: PDF (cairo)
# ============================================================================

library(readr)
library(ggplot2)
library(gridExtra)
library(grid)

# --- Data import ---
data <- read_csv("cotton_params.csv", show_col_types = FALSE)

lar  <- data$`2D_LAR`
var  <- data$`2D_VAR`
lsr  <- data$`2D_LSR`
vsr  <- data$`2D_VSR`

n <- length(lar)
conf <- 1.96 / sqrt(n)

# --- Linear detrending ---
detrend <- function(x) {
  t <- 1:length(x)
  fit <- lm(x ~ t)
  res <- residuals(fit)
  res - mean(res)
}

lar_dt  <- detrend(lar)
var_dt  <- detrend(var)
lsr_dt  <- detrend(lsr)
vsr_dt  <- detrend(vsr)

# --- Colors ---
ACF_COL_SIG <- "#1a1a1a"
ACF_COL_NS  <- "#E0E0E0"
CCF_COL_SIG <- "#B07D2B"
CCF_COL_NS  <- "#F0E2C5"
COL_CI     <- "#c0392b"
COL_AXIS   <- "#333333"
COL_TEXT   <- "#222222"

# --- ACF plot function ---
plot_acf <- function(x, var_name, max_lag = 40, conf_level = conf) {
  acf_result <- acf(x, lag.max = max_lag, plot = FALSE, na.action = na.pass)
  
  df_acf <- data.frame(
    lag = as.vector(acf_result$lag),
    acf = as.vector(acf_result$acf)
  )
  df_acf$sig <- ifelse(abs(df_acf$acf) > conf_level, 
                       "Significant", "Non-significant")
  
  ggplot(df_acf, aes(x = lag, y = acf, fill = sig)) +
    geom_bar(stat = "identity", width = 0.5, color = NA, alpha = 0.95) +
    scale_fill_manual(values = c(
      "Significant" = ACF_COL_SIG, 
      "Non-significant" = ACF_COL_NS
    )) +
    geom_hline(yintercept = c(conf_level, -conf_level), 
               linetype = "dashed", color = COL_CI, linewidth = 0.5) +
    geom_hline(yintercept = 0, color = COL_AXIS, linewidth = 0.3) +
    scale_x_continuous(breaks = seq(0, max_lag, by = 5), expand = c(0, 0)) +
    scale_y_continuous(
      limits = c(-0.7, 1.05), 
      breaks = seq(-0.6, 1.0, by = 0.2),
      labels = function(x) sprintf("%.1f", x)
    ) +
    labs(x = "Lag", y = paste("ACF:", var_name)) +
    theme_minimal(base_size = 10) +
    theme(
      panel.grid       = element_blank(),
      panel.border     = element_blank(),
      axis.line        = element_line(color = COL_AXIS, linewidth = 0.3),
      axis.title       = element_text(size = 11, color = COL_TEXT, face = "plain"),
      axis.text        = element_text(size = 9, color = COL_TEXT),
      axis.ticks       = element_line(color = COL_AXIS, linewidth = 0.3),
      axis.ticks.length = unit(2, "pt"),
      legend.position  = "none",
      plot.margin      = margin(8, 8, 8, 8)
    )
}

# --- CCF plot function ---
plot_ccf <- function(x, y, x_name, y_name, max_lag = 30, conf_level = conf) {
  ccf_result <- ccf(x, y, lag.max = max_lag, plot = FALSE, na.action = na.pass)
  
  df_ccf <- data.frame(
    lag = as.vector(ccf_result$lag),
    ccf = as.vector(ccf_result$acf)
  )
  df_ccf$sig <- ifelse(abs(df_ccf$ccf) > conf_level, 
                       "Significant", "Non-significant")
  
  label <- paste(x_name, "<->", y_name)
  
  ggplot(df_ccf, aes(x = lag, y = ccf, fill = sig)) +
    geom_bar(stat = "identity", width = 0.5, color = NA, alpha = 0.95) +
    scale_fill_manual(values = c(
      "Significant" = CCF_COL_SIG, 
      "Non-significant" = CCF_COL_NS
    )) +
    geom_hline(yintercept = c(conf_level, -conf_level), 
               linetype = "dashed", color = COL_CI, linewidth = 0.5) +
    geom_hline(yintercept = 0, color = COL_AXIS, linewidth = 0.3) +
    scale_x_continuous(breaks = seq(-max_lag, max_lag, by = 5), 
                       expand = c(0, 0)) +
    scale_y_continuous(
      limits = c(-0.7, 0.85), 
      breaks = seq(-0.6, 0.8, by = 0.2),
      labels = function(x) sprintf("%.1f", x)
    ) +
    labs(x = "Lag", y = paste("CCF:", label)) +
    theme_minimal(base_size = 10) +
    theme(
      panel.grid       = element_blank(),
      panel.border     = element_blank(),
      axis.line        = element_line(color = COL_AXIS, linewidth = 0.3),
      axis.title       = element_text(size = 11, color = COL_TEXT, face = "plain"),
      axis.text        = element_text(size = 9, color = COL_TEXT),
      axis.ticks       = element_line(color = COL_AXIS, linewidth = 0.3),
      axis.ticks.length = unit(2, "pt"),
      legend.position  = "none",
      plot.margin      = margin(8, 8, 8, 8)
    )
}

# --- Generate plots ---
p_lar_acf  <- plot_acf(lar_dt,  "2D-LAR")
p_var_acf  <- plot_acf(var_dt,  "2D-VAR")
p_lsr_acf  <- plot_acf(lsr_dt,  "2D-LSR")
p_vsr_acf  <- plot_acf(vsr_dt,  "2D-VSR")

p_lar_var_ccf <- plot_ccf(lar_dt, var_dt, "2D-LAR", "2D-VAR")
p_lsr_vsr_ccf <- plot_ccf(lsr_dt, vsr_dt, "2D-LSR", "2D-VSR")

# --- Shared legends ---
get_legend <- function(myggplot) {
  tmp <- ggplot_gtable(ggplot_build(myggplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  if (length(leg) > 0) {
    tmp$grobs[[leg]]
  } else {
    nullGrob()
  }
}

legend_acf_dummy <- ggplot(
  data.frame(sig = c("Significant", "Non-significant"), y = c(1, 1)),
  aes(x = sig, y = y, fill = sig)
) +
  geom_bar(stat = "identity", width = 0.5) +
  scale_fill_manual(
    name = NULL,
    values = c("Significant" = ACF_COL_SIG, "Non-significant" = ACF_COL_NS)
  ) +
  theme_void(base_size = 10) +
  theme(
    legend.position   = "bottom",
    legend.box        = "horizontal",
    legend.text       = element_text(size = 8, color = COL_TEXT),
    legend.key.size   = unit(0.4, "cm")
  )
legend_acf_grob <- get_legend(legend_acf_dummy)

legend_ccf_dummy <- ggplot(
  data.frame(sig = c("Significant", "Non-significant"), y = c(1, 1)),
  aes(x = sig, y = y, fill = sig)
) +
  geom_bar(stat = "identity", width = 0.5) +
  scale_fill_manual(
    name = NULL,
    values = c("Significant" = CCF_COL_SIG, "Non-significant" = CCF_COL_NS)
  ) +
  theme_void(base_size = 10) +
  theme(
    legend.position   = "bottom",
    legend.box        = "horizontal",
    legend.text       = element_text(size = 8, color = COL_TEXT),
    legend.key.size   = unit(0.4, "cm")
  )
legend_ccf_grob <- get_legend(legend_ccf_dummy)

# --- Assemble panels ---
acf_grob <- arrangeGrob(
  p_lar_acf, p_var_acf, p_lsr_acf, p_vsr_acf, legend_acf_grob,
  layout_matrix = rbind(c(1, 2), c(3, 4), c(5, 5)),
  heights = unit(c(1, 1, 0.12), c("null", "null", "null")),
  padding = unit(3, "mm")
)

ccf_grob <- arrangeGrob(
  p_lar_var_ccf, p_lsr_vsr_ccf, legend_ccf_grob,
  layout_matrix = rbind(c(1), c(2), c(3)),
  heights = unit(c(1, 1, 0.12), c("null", "null", "null")),
  padding = unit(3, "mm")
)

# --- Export ---
ggsave("Fig_ACF_Nature.pdf", plot = acf_grob, 
       width = 14, height = 14, units = "cm", dpi = 300, 
       device = cairo_pdf)

ggsave("Fig_CCF_Nature.pdf", plot = ccf_grob, 
       width = 8, height = 14, units = "cm", dpi = 300, 
       device = cairo_pdf)