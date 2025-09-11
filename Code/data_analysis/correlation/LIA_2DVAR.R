rm(list = ls())

library(ggplot2)
library(ggsci)
library(ggpubr)
library(ggExtra)
library(broom)
library(ggthemes)


# dataJC = read.table("clipboard",sep = "\t",header = TRUE)
# save(dataJC, file = "dataJC.RData", compress = "xz")
load("dataJC.RData")
#----
aa = dataJC$LIA
bb = dataJC$X2D_VAR
model <- lm(bb ~ aa)
summary_model = summary(model) 

# 截距与斜率
intercept = round(summary_model$coefficients[1,1], digits = 3)
slope = round(summary_model$coefficients[2,1], digits = 3)   

r_squared = round(summary_model$r.squared, digits = 2)
rmse = sqrt(mean(residuals(model)^2))  # RMSE
mae = mean(abs(residuals(model)))     # MAE
f_statistic = round(summary_model$fstatistic[1], digits = 2)
p_value_f = pf(summary_model$fstatistic[1], summary_model$fstatistic[2], summary_model$fstatistic[3], lower.tail = FALSE)

# 如果 p-value 太小，设置为 "< 0.001"
if (p_value_f < 0.001) {
  p_value_f = "< 0.001"
} else {
  p_value_f = round(p_value_f, digits = 3)
}

equation = paste("y = ", slope, "x +", intercept)

p1 = ggplot(dataJC, aes(x = aa, y = bb))+
  #expand_limits(x=c(-13.5,-0.5),y=c(-15,240))+
  geom_point(shape = 21, size = 3.8, fill = "#1C1C1C", position="jitter",alpha=0.8)+
  stat_smooth(method = "lm",formula = y ~ x, 
              size = 1.2, linetype = 1, alpha = 0.7, color = "#3E608D", fill = "#D9D9D9")+
  geom_rug(color = "black", size = 1, alpha = 0.4, position = "jitter",show.legend = FALSE)+
  scale_fill_npg()+
  #theme_base()+
  #theme_stata()+
  theme_bw()+                                                         # stat_cor(method = "pearson")+
  theme(axis.text.x=element_text(angle=0,size=15,vjust=1,hjust=0.5,color = "black"),
        axis.text.y=element_text(size=15,color = "black"),
        axis.title.y=element_text(size=18.4),
        axis.title.x=element_text(size=18.4),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank())+
  labs(x = "LIA", y = "2D-VAR")+
  annotate("text", 
           x = min(aa) + 0.2, y = max(bb), 
           label = paste(equation, "\nR² = ", r_squared, 
                         "\nF-statistic = ", f_statistic, 
                         "\np-value = ", p_value_f), 
           hjust = 0, vjust = 1, size = 6)
  # scale_x_continuous(
  #   limits = c(0, 1),              # 强制限定坐标轴范围
  #   # expand = c(0, 0),                   # 取消轴两端的扩展空间
  #   breaks = seq(0, 1, by = 0.25),
  #   # labels = sprintf("%.1f", seq(-13, 0, by = 2))  # 格式化刻度标签（保留1位小数）
  # ) +
  # scale_y_continuous(
  #   limits = c(0.68, 1.12),
  #   breaks = seq(0.7, 1.1, by = 0.1),
  #   # labels = scales::number_format()      # 用scales包格式化数值标签
  # )

p1

p1 = ggMarginal(p1,type="density",xparams = list(fill = scales::alpha("#1C1C1C", alpha = 0.5)),size = 12,
                yparams = list(fill = scales::alpha("#1C1C1C", alpha = 0.5)))
p1
ggsave("LIA_2DVAR.pdf", p1, width = 6, height = 6, unit = "in", dpi = 900)

