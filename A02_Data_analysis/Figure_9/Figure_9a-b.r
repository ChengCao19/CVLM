# ============================================================================
# PPFD and Pn diurnal time series
# Nature-style with ribbon for SD, thin lines, small points
# Output: PDF (cairo)
# ============================================================================

library(ggplot2)
library(tidyverse)
library(patchwork)

load("dataPP.RData")

# --- Data preparation ---
data_long <- dataPP %>%
  mutate(Time = factor(Time, levels = unique(Time))) %>%
  pivot_longer(
    cols = -Time,
    names_to = c("Variable", "Replicate"),
    names_pattern = "(PPFD|Pn)(\\d)",
    values_to = "Value"
  ) %>%
  mutate(
    Variable = factor(Variable, 
                      levels = c("PPFD", "Pn"),
                      labels = c("PPFD", "Pn")),
    Replicate = as.factor(Replicate)
  )

summary_data <- data_long %>%
  group_by(Time, Variable) %>%
  summarise(
    Mean = mean(Value, na.rm = TRUE),
    SD = sd(Value, na.rm = TRUE),
    .groups = "drop"
  )

# --- Colors ---
ppfd_color <- "#2E7D6B"
pn_color   <- "#8B4557"

# --- Theme ---
theme_cns <- theme_classic(base_size = 10) +
  theme(
    axis.text  = element_text(size = 8, color = "#333333"),
    axis.title = element_text(size = 11, color = "black"),
    axis.line  = element_line(color = "#333333", linewidth = 0.3),
    axis.ticks = element_line(color = "#333333", linewidth = 0.25),
    axis.ticks.length = unit(2, "mm"),
    panel.grid = element_blank(),
    plot.margin = margin(10, 12, 8, 10)
  )

# --- PPFD plot ---
plot_ppfd <- summary_data %>%
  filter(str_detect(Variable, "PPFD")) %>%
  ggplot(aes(x = Time, y = Mean, group = 1)) +
  geom_ribbon(aes(ymin = Mean - SD, ymax = Mean + SD), 
              fill = ppfd_color, alpha = 0.08, colour = NA) +
  geom_line(linewidth = 0.5, colour = ppfd_color, lineend = "round") +
  geom_point(size = 1.8, shape = 21, fill = "white", 
             colour = ppfd_color, stroke = 0.5) +
  labs(x = NULL,
       y = expression("PPFD ("*mu*"mol"~m^{-2}~s^{-1}*")")) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.12)), limits = c(0, NA)) +
  theme_cns +
  theme(axis.text.x = element_blank(),
        axis.ticks.x = element_blank())

# --- Pn plot ---
plot_pn <- summary_data %>%
  filter(str_detect(Variable, "Pn")) %>%
  ggplot(aes(x = Time, y = Mean, group = 1)) +
  geom_ribbon(aes(ymin = Mean - SD, ymax = Mean + SD), 
              fill = pn_color, alpha = 0.08, colour = NA) +
  geom_line(linewidth = 0.5, colour = pn_color, lineend = "round") +
  geom_point(size = 1.8, shape = 21, fill = "white", 
             colour = pn_color, stroke = 0.5) +
  labs(x = "Time", 
       y = expression(P[n]~"("*mu*"mol"~CO[2]~m^{-2}~s^{-1}*")")) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.12)), limits = c(0, NA)) +
  theme_cns

# --- Combine and export ---
combined <- plot_ppfd / plot_pn +
  plot_layout(heights = c(1, 1)) +
  plot_annotation(tag_levels = 'a') &
  theme(plot.tag = element_text(size = 14, face = "plain", colour = "black",
                                margin = margin(b = 8)),
        plot.margin = margin(5, 5, 5, 5))

print(combined)

ggsave("Figure_9a-b.pdf", combined, 
       width = 8.5, height = 10, unit = "cm", dpi = 900, device = cairo_pdf)