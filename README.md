# Gomorphological classification

This repository contains the code and results for “How can a classifier’s decisions be explained in automatic geomorphological mapping?” article.

Reference geomorphological maps are available from the Head Office of Geodesy and Cartography in Poland and are licensed, therefore they are not publicly available.

## Reproduction

## Results

The `results` directory contains the following files with the results of this study:

- `lightgbm.csv` - classification accuracy of the LightGBM model using hold-out validation
- `randomforest.csv` - classification accuracy of the Random Forest model using hold-out validation
- `xgboost.csv` - classification accuracy of the XGBoost model using hold-out validation
- `maps_crossvalidation.csv` - classification accuracy of the XGBoost model for individual maps using cross-validation
- `variable_importance.csv` - significance of geomorphometric variables calculated for the XGBoost model

Additionally, the `1B_ALE_plots.pdf` file in the `appendix` directory contains generated accumulated local effects (ALE) plots for all landforms.
