#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ACF and CCF analysis for cotton leaf movement data.
Uses biased estimator (divides by n) to match R's acf()/ccf() default.
Outputs CSV files for subsequent R visualization.
"""

import pandas as pd
import numpy as np
from scipy.stats import pearsonr

# --- Data import ---
df = pd.read_excel('parameters.xlsx', header=0)

lar = df['2D_LAR'].values.astype(np.float64)
var = df['2D_VAR'].values.astype(np.float64)
lsr = df['2D_LSR'].values.astype(np.float64)
vsr = df['2D_VSR'].values.astype(np.float64)

n = len(lar)
conf = 1.96 / np.sqrt(n)

print(f"Dataset: n = {n}, 95% CI = ±{conf:.4f}")

# --- Linear detrending ---
def detrend_linear(x):
    t = np.arange(len(x), dtype=np.float64)
    slope, intercept = np.polyfit(t, x, 1)
    return x - (slope * t + intercept)

lar_dt = detrend_linear(lar)
var_dt = detrend_linear(var)
lsr_dt = detrend_linear(lsr)
vsr_dt = detrend_linear(vsr)

# --- ACF (biased estimator) ---
def compute_acf(x, max_lag=40):
    x = x - np.mean(x)
    n = len(x)
    c0 = np.sum(x * x) / n
    acf_vals = [1.0]
    for k in range(1, max_lag + 1):
        c = np.sum(x[:-k] * x[k:]) / n
        acf_vals.append(c / c0)
    return np.array(acf_vals)

acf_lar = compute_acf(lar_dt, 40)
acf_var = compute_acf(var_dt, 40)
acf_lsr = compute_acf(lsr_dt, 40)
acf_vsr = compute_acf(vsr_dt, 40)

# --- CCF (biased estimator) ---
def compute_ccf(x, y, max_lag=30):
    x = x - np.mean(x)
    y = y - np.mean(y)
    n = len(x)
    c0_x = np.sum(x * x) / n
    c0_y = np.sum(y * y) / n
    ccf_vals = []
    lags = []
    for k in range(-max_lag, max_lag + 1):
        if k < 0:
            c = np.sum(x[:k] * y[-k:]) / n
        elif k == 0:
            c = np.sum(x * y) / n
        else:
            c = np.sum(x[k:] * y[:-k]) / n
        ccf_vals.append(c / np.sqrt(c0_x * c0_y))
        lags.append(k)
    return np.array(lags), np.array(ccf_vals)

lags_ccf, ccf_lar_var = compute_ccf(lar_dt, var_dt, 30)
_, ccf_lsr_vsr = compute_ccf(lsr_dt, vsr_dt, 30)

# --- Verification (lag-0 CCF = Pearson r) ---
r_lar_var, _ = pearsonr(lar_dt, var_dt)
r_lsr_vsr, _ = pearsonr(lsr_dt, vsr_dt)
lag0_idx = np.where(lags_ccf == 0)[0][0]
assert abs(ccf_lar_var[lag0_idx] - r_lar_var) < 1e-10
assert abs(ccf_lsr_vsr[lag0_idx] - r_lsr_vsr) < 1e-10
print("\n✓ All computations verified.")

# --- Save results for R ---
df_out = pd.DataFrame({
    'Time': df['Time'].values,
    '2D_LAR': lar, '2D_VAR': var, '2D_LSR': lsr, '2D_VSR': vsr
})
df_out.to_csv('cotton_params.csv', index=False)

acf_df = pd.DataFrame({
    'lag': np.arange(41),
    'lag_time_h': np.round(np.arange(41) * 25 / 60, 4),
    'ACF_LAR': np.round(acf_lar, 6),
    'ACF_VAR': np.round(acf_var, 6),
    'ACF_LSR': np.round(acf_lsr, 6),
    'ACF_VSR': np.round(acf_vsr, 6),
})
acf_df.to_csv('ACF_results.csv', index=False)

ccf_df = pd.DataFrame({
    'lag': lags_ccf,
    'lag_time_h': np.round(lags_ccf * 25 / 60, 4),
    'CCF_LAR_VAR': np.round(ccf_lar_var, 6),
    'CCF_LSR_VSR': np.round(ccf_lsr_vsr, 6),
})
ccf_df.to_csv('CCF_results.csv', index=False)

print("\n✓ Results saved: cotton_params.csv, ACF_results.csv, CCF_results.csv")

# --- Summary metrics ---
print("\n=== ACF Key Metrics ===")
for name, acf in [('2D-LAR', acf_lar), ('2D-VAR', acf_var),
                   ('2D-LSR', acf_lsr), ('2D-VSR', acf_vsr)]:
    lag1 = acf[1]
    max_idx = np.argmax(np.abs(acf[1:])) + 1
    sig_count = np.sum(np.abs(acf[1:]) > conf)
    print(f"{name}: lag1={lag1:.4f}, max|ACF|={np.abs(acf[max_idx]):.4f}@lag{max_idx}, sig_lags={sig_count}")

print("\n=== CCF Key Metrics ===")
for name, ccf in [('LAR↔VAR', ccf_lar_var), ('LSR↔VSR', ccf_lsr_vsr)]:
    lag0 = ccf[lag0_idx]
    max_idx = np.argmax(np.abs(ccf))
    max_lag = lags_ccf[max_idx]
    sig_count = np.sum(np.abs(ccf) > conf)
    print(f"{name}: lag0={lag0:.4f}, max|CCF|={np.abs(ccf[max_idx]):.4f}@lag{max_lag:+d}, sig_lags={sig_count}")