This repository contains the scripts (Python and Julia) to recreate the results for the Paper: "Estimation of reactive power loads for low voltage
network consumers using smart meter data", by Ewout Venstermans, Md. Umar Hashmi, and Marta Vanin. The code is run using a local environment on Python 3.12.4

## Open source datasets:
The following open-source datasets (all 15-min resolution) were used during this work:
- [Slovakian dataset](https://www.sciencedirect.com/science/article/pii/S2352340923006819?via%3Dihub): An open-source dataset containing consumption (active and reactive power) data for 1000 households over the year 2019.
- [German dataset](https://www.nature.com/articles/s41597-022-01156-1): An open-source dataset containing consumption (active and reactive power) data for 38 households in Germany over the years 2018-2020.
- [MFRED dataset](https://www.nature.com/articles/s41597-020-00721-w): An open-source dataset containing consumption (active and reactive power) data for 26 buildings in the USA over the years 2019-2021.

The downloaded datasets should be stored in the `Clustering/data/repository` folder under their corresponding country name. The data needs to be unpacked from zip files, if in zip format. Additionally, a csv file containing the hyperparameters used for clustering can be found in this folder, for recreation of the results.

## Clustering of the datasets and reactive power estimation.
The general code is provided in the form of python jupyter notebooks in the folder `clustering`, ran on a local environment using `Python version 3.12.4`. 

Five clustering notebooks are provided:
- **data_cleaning_code**: Contains the workflow to clean and format the data before clustering. The underlying functionality for this notebook is found in the `data_cleaning_codepy`file.
- **clustering_on_PF_time_series**: Clusters the buildings directly on their PF time series. The underlying functionality for this notebook is found in the `general_clustering_functions.py` and `clustering_on_PF_time_series_functions.py` files.
- **Clustering_on_PQ_features**: Clusters the buildings based on features extracted from the P and Q time series. The underlying functionality for this notebook is found in the `general_clustering_functions.py` and `clustering_on_PQ_features.py` files.
- **Clustering_on_PQSPF_features**: Clusters the buildings based on features extracted from the P, Q, S and PF time series. The underlying functionality for this notebook is found in the `general_clustering_functions.py` and `clustering_on_PQSPF_features.py` files.
- **visualization_results**: Finally compares the different clustering results and defines the baseline methods. The underlying functionality for this notebook is found in the `general_clustering_functions.py` and `visualization_results.py` files.

## Analyzing the impact of improved reactive power estimation on realistic network voltages.
The general code is provided as Julia files in the folder `Q_estimation_case`. The results can be reproduced by running the `Q_estimation_application.jl` file.

Notably `load_data.jl` contains the functions to load and store the data.

The functions to build the network are provided in `network_functions.jl`, while the main functionality to run the power flows is provided in `power_flow_analysis.jl`.

The functionality to visualize the results is provided in visualization.jl.

The required packages to install are provided via the `Project.toml` and `Manifest.toml` files.

This project includes data files originally obtained from the following repository:

https://github.com/Electa-Git/ImpedanceEstimationWithCarson

The original data are licensed under the BSD 3-Clause "New" or "Revised" License.








