LightGBM.jl
========

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://wakakusa.github.io/LightGBM.jl/dev)


**LightGBM.jl** provides a high-performance Julia interface for Microsoft's
[LightGBM](https://github.com/Microsoft/LightGBM). The packages adds several convenience features,
including automated cross-validation and exhaustive search procedures, and automatically converts
all LightGBM parameters that refer to indices (e.g. categorical_feature) from Julia's one-based
indices to C's zero-based indices. All major operating systems (Windows, Linux, and Mac OS X) are
supported.

# Installation
Install the latest version of LightGBM by following the installation steps on: (https://github.com/Microsoft/LightGBM/wiki/Installation-Guide). Note that because LightGBM's C API
is still under development, Upstream changes can lead to temporary incompatibilities between this
package and the latest LightGBM master. To avoid this, you can build against
[Allardvm/LightGBM](https://github.com/Allardvm/LightGBM.git), which contains the latest LightGBM
version that has been confirmed to work with this package.

Then add the package to Julia with:
```julia
Pkg.clone("https://github.com/Allardvm/LightGBM.jl.git")
```

To use the package, set the environment variable LIGHTGBM_PATH to point to the LightGBM directory
prior to loading LightGBM.jl. This can be done for the duration of a single Julia session with:
```julia
ENV["LIGHTGBM_PATH"] = "../LightGBM"
```

To test the package, first set the environment variable LIGHTGBM_PATH and then call:
```julia
Pkg.test("LightGBM")
```

# Getting started
```julia
ENV["LIGHTGBM_PATH"] = "../LightGBM"
using LightGBM

# Load LightGBM's binary classification example.
binary_test = readdlm(ENV["LIGHTGBM_PATH"] * "/examples/binary_classification/binary.test", '\t')
binary_train = readdlm(ENV["LIGHTGBM_PATH"] * "/examples/binary_classification/binary.train", '\t')
X_train = binary_train[:, 2:end]
y_train = binary_train[:, 1]
X_test = binary_test[:, 2:end]
y_test = binary_test[:, 1]

# Create an estimator with the desired parameters—leave other parameters at the default values.
estimator = LGBMBinary(num_iterations = 100,
                       learning_rate = .1,
                       early_stopping_round = 5,
                       feature_fraction = .8,
                       bagging_fraction = .9,
                       bagging_freq = 1,
                       num_leaves = 1000,
                       metric = ["auc", "binary_logloss"])

# Fit the estimator on the training data and return its scores for the test data.
fit(estimator, X_train, y_train, (X_test, y_test))

# Predict arbitrary data with the estimator.
predict(estimator, X_train)

# Cross-validate using a two-fold cross-validation iterable providing training indices.
splits = (collect(1:3500), collect(3501:7000))
cv(estimator, X_train, y_train, splits)

# Exhaustive search on an iterable containing all combinations of learning_rate ∈ {.1, .2} and
# bagging_fraction ∈ {.8, .9}
params = [Dict(:learning_rate => learning_rate,
               :bagging_fraction => bagging_fraction) for
          learning_rate in (.1, .2),
          bagging_fraction in (.8, .9)]
search_cv(estimator, X_train, y_train, splits, params)

# Save and load the fitted model.
filename = pwd() * "/finished.model"
savemodel(estimator, filename)
loadmodel(estimator, filename)
```

# Exports

## Functions

### `fit(estimator, X, y[, test...]; [verbosity = 1, is_row_major = false])`
Fit the `estimator` with features data `X` and label `y` using the X-y pairs in `test` as
validation sets.

Return a dictionary with an entry for each validation set. Each entry of the dictionary is another
dictionary with an entry for each validation metric in the `estimator`. Each of these entries is an
array that holds the validation metric's value at each evaluation of the metric.

#### Arguments
* `estimator::LGBMEstimator`: the estimator to be fit.
* `X::Matrix{TX<:Real}`: the features data.
* `y::Vector{Ty<:Real}`: the labels.
* `test::Tuple{Matrix{TX},Vector{Ty}}...`: optionally contains one or more tuples of X-y pairs of
    the same types as `X` and `y` that should be used as validation sets.
* `verbosity::Integer`: keyword argument that controls LightGBM's verbosity. `< 0` for fatal logs
    only, `0` includes warning logs, `1` includes info logs, and `> 1` includes debug logs.
* `is_row_major::Bool`: keyword argument that indicates whether or not `X` is row-major. `true`
    indicates that it is row-major, `false` indicates that it is column-major (Julia's default).
* `weights::Vector{Tw<:Real}`: the training weights.
* `init_score::Vector{Ti<:Real}`: the init scores.

### `predict(estimator, X; [predict_type = 0, num_iterations = -1, verbosity = 1, is_row_major = false])`
Return an array with the labels that the `estimator` predicts for features data `X`.

#### Arguments
* `estimator::LGBMEstimator`: the estimator to use in the prediction.
* `X::Matrix{T<:Real}`: the features data.
* `predict_type::Integer`: keyword argument that controls the prediction type. `0` for normal
    scores with transform (if needed), `1` for raw scores, `2` for leaf indices.
* `num_iterations::Integer`: keyword argument that sets the number of iterations of the model to
    use in the prediction. `< 0` for all iterations.
* `verbosity::Integer`: keyword argument that controls LightGBM's verbosity. `< 0` for fatal logs
    only, `0` includes warning logs, `1` includes info logs, and `> 1` includes debug logs.
* `is_row_major::Bool`: keyword argument that indicates whether or not `X` is row-major. `true`
    indicates that it is row-major, `false` indicates that it is column-major (Julia's default).

### `cv(estimator, X, y, splits; [verbosity = 1])` (Experimental—interface may change)
Cross-validate the `estimator` with features data `X` and label `y`. The iterable `splits` provides
vectors of indices for the training dataset. The remaining indices are used to create the
validation dataset.

Return a dictionary with an entry for the validation dataset and, if the parameter
`is_training_metric` is set in the `estimator`, an entry for the training dataset. Each entry of
the dictionary is another dictionary with an entry for each validation metric in the `estimator`.
Each of these entries is an array that holds the validation metric's value for each dataset, at the
last valid iteration.

#### Arguments
* `estimator::LGBMEstimator`: the estimator to be fit.
* `X::Matrix{TX<:Real}`: the features data.
* `y::Vector{Ty<:Real}`: the labels.
* `splits`: the iterable providing arrays of indices for the training dataset.
* `verbosity::Integer`: keyword argument that controls LightGBM's verbosity. `< 0` for fatal logs
    only, `0` includes warning logs, `1` includes info logs, and `> 1` includes debug logs.

### `search_cv(estimator, X, y, splits, params; [verbosity = 1])` (Experimental—interface may change)
Exhaustive search over the specified sets of parameter values for the `estimator` with features
data `X` and label `y`. The iterable `splits` provides vectors of indices for the training dataset.
The remaining indices are used to create the validation dataset.

Return an array with a tuple for each set of parameters value, where the first entry is a set of
parameter values and the second entry the cross-validation outcome of those values. This outcome is
a dictionary with an entry for the validation dataset and, if the parameter `is_training_metric` is
set in the `estimator`, an entry for the training dataset. Each entry of the dictionary is
another dictionary with an entry for each validation metric in the `estimator`. Each of these
entries is an array that holds the validation metric's value for each dataset, at the last valid
iteration.

#### Arguments
* `estimator::LGBMEstimator`: the estimator to be fit.
* `X::Matrix{TX<:Real}`: the features data.
* `y::Vector{Ty<:Real}`: the labels.
* `splits`: the iterable providing arrays of indices for the training dataset.
* `params`: the iterable providing dictionaries of pairs of parameters (Symbols) and values to
    configure the `estimator` with.
* `verbosity::Integer`: keyword argument that controls LightGBM's verbosity. `< 0` for fatal logs
    only, `0` includes warning logs, `1` includes info logs, and `> 1` includes debug logs.

### `savemodel(estimator, filename; [num_iteration = -1])`
Save the fitted model in `estimator` as `filename`.

#### Arguments
* `estimator::LGBMEstimator`: the estimator to use in the prediction.
* `filename::String`: the name of the file to save the model in.
* `num_iteration::Integer`: keyword argument that sets the number of iterations of the model that
    should be saved. `< 0` for all iterations.

### `loadmodel(estimator, filename)`
Load the fitted model `filename` into `estimator`. Note that this only loads the fitted model—not
the parameters or data of the estimator whose model was saved as `filename`.

#### Arguments
* `estimator::LGBMEstimator`: the estimator to use in the prediction.
* `filename::String`: the name of the file that contains the model.

## Estimators

### `LGBMRegression <: LGBMEstimator`
```julia
LGBMRegression(; [num_iterations = 10,
                  learning_rate = .1,
                  num_leaves = 127,
                  max_depth = -1,
                  tree_learner = "serial",
                  num_threads = Sys.CPU_CORES,
                  histogram_pool_size = -1.,
                  min_data_in_leaf = 100,
                  min_sum_hessian_in_leaf = 10.,
                  feature_fraction = 1.,
                  feature_fraction_seed = 2,
                  bagging_fraction = 1.,
                  bagging_freq = 0,
                  bagging_seed = 3,
                  early_stopping_round = 0,
                  max_bin = 255,
                  data_random_seed = 1,
                  init_score = "",
                  is_sparse = true,
                  save_binary = false,
                  is_unbalance = false,
                  metric = ["l2"],
                  metric_freq = 1,
                  is_training_metric = false,
                  ndcg_at = Int[],
                  num_machines = 1,
                  local_listen_port = 12400,
                  time_out = 120,
                  machine_list_file = "",
                  device_type="cpu"])
```
Return an LGBMRegression estimator.

### `LGBMBinary <: LGBMEstimator`
```julia
LGBMBinary(; [num_iterations = 10,
              learning_rate = .1,
              num_leaves = 127,
              max_depth = -1,
              tree_learner = "serial",
              num_threads = Sys.CPU_CORES,
              histogram_pool_size = -1.,
              min_data_in_leaf = 100,
              min_sum_hessian_in_leaf = 10.,
              feature_fraction = 1.,
              feature_fraction_seed = 2,
              bagging_fraction = 1.,
              bagging_freq = 0,
              bagging_seed = 3,
              early_stopping_round = 0,
              max_bin = 255,
              data_random_seed = 1,
              init_score = "",
              is_sparse = true,
              save_binary = false,
              sigmoid = 1.,
              is_unbalance = false,
              metric = ["binary_logloss"],
              metric_freq = 1,
              is_training_metric = false,
              ndcg_at = Int[],
              num_machines = 1,
              local_listen_port = 12400,
              time_out = 120,
              machine_list_file = "",
              device_type="cpu"])
```
Return an LGBMBinary estimator.

### `LGBMMulticlass <: LGBMEstimator`
```julia
LGBMMulticlass(; [num_iterations = 10,
                  learning_rate = .1,
                  num_leaves = 127,
                  max_depth = -1,
                  tree_learner = "serial",
                  num_threads = Sys.CPU_CORES,
                  histogram_pool_size = -1.,
                  min_data_in_leaf = 100,
                  min_sum_hessian_in_leaf = 10.,
                  feature_fraction = 1.,
                  feature_fraction_seed = 2,
                  bagging_fraction = 1.,
                  bagging_freq = 0,
                  bagging_seed = 3,
                  early_stopping_round = 0,
                  max_bin = 255,
                  data_random_seed = 1,
                  init_score = "",
                  is_sparse = true,
                  save_binary = false,
                  is_unbalance = false,
                  metric = ["multi_logloss"],
                  metric_freq = 1,
                  is_training_metric = false,
                  ndcg_at = Int[],
                  num_machines = 1,
                  local_listen_port = 12400,
                  time_out = 120,
                  machine_list_file = "",
                  num_class = 1,
                  device_type="cpu"])
```
Return an LGBMMulticlass estimator.
