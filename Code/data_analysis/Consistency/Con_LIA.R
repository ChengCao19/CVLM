rm(list = ls())


library(ggplot2)
library(RColorBrewer)
library(svglite)
library(epiR)

#----
# volume = read.table("clipboard",header = TRUE)
# save(volume, file = "volume.RData")
load("dataJC.RData")

# 提取数据
aa <- dataJC$LIA
bb <- dataJC$X2D_LIA

# 计算指标
residuals <- bb - aa
rmse <- sqrt(mean(residuals^2, na.rm = TRUE))
mae <- mean(abs(residuals), na.rm = TRUE)
bias <- mean(residuals, na.rm = TRUE)
ccc <- epi.ccc(aa, bb, ci = "z-transform")$rho.c[,1]

# 绘制实际值vs理论值的散点图，并添加一条y=x的45度线
p1 = ggplot(data = dataJC, aes(x = LIA, y = X2D_LIA))+
  geom_point(size = 7, shape = 21, fill = "#9B434B", alpha = 0.4) +                                                 
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black", size = 1.05)+
  geom_smooth(method = "lm", se = FALSE, color = "black") +
  labs(x = "Actual Value", y = "Theoretical Value", title = "")+
  theme_bw()+                                                                 # 使用简洁主题
  theme(panel.grid.major = element_blank(),                                   # 去除主要网格线
        panel.grid.minor = element_blank(),                                   # 去除次要网格线
        panel.background = element_blank(),
        axis.text.x = element_text(size = 14),
        axis.text.y = element_text(size = 14),
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14))+
  coord_fixed(ratio = 1, xlim = c(0, 1), ylim = c(0, 1))+
  annotate("text", x = 0.2, y = 1, label = bquote(RMSE == .(round(rmse, 3))), size = 6)+
  annotate("text", x = 0.2, y = 0.9, label = bquote(MAE == .(round(mae, 3))), size = 6)+
  annotate("text", x = 0.2, y = 0.8, label = bquote(Meanbias == .(round(bias, 3))), size = 6)+
  annotate("text", x = 0.2, y = 0.7, label = bquote(CCC == .(round(ccc, 3))), size = 6)+
  annotate("text", x = 0.5, y = 0, label = "(a)", size = 8)
p1
ggsave("LIA_JC.pdf", p1, width = 6, height = 6, units = "in", dpi = 900)


