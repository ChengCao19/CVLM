import pandas as pd


def export_to_excel(tvd_results, svd_results, save_path):
    with pd.ExcelWriter(save_path, engine="openpyxl") as writer:
        if tvd_results:
            df_tvd = pd.DataFrame(tvd_results)
            df_tvd.to_excel(writer, sheet_name="TVDs", index=False)
        if svd_results:
            df_svd = pd.DataFrame(svd_results)
            df_svd.to_excel(writer, sheet_name="SVDs", index=False)
