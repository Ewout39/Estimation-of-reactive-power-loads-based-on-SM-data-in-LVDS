import random
import pandas as pd
import numpy as np
import h5py
import copy
import zipfile
from datetime import timedelta


def Slovakia_data_loading(base_folder):
    data = {}
    data_test = {}
    list_test_files = []
    random.seed(42)
    full_range = list(range(1, 100)) #1001
    list_files = random.sample(full_range, 50) #400
    list_test_files = list(set(full_range) - set(list_files))
    list_files.sort()
    list_test_files.sort()



    for i in list_files:
        file_path = base_folder / f"meters_{i}_measurement.json"
        data[i] = pd.read_json(file_path)

    for i in list_test_files:
        file_path = base_folder / f"meters_{i}_measurement.json"
        data_test[i] = pd.read_json(file_path)

    meter_data = {}
    file_path = base_folder / "meter_info.csv"
    meter_data = pd.read_csv(file_path, delimiter =';')
    meter_data.set_index('meterID', inplace=True)

    first_key = next(iter(data))
    last_key = next(reversed(data))
    first_key_test = next(iter(data_test))
    last_key_test = next(reversed(data_test))
    print(len(data_test))
    print(len(data))

    active_power, reactive_power, active_power_original, reactive_power_original, houses = P_Q_extraction(data, meter_data)
    active_power_test, reactive_power_test, active_power_original_test, reactive_power_original_test, houses_test = P_Q_extraction(data_test, meter_data)

    houses_PV = PV_detection_Slovakia(data, active_power)
    houses_PV_test = PV_detection_Slovakia(data_test, active_power_test)

    return data, active_power, reactive_power, active_power_original, reactive_power_original, houses, houses_PV, data_test, active_power_test, reactive_power_test, active_power_original_test, reactive_power_original_test, houses_test, houses_PV_test, meter_data, first_key, last_key, first_key_test, last_key_test

def Germany_data_loading(base_folder):
    data_2018 = {}
    data_2019 = {}
    data_2020 = {}
    data_2018_heat = {}
    data_2019_heat = {}
    data_2020_heat = {}
    first_key = 3
    last_key = 40
    for year in [2018, 2019, 2020]:
        nan_values = 0
        data = {}
        data_heat = {}
        file = base_folder / f"{year}_data_15min.hdf5"

        with h5py.File(file, "r") as year_file:
            for group in year_file.keys():
                for group2 in year_file[group].keys():
                    for i in range(3, 41):
                        group_name = f'SFH{i}'  
                        if group2 == group_name:
                            for key in year_file[group][group2].keys():
                                if key == 'HOUSEHOLD':
                                    data[i] = pd.DataFrame(year_file[group][group2][key]['table'][:])
                                    nan_values += data[i].isna().sum().sum()

                                if key == 'HEATPUMP':
                                    data_heat[i] = pd.DataFrame(year_file[group][group2][key]['table'][:])
                                    nan_values += data_heat[i].isna().sum().sum()
        
        if year == 2018:
            data_2018 = dict(sorted(data.items()))
            data_2018_heat = dict(sorted(data_heat.items()))
            total_nan_2018 = nan_values
        elif year == 2019:
            data_2019 = dict(sorted(data.items()))
            data_2019_heat = dict(sorted(data_heat.items()))
            total_nan_2019 = nan_values
        elif year == 2020:
            data_2020 = dict(sorted(data.items()))
            data_2020_heat = dict(sorted(data_heat.items()))
            total_nan_2020 = nan_values

    datasets = [
        (data_2018, total_nan_2018, "2018"),
        (data_2019, total_nan_2019, "2019"),
        (data_2020, total_nan_2020, "2020"),
    ]

    datasets_sorted = sorted(datasets, key=lambda x: x[1])

    train_year = datasets_sorted[1][2]
    test_year = datasets_sorted[0][2]

    data_1, data_heat_1 = German_datetime_indexing(data_2018, data_2018_heat, data_2019, data_2019_heat, data_2020, data_2020_heat)
    data_2 = create_power_dataframe(data_1, data_heat_1, first_key, last_key)

    no_data_set = flagging_buildings_with_no_data_full_year(data_2, first_key, last_key)

    data_train, houses_included_train = removing_buildings_with_gaps(data_2, no_data_set, first_key, last_key, train_year)
    data_test, houses_included_test = removing_buildings_with_gaps(data_2, no_data_set, first_key, last_key, test_year)

    return data_train, data_test, houses_included_train, houses_included_test, first_key, last_key

def USA_data_loading(base_folder):
    """Loads the data from the USA dataset

    Args:
        base_folder (string): path location for dataset

    Returns:
        dictionary: data_train: training data for the USA dataset
        dictionary: data_test: testing data for the USA dataset
    """
    data_2019_original = {}
    data_2021_original = {}
    data_2020_original = {}
    first_key = 1
    last_key = 26
    for year in [2019, 2020, 2021]:
        data = {}
        file_path = base_folder / f"MFRED_Aggregates_15min_{year}Q1-4.csv"
        data[year] = pd.read_csv(file_path, sep=';')

        if year == 2019:
            data_2019_original = dict(sorted(data.items()))
        elif year == 2020:
            data_2020_original = dict(sorted(data.items()))
        elif year == 2021:
            data_2021_original = dict(sorted(data.items()))
    
    data_2019 = timing(get_data(data_2019_original), 0)
    data_2020 = timing(get_data(data_2020_original), 0)
    data_2021 = timing(get_data(data_2021_original), 1)

    full_datetime_test(data_2019)
    full_datetime_test(data_2020)
    full_datetime_test(data_2021)

    total_nan_2019 = check_nan(data_2019, first_key, last_key)
    total_nan_2020 = check_nan(data_2020, first_key, last_key)
    total_nan_2021 = check_nan(data_2021, first_key, last_key)

    datasets = [
        (data_2019, total_nan_2019, '2019'),
        (data_2020, total_nan_2020, '2020'),
        (data_2021, total_nan_2021, '2021'),
    ]

    datasets_sorted = sorted(datasets, key=lambda x: x[1])
  
    data_train = datasets_sorted[0][0]
    data_test = datasets_sorted[1][0]
    #print(len(data_train[1]))
    print(len(data_test[1]))
    #print(f"Training data year: {datasets_sorted[0][2]}, Testing data year: {datasets_sorted[1][2]}")

    data_train_nan_fill = filling_nan(data_train, first_key, last_key)
    data_test_nan_fill = filling_nan(data_test, first_key, last_key)
    

    return data_train_nan_fill, data_test_nan_fill, first_key, last_key


def get_data(data):
    """ Extracts the relevant data from the input dictionary and organizes it into a new dictionary.

    Args:
        data (dictionary): initial input dictionary containing data for different years and households.

    Returns:
        dictionary: output dictionary containing organized data for each household, with keys as household numbers.
    """
    data1 = {}
    for year in data.keys():
        yearly_data = data[year]
        for household, values in yearly_data.items(): 
            global a
            a = values
            timestamps = yearly_data['DateTimeUTC']

            if household == 'DateTimeUTC' or  household == 'AGs01To26_kW' or household == 'AGs01To26_kVAR' or household == 'AGs01To26_kWh':
                    continue
            if int(household[2:4]) in data1:
                if household.split('_')[1] == 'kW':
                    data1[int(household[2:4])]['P'] = values.values
                elif household.split('_')[1] == 'kVAR':
                    data1[int(household[2:4])]['Q'] = values.values
            else:
                data1[int(household[2:4])] = pd.DataFrame(index = timestamps, columns = ['Nr', 'P', 'Q'])
                data1[int(household[2:4])]['Nr'] = int(household[2:4])
                if household.split('_')[1] == 'kW':
                    data1[int(household[2:4])]['P'] = values.values
                elif household.split('_')[1] == 'kVAR':
                    data1[int(household[2:4])]['Q'] = values.values
    return data1

def timing(data, remove_row):
    """Adjusts the timing of the data.

    Args:
        data (dictionary): Input dictionary containing data for different households.
        remove_row (int): Flag indicating whether to remove the last row.

    Returns:
        dictionary: Adjusted data with updated timing.
    """
    for household, values in data.items():
        values.index = pd.to_datetime(values.index, dayfirst=True)
        values.index = values.index.tz_localize('UTC').tz_convert('America/New_York')
        if remove_row == 1:
                values = values.iloc[:-1]
        data[household] = values.sort_index()
    return data

def full_datetime_test(data):
    """Checks for missing timestamps.

    Args:
        data (dictionary): Input dictionary containing data for different households.
    """
    for i in data.keys():
        full_range = pd.date_range(start=data[i].index.min(), end=data[i].index.max(), freq='15min')
        missing = full_range.difference(data[i].index)
        if not missing.empty:
            print(f" Missing {len(missing)} timestamps:")
            print(missing)

def check_nan(data, first_key, last_key):   
    """Checks for NaN values and missing columns.

    Args:
        data (dictionary): input dictionary
        first_key (int): First household key to check
        last_key (int): Last household key to check

    Returns:
        data (dictionary): input dictionary
        nan_values (int): number of NaN values found
    """
    total_nan_values = 0
    for i in range(first_key,last_key+1):                
        nan_values = data[i].isna().sum()
        #print("building:", i, "NaN values in each column:")
        #print(nan_values)
        total_nan_values += nan_values.sum()

    for i in range(first_key,last_key+1):
        if 'P' not in data[i].columns:
            #print('no P in', i)
            pass
        if 'Q' not in data[i].columns:
            #print('no Q in', i)
            pass
    return total_nan_values

def filling_nan(dataset1, first_key, last_key):
    """Fills NaN values in the dataset by averaging the values from the previous and next weeks.
    
    Args:
        dataset1 (dictionary): Input dictionary containing data for different households.
        first_key (int): First household key to check.
        last_key (int): Last household key to check.

    Returns:
        dictionary: Dataset with filled NaN values.
    """
    dataset = copy.deepcopy(dataset1)
    for i in range(first_key,last_key+1):
        data_timed = dataset[i]
        for col in data_timed.columns:
            start = None
            end = None
            length = 0
            is_nan = data_timed[col].isna()
            for j in range(1, len(is_nan)):
                if is_nan.iloc[j] == True and is_nan.iloc[j-1] == False:
                    start = j
                elif is_nan.iloc[j] == False and is_nan.iloc[j-1] == True:
                    end = j -1
                    if start is not None and end is not None:
                        length = end - start + 1
                    if length > 0:
                        start_date = data_timed.index[start]
                        end_date = data_timed.index[end]
                        for date in data_timed.loc[start_date:end_date].index:
                            previous_data = date - timedelta(weeks=1)
                            next_data = date + timedelta(weeks=1)
                            data_timed.loc[date, col] = (data_timed.loc[previous_data, col] + data_timed.loc[next_data, col])/2
                    else:
                        continue
    return dataset

def German_datetime_indexing(data_2018, data_2018_heat, data_2019, data_2019_heat, data_2020, data_2020_heat):
    """Adjusts the datetime indexing for German data.

    Args:
        data_2018 (dictionary): Input dictionary containing data for the year 2018.
        data_2018_heat (dictionary): Input dictionary containing heat pump data for the year 2018.
        data_2019 (dictionary): Input dictionary containing data for the year 2019.
        data_2019_heat (dictionary): Input dictionary containing heat pump data for the year 2019.
        data_2020 (dictionary): Input dictionary containing data for the year 2020.
        data_2020_heat (dictionary): Input dictionary containing heat pump data for the year 2020.

    Returns:
        data1 (dictionary): Adjusted data with updated datetime indexing.
        data_heat1 (dictionary): Adjusted heat pump data with updated datetime indexing.
    """  
    data1 = {}
    data_heat1 = {}

    for yearly_data in [data_2018, data_2019, data_2020]:
        for household, values in yearly_data.items():
            if household in data1:
                data1[household] = pd.concat([data1[household], values])
            else:
                data1[household] = values

    for yearly_data in [data_2018_heat, data_2019_heat, data_2020_heat]:    
        for household, values in yearly_data.items():
            if household in data_heat1:
                data_heat1[household] = pd.concat([data_heat1[household], values])
            else:
                data_heat1[household] = values

    for household, values in data1.items():
        values['index'] = pd.to_datetime(values['index'], unit='s')
        values.set_index('index', inplace=True)
        values.index = values.index.tz_localize('UTC').tz_convert('Europe/Berlin')
        data1[household] = values.sort_index()

    for household, values in data_heat1.items():
        values['index'] = pd.to_datetime(values['index'], unit='s')
        values.set_index('index', inplace=True)
        values.index = values.index.tz_localize('UTC').tz_convert('Europe/Berlin')
        data_heat1[household] = values.sort_index()
    
    return data1, data_heat1

def create_power_dataframe(data1, data_heat1, first_key, last_key):
    """Creates a power dataframe by combining data from two input dictionaries.

    Args:
        data1 (dictionary): Input dictionary containing data for different households.
        data_heat1 (dictionary): Input dictionary containing heat pump data for different households.
        no_data_set (set): Set of household keys with no data available.
        first_key (int): First household key to include in the power dataframe.
        last_key (int): Last household key to include in the power dataframe.

    Returns:
        power_dict (dictionary): Output dictionary containing power dataframes for each household.
    """

    data = {}
    data_heat = {}
    power_dict = {}

    for i in range(first_key, last_key+1):
        if i not in [13, 15, 26, 33]:
            data[i] = data1[i][['P_TOT', 'Q_TOT', 'PF_TOT', 'S_TOT']]
            data_heat[i] = data_heat1[i][['P_TOT', 'Q_TOT', 'PF_TOT', 'S_TOT']]
        else:
            data[i] = data1[i][['P_TOT', 'Q_TOT', 'PF_TOT', 'S_TOT', 'P_TOT_WITH_PV']]
            data_heat[i] = data_heat1[i][['P_TOT', 'Q_TOT', 'PF_TOT', 'S_TOT']]

    for i in range(first_key, last_key+1):
        power_dataframe = pd.DataFrame(index=data[i].index, columns=['Nr', 'P_noPV', 'P', 'P_heat', 'Q', 'Q_heat', 'S', 'S_heat', 'S_noheat', 'PF', 'PF_noheat', 'PF_heat'])
        power_dataframe['Nr'] = i
        power_dataframe['P_noPV'] = data[i]['P_TOT']
        power_dataframe['P_heat'] = data_heat[i]['P_TOT']
        if i in [13, 15, 26, 33]:
            power_dataframe['P'] = data[i]['P_TOT_WITH_PV'] + data_heat[i]['P_TOT']
            for j in power_dataframe['P_noPV'].index:
                if pd.isna(power_dataframe['P_noPV'][j]):
                    power_dataframe.loc[j, 'P_noPV'] = 0
        else:
            power_dataframe['P'] = data[i]['P_TOT']+data_heat[i]['P_TOT']
        power_dataframe['Q'] = data[i]['Q_TOT'] + data_heat[i]['Q_TOT']
        power_dataframe['Q_heat'] = data_heat[i]['Q_TOT']
        power_dataframe['S_noheat'] = data[i]['S_TOT']
        power_dataframe['S_heat'] = data_heat[i]['S_TOT']
        power_dataframe['PF_noheat'] = data[i]['PF_TOT']
        power_dataframe['PF_heat'] = data_heat[i]['PF_TOT']
        power_dict[i] = power_dataframe
        

    return power_dict

def removing_buildings_with_gaps(data, no_data_set, first_key, last_key, year):
    """Removes buildings with gaps in the data.

    Args:
        data (dictionary): Input dictionary containing data for different households.
        no_data_set (set): Set of household keys that have no data.
        first_key (int): First household key to check.
        last_key (int): Last household key to check.
        year (string): Year of the data being processed.

    Returns:
        data (dictionary): Updated dictionary with buildings containing gaps removed.
    """

    begin_time = pd.Timestamp(f'{year}-01-01', tz= 'Europe/Berlin')
    end_time = pd.Timestamp(f'{year}-12-31 23:45:00', tz= 'Europe/Berlin')

    not_included = []
    houses_included = []

    power_dict = {}

    for i in range(first_key, last_key+1):
        if gaps_in_time_series(data[i]['P'], begin_time, end_time):
            #print(f'gaps in {year} P for household:', data[i]['Nr'].iloc[0])
            not_included.append(i)
        if gaps_in_time_series (data[i]['Q'], begin_time, end_time):
            #print(f'gaps in {year} Q for household:', data[i]['Nr'].iloc[0])
            if i not in not_included:
                not_included.append(i)
        if i in no_data_set:
            if i not in not_included:
                not_included.append(i)

    for i in range(first_key, last_key+1):
        if i not in not_included:
            data_range = data[i][begin_time:end_time]
            cols = ['P_noPV', 'P', 'P_heat', 'Q', 'Q_heat', 'S', 'S_heat', 'S_noheat']
            data_range.loc[:, cols] = data_range.loc[:, cols] / 1000
            power_dict[i] = data_range
            houses_included.append(i)
    print(f'Number of households included in {year}:', len(power_dict))
    return power_dict, houses_included

def gaps_in_time_series(time_series, begin, einde):
    """
    Checks if there are any NaN values in the specified range of a time series.

    Args:
        time_series (pd.Series): The time series to check for NaN values.
        begin (int): The starting index of the range to check.
        einde (int): The ending index of the range to check.

    Returns:
        bool: True if there are NaN values in the specified range, False otherwise.
    
    """
    return any(time_series[begin:einde].isna())

def gaps(time_series, begin_date, end_date):
    """
    Checks if there are any gaps in the time series by comparing the index with the expected date range.

    Args:
        time_series (pd.Series): The time series to check for gaps.

    Returns:
        bool: True if there are gaps in the time series, False otherwise.
    """
    expected_dates = pd.date_range(start=begin_date, end=end_date, freq='15min')
    if not time_series.index.equals(expected_dates):
        return True
    else:
        return False

def flagging_buildings_with_no_data_full_year(data, first_key, last_key):
    """Flags buildings with no data for the full year.

    Args:
        data (dictionary): Input dictionary containing data for different households.
        first_key (int): First household key to check.
        last_key (int): Last household key to check.
    
    returns:
        no_data_set (list): List of household keys with no data for the full year.
    """
    begin_time = data[first_key].index[0]
    end_time = data[first_key].index[-1]

    no_data_set = []

    for i in range(first_key,last_key+1):
        if i in data:
            if gaps(data[i], begin_time, end_time):
                #print('no data', i)
                no_data_set.append(i)
    return no_data_set

def replace_exceeded_values(Q_values, P_values, meter_data, last_P, last_Q, i):
    """
    Replaces values in Q_values and P_values with the last valid non-zero values if they exceed the reserved capacity.

    Args:
        Q_values (list): List of reactive power values.
        P_values (list): List of active power values.
        meter_data (dict): Dictionary containing reserved capacity information for each household.
        last_P (float): Last valid non-zero active power value.
        last_Q (float): Last valid non-zero reactive power value.
        i (int): Household index.
    
    Returns:
        out_P (list): Updated list of active power values.
        out_Q (list): Updated list of reactive power values.
    """
    out_P = copy.deepcopy(P_values)
    out_Q = copy.deepcopy(Q_values)
    last_valid_Q = last_Q
    last_valid_P = last_P
    for k in range(len(Q_values)):
        if P_values[k] <= meter_data['reservedCapacity'][i]  and Q_values[k] <= meter_data['reservedCapacity'][i]:
            last_valid_Q = out_Q[k]
            last_valid_P = out_P[k]
        if Q_values[k] > meter_data['reservedCapacity'][i] or P_values[k] > meter_data['reservedCapacity'][i]:
            out_Q[k] = last_valid_Q
            out_P[k] = last_valid_P
            #print(i)
    return out_P, out_Q

def P_Q_extraction(data, meter_data):
    """"
    Extracts active and reactive power data from the input dictionary and organizes it into separate dictionaries.

    Args:
        data (dictionary): Input dictionary containing data for different households.
        meter_data (dictionary): Dictionary containing reserved capacity information for each household.
    
    Returns:
        reactive_power (dictionary): Dictionary containing reactive power data for each household.
        active_power (dictionary): Dictionary containing active power data for each household.
        reactive_power_original (dictionary): Dictionary containing original reactive power data for each household.
        active_power_original (dictionary): Dictionary containing original active power data for each household.
        houses (list): List of tuples containing household numbers and their corresponding keys.
    """
    reactive_power = {}
    active_power = {}
    reactive_power_original = {}
    active_power_original = {}
    houses = []

    for i in data.keys():  #house
        houses.append((i, i))
        house_data = data[i]
        house_data['datetime'] = pd.to_datetime(house_data[['year', 'month', 'day']]).dt.tz_localize('Europe/Bratislava')
        reactive_power_inner = []
        active_power_inner = []
        active_power_inner_or = []
        reactive_power_inner_or = []

        #non_zero_leading_reactive_power = any( any(value != 0.0 for value in day) for day in house_data['leadingReactivePower'])
        #non_zero_lagging_reactive_power = any( any(value != 0.0 for value in day) for day in house_data['laggingReactivePower'])
        #non_zero_active_power = any( any(value != 0.0 for value in day) for day in data[i]['consumption'])
        #if not non_zero_leading_reactive_power:
            #print(f'Non-zero values found in leadingReactivePower house {i}:', non_zero_leading_reactive_power)
        #if not non_zero_lagging_reactive_power:
            #print(f'Non-zero values found in laggingReactivePower house {i}:', non_zero_lagging_reactive_power)
        #if not non_zero_active_power:
            #print(f'Non-zero values found in activePower house {i}:', non_zero_active_power)

        last_P = 0
        last_Q = 0
        for j, (lagging, leading, consumption) in enumerate(zip(house_data['laggingReactivePower'], house_data['leadingReactivePower'], house_data['consumption'])):  #day-list
            lagging = np.array(lagging) #Ind
            leading = np.array(leading) #Caps
            consumption = np.array(consumption)
            timestamps = house_data['datetime'][j] + pd.to_timedelta(np.arange(len(lagging)) * 15, unit='min')



            Q_values = np.zeros(len(lagging), dtype=float) 
            P_values = np.zeros(len(consumption), dtype=float)
            
            P_values = consumption
            Q_values = lagging - leading
            Q_values_original = Q_values.copy()
            P_values_original = P_values.copy()

            P_values1, Q_values1 = replace_exceeded_values(Q_values, P_values, meter_data, last_P, last_Q, i)
            reactive_power_inner.extend(zip(timestamps, Q_values1))
            active_power_inner.extend(zip(timestamps, P_values1))
            active_power_inner_or.extend(zip(timestamps, P_values_original))
            reactive_power_inner_or.extend(zip(timestamps, Q_values_original))
            last_P = P_values1[-1]
            last_Q = Q_values1[-1]

        reactive_power_df = pd.DataFrame(reactive_power_inner, columns=['datetime', 'Q'])
        reactive_power_df.set_index('datetime', inplace=True)
        reactive_power_df = reactive_power_df.sort_index()
        reactive_power[i] = reactive_power_df

        reactive_power_original_df = pd.DataFrame(reactive_power_inner_or, columns=['datetime', 'Q'])
        reactive_power_original_df.set_index('datetime', inplace=True)
        reactive_power_original_df = reactive_power_original_df.sort_index()
        reactive_power_original[i] = reactive_power_original_df

        active_power_df = pd.DataFrame(active_power_inner, columns=['datetime', 'P'])
        active_power_df['datetime'] = pd.to_datetime(active_power_df['datetime'])
        active_power_df['day'] = active_power_df['datetime'].dt.dayofweek
        active_power_df.set_index('datetime', inplace=True)
        active_power_df = active_power_df.sort_index()
        active_power[i] = active_power_df

        active_power_original_df = pd.DataFrame(active_power_inner_or, columns=['datetime', 'P'])
        active_power_original_df['datetime'] = pd.to_datetime(active_power_original_df['datetime'])
        active_power_original_df['day'] = active_power_original_df['datetime'].dt.dayofweek
        active_power_original_df.set_index('datetime', inplace=True)
        active_power_original_df = active_power_original_df.sort_index()
        active_power_original[i] = active_power_original_df
    return active_power, reactive_power, active_power_original, reactive_power_original, houses

def PV_detection_Slovakia(data, active_power):
    """Detects buildings with PV installed

    Args:
        data (dictionary): Input dictionary containing data for different households.
        active_power (dictionary): Dictionary containing active power data for each household.

    Returns:
        list: List of household numbers with detected PV installation.
    """
    houses_PV = []
    for i in data.keys():
        house_data = active_power[i]
        night_boolean = ((house_data.index.hour >= 23) | (house_data.index.hour < 4))
        day_boolean = ((house_data.index.hour >= 11) & (house_data.index.hour < 17))
        night_data = house_data.loc[night_boolean, 'P']
        day_data = house_data.loc[day_boolean, 'P']
        if (np.median(night_data) > 1.8*np.median(day_data)):
            houses_PV.append(i)
    return houses_PV

def PV_detection_German(data):
    PV_dict = {}
    for i in data.keys():
        df = data[i]
        timestamps = df.index
        PV_values = np.where((i in [13, 15, 26, 33]), '1', '0')  #1 if PV, 0 if not

        PV_df = pd.DataFrame({'PV':PV_values}, index = timestamps)
        PV_dict[i] = PV_df
    return PV_dict

def PV_detection_USA(data):
    houses_PV = []
    for i in data.keys():
        house_data = data[i]
        night_boolean = ((house_data.index.hour >= 23) | (house_data.index.hour < 4))
        day_boolean = ((house_data.index.hour >= 11) & (house_data.index.hour < 17))
        night_data = house_data.loc[night_boolean, 'P']
        day_data = house_data.loc[day_boolean, 'P']
        if (np.median(night_data) > 1.8*np.median(day_data)):
            houses_PV.append(i)
    PV_dict = {}
    for i in data.keys():
        df = data[i]
        timestamps = df.index
        PV_values = np.where((i in houses_PV), '1', '0')  #1 if PV, 0 if not

        PV_df = pd.DataFrame({'PV':PV_values}, index = timestamps)
        PV_dict[i] = PV_df
    return PV_dict

def merge_data_Slovak(data, active_power1, reactive_power1, meter_data, houses, houses_PV):
    """Merges metadata and data together in a single dictionary.

    Args:
        data (dictionary): Input dictionary containing data for different households.
        active_power1 (dictionary): Dictionary containing updated active power data for each household.
        reactive_power1 (dictionary): Dictionary containing updated reactive power data for each household.
        meter_data (dictionary): Dictionary containing meter data for each household.
        houses (list): List of household numbers.
        houses_PV (list): List of household numbers with detected PV installation.

    Returns:
        dictionary: Merged dictionary containing data for all households.
    """
    active_power_dict = {i: v for i, v in enumerate(active_power1.values())}
    reactive_power_dict = {i: v for i, v in enumerate(reactive_power1.values())}
    power_df = {}
    houses = pd.DataFrame(houses, columns=['index', 'number'])
    for i in range(1,len(data)+1):
        house_number = pd.Series(houses['number'].loc[i-1], index=active_power_dict[i-1]['day'].index, name='Nr')
        power_df[i] = pd.merge(house_number, active_power_dict[i-1]['day'], left_index=True, right_index=True, how='inner')

    for i in range(1,len(data)+1):
        reserved_cap = pd.Series(meter_data['reservedCapacity'].loc[i], index=active_power_dict[i-1]['day'].index, name='Res_Cap')
        power_df[i] = pd.merge(power_df[i], reserved_cap, left_index=True, right_index=True, how='inner')

    for i in range(1,len(data)+1):
        power_df[i] = pd.merge(power_df[i], active_power_dict[i-1]['P'], left_index=True, right_index=True, how='inner')

    for i in range(1,len(data)+1):
        power_df[i] = pd.merge(power_df[i], reactive_power_dict[i-1], left_index=True, right_index=True, how='inner')
    
    power_factor, apparent_power, PV_dict = PF_S_calculation(power_df, houses_PV)

    for i in range(1,(len(power_df)+1)):
        power_df[i] = pd.merge(power_df[i], power_factor[i], left_index=True, right_index=True, how='inner')

    for i in range(1,(len(power_df)+1)):
        power_df[i] = pd.merge(power_df[i], apparent_power[i], left_index=True, right_index=True, how='inner')

    for i in range(1,(len(power_df)+1)):
        power_df[i] = pd.merge(power_df[i], PV_dict[i], left_index=True, right_index=True, how='inner')

    return power_df

def merge_data_German(data):
    """Merges the data for the German dataset by calculating apparent power, power factor, and detecting PV installations.

    Args:
        data (dictionary): Input dictionary containing data for different households.
    Returns:
        dictionary: Merged dictionary containing data for all households with calculated apparent power, power factor, and PV detection.
    """
    PV_dict = PV_detection_German(data)
        
    power_dict = {}
    
    for key, dataframe in data.items():
        dataframe['S'] = np.sqrt(dataframe['P']**2 + dataframe['Q']**2)
        zero_s_mask = dataframe['S'] == 0
        dataframe['PF'] = np.where(zero_s_mask, 1, dataframe['P'] / dataframe['S'])
        dataframe = pd.merge(dataframe, PV_dict[key], left_index=True, right_index=True, how='inner')
        power_dict[key] = dataframe
    return power_dict

def merge_data_USA(data):
    """Merges the data for the USA dataset by calculating apparent power, power factor, and detecting PV installations.

    Args:
        data (dictionary): Input dictionary containing data for different households.

    Returns:
        dictionary: Merged dictionary containing data for all households with calculated apparent power, power factor, and PV detection.
    """
    power_dict = {}

    PV_dict = PV_detection_USA(data)
    for key, dataframe in data.items():
        dataframe['S'] = np.sqrt(dataframe['P']**2 + dataframe['Q']**2)
        zero_s_mask = dataframe['S'] == 0
        dataframe['PF'] = np.where(zero_s_mask, 1, dataframe['P'] / dataframe['S'])
        dataframe = pd.merge(dataframe, PV_dict[key], left_index=True, right_index=True, how='inner')
        power_dict[key] = dataframe
    return power_dict

def PF_S_calculation(power_df, houses_PV):
    """Calculates the power factor and apparent power for each household.

    Args:
        power_df (dictionary): Dictionary containing data for each household.
        houses_PV (list): List of household numbers with detected PV installation.

    Returns:
        tuple: Tuples containing power factor and apparent power data for each household.
    """
    power_factor = {}
    apparent_power = {}
    for i in power_df.keys():
        df = power_df[i]
        P = df['P'].values
        Q = df['Q'].values
        timestamps = df.index
        S = np.sqrt(P**2 + Q**2)
        
        PF_values = np.where((P == 0.0) & (Q == 0.0), 1, np.where((i in houses_PV) & (P == 0) & (timestamps.hour >=5) & (timestamps.hour<= 22), 1,  P/S))

        power_factor_df = pd.DataFrame({'PF':PF_values}, index = timestamps)
        power_factor[i] = power_factor_df

        apparent_power_df = pd.DataFrame({'S': S}, index = timestamps)
        apparent_power[i] = apparent_power_df

    PV_dict = {}
    for i in power_df.keys():
        df = power_df[i]
        timestamps = df.index
        PV_values = np.where((i in houses_PV), '1', '0')  #1 if PV, 0 if not

        PV_df = pd.DataFrame({'PV':PV_values}, index = timestamps)
        PV_dict[i] = PV_df
    return power_factor, apparent_power, PV_dict

def zero_sequence(time_series):
    """Checks if there are any sequences of zero values in the time series that exceed a certain length.

    Args:
        time_series (pd.DataFrame): Input time series data containing 'P' and 'Q' columns.

    Returns:
        bool: True if there are sequences of zero values exceeding the threshold, False otherwise.
    """ 
    P_s = time_series['P'].values
    Q_s = time_series['Q'].values
    zero_P = P_s == 0
    zero_Q = Q_s == 0
    diff_P = np.diff(np.concatenate(([0], zero_P, [0])))
    diff_Q = np.diff(np.concatenate(([0], zero_Q, [0])))
    starter_P = np.where(diff_P == 1)[0]
    starter_Q = np.where(diff_Q == 1)[0]
    ender_P = np.where(diff_P == -1)[0]
    ender_Q = np.where(diff_Q == -1)[0]
    zero_length_P = ender_P - starter_P
    zero_length_Q = ender_Q - starter_Q

    if np.any(zero_length_P >= 6*24*4) or np.any(zero_length_Q >= 6*24*4):
        return True
    else:
        return False

def cleaning(power_df, dates):
    """Cleans the power data by removing buildings with gaps or sequences of zero values.

    Args:
        power_df (dictionary): Dictionary containing power data for each household.
        dates (pd.DataFrame): DataFrame containing the date range for the data.

    Returns:
        tuple: Tuple containing the cleaned power data, list of houses included, and groups of small, medium, and large households.
    """
    no_full_year = []
    begin_date = dates.index[0]
    end_date = dates.index[-1]

    for i in power_df.keys():
        if zero_sequence(power_df[i]) and i not in no_full_year:
            no_full_year.append(i)
            print('zeros', power_df[i]['Nr'].iloc[0])
        if gaps(power_df[i], begin_date, end_date) and i not in no_full_year:
            no_full_year.append(i)
            print('length', power_df[i]['Nr'].iloc[0])               
        nan_values =power_df[i].isna().sum()
        if nan_values.sum() > 0:
            print(i, "NaN values in each column:")
            print(nan_values)
        
    powerdf_clean = {}
    power_df_update = power_df
    power_df_update = {k: v for k, v in power_df.items() if k not in no_full_year}
    houses_list = {k for k in power_df_update.keys()}
    powerdf_clean = {i: v for i, (_, v) in enumerate(power_df_update.items(), start=1)}

    return powerdf_clean, houses_list

def storing(powerdf_clean, path_folder, name):
    """Creates a new directory and stores the cleaned data in a zip-folder as csv files.

    Args:
        powerdf_clean (dictionary): Dictionary of the cleaned data
        path_folder (string): Path to the folder where the zip file will be stored
        name (string): Name of the zip file
    """
    temp_dir = path_folder / "temp_dataframes"
    temp_dir.mkdir(parents=True, exist_ok=True)

    for key, df in powerdf_clean.items():
        if isinstance(df.index, pd.DatetimeIndex):
            df.index = df.index.tz_convert('UTC')
        file_path = temp_dir / f"{key}.csv"
        df.to_csv(file_path)

    
    zip_filename = path_folder / f"{name}.zip"
    with zipfile.ZipFile(zip_filename, 'w') as zipf:
        for file_path in temp_dir.iterdir():
            zipf.write(file_path, file_path.name)

    
    for file_path in temp_dir.iterdir():
            file_path.unlink()
    temp_dir.rmdir()

def Merge_data_Slovak(active_power, reactive_power):
    """Merges active and reactive power data into a single dictionary.

    Args:
        active_power (dictionary): Dictionary containing active power data for each household.
        reactive_power (dictionary): Dictionary containing reactive power data for each household.
    
    Returns:
        merged_data (dictionary): Merged dictionary containing both active and reactive power data for each household.
    """
    data_merged = {}
    for house in active_power:
        data_merged[house] = pd.merge(active_power[house], reactive_power[house], left_index=True, right_index=True, how='inner')

    return data_merged














