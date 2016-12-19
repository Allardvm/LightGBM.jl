using LightGBM
using Base.Test

binary_test = readdlm(ENV["LIGHTGBM_PATH"] * "/examples/binary_classification/binary.test", '\t');
binary_train = readdlm(ENV["LIGHTGBM_PATH"] * "/examples/binary_classification/binary.train", '\t');
X_train = binary_train[:, 2:end]
y_train = binary_train[:, 1]
X_test = binary_test[:, 2:end]
y_test = binary_test[:, 1]

# Test estimator construction.
estimator = LightGBM.LGBMBinary(num_iterations = 20,
                                learning_rate = .1,
                                early_stopping_round = 1,
                                feature_fraction = .8,
                                bagging_fraction = .9,
                                bagging_freq = 1,
                                num_leaves = 1000,
                                metric = ["auc", "binary_logloss"],
                                is_training_metric = true,
                                max_bin = 255,
                                min_sum_hessian_in_leaf = 0.,
                                min_data_in_leaf = 1);

# Test fitting.
LightGBM.fit(estimator, X_train, y_train, verbosity = 0);
LightGBM.fit(estimator, X_train, y_train, (X_test, y_test), verbosity = 0);

# Test setting feature names, prediction, and loading and saving models.
feature_names = ["testname_$i" for i in 1:28]
LightGBM.LGBM_DatasetSetFeatureNames(estimator.booster.datasets[1], feature_names)
test_filename = tempname()
    LightGBM.savemodel(estimator, test_filename);
try
    saved_feature_names_2_to_28 = split(readstring(test_filename))[8:34];
    @test saved_feature_names_2_to_28 == feature_names[2:28]
    pre = LightGBM.predict(estimator, X_train, verbosity = 0);
    LightGBM.loadmodel(estimator, test_filename);
    post = LightGBM.predict(estimator, X_train, verbosity = 0);
    @test isapprox(pre, post)
finally
    rm(test_filename);
end

# Test cross-validation.
splits = (collect(1:3500), collect(3501:7000));
LightGBM.cv(estimator, X_train, y_train, splits; verbosity = 0);

# Test exhaustive search.
params = [Dict(:num_iterations => num_iterations,
               :num_leaves => num_leaves) for
          num_iterations in (1, 2),
          num_leaves in (5, 10)];
LightGBM.search_cv(estimator, X_train, y_train, splits, params; verbosity = 0);

# Test wrapper functions.
train_ds = LightGBM.LGBM_DatasetCreateFromMat(X_train, "objective=binary");
@test LightGBM.LGBM_DatasetGetNumData(train_ds) == 7000
@test LightGBM.LGBM_DatasetGetNumFeature(train_ds) == 28
@test LightGBM.LGBM_DatasetSetField(train_ds, "label", y_train) == nothing
@test LightGBM.LGBM_DatasetGetField(train_ds, "label") == y_train
bst = LightGBM.LGBM_BoosterCreate(train_ds, "lambda_l1=10. metric=auc")

test_ds = LightGBM.LGBM_DatasetCreateFromMat(X_test, "objective=binary", train_ds);
@test LightGBM.LGBM_DatasetSetField(test_ds, "label", y_test) == nothing
@test LightGBM.LGBM_BoosterAddValidData(bst, test_ds) == nothing
@test LightGBM.LGBM_BoosterUpdateOneIter(bst) == 0
@test LightGBM.LGBM_BoosterGetCurrentIteration(bst) == 1
@test LightGBM.LGBM_BoosterGetEvalCounts(bst) == 1
@test LightGBM.LGBM_BoosterGetEvalNames(bst)[1] == "auc"
