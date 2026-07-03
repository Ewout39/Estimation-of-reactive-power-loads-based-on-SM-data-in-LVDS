import numpy as np
import warnings
import pandas as pd

warnings.simplefilter("ignore", FutureWarning)


def representative_month(dataset, month_length2):
    """Calculates the average monthly profile and representative month for each household in the dataset.
    
    Args:
        dataset (dict): Dictionary containing power dataframes for each household.
        month_length2 (int): The length of each month's data.

    Returns:
        dict: A dictionary containing the representative month for each household.
        dict: A dictionary containing the index of the representative month for each household.
    """

    average_monthly_profile = {}
    monthly_data = {}
    error_monthly = {}
    represent_month = {}
    represent_month_idx = {}
    months_with_31_days = [1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    for i in range(1, len(dataset)+1):
        monthly_data[i] = [month['PF'].reset_index(drop=True) for _, month in dataset[i].groupby(pd.Grouper(freq='ME'))]
        padded_months = [month.reindex(range(month_length2), fill_value=np.nan) for month in monthly_data[i]]
        monthly_array = np.array(padded_months)
        average_monthly_profile[i] = np.nanmean(monthly_array, axis=0)
        error_month = pd.DataFrame(index=range(1,14), columns=['error'])
        k = 1
        for month in padded_months:
            error = np.nanmean(np.abs(month - average_monthly_profile[i]))
            error_month.loc[k, 'error'] = error
            k += 1
        error_monthly[i] = error_month
        good_index = error_month.index.isin(months_with_31_days)
        error_month = error_month[good_index]
        rep_month_idx = error_month.idxmin()
        represent_month_idx[i] = rep_month_idx
        representative_month = monthly_data[i][int(rep_month_idx)-1]
        represent_month[i] = np.array(representative_month.reindex(range(month_length2)).ffill().to_numpy()[:month_length2])
    
    return represent_month, represent_month_idx

def array_normalization(data_array, input):
    """Normalizes the input data array based on the specified input type.
    
    Args:
        data_array (np.ndarray): The input data array to normalize.
        input (int): The type of input data (0, 1, or 2).

    Returns:
        np.ndarray: The normalized data array.
    """

    power_factor_arr = []
    if input == 2:
        columns = data_array.columns
    else:
        columns = data_array
    for i in range(1, len(columns)+1):   #household
        if input == 0:
            power_factor_list = data_array[i]['PF']
        else:
            power_factor_list = data_array[i]
        power_factor_arr.append(power_factor_list)
    power_factor_arr = np.array(power_factor_arr)

    print(power_factor_arr.shape)
    return power_factor_arr
