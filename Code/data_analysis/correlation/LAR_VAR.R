rm(list = ls())

library(ggplot2)
#library(ggsci)
library(ggpubr)
library(ggExtra)
library(broom)
library(ggthemes)

# data3 = read.table("clipboard",sep = "\t",header = TRUE)
load("data3.RData")
#----
cc = data3$X2D_LAR
dd = data3$X2D_VAR
#model = lm(X2D_VAR ~ poly(X2D_LAR, 3), data = data3)
model <- lm(dd ~ cc)
summary_model = summary(model)                                                # 线性

# # 提取系数
# coefficients <- coef(model)
# intercept <- coefficients[1]   # 截距
# slope_1 <- coefficients[2]     # 一次项的系数
# slope_2 <- coefficients[3]     # 二次项的系数
# slope_3 <- coefficients[4]     # 三次项的系数

# 提取 R-squared 值
r_squared = round(summary_model$r.squared, digits = 2)
f_statistic = round(summary_model$fstatistic[1], digits = 2)
p_value_f = pf(summary_model$fstatistic[1], summary_model$fstatistic[2], summary_model$fstatistic[3], lower.tail = FALSE)

# 如果 p-value 太小，设置为 "< 0.001"
if (p_value_f < 0.001) {
  p_value_f = "< 0.001"
} else {
  p_value_f = round(p_value_f, digits = 3)
}
# # 构建回归方程
# equation = paste("y = ", round(slope_1, 2), "x-", abs(round(slope_2, 2)), 
#                  "x2-", abs(round(slope_3, 2)), "x3+", round(intercept, 2))
# 截距与斜率
intercept = round(summary_model$coefficients[1,1], digits = 3)
slope = round(summary_model$coefficients[2,1], digits = 3)
# 构建公式字符串
equation = paste("y = ", slope, "x + ", intercept)

Scatter = ggplot(data3, aes(x = cc, y = dd))+
  #expand_limits(x=c(-13.5,-0.5),y=c(-15,240))+
  geom_point(shape = 21, size = 3.8, fill = "#314973", position="jitter",alpha=0.8)+
  stat_smooth(method = "lm",formula = y ~ x, 
              size = 1.2, linetype = 1, alpha = 0.7, color = "#3E608D", fill = "#96ABD2")+
  geom_rug(color = "black", size = 1, alpha = 0.4, position = "jitter",show.legend = FALSE)+
  #scale_fill_npg()+
  #theme_base()+
  #theme_stata()+
  theme_bw()+                                                         # stat_cor(method = "pearson")+
  theme(axis.text.x=element_text(angle=0,size=15,vjust=1,hjust=0.5,color = "black"),
        axis.text.y=element_text(size=15,color = "black"),
        axis.title.y=element_text(size=18.4),
        axis.title.x=element_text(size=18.4),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank())+
  labs(x = "2D-LAR", y = "2D-VAR")+
  annotate("text", x = min(cc), y = max(dd), 
           label = paste(equation, "\nR² = ", r_squared, 
                         "\nF-statistic = ", f_statistic, 
                         "\np-value = ", p_value_f), 
           hjust = 0, vjust = 1, size = 6)

Scatter

p = ggMarginal(Scatter,type="density",xparams = list(fill = scales::alpha("#314973", alpha = 0.5)),size = 12,
               yparams = list(fill = scales::alpha("#314973", alpha = 0.5)))
p
ggsave("LAR_VAR.pdf", p, width = 6, height = 6, unit = "in", dpi = 900)

