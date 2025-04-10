#############################################
#     Local Interpolation Lab
#############################################

install.packages("geoR")
install.packages("gstat")
install.packages(("sp"))
install.packages("raster")
install.packages("RColorBrewer")

# Load necessary libraries
library(geoR)          # Geostatistical analysis
library(gstat)         # Spatial interpolation
library(sp)            # Spatial data manipulation
library(raster)        # Raster data handling
library(RColorBrewer)  # Color palettes for plotting

### Step 1: Load and Inspect the Dataset
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Load the `soja98` dataset into R and inspect its structure.
#   - Use `data()` to load the dataset into the workspace.
#   - Use `help()` to view documentation about the dataset.
#   - Use `head()` to inspect the first few rows of the dataset.

# Example of loading and inspecting a dataset:
#   data(dataset_name)       # Loads a dataset into R
#   help(dataset_name)       # Displays documentation for the dataset
#   head(dataset_name)       # Displays the first few rows of the dataset

#----------------
data(soja98)           # Complete: Load the dataset
help(soja98)           # Complete: View documentation for the dataset
head(soja98)           # Complete: Inspect first few rows of the dataset
#----------------

### Step 2: Select Relevant Columns
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Select only relevant columns: X, Y coordinates and potassium (K).
#   - Use indexing to keep only columns 1, 2, and 5.

# Example of selecting columns:
#   dataframe <- dataframe[, c(column_index1, column_index2, column_index3)]

#----------------
soja98 <- soja98[, c(1, 2, 5)]  # Complete: Select relevant columns (X, Y, K)
#----------------

### Step 3: Convert to Spatial Points
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Convert the dataframe into a spatial points object.
#   - Use `coordinates()` to specify which columns represent spatial coordinates.
#   - This step is necessary for spatial interpolation methods.

# Example of converting a dataframe into spatial points:
#   coordinates(dataframe) <- ~longitude+latitude

#----------------
coordinates(soja98) <- ~X+Y  # Complete: Convert to spatial points using X and Y columns
#----------------

### Step 4: Split Data into Calibration and Validation Sets
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Split the data into calibration (`cal`) and validation (`val`) datasets.
#   - Calibration data will be used for generating interpolation maps.
#   - Validation data will be used to evaluate interpolation accuracy.
#   - Use `set.seed()` for reproducibility when randomly splitting data.

## Explanation:
## - `set.seed(seed_value)` ensures that random operations (e.g., sampling) produce consistent results every time you run your code.
## - `sample()` randomly selects indices from a dataset.

## Example of splitting data:
##   set.seed(123)
##   IDX <- sample(1:nrow(dataframe), sample_size)
##   calibration_data <- dataframe[IDX, ]
##   validation_data <- dataframe[-IDX, ]

set.seed(4887)                             # Ensures reproducibility in random sampling
IDX <- sample(1:nrow(soja98), 150)         # Complete: Randomly select indices for calibration data

cal <- soja98[IDX, ]                       # Calibration dataset (selected indices)
val <- soja98[-IDX, ]                      # Validation dataset (remaining indices)


###############################################
#           Inverse Distance Weighting (IDW)
###############################################

### Step 1: Create a Grid for Interpolation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create a grid with 5m cell size for interpolation.
#   - The grid defines the spatial resolution of the interpolated map.
#   - Use `extent()` to get the spatial extent of the dataset.
#   - Use `expand.grid()` to generate a grid of X and Y coordinates.

## Explanation:
# - `extent(data)` extracts the minimum and maximum coordinates in X and Y directions.
# - `seq(start, end, step_size)` generates sequences of numbers for grid creation.
# - `expand.grid()` creates a dataframe with all combinations of X and Y coordinates.

## Example of creating a grid:
#   cellSize <- 10
#   range.all <- extent(dataframe)
#   grid <- expand.grid(x = seq(range.all[1], range.all[2], by = cellSize),
#                       y = seq(range.all[3], range.all[4], by = cellSize))

cellSize <- 5  # Define grid cell size (5 meters)
range.all <- extent(soja98)  # Get spatial extent of the dataset

grd <- expand.grid(
  x = seq(range.all[1], range.all[2], by = cellSize),  # Complete: Generate X coordinates
  y = seq(range.all[3], range.all[4], by = cellSize)   # Complete: Generate Y coordinates
)
coordinates(grd) <- ~x + y   # Convert to spatial points object
gridded(grd) <- TRUE         # Convert to gridded structure

## TASK: What happens if you change `cellSize` to a larger or smaller value? Try `cellSize <- 10`.
# the number of grids increases if you decrease cellSize and decreases if you increase cellSize


### Step 2: Perform IDW Interpolation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Perform IDW interpolation using calibration data (`cal`) and the grid (`grd`).
#   - Use `idw()` to interpolate potassium (K) values onto the grid.

## Explanation:
# - IDW estimates values at unsampled locations as weighted averages of nearby sampled points.
# - The formula `K ~ 1` means we are interpolating potassium (`K`) without considering other predictors.

## Example of IDW interpolation:
#   idw_result <- idw(variable ~ formula, calibration_data, grid)

K.idw <- idw(K ~ 1, cal, grd)  # Complete: Specify formula, calibration data, and grid



### Step 3: Visualize IDW Results
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Visualize the IDW interpolation results using `spplot()`.
#   - Use color ramps from `RColorBrewer` for better visualization.

## Explanation:
# - `spplot()` creates spatial plots for visualizing interpolated maps.
# - Calibration points can be overlaid on the map using custom symbols.

## Example of creating a color ramp:
#   colors <- brewer.pal(9, "Blues")

cols <- brewer.pal(9, "BuPu")  # Generate color ramp for visualization

spplot(K.idw, "var1.pred", col.regions = cols, cuts = 8, main = 'Inverse Distance Weighting')



### Step 4: Evaluate Accuracy with RMSE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Evaluate the accuracy of IDW interpolation using RMSE (Root Mean Squared Error).
#   - Extract interpolated values at calibration and validation points using `extract()`.
#   - Apply the RMSE formula: sqrt(mean((predicted - observed)^2)).

## Explanation:
# - RMSE quantifies how far predictions deviate from observed values.
# - Validation RMSE is typically larger than calibration RMSE because calibration points are used in interpolation.

## Example of RMSE calculation:
#   RMSE <- sqrt(mean((predicted_values - observed_values)^2))

r.idw <- raster(K.idw)               # Convert IDW output to a raster object

k.idw.cal <- extract(r.idw, cal)     # Extract interpolated values at calibration points
RMSE.idw.cal <- sqrt(mean((k.idw.cal - cal$K)^2, na.rm = T))  # Complete: Apply RMSE formula

k.idw.val <- extract(r.idw, val)     # Extract interpolated values at validation points
RMSE.idw.val <- sqrt(mean((k.idw.val - val$K)^2, na.rm = T))  # Complete: Apply RMSE formula

cat("IDW Calibration RMSE:", RMSE.idw.cal)
cat("IDW Validation RMSE:", RMSE.idw.val)



### Step 5: Use Yardstick Package for Alternative RMSE Calculation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Use the `yardstick` package to calculate RMSE as an alternative method.
install.packages("yardstick")
install.packages("dplyr")
library(yardstick)
library(dplyr)

## Explanation:
# - The `yardstick::rmse()` function calculates RMSE directly from a dataframe.
# - The dataframe must contain columns for observed (`truth`) and predicted (`estimate`) values.

## Example of using yardstick:
#   rmse(dataframe, truth = observed_column, estimate = predicted_column)

rmse_df <- tibble(
  truth = val$K,
  estimate = k.idw.val
)
yardstick_rmse <- rmse(rmse_df, truth = truth, estimate = estimate)

cat("Validation RMSE using yardstick:", yardstick_rmse$.estimate)



###############################################
#           Effect of Sample Size on RMSE
###############################################

### Step 1: Initialize Sample Sizes and RMSE Array
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Simulate different sample sizes to observe their effect on RMSE.
#   - Create a vector `n` containing sample sizes from 5 to 150 in increments of 5.
#   - Create an empty array `RMSE` to store RMSE values for each sample size.

## Explanation:
# - `seq(start, end, by)` generates a sequence of numbers.
# - `array(NA, length)` creates an empty array of a specified length filled with `NA`.

## Example of initializing sample sizes and results:
#   sample_sizes <- seq(10, 100, by = 10)
#   results <- array(NA, length(sample_sizes))

n <- seq(5, 150, by = 5)  # Complete: Specify increment for sample sizes
RMSE <- array(NA, length(n))      # Array to store RMSE values


### Step 2: Simulation Loop
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Use a loop to simulate IDW interpolation for different sample sizes.
#   - For each sample size, randomly select calibration points.
#   - Perform IDW interpolation and calculate RMSE for validation data.

## Explanation:
# - `for (i in seq_along(n))` iterates over each sample size in `n`.
# - `sample()` randomly selects indices from the calibration dataset.
# - `idw()` performs interpolation using the sampled calibration data.
# - `extract()` retrieves interpolated values at validation points.
# - RMSE is calculated and stored in the `RMSE` array.

## Example of a simulation loop:
#   for (i in 1:length(sample_sizes)) {
#     sampled_indices <- sample(1:nrow(data), sample_sizes[i])
#     # Perform interpolation and calculate RMSE
#   }

for (i in seq_along(n)) {
  # Randomly sample calibration points
  samp <- sample(1:length(cal), n[i])  # Complete: Specify population and sample size
  
  # Perform IDW interpolation with sampled data
  K.idw <- idw(K ~ 1, cal[samp, ], grd)    # Complete: Specify formula, data, and grid
  
  # Convert IDW output to raster and extract validation values
  r.idw <- raster(K.idw)
  k.idw.val <- extract(r.idw, val)
  
  # Calculate RMSE for validation data
  RMSE[i] <- sqrt(mean((k.idw.val - val$K)^2, na.rm = T))  # Complete: Apply RMSE formula
}



### Step 3: Plot Results
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Visualize the relationship between sample size and RMSE using a line plot.

## Explanation:
# - `plot(x, y, type = "b")` creates a line plot with points connected by lines.
# - Larger sample sizes generally improve accuracy (lower RMSE), but randomness can cause variability.

## Example of plotting:
#   plot(x_values, y_values, type = "b", main = "Title", xlab = "X Label", ylab = "Y Label")

plot(n, RMSE, type = "b", 
     main = "Effect of Sample Size on RMSE",
     xlab = "Sample Size", 
     ylab = "RMSE")



### Reflection Questions:
## 1. **Why doesn’t RMSE decrease smoothly as sample size increases?**  
##   Hint: Consider the role of randomness in sampling calibration points.

# RMSE doesn't decrease smoothly because randomizing causes there to be variability in the points chosen.
# Randomness also means fewer points are plotted, meaning the graph has a smaller chance of being smooth.

## 2. **What sample size minimizes RMSE in your simulation? Is this consistent across multiple runs?**
  
#  Around n = 80 and n = 150 minimizes RMSE across all runs.

  ###############################################
#           Ordinary Kriging (OK)
###############################################

### Step 1: Fit Variogram Models
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Fit spherical and exponential variogram models to the calibration data.
#   - Use `variogram()` to compute the experimental variogram.
#   - Use `fit.variogram()` to fit models to the experimental variogram.

## Explanation:
# - A variogram measures spatial autocorrelation by plotting semivariance against lag distance.
# - Fitting a model (e.g., spherical or exponential) allows us to describe this relationship mathematically.

## Example of fitting a variogram:
#   variog <- variogram(variable ~ 1, data)
#   model_fit <- fit.variogram(variog, vgm("Model"))

variog <- variogram(K ~ 1, cal)  # Complete: Specify formula and data
sphr.fit <- fit.variogram(variog, vgm("Sph"))  # Complete: Fit spherical model
exp.fit <- fit.variogram(variog, vgm("Exp"))  # Complete: Fit exponential model



### Step 2: Plot Variogram Models
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Plot the experimental variogram and fitted models.

## Explanation:
# - `gamma` stores semivariance values from the experimental variogram.
# - `bins` stores lag distances.
# - `variogramLine()` generates predictions from fitted models.

## Example of plotting variograms:
#   plot(lag_distances, semivariance)
#   lines(lag_distances, model_predictions, col = "color")

gamma <- variog$gamma                        # Experimental semivariance values
bins <- variog$dist                          # Lag distances

gamma.sphr <- variogramLine(sphr.fit, dist_vector = bins)$gamma   # Spherical model predictions
gamma.exp <- variogramLine(exp.fit, dist_vector = bins)$gamma     # Exponential model predictions

plot(bins, gamma, main = "Variogram Models", 
     xlab = "Lag Distance", ylab = "Semivariance")
lines(bins, gamma.sphr, col = "pink")  # Complete: Add spherical model line (color = 'blue')
lines(bins, gamma.exp, col = "skyblue")  # Complete: Add exponential model line (color = 'red')
legend("bottomright", 
       legend = c("Spherical", "Exponential"), 
       col = c("pink", "skyblue"), 
       lty = 1)



### Step 3: Perform Kriging
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Perform ordinary kriging using the spherical and exponential models.

## Explanation:
# - Kriging estimates values at unsampled locations using weighted averages based on spatial structure.
# - Weights are determined by the fitted variogram model.

## Example of kriging:
#   krige_result <- krige(variable ~ 1, data, grid, model = variogram_model)

K.sph <- krige(K ~ 1, cal, grd, model = sphr.fit)  # Complete: Specify formula, data, grid, and model
K.exp <- krige(K ~ 1, cal, grd, model = exp.fit)  # Complete: Specify formula, data, grid, and model



### Step 4: Visualize Kriging Results
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Plot kriging predictions for both models.

## Example of plotting spatial predictions:
#   spplot(krige_result, main = "Title")

spplot(K.sph, main = "Ordinary Kriging (Spherical)")
spplot(K.exp, main = "Ordinary Kriging (Exponential)")


### Step 5: Evaluate Kriging Accuracy
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Calculate RMSE for calibration and validation data using both models.

## Example of RMSE calculation:
#   RMSE <- sqrt(mean((predicted_values - observed_values)^2))

# Spherical model
r.sph <- raster(K.sph)
k.sph.cal <- extract(r.sph, cal)
RMSE.sph.cal <- sqrt(mean((k.sph.cal - cal$K)^2, na.rm = T))  # Complete: Apply RMSE formula

k.sph.val <- extract(r.sph, val)
RMSE.sph.val <- sqrt(mean((k.sph.val - val$K)^2, na.rm = T))  # Complete: Apply RMSE formula

# Exponential model
r.exp <- raster(K.exp)
k.exp.cal <- extract(r.exp, cal)
RMSE.exp.cal <- sqrt(mean((k.exp.cal - cal$K)^2, na.rm = T))  # Complete: Apply RMSE formula

k.exp.val <- extract(r.exp, val)
RMSE.exp.val <- sqrt(mean((k.exp.val - val$K)^2, na.rm = T))  # Complete: Apply RMSE formula

cat("Spherical Model Calibration RMSE:", RMSE.sph.cal,
    "\nSpherical Model Validation RMSE:", RMSE.sph.val,
    "\nExponential Model Calibration RMSE:", RMSE.exp.cal,
    "\nExponential Model Validation RMSE:", RMSE.exp.val)



### Reflection Questions:
## 1. **Why might the spherical model have a lower calibration RMSE than the exponential model?**  
##  Hint: Consider the nugget effect and how it influences weights in kriging.

# The nugget effect causes small variability in the data that cannot be accounted for.
# Spherical models have a lower calibration RMSE because they have a defined range, meaning the nugget effect
# does not have as big of an effect on it.

## 2. **How do the variogram models (spherical vs. exponential) affect the spatial pattern of kriging variance?**  
##   Hint: Compare the `var1.var` maps using `spplot(K.sph[, "var1.var"])`.

# The models predict kriging variance more differently along the edges, although almost the entire plot is different.

## 3. **Under what conditions would kriging outperform IDW?**  
##  Hint: Think about data sparsity and spatial structure.

# Kriging would outperform IDW when fewer cells are used because there is more prediction occuring.