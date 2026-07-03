import numpy as np
from matplotlib import pyplot as plt
import pandas as pd
from sklearn.metrics import r2_score
import seaborn as sns
import string
from openpyxl import load_workbook

def Optimal_PF_per_cluster(PF_list, PF_list_best):
    """ Visualizes the relationship between the best power factor (PF) per building and the best PF per cluster.
    
    Args:
        PF_list (list): List of tuples containing house numbers and their corresponding cluster-based PFs.
        PF_list_best (list): List of tuples containing house numbers and their corresponding building-optimal PFs.
    """
    pf_cluster = dict(PF_list)
    pf_building = dict(PF_list_best)
    common_houses = pf_cluster.keys() & pf_building.keys()
    if len(common_houses) != len(pf_cluster.keys()):
        print("Warning: Inconsistent number of houses between cluster and building lists.")

    x = [pf_building[h] for h in common_houses]
    y = [pf_cluster[h] for h in common_houses]
    
    plt.figure(figsize=(6, 6))
    plt.scatter(x, y, alpha=0.6)
    plt.xlabel("Best PF per building")
    plt.ylabel("Best PF per cluster")
    plt.title("Building-optimal PF vs Cluster-based PF")
    plt.grid(True)

    plt.show()

def Optimal_PF_per_cluster_buildings(PF_list, PF_list_best): 
    """ Visualizes the relationship between the best power factor (PF) per building and the best PF per cluster.

    Args:
        PF_list (list): List of tuples containing house numbers and their corresponding cluster-based PFs.
        PF_list_best (list): List of tuples containing house numbers and their corresponding building-optimal PFs.
    """
    pf_cluster = dict(PF_list)
    pf_building = dict(PF_list_best)

    houses = sorted(pf_building.keys() & pf_cluster.keys())

    y = [pf_building[h] for h in houses]
    colors = [pf_cluster[h] for h in houses]

    plt.figure(figsize=(12, 5))

    scatter = plt.scatter(
        houses,
        y,
        c=colors,
        cmap="viridis",
        alpha=0.8
    )

    plt.xlabel("House")
    plt.ylabel("Best PF (per building)")
    plt.title("Building-optimal PF per house, colored by cluster PF")

    plt.xticks(rotation=90)
    plt.grid(True, axis="y")

    cbar = plt.colorbar(scatter)
    cbar.set_label("Cluster-based PF")

    plt.tight_layout()
    plt.show()

def daily_stats_weekday_weekend(df):
    """
    Compute daily statistics for one building, separated into weekday and weekend.

    Args:
        df (pd.DataFrame): DataFrame containing the building's data with columns 'P', 'Q', 'PF', and 'S'.
    Returns:
        pd.DataFrame: DataFrame containing daily statistics for weekday and weekend.
    """

    d = df.copy()
    d = d[d["P"] != 0]

    d["date"] = d.index.date
    d["hour"] = d.index.hour
    d["is_weekend"] = d.index.dayofweek >= 5
    d["is_day"] = d["hour"].between(7, 21)

    results = {}

    for label, mask in {
        "weekday": ~d["is_weekend"],
        "weekend": d["is_weekend"]
    }.items():

        if mask.sum() == 0:
            continue

        sub = d[mask]

        daily = sub.groupby("date").agg(
            P_mean=("P", "mean"),
            P_max=("P", "max"),
            P_min=("P", "min"),
            Q_mean=("Q", "mean"),
            Q_max=("Q", "max"),
            Q_min=("Q", "min"),
            PF_mean=("PF", "mean"),
            PF_min=("PF", "min"),
            PF_IQR=("PF", lambda x: x.quantile(0.75) - x.quantile(0.25)),
            S_mean=("S", "mean"),
        )

        P_day = sub[sub["is_day"]].groupby("date")["P"].mean()
        P_night = sub[~sub["is_day"]].groupby("date")["P"].mean()
        daily["P_day_night_ratio"] = P_day / P_night

        results[label] = daily.mean()

    return pd.DataFrame(results).T

def daily_stats_per_cluster(data_clean, PF_list, homes):
    """ Compute daily statistics for each cluster, separated into weekday and weekend.
    
    Args:
        data_clean (dict): Dictionary of cleaned dataframes for each building.
        PF_list (list): List of tuples containing house numbers and their corresponding cluster-based PFs.
        homes (list): List of house numbers to include in the analysis.
    
    Returns:
        dict: Dictionary containing daily statistics for each cluster, separated into weekday and weekend.
    """
    house_to_cluster = dict(PF_list)
    clusters = sorted(set(house_to_cluster.values()))

    cluster_daily = {}

    for cluster in clusters:
        weekday_rows = []
        weekend_rows = []

        for _, df in data_clean.items():
            house_nr = int(df["Nr"].iloc[1])

            if house_nr not in homes:
                continue
            if house_to_cluster.get(house_nr) != cluster:
                continue

            daily = daily_stats_weekday_weekend(df)

            if "weekday" in daily.index:
                weekday_rows.append(daily.loc["weekday"])
            if "weekend" in daily.index:
                weekend_rows.append(daily.loc["weekend"])

        wd = pd.DataFrame(weekday_rows)
        we = pd.DataFrame(weekend_rows)

        cluster_daily[cluster] = {
            "weekday": {
                "Mean": wd.mean(),
                "Median": wd.median(),
                "IQR": wd.quantile(0.75) - wd.quantile(0.25),
                "Distributions": wd,
            },

            "weekend": {
                "Mean": we.mean(),
                "Median": we.median(),
                "IQR": we.quantile(0.75) - we.quantile(0.25),
                "Distributions": we,
            },
        }

    return cluster_daily

def compact_daily_cluster_table(cluster_daily):
    """" Create a compact table of daily statistics for each cluster, separated into weekday and weekend.

    Args:
        cluster_daily (dict): Dictionary containing daily statistics for each cluster, separated into weekday and weekend.
    
    Returns:
        pd.DataFrame: DataFrame containing compact daily statistics for each cluster, separated into weekday and weekend.
    """
    rows = []

    for cluster, data in cluster_daily.items():
        wd = data["weekday"]["Mean"]
        we = data["weekend"]["Mean"]

        row = {
            "Cluster": cluster,

            # Load
            "P_mean_wd": wd["P_mean"],
            "P_mean_we": we["P_mean"],
            "P_day_night_wd": wd["P_day_night_ratio"],

            # PF
            "PF_mean_wd": wd["PF_mean"],
            "PF_mean_we": we["PF_mean"],
            "PF_IQR_wd": wd["PF_IQR"],
            "PF_IQR_we": we["PF_IQR"],
            "PF_min_we": we["PF_min"],
        }

        rows.append(row)

    df = pd.DataFrame(rows).set_index("Cluster")
    return df

def size_distribution_per_cluster(data_clean, PF_list, homes):
    """ Compute the size distribution of buildings in each cluster.

    Args:
        data_clean (dict): Dictionary of cleaned dataframes for each building.
        PF_list (list): List of tuples containing house numbers and their corresponding cluster-based PFs.
        homes (list): List of house numbers to include in the analysis.
    
    Returns:
        pd.DataFrame: DataFrame containing the size distribution of buildings in each cluster.
    """
    house_to_cluster = dict(PF_list)
    clusters = sorted(set(house_to_cluster.values()))

    cluster_sizes = {}

    for cluster in clusters:
        houses_list = []
        total_size = []
        correlation_list = []
        for _, df in data_clean.items():
            house_nr = int(df["Nr"].iloc[1])
            if house_nr not in homes:
                continue
            if house_to_cluster.get(house_nr) != cluster:
                continue

            houses_list.append(house_nr)
            total_size.append(df["P"].sum()*0.25)

            d = df[df["P"] != 0]
            correlation_list.append(d["P"].corr(d["Q"]))

        cluster_sizes[cluster] = {
            "Count": len(houses_list),
            "Avg_size": np.mean(total_size) if total_size else 0,
            "Median_PQ_correlation": np.median(correlation_list) if correlation_list else 0
        }

    return pd.DataFrame(cluster_sizes)

def R2_metric_calc(dict_list, PF_serie_list):
    """ Calculate the R² metric for the estimated reactive power (Q).

    Args:
        dict_list (list): List of dictionaries containing dataframes for each building.
        PF_serie_list (list): List of lists containing tuples with house numbers and their corresponding cluster-based PFs.

    Returns:
        float: R² metric.
    """
    
    y_true = []
    y_pred = []
    for dict, PF_serie in zip(dict_list, PF_serie_list):
        for idx, power_data in dict.items():
            house = power_data['Nr'].iloc[0]
            for home, PF in PF_serie:
                if house == home:
                    PF_use = PF
            P_values = power_data['P'].values
            Q_values = power_data['Q'].values
            Q_est_inner = np.sqrt((P_values/PF_use)**2-(P_values)**2)
            y_true.extend(Q_values)
            y_pred.extend(Q_est_inner)
    

    r2 = r2_score(y_true, y_pred)
    return r2

def R2_metric_basecase(dict_list, PF_basecase):
    """ Calculate the R² metric for the estimated reactive power (Q) using a base case power factor.

    Args:
        dict_list (list): List of dictionaries containing dataframes for each building.
        PF_basecase (float): Base case power factor to use for estimation.

    Returns:
        float: R² metric for the base case estimation.
    """
    y_true = []
    y_pred = []
    for dict in dict_list:
        for idx, power_data in dict.items():
            P_values = power_data['P'].values
            Q_values = power_data['Q'].values
            Q_est_inner = np.sqrt((P_values/PF_basecase)**2-(P_values)**2)
            y_true.extend(Q_values)
            y_pred.extend(Q_est_inner)

    r2 = r2_score(y_true, y_pred)
    return r2

def error_timed_func(dict_input, PF_serie, homes):
    """ Calculate the absolute error over time for each building based on the estimated reactive power (Q) using cluster-based power factors.

    Args:
        dict_input (dict): Dictionary of dataframes for each building.
        PF_serie (list): List of tuples containing home and power factor.
        homes (list): List of building names.

    Returns:
        pd.DataFrame: DataFrame containing the absolute error over time for each building.
    """
    error_timed = pd.DataFrame(index = dict_input[list(dict_input.keys())[0]].index, columns = homes)
    for idx, power_data in dict_input.items():
        house = power_data['Nr'].iloc[0]
        for home, PF in PF_serie:
            if house == home:
                PF_use = PF
        P_values = power_data['P'].values
        Q_values = power_data['Q'].values
        Q_est_inner = np.sqrt((P_values/PF_use)**2-(P_values)**2)  #np.sign(P_values)
        err_base = np.abs(Q_values - Q_est_inner)
        error_timed[house] = err_base
    print(len(error_timed.columns))
    return error_timed

def Basecase_time(dataset, homes, PF_basecase):
    """ Calculate the absolute error over time for each building based on the estimated reactive power (Q) using a base case power factor.

    Args:
        dataset (dict): Dictionary of dataframes for each building.
        homes (list): List of building names.
        PF_basecase (float): Base case power factor to use for estimation.
    
    Returns:
        pd.DataFrame: DataFrame containing the absolute error over time for each building using the base case power factor.
    """
    Basecase_error = pd.DataFrame(index = dataset[list(dataset.keys())[0]].index, columns = homes)
    for idx, power_data in dataset.items():
        house = power_data['Nr'].iloc[0]
        P_values = power_data['P'].values
        Q_values = power_data['Q'].values
        Q_est_inner = np.sqrt((P_values/PF_basecase)**2-(P_values)**2)
        err_base = np.abs(Q_values - Q_est_inner)
        error_basecase_df = pd.DataFrame(err_base, index=power_data.index, columns=['Error'])
        Basecase_error[house] = error_basecase_df
    return Basecase_error

def error_over_time_viz(error_over_time, basecase_error, error_over_time_best, TUB):
    """ Visualizes the absolute error over time for each building, along with the base case error.

    Args:
        error_over_time (pd.DataFrame): DataFrame containing the absolute error over time for each building.
        basecase_error (pd.DataFrame): DataFrame containing the absolute error over time for each building using the base case power factor.
        error_over_time_best (pd.DataFrame): DataFrame containing the absolute error over time for each building using the best method.
        TUB (str): A string indicating whether the method is "TUB" or not, used for labeling the legend.
    """
    basecase_average = basecase_error.mean(axis=1)
    error_over_time_mean = error_over_time.mean(axis=1)
    plt.figure(figsize=(20,10))
    if TUB == "TUB":
        plt.plot(error_over_time_best.mean(axis=1), color = 'blue', alpha=0.5)
    else:
        plt.plot(error_over_time_mean, color = 'blue', alpha=0.5)
    plt.plot(basecase_average, label='Basecase', color='black', linewidth=1, alpha = 0.4)
    plt.xlabel('Time', fontsize = 20)
    plt.ylabel('Absolute RMSE error [kVAr]', fontsize = 20)
    if TUB == "TUB":
       plt.legend(['Ideal scenario (B)', 'Basecase'],loc='upper right', fontsize=20)
    else:
        plt.legend(['Optimal technique (H)', 'Basecase'],loc='upper right', fontsize=20)
    plt.title('Absolute Error averaged over all buildings [kVAr]', fontsize = 20)
    plt.xticks(fontsize=16)
    plt.yticks(fontsize=16)
    plt.grid()
    plt.show()

def distribution_error_plot(size_distribution, error_over_time, basecase_error, error_over_time_best, input_period, Clustering_method):
    """ Plots the distribution of errors.
    
    Args:
        size_distribution (list): List of DataFrames containing size distribution for each season.
        error_over_time (list): List of DataFrames containing error over time for each season.
        basecase_error (list): List of DataFrames containing basecase error for each season.
        error_over_time_best (list): List of DataFrames containing best error over time for each season.
        input_period (str): The input period, either "seasonal" or "yearly".
        Clustering_method (str): The clustering method used, e.g., "KMeans", "DBSCAN", etc.
    """

    colors = ["#000000", "#555250", "#ADADAD"] 
    line_styles = ['-', '--', ':'] 

    if input_period == "seasonal":
        error_over_time_summer = error_over_time[0]
        error_over_time_fall = error_over_time[1]
        error_over_time_winter = error_over_time[2]
        error_over_time_spring = error_over_time[3]
        Basecase_error_summer = basecase_error[0]
        Basecase_error_fall = basecase_error[1]
        Basecase_error_winter = basecase_error[2]
        Basecase_error_spring = basecase_error[3]
        error_over_time_summer_best = error_over_time_best[0]
        error_over_time_fall_best = error_over_time_best[1]
        error_over_time_winter_best = error_over_time_best[2]
        error_over_time_spring_best = error_over_time_best[3]
        size_distribution_Summer = size_distribution[0]
        size_distribution_Fall = size_distribution[1]
        size_distribution_Winter = size_distribution[2]
        size_distribution_Spring = size_distribution[3]
        seasonal_dfs = [error_over_time_winter, error_over_time_spring, error_over_time_summer, error_over_time_fall]
        seasonal_dfs_base = [Basecase_error_winter, Basecase_error_spring, Basecase_error_summer, Basecase_error_fall]
        seasonal_dfs_best = [error_over_time_winter_best, error_over_time_spring_best, error_over_time_summer_best, error_over_time_fall_best]
        season_labels = ['Winter', 'Spring', 'Summer', 'Fall']
        PF_lists =[size_distribution_Winter.columns.tolist(), size_distribution_Spring.columns.tolist(), size_distribution_Summer.columns.tolist(), size_distribution_Fall.columns.tolist()]
        PF_numbers = [size_distribution_Winter.loc['Count'].values.tolist(), size_distribution_Spring.loc['Count'].values.tolist(), size_distribution_Summer.loc['Count'].values.tolist(), size_distribution_Fall.loc['Count'].values.tolist()]

    
        fig, axes = plt.subplots(4, 2, figsize=(12, 10), gridspec_kw={'height_ratios': [0.3, 1, 0.3, 1]})
        axes = axes.flatten()           

        for i, (df, label) in enumerate(zip(seasonal_dfs, season_labels)):
            avg_series = df.mean(axis=1).dropna()
            avg_series_best = seasonal_dfs_best[i].mean(axis=1).dropna()
            avg_series_base = seasonal_dfs_base[i].mean(axis=1).dropna()
            PF_list_to_plot = PF_lists[i]
            PF_numbers_to_plot = PF_numbers[i]

            if i >= 2: i+=2
            axes[i].bar(PF_list_to_plot, PF_numbers_to_plot, color=colors[0], width=0.005, alpha=0.6)
            
            xmin = min(PF_list_to_plot) - 0.01
            xmax = max(PF_list_to_plot) + 0.01
            if xmin < 0.8:
                step_size = 0.02
            else:
                step_size = 0.01
            axes[i].set_xticks(np.arange(xmin, xmax + 0.001, step_size))
            axes[i].set_title(f'{input_period}: {label}', fontsize=20)
            axes[i].set_xlabel('Best-found PF with clustering', fontsize=18)
            axes[i].set_ylabel('Amount', fontsize=20)
            axes[i].tick_params(labelsize=14)

            sns.kdeplot(avg_series, ax=axes[i+2], fill=True, color=colors[0], alpha=0.6, linestyle=line_styles[0], label=f'{Clustering_method}')
            sns.kdeplot(avg_series_best, ax=axes[i+2], fill=True, color=colors[1], alpha=0.6, linestyle=line_styles[1], label='TUB')
            sns.kdeplot(avg_series_base, ax=axes[i+2], fill=True, color=colors[2], alpha=0.6, linestyle=line_styles[2], label='BC')

            axes[i+2].set_xlabel('Absolute error averaged over all buildings [kVAr]', fontsize=16)
            axes[i+2].set_ylabel('Probability density', fontsize=20)
            axes[i+2].tick_params(labelsize=12)
            axes[i+2].legend(fontsize=15)


        plt.tight_layout()
        plt.subplots_adjust(hspace=0.4)


        for i in range(4, 8): 
            pos = axes[i].get_position()
            axes[i].set_position([
                pos.x0,
                pos.y0 - 0.06, 
                pos.width,
                pos.height
            ])
    else:
        error_over_time = error_over_time[0]
        Basecase_error = basecase_error[0]
        error_over_time_best = error_over_time_best[0]
        size_distribution = size_distribution[0]
        PF_list = size_distribution.columns.tolist()
        PF_numbers = size_distribution.loc['Count'].values.tolist()

        fig, axes = plt.subplots(2, 1, figsize=(12, 10), gridspec_kw={'height_ratios': [0.3, 1]})
        axes = axes.flatten() 

        basecase_average = Basecase_error.mean(axis=1).dropna()
        error_over_time_mean = error_over_time.mean(axis=1).dropna()
        error_over_time_best_mean = error_over_time_best.mean(axis=1).dropna()

        axes[0].bar(PF_list, PF_numbers, color=colors[0], width=0.005, alpha=0.6)
        x_min = min(PF_list) - 0.01
        x_max = max(PF_list) + 0.01
        if x_min < 0.8:
            step_size = 0.02
        else:
            step_size = 0.01
        axes[0].set_xticks(np.arange(x_min, x_max + 0.001, step_size))
        axes[0].set_title(f'{input_period}', fontsize=20)
        axes[0].set_xlabel('Best-found PF with clustering', fontsize=16)
        axes[0].set_ylabel('Amount', fontsize=20)
        axes[0].tick_params(labelsize=12)

        sns.kdeplot(error_over_time_mean, ax=axes[1], fill=True, color=colors[0], alpha=0.6, linestyle=line_styles[0], label=f'{Clustering_method}')
        sns.kdeplot(error_over_time_best_mean, ax=axes[1], fill=True, color=colors[1], alpha=0.6, linestyle=line_styles[1], label='TUB')
        sns.kdeplot(basecase_average, ax=axes[1], fill=True, color=colors[2], alpha=0.6, linestyle=line_styles[2], label='BC')

        axes[1].set_xlabel('Absolute error averaged over all buildings [kVAr]', fontsize=16)
        axes[1].set_ylabel('Probability density', fontsize=20)
        axes[1].tick_params(labelsize=12)
        axes[1].legend(fontsize=15)

        plt.tight_layout()
        plt.subplots_adjust(hspace=0.4)


    plt.show()

def read_all_clustering_results(path_folder, dataset_chosen, Clustering_method, MAEVsRMSE):
    file_path = path_folder / f"Clustering_overview_{dataset_chosen}.xlsx"
    
    ws_results = f"{Clustering_method}_testing_results"

    if MAEVsRMSE == "MAE":
        rows_to_read = list(range(17, 26))
    else:
        rows_to_read = list(range(4, 13))

    def skip_func(x):
        return x not in rows_to_read

    df_results = pd.read_excel(file_path, sheet_name=ws_results, skiprows=skip_func, usecols="L:R", header=None)
    df_results.columns = list(['BC', 'TUB', 'PF_time', 'PQ_Pearson', 'PQSPF_Pearson', 'PQ_PCA', 'PQSPF-PCA'])
    return df_results

def comparison_clustering_approaches(df_results):
    plt.figure(figsize=(8, 6))  # Adjust size as needed
    df_melted = df_results.melt(var_name='Approach', value_name='RMSE')

    
    df_melted = df_results.melt(var_name='Approach', value_name='RMSE')


    plt.figure(figsize=(8, 6))
    sns.boxplot(data=df_melted, x='Approach', y='RMSE', color='steelblue', linewidth=1, fliersize=3)

    plt.axhspan(ymin=0.04582, ymax=0.06623, xmin=0, xmax=1, color='gray', alpha=0.3)

    plt.xlabel("", fontsize = 30)
    plt.ylabel("RMSE [kVAr]", fontsize = 30)
    plt.xticks(rotation=25, fontsize = 25, ha= 'right')
    plt.yticks(fontsize = 24)
    plt.tight_layout()
    plt.show()

def plot_input_scenarios(df_results):
    df_results_split = df_results.drop(columns=['BC', 'TUB'])
    rows = ['Full year', 'Single month', 'Seasonal']
    rows_to_plot = ['Full year', 'Single month', 'Seasonal']

    df_grouped = df_results_split.groupby(df_results_split.index // 3).mean()

    if len(rows) >= len(df_grouped):
        df_grouped.index = rows[:len(df_grouped)]

    df_melted = df_grouped.reset_index().melt(id_vars='index', var_name='Column', value_name='Mean Value')
    df_melted_filtered = df_melted[df_melted['index'].isin(rows_to_plot)]
    gray_palette = sns.color_palette("gray", n_colors=len(rows_to_plot))
    
    plt.figure(figsize=(8, 6))
    sns.lineplot(data=df_melted_filtered,x='Column', y='Mean Value', hue='index', style='index', dashes=True, palette=gray_palette, legend=True)

    sns.scatterplot(data=df_melted_filtered,x='Column',y='Mean Value',hue='index',style='index',s=400,palette=gray_palette,legend = False)
    plt.xlabel('Approaches', fontsize = 30)
    plt.ylabel('Error [kVAr]', fontsize = 30)
    legend = plt.legend(fontsize = 15, loc='upper right')
    legend.get_frame().set_alpha(0.5)
    plt.xticks(fontsize = 25, rotation=15, ha='right')
    plt.yticks(fontsize = 25)
    plt.show()



















































