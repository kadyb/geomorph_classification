# Gomorphological classification

This repository contains the code and results for “How can a classifier’s decisions be explained in automatic geomorphological mapping?” article.

Reference geomorphological maps are available from the Head Office of Geodesy and Cartography in Poland and are licensed, therefore they are not publicly available.

## Reproduction

1. Open the `geomorph_classification.Rproj` project file in [RStudio](https://rstudio.com/).
2. Generate geomorphometric variables for the entire country from digital elevation model (DEM) using `01_generate_variables.R`. This requires [SAGA GIS](https://saga-gis.sourceforge.io/en/index.html) and [GDAL](https://gdal.org/).
3. Prepare a dataset based on reference geomorphological maps and geomorphometric variables using `02_prepare_dataset.R`.
4. Scripts for train and validate machine learning models are defined in the following files: `03A_randomforest.R`, `03B_xgboost.R`, and `03C_lightgbm.R`. Please note that this process is very time-consuming.
5. Cross-validation for the best classifier (in this case XGBoost) for individual maps (morphogenetic zones) can be performed using `04_maps_crossvalidation.R`.
6. Prediction for the entire country can be made using `05_predict.R`. The result is three products, i.e. a landform classification map, a classification uncertainty map and a probability map of a specified landform. In addition, post-processing is performed including modal and sieve filters to smooth the output.
7. The accumulated local effects are calculated in the `06_ALE.R` for each sheet.

Note that the classes (landforms) numbering in XGBoost and LightGBM starts from 0, while in R from 1.

## Results

The `results` directory contains the following files with the results of this study:

- `lightgbm.csv` - classification accuracy of the LightGBM model using hold-out validation
- `randomforest.csv` - classification accuracy of the Random Forest model using hold-out validation
- `xgboost.csv` - classification accuracy of the XGBoost model using hold-out validation
- `maps_crossvalidation.csv` - classification accuracy of the XGBoost model for individual maps using cross-validation
- `variable_importance.csv` - significance of geomorphometric variables calculated for the XGBoost model

Additionally, the `1B_ALE_plots.pdf` file in the `appendix` directory contains generated accumulated local effects (ALE) plots for all landforms.
