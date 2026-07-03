import numpy as np
import pandas as pd
from scipy.stats import iqr, skew, kurtosis
import seaborn as sns
import matplotlib.pyplot as plt
from kneed import KneeLocator
from sklearn.decomposition import PCA


def representative_month(dataset_P, dataset_Q, season_index, month_length2):
    """ Computes the average monthly profile for each dataset (P and Q) and identifies the representative month based on the minimum error.

    Args:
        dataset_P (pd.DataFrame): The dataset containing P values.
        dataset_Q (pd.DataFrame): The dataset containing Q values.
        season_index (list): A list of indices representing the seasons.
        month_length2 (int): The length of the month to be used for padding.
    
    Returns:
        represent_month_P (dict): A dictionary containing the representative month for dataset P.
        represent_month_Q (dict): A dictionary containing the representative month for dataset Q.
        represent_month_idx (dict): A dictionary containing the index of the representative month.
    """
    average_monthly_profile_P = {}
    average_monthly_profile_Q = {}
    monthly_data_P = {}
    monthly_data_Q = {}
    error_monthly_P = {}
    error_monthly_Q = {}
    represent_month_P = {}
    represent_month_Q = {}
    represent_month_idx = {}
    months_with_31_days = [1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    for i in range(len(dataset_P.columns)):
        monthly_data_P[i] = [month.reset_index(drop=True) for _, month in dataset_P[i].groupby(pd.Grouper(freq='ME')) if not month.empty]
        monthly_data_Q[i] = [month.reset_index(drop=True) for _, month in dataset_Q[i].groupby(pd.Grouper(freq='ME')) if not month.empty]
        padded_months_P = [month.reindex(range(month_length2), fill_value=np.nan) for month in monthly_data_P[i]]
        padded_months_Q = [month.reindex(range(month_length2), fill_value=np.nan) for month in monthly_data_Q[i]]
        monthly_array_P = np.array(padded_months_P)
        monthly_array_Q = np.array(padded_months_Q)
        average_monthly_profile_P[i] = np.nanmean(monthly_array_P, axis=0)
        average_monthly_profile_Q[i] = np.nanmean(monthly_array_Q, axis=0)
        error_month_P = pd.DataFrame(index=season_index, columns=['error'])
        error_month_Q = pd.DataFrame(index=season_index, columns=['error'])
        total_error = pd.DataFrame(index=season_index, columns=['error'])
        k = 0
        j = 0
        norm_average_profile_P = (average_monthly_profile_P[i] - np.mean(average_monthly_profile_P[i]))/np.std(average_monthly_profile_P[i])
        norm_average_profile_Q = (average_monthly_profile_Q[i] - np.mean(average_monthly_profile_Q[i]))/np.std(average_monthly_profile_Q[i])
        norm_monthly_data_P = [(month - np.mean(month))/np.std(month) for month in monthly_data_P[i]]
        norm_monthly_data_Q = [(month - np.mean(month))/np.std(month) for month in monthly_data_Q[i]]
        norm_padded_months_P = [month.reindex(range(month_length2), fill_value=np.nan) for month in norm_monthly_data_P]
        norm_padded_months_Q = [month.reindex(range(month_length2), fill_value=np.nan) for month in norm_monthly_data_Q]

        for month in norm_padded_months_P:
            idx = season_index[k]
            error = np.nanmean(np.abs(month - norm_average_profile_P))
            error_month_P.loc[idx, 'error'] = error
            k += 1
        error_monthly_P[i] = error_month_P
        for month in norm_padded_months_Q:
            idx = season_index[j]
            error = np.nanmean(np.abs(month - norm_average_profile_Q))
            error_month_Q.loc[idx, 'error'] = error
            j += 1
        error_monthly_Q[i] = error_month_Q

        for idx in error_month_P.index:
            total_error.loc[idx, 'error'] = error_month_P.loc[idx, 'error'] + error_month_Q.loc[idx, 'error']
        good_index = error_month_P.index.isin(months_with_31_days)
        error_month_P = error_month_P[good_index]
        error_month_Q = error_month_Q[good_index]
        total_Error = total_error[good_index]
        rep_month_idx = int(total_Error['error'].idxmin())
        represent_month_idx[i] = rep_month_idx
        representative_month_P = monthly_data_P[i][int(season_index.index(int(rep_month_idx)))]
        representative_month_Q = monthly_data_Q[i][int(season_index.index(int(rep_month_idx)))]
        represent_month_P[i] = np.array(representative_month_P.reindex(range(month_length2)).ffill().to_numpy()[:month_length2])
        represent_month_Q[i] = np.array(representative_month_Q.reindex(range(month_length2)).ffill().to_numpy()[:month_length2])
    
    return represent_month_P, represent_month_Q, represent_month_idx

def feature_extraction(data, data_summer_P, data_fall_P, data_winter_P, data_spring_P, data_summer_Q, data_fall_Q, data_winter_Q, data_spring_Q):
    """ Extracts statistical features from the seasonal datasets for both P and Q.

    Args:
        data (pd.DataFrame): The original dataset.
        data_summer_P (list): List of summer datasets for P.
        data_fall_P (list): List of fall datasets for P.
        data_winter_P (list): List of winter datasets for P.
        data_spring_P (list): List of spring datasets for P.
        data_summer_Q (list): List of summer datasets for Q.
        data_fall_Q (list): List of fall datasets for Q.
        data_winter_Q (list): List of winter datasets for Q.
        data_spring_Q (list): List of spring datasets for Q.

    Returns:
        feature_dfs (pd.DataFrame): A DataFrame containing the extracted features for each dataset.
    """
    
    feature_dfs = pd.DataFrame(columns = ['Summer_P_mean', 'Spring_P_mean', 'Fall_P_mean', 'Winter_P_mean', 'Summer_P_std', 'Spring_P_std', 'Fall_P_std', 'Winter_P_std', 
    'Summer_P_max', 'Spring_P_max', 'Fall_P_max', 'Winter_P_max', 'Summer_P_min', 'Spring_P_min', 'Fall_P_min', 'Winter_P_min', 'Summer_P_median', 'Spring_P_median', 'Fall_P_median', 
    'Winter_P_median', 'Summer_P_iqr', 'Spring_P_iqr', 'Fall_P_iqr', 'Winter_P_iqr', 'Summer_P_skew', 'Spring_P_skew', 'Fall_P_skew', 'Winter_P_skew', 'Summer_P_kurt', 'Spring_P_kurt', 
    'Fall_P_kurt', 'Winter_P_kurt', 'Summer_Q_mean', 'Spring_Q_mean', 'Fall_Q_mean', 'Winter_Q_mean', 'Summer_Q_std', 'Spring_Q_std', 'Fall_Q_std', 'Winter_Q_std', 'Summer_Q_max', 
    'Spring_Q_max', 'Fall_Q_max', 'Winter_Q_max', 'Summer_Q_min', 'Spring_Q_min', 'Fall_Q_min', 'Winter_Q_min', 'Summer_Q_median', 'Spring_Q_median', 'Fall_Q_median', 'Winter_Q_median', 
    'Summer_Q_iqr', 'Spring_Q_iqr', 'Fall_Q_iqr', 'Winter_Q_iqr', 'Summer_Q_skew', 'Spring_Q_skew', 'Fall_Q_skew', 'Winter_Q_skew', 'Summer_Q_kurt', 'Spring_Q_kurt', 'Fall_Q_kurt', 
    'Winter_Q_kurt'])
    for i in range(len(data)):
        feature_dfs.loc[i, 'Summer_P_mean'] = data_summer_P[i].mean(axis=0)
        feature_dfs.loc[i, 'Spring_P_mean'] = data_spring_P[i].mean(axis=0)
        feature_dfs.loc[i, 'Fall_P_mean'] = data_fall_P[i].mean(axis=0)
        feature_dfs.loc[i, 'Winter_P_mean'] = data_winter_P[i].mean(axis=0)
        feature_dfs.loc[i, 'Summer_P_std'] = data_summer_P[i].std(axis=0)
        feature_dfs.loc[i, 'Spring_P_std'] = data_spring_P[i].std(axis=0)
        feature_dfs.loc[i, 'Fall_P_std'] = data_fall_P[i].std(axis=0)
        feature_dfs.loc[i, 'Winter_P_std'] = data_winter_P[i].std(axis=0)
        feature_dfs.loc[i, 'Summer_P_max'] = data_summer_P[i].max(axis=0)
        feature_dfs.loc[i, 'Spring_P_max'] = data_spring_P[i].max(axis=0)
        feature_dfs.loc[i, 'Fall_P_max'] = data_fall_P[i].max(axis=0)
        feature_dfs.loc[i, 'Winter_P_max'] = data_winter_P[i].max(axis=0)
        feature_dfs.loc[i, 'Summer_P_min'] = data_summer_P[i].min(axis=0)
        feature_dfs.loc[i, 'Spring_P_min'] = data_spring_P[i].min(axis=0)
        feature_dfs.loc[i, 'Fall_P_min'] = data_fall_P[i].min(axis=0)
        feature_dfs.loc[i, 'Winter_P_min'] = data_winter_P[i].min(axis=0)
        feature_dfs.loc[i, 'Summer_P_median'] = np.median(data_summer_P[i], axis=0)
        feature_dfs.loc[i, 'Spring_P_median'] = np.median(data_spring_P[i], axis=0)
        feature_dfs.loc[i, 'Fall_P_median'] = np.median(data_fall_P[i], axis=0)
        feature_dfs.loc[i, 'Winter_P_median'] = np.median(data_winter_P[i], axis=0)
        feature_dfs.loc[i, 'Summer_P_iqr'] = iqr(data_summer_P[i])
        feature_dfs.loc[i, 'Spring_P_iqr'] = iqr(data_spring_P[i])
        feature_dfs.loc[i, 'Fall_P_iqr'] = iqr(data_fall_P[i])
        feature_dfs.loc[i, 'Winter_P_iqr'] = iqr(data_winter_P[i])
        feature_dfs.loc[i, 'Summer_P_skew'] = skew(data_summer_P[i])
        feature_dfs.loc[i, 'Spring_P_skew'] = skew(data_spring_P[i])
        feature_dfs.loc[i, 'Fall_P_skew'] = skew(data_fall_P[i])
        feature_dfs.loc[i, 'Winter_P_skew'] = skew(data_winter_P[i])
        feature_dfs.loc[i, 'Summer_P_kurt'] = kurtosis(data_summer_P[i])
        feature_dfs.loc[i, 'Spring_P_kurt'] = kurtosis(data_spring_P[i])
        feature_dfs.loc[i, 'Fall_P_kurt'] = kurtosis(data_fall_P[i])
        feature_dfs.loc[i, 'Winter_P_kurt'] = kurtosis(data_winter_P[i])
        feature_dfs.loc[i, 'Summer_Q_mean'] = data_summer_Q[i].mean(axis=0)
        feature_dfs.loc[i, 'Spring_Q_mean'] = data_spring_Q[i].mean(axis=0)
        feature_dfs.loc[i, 'Fall_Q_mean'] = data_fall_Q[i].mean(axis=0)
        feature_dfs.loc[i, 'Winter_Q_mean'] = data_winter_Q[i].mean(axis=0)
        feature_dfs.loc[i, 'Summer_Q_std'] = data_summer_Q[i].std(axis=0)
        feature_dfs.loc[i, 'Spring_Q_std'] = data_spring_Q[i].std(axis=0)
        feature_dfs.loc[i, 'Fall_Q_std'] = data_fall_Q[i].std(axis=0)
        feature_dfs.loc[i, 'Winter_Q_std'] = data_winter_Q[i].std(axis=0)
        feature_dfs.loc[i, 'Summer_Q_max'] = data_summer_Q[i].max(axis=0)
        feature_dfs.loc[i, 'Spring_Q_max'] = data_spring_Q[i].max(axis=0)
        feature_dfs.loc[i, 'Fall_Q_max'] = data_fall_Q[i].max(axis=0)
        feature_dfs.loc[i, 'Winter_Q_max'] = data_winter_Q[i].max(axis=0)
        feature_dfs.loc[i, 'Summer_Q_min'] = data_summer_Q[i].min(axis=0)
        feature_dfs.loc[i, 'Spring_Q_min'] = data_spring_Q[i].min(axis=0)
        feature_dfs.loc[i, 'Fall_Q_min'] = data_fall_Q[i].min(axis=0)
        feature_dfs.loc[i, 'Winter_Q_min'] = data_winter_Q[i].min(axis=0)
        feature_dfs.loc[i, 'Summer_Q_median'] = np.median(data_summer_Q[i], axis=0)
        feature_dfs.loc[i, 'Spring_Q_median'] = np.median(data_spring_Q[i], axis=0)
        feature_dfs.loc[i, 'Fall_Q_median'] = np.median(data_fall_Q[i], axis=0)
        feature_dfs.loc[i, 'Winter_Q_median'] = np.median(data_winter_Q[i], axis=0)
        feature_dfs.loc[i, 'Summer_Q_iqr'] = iqr(data_summer_Q[i])
        feature_dfs.loc[i, 'Spring_Q_iqr'] = iqr(data_spring_Q[i])
        feature_dfs.loc[i, 'Fall_Q_iqr'] = iqr(data_fall_Q[i])
        feature_dfs.loc[i, 'Winter_Q_iqr'] = iqr(data_winter_Q[i])
        feature_dfs.loc[i, 'Summer_Q_skew'] = skew(data_summer_Q[i])
        feature_dfs.loc[i, 'Spring_Q_skew'] = skew(data_spring_Q[i])
        feature_dfs.loc[i, 'Fall_Q_skew'] = skew(data_fall_Q[i])
        feature_dfs.loc[i, 'Winter_Q_skew'] = skew(data_winter_Q[i])
        feature_dfs.loc[i, 'Summer_Q_kurt'] = kurtosis(data_summer_Q[i])
        feature_dfs.loc[i, 'Spring_Q_kurt'] = kurtosis(data_spring_Q[i])
        feature_dfs.loc[i, 'Fall_Q_kurt'] = kurtosis(data_fall_Q[i])
        feature_dfs.loc[i, 'Winter_Q_kurt'] = kurtosis(data_winter_Q[i])
    return feature_dfs

def feature_extraction_seasonal(data, data_season_P, data_season_Q, season):
    """ Extracts statistical features from the seasonal datasets for both P and Q.

    Args:
        data (pd.DataFrame): The original dataset.
        data_season_P (list): List of seasonal datasets for P.
        data_season_Q (list): List of seasonal datasets for Q.
        season (str): The name of the season (e.g., 'Summer', 'Fall', 'Winter', 'Spring').

    Returns:
        feature_df_season (pd.DataFrame): A DataFrame containing the extracted features for the specified season.
    """

    feature_df_season = pd.DataFrame(columns = [f"{season}_P_mean", f"{season}_P_std", f"{season}_P_max", f"{season}_P_min",
                                            f"{season}_P_median", f"{season}_P_iqr", f"{season}_P_skew", f"{season}_P_kurt",
                                            f"{season}_Q_mean", f"{season}_Q_std", f"{season}_Q_max", f"{season}_Q_min",
                                            f"{season}_Q_median", f"{season}_Q_iqr", f"{season}_Q_skew", f"{season}_Q_kurt"])
    for i in range(len(data)):
        feature_df_season.loc[i, f"{season}_P_mean"] = data_season_P[i].mean(axis=0)
        feature_df_season.loc[i, f"{season}_P_std"] = data_season_P[i].std(axis=0)
        feature_df_season.loc[i, f"{season}_P_max"] = data_season_P[i].max(axis=0)
        feature_df_season.loc[i, f"{season}_P_min"] = data_season_P[i].min(axis=0)
        feature_df_season.loc[i, f"{season}_P_median"] = np.median(data_season_P[i], axis=0)
        feature_df_season.loc[i, f"{season}_P_iqr"] = iqr(data_season_P[i])
        feature_df_season.loc[i, f"{season}_P_skew"] = skew(data_season_P[i])
        feature_df_season.loc[i, f"{season}_P_kurt"] = kurtosis(data_season_P[i])
        feature_df_season.loc[i, f"{season}_Q_mean"] = data_season_Q[i].mean(axis=0)
        feature_df_season.loc[i, f"{season}_Q_std"] = data_season_Q[i].std(axis=0)
        feature_df_season.loc[i, f"{season}_Q_max"] = data_season_Q[i].max(axis=0)
        feature_df_season.loc[i, f"{season}_Q_min"] = data_season_Q[i].min(axis=0)
        feature_df_season.loc[i, f"{season}_Q_median"] = np.median(data_season_Q[i], axis=0)
        feature_df_season.loc[i, f"{season}_Q_iqr"] = iqr(data_season_Q[i])
        feature_df_season.loc[i, f"{season}_Q_skew"] = skew(data_season_Q[i])
        feature_df_season.loc[i, f"{season}_Q_kurt"] = kurtosis(data_season_Q[i])
    return feature_df_season

def correlation(features):
    """ Computes the correlation matrix of the features and identifies highly correlated features.

    Args:
        features (pd.DataFrame): The input features for correlation analysis.

    Returns:
        features_reduced (pd.DataFrame): The features with highly correlated features removed.
        high_corr_features (list): A list of highly correlated features that were removed.
    """

    correlation_matrix = features.corr()
    sns.heatmap(correlation_matrix, cmap = 'coolwarm')
    plt.show()

    upper = correlation_matrix.where(np.triu(np.ones(correlation_matrix.shape), k=1).astype(bool))
    high_corr_features = [column for column in upper.columns if any(upper[column] > 0.9)]
    print(len(high_corr_features), high_corr_features)
    features_reduced = features.drop(columns=high_corr_features)
    return features_reduced, high_corr_features

def normalization(features, dataset_chosen, features_reduced = None, features_train = None):
    """ Normalizes the features by dividing each feature by its maximum value.

    Args:
        features (pd.DataFrame): The original features.
        features_reduced (pd.DataFrame): The reduced features after removing highly correlated features.
        dataset_chosen (str): The name of the dataset being used.
        features_train (pd.DataFrame, optional): The training features for normalization. Defaults to None.

    Returns:
        feature_df (pd.DataFrame): The normalized original features.
        feature_df_reduced (pd.DataFrame): The normalized reduced features.
        feature_df_train (pd.DataFrame, optional): The normalized training features. Defaults to None.
    """
    if features_reduced is not None:
        max_values_reduced = features_reduced.max()
        max_values_reduced[max_values_reduced == 0] = 1 
        feature_df_reduced = features_reduced/max_values_reduced
    else:
        feature_df_reduced = None
    max_values = features.max()
    max_values[max_values == 0] = 1
    feature_df = features/max_values
    if features_train is not None:
        max_values_train = features_train.max()
        max_values_train[max_values_train == 0] = 1
        feature_df_train = features_train/max_values_train
    else:
        feature_df_train = None
    if dataset_chosen == "USA" and features_reduced is not None:
        feature_df_reduced = feature_df_reduced.astype(float)
    elif features_reduced is not None:
        feature_df_reduced = feature_df_reduced.apply(pd.to_numeric, errors='coerce')
    if features_reduced is not None:
        feature_df_reduced = np.array(feature_df_reduced)
    return feature_df, feature_df_reduced, feature_df_train

def PCA_components(features, input_style):
  """ Extracts the number of PCA components needed to explain 90% of the variance in the data.

    Args:
        features (numpy.ndarray): The input features for PCA analysis.
        input_style (str): The style of input data, either 'seasonal' or other.

    Returns:
        int: The number of PCA components needed to explain 90% of the variance.
  """
  pcs = PCA(svd_solver='full')
  pcs.fit(features)

  pcsSummary_df = pd.DataFrame({'Standard deviation': np.sqrt(pcs.explained_variance_),
                            'Proportion of variance': pcs.explained_variance_ratio_,
                              'Cumulative Ratio' : np.cumsum(pcs.explained_variance_ratio_) })

  cumulative_proportion = np.cumsum(pcs.explained_variance_ratio_)
  x = range(1, len(cumulative_proportion) + 1)
  kn = KneeLocator(x, cumulative_proportion, curve='concave', direction='increasing')

  pcsSummary_df = pcsSummary_df.transpose()
  if pcsSummary_df.iloc[2, kn.knee] > 0.90:
      round_feature = kn.knee
      if input_style == 'seasonal':
        if round_feature < 10:
            round_feature = 10
      else: 
        if round_feature < 10:
          round_feature = 10
  else:
    for i in range(len(pcsSummary_df.columns)):
          if pcsSummary_df.iloc[2,i] > 0.90:
              round_feature = i
              if input_style == 'seasonal':
                if round_feature < 10:
                    round_feature = 10
              else: 
                if round_feature < 10:
                  round_feature = 10
              break
  print(round_feature)
  return round_feature

def PCA_analysis(features, N_components, features_train):
    """ Performs PCA analysis on the input features and transforms them into the specified number of components.
    
    Args:
        features (pd.DataFrame): The input features for PCA analysis.
        N_components (int): The number of PCA components to retain.
        features_train (pd.DataFrame): The training features for PCA analysis.

    Returns:
        pd.DataFrame: The transformed features with the specified number of PCA components.
    """
    pca = PCA(n_components=N_components, svd_solver='full')
    pca.fit(features_train)
    pca_results = pca.transform(features)
    pca_results_df = pd.DataFrame(pca_results, columns=[f'PC{i}' for i in range(1, N_components+1)])
    pca_results_df = np.array(pca_results_df)
    return pca_results_df













































































