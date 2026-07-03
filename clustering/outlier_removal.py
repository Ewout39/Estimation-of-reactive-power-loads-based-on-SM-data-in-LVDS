import pandas as pd
import numpy as np
import copy
import matplotlib.pyplot as plt
import seaborn as sns

def outlier_removal(data_merged, data_merged_original, chosen_dataset):
    """Removes outliers from the active and reactive power time series simultaneously.

    Args:
        data_merged (dictionary): A dictionary containing the merged active and reactive power time series.
        data_merged_original (dictionary): A dictionary containing the original merged active and reactive power time series.
        chosen_dataset (str): The name of the dataset being processed.

    Returns:
        tuple: A tuple containing the updated active and reactive power time series, along with the bounds and outlier dictionaries.
    """
    window = 15*24*4
    if chosen_dataset == "Slovakia":
        low_quantile = 0.25
        high_quantile = 0.75
        alpha, beta, gamma = 1.8, 1, 1
        delta = 1.5
    elif chosen_dataset == "Germany":
        low_quantile = 0.1
        high_quantile = 0.95
        alpha, beta, gamma = 1, 1.5, 1
        delta = 1.5
    elif chosen_dataset == "USA":
        low_quantile = 0.25
        high_quantile = 0.85
        alpha, beta, gamma = 1, 1.5, 1
        delta = 1.5
    data1 = copy.deepcopy(data_merged)
    data1_original = copy.deepcopy(data_merged_original)
    upper_bound_active = {}
    lower_bound_active = {}
    upper_bound_reactive = {}
    lower_bound_reactive = {}
    outliers_P_dict = {}
    outliers_Q_dict = {}
    for i in data1.keys():
        len_error_high = 3
        len_error_low = 3
        active_df = data1[i]['P'].copy()
        reactive_df = data1[i]['Q'].copy()
        active_df_original = data1_original[i]['P']
        reactive_df_original = data1_original[i]['Q']

        rolling_q1_P = active_df_original.rolling(window=window, center=True, min_periods=4).quantile(low_quantile)
        rolling_q3_P = active_df_original.rolling(window=window, center=True, min_periods=4).quantile(high_quantile)
        rolling_q2_P = active_df_original.rolling(window=window, center=True, min_periods=4).median()
        iqr_P_upper = rolling_q3_P - rolling_q2_P
        iqr_P_lower = rolling_q2_P - rolling_q1_P
        lower_bound_P = rolling_q1_P - len_error_low*iqr_P_lower
        upper_bound_P = rolling_q3_P + len_error_high*iqr_P_upper

        rolling_q1_Q = reactive_df_original.rolling(window=window, center=True, min_periods=4).quantile(low_quantile)
        rolling_q3_Q = reactive_df_original.rolling(window=window, center=True, min_periods=4).quantile(high_quantile)
        rolling_q2_Q = reactive_df_original.rolling(window=window, center=True, min_periods=4).median()
        iqr_Q_upper = rolling_q3_Q - rolling_q2_Q
        iqr_Q_lower = rolling_q2_Q - rolling_q1_Q
        lower_bound_Q = rolling_q1_Q - len_error_low*iqr_Q_lower
        upper_bound_Q = rolling_q3_Q + len_error_high*iqr_Q_upper
        outliers_P = (active_df_original < lower_bound_P) | (active_df_original > upper_bound_P)
        outliers_Q = (reactive_df_original < lower_bound_Q) | (reactive_df_original > upper_bound_Q)
        outliers_P_dict[i] = outliers_P
        outliers_Q_dict[i] = outliers_Q 

        mean_P = active_df_original.resample('D').mean()
        max_P = active_df_original.resample('D').max()
        std_P = active_df_original.resample('D').std()
        
        mean_Q = reactive_df_original.resample('D').mean()
        max_Q = reactive_df_original.resample('D').max()
        std_Q = reactive_df_original.resample('D').std()
        
        resample_max_P = max_P.resample('MS').mean()
        resample_max_Q = max_Q.resample('MS').mean()
        resample_std_P = std_P.resample('MS').mean()
        resample_std_Q = std_Q.resample('MS').mean()
        monthly_max_P = resample_max_P.reindex(active_df.index, method='ffill')
        monthly_max_Q = resample_max_Q.reindex(reactive_df.index, method='ffill')
        daily_mean_P = mean_P.reindex(active_df.index, method='ffill')
        daily_mean_Q = mean_Q.reindex(reactive_df.index, method='ffill')
        daily_std_P = std_P.reindex(active_df.index, method='ffill')
        daily_std_Q = std_Q.reindex(reactive_df.index, method='ffill')
        monthly_std_P = resample_std_P.reindex(active_df.index, method='ffill')
        monthly_std_Q = resample_std_Q.reindex(reactive_df.index, method='ffill')
        omega_P = np.abs(active_df_original[outliers_P] - daily_mean_P[outliers_P]) / daily_mean_P[outliers_P]
        tau_P = np.abs(active_df_original[outliers_P] - monthly_max_P[outliers_P]) / monthly_max_P[outliers_P]
        sigma_P = np.abs(daily_std_P[outliers_P] - monthly_std_P[outliers_P]) / monthly_std_P[outliers_P]
        
        omega_Q = np.abs(reactive_df_original[outliers_Q] - daily_mean_Q[outliers_Q]) / daily_mean_Q[outliers_Q]
        tau_Q = np.abs(reactive_df_original[outliers_Q] - monthly_max_Q[outliers_Q]) / monthly_max_Q[outliers_Q]
        sigma_Q = np.abs(daily_std_Q[outliers_Q] - monthly_std_Q[outliers_Q]) / monthly_std_Q[outliers_Q]

        omega_P = (omega_P) / (omega_P.max())
        tau_P = (tau_P) / (tau_P.max())
        sigma_P = (sigma_P) / (sigma_P.max())
        
        omega_Q = (omega_Q) / (omega_Q.max())
        tau_Q = (tau_Q) / (tau_Q.max())
        sigma_Q = (sigma_Q) / (sigma_Q.max())

        D_P = (alpha * omega_P + beta * sigma_P + gamma * tau_P) / 3
        D_Q = (alpha * omega_Q + beta * sigma_Q + gamma * tau_Q) / 3
        threshold_P = D_P.mean() * delta
        threshold_Q = D_Q.mean() * delta
        act_P_out = D_P[D_P > threshold_P].index
        act_Q_out = D_Q[D_Q > threshold_Q].index

        upper_bound_reactive[i] = pd.DataFrame(upper_bound_Q, index=reactive_df.index)
        lower_bound_reactive[i] = pd.DataFrame(lower_bound_Q, index=reactive_df.index)
        upper_bound_active[i] = pd.DataFrame(upper_bound_P, index=active_df.index)
        lower_bound_active[i] = pd.DataFrame(lower_bound_P, index=active_df.index)
        active_df[act_P_out] = np.nan
        reactive_df[act_P_out] = np.nan
        active_df[act_Q_out] = np.nan
        reactive_df[act_Q_out] = np.nan
        active_df.ffill(inplace=True)
        reactive_df.ffill(inplace=True)
        active_df.bfill(inplace=True)
        reactive_df.bfill(inplace=True)

        data1[i]['P'] = active_df
        data1[i]['Q'] = reactive_df
    return data1, upper_bound_active, lower_bound_active, upper_bound_reactive, lower_bound_reactive, outliers_P_dict, outliers_Q_dict

def outlier_plots(data_merged, data_merged_original, lower_bound_active, upper_bound_active, lower_bound_reactive, upper_bound_reactive, house):
    """Generates plots to visualize the effect of the outlier removal".

    Args:
        data_merged (dictionary): dictionary containing merged active and reactive power data.
        data_merged_original (dictionary): dictionary containing original merged active and reactive power data.
        lower_bound_active (dictionary): dictionary containing lower bounds for active power.
        upper_bound_active (dictionary): dictionary containing upper bounds for active power.
        lower_bound_reactive (dictionary): dictionary containing lower bounds for reactive power.
        upper_bound_reactive (dictionary): dictionary containing upper bounds for reactive power.
        house (str): The house identifier for which to generate plots.
    """
    
    start_date = data_merged[house].index[0]
    end_date = data_merged[house].index[-1]
    fontsise = 15
    fontzise = 13 

    year_data1 = data_merged[house][start_date:end_date]
    year_data2 = data_merged_original[house][start_date:end_date]
    lower_P = lower_bound_active[house][start_date:end_date]
    upper_P = upper_bound_active[house][start_date:end_date]
    fig, ax = plt.subplots(2, 2, figsize=(20, 12))
    ax[0, 0].plot(year_data2.index, year_data2['P'], linestyle='-', color='b', alpha=0.5)
    ax[0, 0].plot(year_data1.index, year_data1['P'], linestyle='-', color='r', alpha=0.5)
    ax[0, 0].plot(year_data1.index, lower_P, color='black', linewidth=4)
    ax[0, 0].plot(year_data1.index, upper_P, color='black', linewidth=4)

    ax[0, 0].legend(['original', 'corrected'], loc='upper right', fontsize=fontzise)
    ax[0, 0].set_xlabel('Date', fontsize=fontsise)
    ax[0, 0].set_ylabel('Active Power (kW)', fontsize=fontsise)
    ax[0, 0].set_title('Active power over time of a Slovakian house', fontsize=fontsise)
    ax[0, 0].grid(True)

    for label in ax[0, 0].get_xticklabels():
        label.set_rotation(45)

    sns.kdeplot(year_data2['P'], color='b', alpha=0.5, ax=ax[0, 1])
    sns.kdeplot(year_data1['P'], color='r', alpha=0.5, ax=ax[0, 1])

    ax[0, 1].legend(['original', 'corrected'], fontsize=fontzise)
    ax[0, 1].set_xlabel('Active Power [kW]', fontsize=fontsise)
    ax[0, 1].set_ylabel('Density', fontsize=fontsise)
    ax[0, 1].set_title('Active Power Density for a Slovakian house', fontsize=fontsise)
    ax[0, 1].grid(True)

    year_data1 = data_merged[house][start_date:end_date]
    year_data2 = data_merged_original[house][start_date:end_date]
    lower_Q = lower_bound_reactive[house][start_date:end_date]
    upper_Q = upper_bound_reactive[house][start_date:end_date]
    ax[1, 0].plot(year_data2.index, year_data2['Q'], linestyle='-', color='b', alpha=0.5)
    ax[1, 0].plot(year_data1.index, year_data1['Q'], linestyle='-', color='r', alpha=0.5)
    ax[1, 0].plot(year_data1.index, lower_Q, color='black')
    ax[1, 0].plot(year_data1.index, upper_Q, color='black')

    ax[1, 0].legend(['original', 'corrected'], loc='upper right', fontsize=fontzise)
    ax[1, 0].set_xlabel('Date', fontsize=fontsise)
    ax[1, 0].set_ylabel('Reactive Power (kVAr)', fontsize=fontsise)
    ax[1, 0].set_title('Reactive power over time of a Slovakian house', fontsize=fontsise)
    ax[1, 0].grid(True)

    for label in ax[1, 0].get_xticklabels():
        label.set_rotation(45)

    sns.kdeplot(year_data2['Q'], color='b', alpha=0.5, ax=ax[1, 1])
    sns.kdeplot(year_data1['Q'], color='r', alpha=0.5, ax=ax[1, 1])

    ax[1, 1].legend(['original', 'corrected'], fontsize=fontzise)
    ax[1, 1].set_xlabel('Reactive Power [kVAr]', fontsize=fontsise)
    ax[1, 1].set_ylabel('Density', fontsize=fontsise)
    ax[1, 1].set_title(f'Reactive Power Density for a Slovakian house', fontsize=fontsise)
    ax[1, 1].grid(True)

    plt.subplots_adjust(hspace=0.4)
    plt.show()


    year_data1_P = data_merged[house][start_date:end_date]
    year_data1_Q = data_merged[house][start_date:end_date]
    year_data2_P = data_merged_original[house][start_date:end_date]
    year_data2_Q = data_merged_original[house][start_date:end_date]
    fig = plt.figure(figsize=(20,10))
    plt.scatter(year_data1_P['P'], year_data1_Q['Q'], color='r', alpha=0.3)
    plt.scatter(year_data2_P['P'], year_data2_Q['Q'], color='b', alpha=0.3)
    plt.xlabel('Active Power [kW]', fontsize=fontsise)
    plt.ylabel('Reactive Power [kVAr]', fontsize=fontsise)
    plt.title(f'Active Power vs Reactive Power for house {house}', fontsize=fontsise)
    plt.legend(['corrected', 'original'], fontsize=fontzise)
    plt.grid(True)
    plt.show()

