# Tests that init_score works for multiclass
# reference URL
# https://github.com/Microsoft/LightGBM/issues/1778
# https://stackoverflow.com/questions/57275029/using-the-score-from-first-lightgbm-as-init-score-to-second-lightgbm-gives-diffe

@testset "initScoreTest.jl" begin
    try
        # Test regression estimator.
        if isfile( joinpath(ENV["LIGHTGBM_PATH"],"examples/regression/regression.test") )
            regression_test = readdlm(joinpath(ENV["LIGHTGBM_PATH"] , "examples/regression/regression.test"), '\t');
            regression_train = readdlm(joinpath(ENV["LIGHTGBM_PATH"] , "examples/regression/regression.train"), '\t');
            regression_test_init = readdlm(joinpath(ENV["LIGHTGBM_PATH"] , "examples/regression/regression.test.init"), '\t')[:,1];
            regression_train_init = readdlm(joinpath(ENV["LIGHTGBM_PATH"] , "examples/regression/regression.train.init"), '\t')[:,1]; 
        else
            res = HTTP.get("https://raw.githubusercontent.com/microsoft/LightGBM/v2.3.1/examples/regression/regression.test");
            work=String(res.body);
            regression_test =convert(Matrix,CSV.read(IOBuffer(work),delim='\t',header=false));
    
            res = HTTP.get("https://raw.githubusercontent.com/microsoft/LightGBM/v2.3.1/examples/regression/regression.train");
            work=String(res.body);
            regression_train =convert(Matrix,CSV.read(IOBuffer(work),delim='\t',header=false));

            res = HTTP.get("https://raw.githubusercontent.com/microsoft/LightGBM/v2.3.1/examples/regression/regression.test.init");
            work=String(res.body);
            regression_test_init =convert(Matrix,CSV.read(IOBuffer(work),delim='\t',header=false))[:,1];
    
            res = HTTP.get("https://raw.githubusercontent.com/microsoft/LightGBM/v2.3.1/examples/regression/regression.train.init");
            work=String(res.body);
            regression_train_init =convert(Matrix,CSV.read(IOBuffer(work),delim='\t',header=false))[:,1];
        end

        X_train = regression_train[:, 2:end]
        y_train = regression_train[:, 1]
        X_test = regression_test[:, 2:end]
        y_test = regression_test[:, 1]
      
        estimator = LightGBM.LGBMRegression(num_iterations = 100,
                                            learning_rate = .05,
                                            feature_fraction = .9,
                                            bagging_fraction = .8,
                                            bagging_freq = 5,
                                            num_leaves = 31,
                                            metric = ["l2"],
                                            metric_freq = 1,
                                            is_training_metric = true,
                                            max_bin = 255,
                                            min_sum_hessian_in_leaf = 5.,
                                            min_data_in_leaf = 100,
                                            max_depth = -1);

        LightGBM.fit(estimator, X_train, y_train, verbosity = 0,init_score=regression_train_init);
        LightGBM.fit(estimator, X_train, y_train, (X_test, y_test), verbosity = 0,init_score=regression_train_init);
        @test true
    catch
        @test false
    end
end
