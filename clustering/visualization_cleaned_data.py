import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns

def PF_plots(data):
   start_date = data[list(data.keys())[0]].index[0]
   end_date = data[list(data.keys())[0]].index[-1]
   plt.figure(figsize = (20,6))
   for i in range(1,(len(data)+1)):
      year = data[i][start_date:end_date]   
      plt.scatter(year.index, year['PF'], marker='o', color='b')
   plt.xlabel('dates')
   plt.xticks(rotation = 45)
   plt.ylabel('Power factor [/]]')
   plt.title(f'Power factor over all houses')
   plt.grid(True)
   plt.show()

def P_full_year(power_dict):
   start_date = power_dict[list(power_dict.keys())[0]].index[0]
   end_date = power_dict[list(power_dict.keys())[0]].index[-1]
   plt.figure(figsize = (20,6))
   for i in power_dict.keys():
      year = power_dict[i]['P'][start_date:end_date]   
      plt.scatter(year.index, year, marker='o', color='b')
   plt.xlabel('dates')
   plt.xticks(rotation = 45)
   plt.ylabel('Active power [kW]')
   plt.title(f'Active power over all houses')
   plt.grid(True)
   plt.show()

def Q_full_year(power_dict):
   start_date = power_dict[list(power_dict.keys())[0]].index[0]
   end_date = power_dict[list(power_dict.keys())[0]].index[-1]
   plt.figure(figsize = (20,6))
   for i in power_dict.keys():
      year = power_dict[i]['Q'][start_date:end_date]   
      plt.scatter(year.index, year, marker='o', color='b')
   plt.xlabel('datetime')
   plt.xticks(rotation = 45)
   plt.ylabel('Reactive power [kVAr]')
   plt.title(f'Reactive power over all houses')
   plt.grid(True)
   plt.show()

def P_full_year_individual(power_dict, house):
   start_date = power_dict[house].index[0]
   end_date = power_dict[house].index[-1]
   year = power_dict[house]['P'][start_date:end_date]
   plt.figure(figsize = (20,6))
   plt.scatter(year.index, year, marker='o', color='b')
   plt.xlabel('dates')
   plt.xticks(rotation = 45)
   plt.ylabel('Active power [kW]')
   plt.title(f'Active power over all houses')
   plt.grid(True)
   plt.show()

def Q_full_year_individual(power_dict, house):
   start_date = power_dict[house].index[0]
   end_date = power_dict[house].index[-1]
   year = power_dict[house]['Q'][start_date:end_date]
   plt.figure(figsize = (20,6))
   for i in power_dict.keys():
      year = power_dict[i]['Q'][start_date:end_date]   
      plt.scatter(year.index, year, marker='o', color='b')
   plt.xlabel('dates')
   plt.xticks(rotation = 45)
   plt.ylabel('Reactive power [kVAr]')
   plt.title(f'Reactive power over all houses')
   plt.grid(True)
   plt.show()

def PF_plots_individual(power_dict, house):
    start_date = power_dict[house].index[0]
    end_date = power_dict[house].index[-1]

    year_data = power_dict[house][start_date:end_date] 
    plt.figure(figsize = (10,6))
    plt.plot(year_data.index, year_data['PF'], linestyle='-', color='b')
    plt.xlabel('Date')
    plt.xticks(rotation = 45)
    plt.ylabel('Power factor [/]')
    plt.title(f'Power factor over time of house:{house}')
    plt.grid(True)
    plt.show()

def PF_Q_over_P(data):
    start_date = data[list(data.keys())[0]].index[0]
    end_date = data[list(data.keys())[0]].index[-1]
    plt.figure(figsize = (20,6))
    for i in data.keys():
        year_data = data[i][start_date:end_date]   
        plt.scatter(year_data['P'], year_data['PF'], marker='o', color='b')
    plt.xlabel('Active power [kW]')
    plt.xticks(rotation = 45)
    plt.ylabel('Power factor [/]')
    plt.title(f'Power factor over active power over all houses')
    plt.grid(True)
    plt.show()

    plt.figure(figsize = (20,6))
    for i in data.keys():
        year_data = data[i][start_date:end_date]  
        plt.scatter(year_data['P'], year_data['Q'], marker='o', color='b')
    plt.xlabel('Active power [kW]')
    plt.ylim(-10, 30)
    plt.xticks(rotation = 45)
    plt.ylabel('Reactive Power [kVAr]')
    plt.title(f'reactive power over active power over all houses')
    plt.grid(True)
    plt.show()

def load_prob_density_plot(powerdf_dict):
    annual_energy = []
    peak_power = []
    for i in powerdf_dict.keys():
        Nr = powerdf_dict[i]['Nr']
        annual_energy.append((int(Nr.iloc[0]),float(powerdf_dict[i]['P'].sum()*0.25)))
        peak_power.append((int(Nr.iloc[0]), float(powerdf_dict[i]['P'].max())))

    annual_energy_sort = sorted(annual_energy, key=lambda x: x[1])
    peak_power_sort = sorted(peak_power, key=lambda x: x[1])

    max_energy = np.percentile(annual_energy_sort, 100)
    max_power = np.percentile(peak_power_sort, 100)
    min_energy = np.percentile(annual_energy_sort, 0)
    min_power = np.percentile(peak_power_sort, 0)

    annual_energy_filtered = [x[1] for x in annual_energy if x[1] >= min_energy and x[1] <= max_energy]
    peak_power_filtered = [x[1] for x in peak_power if x[1] >= min_power and x[1] <= max_power]

    sns.kdeplot(annual_energy_filtered, label='Annual energy [kWh]', bw_adjust=0.2)
    plt.xlabel('Annual energy [kWh]')
    plt.ylabel('Probability Density')
    plt.title('Probability Density Function of Annual Energy')
    plt.grid(True)
    plt.show()

    sns.kdeplot(peak_power_filtered, label='Peak power [kW]', bw_adjust=0.2)
    plt.xlabel('Peak power [kW]')
    plt.ylabel('Probability Density')
    plt.title('Probability Density Function of Peak Power')
    plt.grid(True)
    plt.show()















