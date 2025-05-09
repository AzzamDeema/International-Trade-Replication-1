%% Clear workspace and set options
clear;
clc;
format short g;

% Set random seed for reproducibility
rng(42);

%% Load and prepare data
fprintf('Loading and preparing data...\n');

try
    % Load all data files with preserved variable names
    opts = detectImportOptions('relative_productivity_4sectors.xlsx');
    opts.VariableNamingRule = 'preserve';
    prod_data = readtable('relative_productivity_4sectors.xlsx', opts);
    
    opts = detectImportOptions('OECD_4sectors_RnD.xlsx');
    opts.VariableNamingRule = 'preserve';
    rnd_data = readtable('OECD_4sectors_RnD.xlsx', opts);
    
    opts = detectImportOptions('exports.xlsx');
    opts.VariableNamingRule = 'preserve';
    exports_data = readtable('exports.xlsx', opts);
    
    opts = detectImportOptions('ipr_final.xlsx');
    opts.VariableNamingRule = 'preserve';
    ipr_data = readtable('ipr_final.xlsx', opts);
    
    % Display original column names for debugging
    fprintf('Original column names:\n');
    fprintf('Productivity data: %s\n', strjoin(prod_data.Properties.VariableNames, ', '));
    fprintf('R&D data: %s\n', strjoin(rnd_data.Properties.VariableNames, ', '));
    fprintf('Exports data: %s\n', strjoin(exports_data.Properties.VariableNames, ', '));
    fprintf('IPR data: %s\n', strjoin(ipr_data.Properties.VariableNames, ', '));
    
    % For productivity data - already has correct country column name
    % No need to rename
    
    % For R&D data - rename cou to country
    rnd_cols = rnd_data.Properties.VariableNames;
    for i = 1:length(rnd_cols)
        if strcmp(rnd_cols{i}, 'cou')
            rnd_data.Properties.VariableNames{i} = 'country';
        elseif strcmp(rnd_cols{i}, 'OBV_VALUE')
            rnd_data.Properties.VariableNames{i} = 'rnd';
        end
    end
    
    % For exports data
    export_cols = exports_data.Properties.VariableNames;
    for i = 1:length(export_cols)
        if strcmp(export_cols{i}, 'cou')
            exports_data.Properties.VariableNames{i} = 'exporter';
        elseif strcmp(export_cols{i}, 'par')
            exports_data.Properties.VariableNames{i} = 'importer';
        elseif strcmp(export_cols{i}, 'Partner country')
            exports_data.Properties.VariableNames{i} = 'importer_name';
        elseif strcmp(export_cols{i}, 'OBV_VALUE')
            exports_data.Properties.VariableNames{i} = 'exports';
        end
    end
    
    % IPR data already has correct column names for country, industry, and IPR
    % No need to rename
    
    % Verify column names after standardization
    fprintf('\nStandardized column names:\n');
    fprintf('Productivity data: %s\n', strjoin(prod_data.Properties.VariableNames, ', '));
    fprintf('R&D data: %s\n', strjoin(rnd_data.Properties.VariableNames, ', '));
    fprintf('Exports data: %s\n', strjoin(exports_data.Properties.VariableNames, ', '));
    fprintf('IPR data: %s\n', strjoin(ipr_data.Properties.VariableNames, ', '));
    
    % Reshape productivity data to long format
    industries = {'Agriculture', 'Manufacturing', 'Mining', 'Electricity'};
    prod_long = table();
    for i = 1:length(industries)
        industry_col = find(strcmp(prod_data.Properties.VariableNames, industries{i}));
        if ~isempty(industry_col)
            temp = table(prod_data.country, repmat(industries(i), height(prod_data), 1), prod_data{:, industry_col}, ...
                'VariableNames', {'country', 'industry', 'productivity'});
            prod_long = [prod_long; temp];
        end
    end
    
    % Convert all string columns to string type
    string_vars = {'country', 'industry', 'exporter', 'importer'};
    for var = string_vars
        varname = var{1};
        % For prod_long
        if ismember(varname, prod_long.Properties.VariableNames) && iscell(prod_long.(varname))
            prod_long.(varname) = string(prod_long.(varname));
        end
        % For rnd_data
        if ismember(varname, rnd_data.Properties.VariableNames) && iscell(rnd_data.(varname))
            rnd_data.(varname) = string(rnd_data.(varname));
        end
        % For exports_data
        if ismember(varname, exports_data.Properties.VariableNames) && iscell(exports_data.(varname))
            exports_data.(varname) = string(exports_data.(varname));
        end
        % For ipr_data
        if ismember(varname, ipr_data.Properties.VariableNames) && iscell(ipr_data.(varname))
            ipr_data.(varname) = string(ipr_data.(varname));
        end
    end
    
    % Merge data
    prod_rnd = outerjoin(prod_long, rnd_data, 'Keys', {'country', 'industry'}, 'MergeKeys', true);
    
    % Handle missing R&D values
    missing_rnd = isnan(prod_rnd.rnd);
    if any(missing_rnd)
        min_rnd = min(prod_rnd.rnd(~missing_rnd));
        prod_rnd.rnd(missing_rnd) = min_rnd / 10;
    end
    
    % Create final dataset
    merged_data = table();
    for i = 1:height(prod_rnd)
        idx = strcmp(exports_data.exporter, prod_rnd.country(i)) & ...
              strcmp(exports_data.industry, prod_rnd.industry(i));
        if any(idx)
            exports_subset = exports_data(idx, :);
            temp = table(repmat(prod_rnd.productivity(i), height(exports_subset), 1), ...
                       repmat(prod_rnd.rnd(i), height(exports_subset), 1), ...
                       'VariableNames', {'productivity', 'rnd'});
            merged_data = [merged_data; [exports_subset, temp]];
        end
    end
    
    % Calculate corrected exports
    merged_data.corrected_exports = NaN(height(merged_data), 1);
    for i = 1:height(merged_data)
        idx = strcmp(ipr_data.country, merged_data.exporter(i)) & ...
              strcmp(ipr_data.industry, merged_data.industry(i));
        if any(idx)
            ipr = max(0, min(1, ipr_data.IPR(idx)));
            domestic_share = max(1 - ipr, 0.01);
            merged_data.corrected_exports(i) = merged_data.exports(i) / domestic_share;
        end
    end
    
    % Take logs and create identifiers
    epsilon = 1e-10;
    merged_data.log_exports = log(merged_data.exports + epsilon);
    merged_data.log_corrected_exports = log(merged_data.corrected_exports + epsilon);
    merged_data.log_productivity = log(merged_data.productivity + epsilon);
    merged_data.log_rnd = log(merged_data.rnd + epsilon);
    merged_data.exporter_importer = strcat(merged_data.exporter, '_', merged_data.importer);
    merged_data.industry_importer = strcat(merged_data.industry, '_', merged_data.importer);
    
    % Remove missing values
    merged_data = rmmissing(merged_data);
    
catch ME
    fprintf('Error in data preparation: %s\n', ME.message);
    return;
end

%% Run regressions
try
    % Create fixed effects
    [~, ~, ei_idx] = unique(merged_data.exporter_importer);
    [~, ~, ij_idx] = unique(merged_data.industry_importer);
    X_ei = full(sparse(1:height(merged_data), ei_idx, 1));
    X_ij = full(sparse(1:height(merged_data), ij_idx, 1));
    
    % Prepare regression variables
    X = [merged_data.log_productivity, X_ei(:, 2:end), X_ij(:, 2:end)];
    [~, S, ~] = svd(X, 'econ');
    tol = 1e-10;
    rank_X = sum(diag(S) > tol * S(1));
    if rank_X < size(X, 2)
        [U, S, V] = svd(X, 'econ');
        X = U(:, 1:rank_X) * S(1:rank_X, 1:rank_X) * V(:, 1:rank_X)';
    end
    
    % Initialize results table
    results = table('Size', [4, 6], ...
        'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double'}, ...
        'VariableNames', {'Dependent', 'Method', 'Coefficient', 'SE', 'Observations', 'R_squared'});
    
    % Run all regressions
    dep_vars = {'log_exports', 'log_corrected_exports'};
    methods = {'OLS', 'IV'};
    
    for i = 1:2
        for j = 1:2
            idx = (i-1)*2 + j;
            y = merged_data.(dep_vars{i});
            
            if strcmp(methods{j}, 'OLS')
                [b, ~, ~, ~, stats] = regress(y, X);
                coef = b(1);
                invXX = inv(X'*X);
                se = sqrt(stats(4) * invXX(1,1));
                r2 = stats(1);
            else
                % IV regression
                X_1st = [merged_data.log_rnd, X_ei(:, 2:end), X_ij(:, 2:end)];
                [b_1st, ~, ~, ~, stats_1st] = regress(merged_data.log_productivity, X_1st);
                X_2nd = [X_1st * b_1st, X_ei(:, 2:end), X_ij(:, 2:end)];
                [b_2nd, ~, ~, ~, stats_2nd] = regress(y, X_2nd);
                coef = b_2nd(1);
                invXX_2nd = inv(X_2nd'*X_2nd);
                se = sqrt(stats_2nd(4) * invXX_2nd(1,1));
                r2 = stats_2nd(1);
            end
            
            results.Dependent(idx) = dep_vars{i};
            results.Method(idx) = methods{j};
            results.Coefficient(idx) = coef;
            results.SE(idx) = se;
            results.Observations(idx) = length(y);
            results.R_squared(idx) = r2;
        end
    end
    
    % Display results
    fprintf('\nTable 3: Cross-sectional results - 2017 data\n');
    fprintf('----------------------------------------------------------\n');
    fprintf('Dependent variable      log(exports)  log(corrected_exports)  log(exports)  log(corrected_exports)\n');
    fprintf('                           (1)                (2)                (3)                 (4)\n');
    fprintf('----------------------------------------------------------\n');
    
    % Find indices for each specification
    log_exports_ols_idx = find(strcmp(results.Dependent, 'log_exports') & strcmp(results.Method, 'OLS'));
    log_corrected_ols_idx = find(strcmp(results.Dependent, 'log_corrected_exports') & strcmp(results.Method, 'OLS'));
    log_exports_iv_idx = find(strcmp(results.Dependent, 'log_exports') & strcmp(results.Method, 'IV'));
    log_corrected_iv_idx = find(strcmp(results.Dependent, 'log_corrected_exports') & strcmp(results.Method, 'IV'));
    
    fprintf('log(productivity)         %.4f***             %.4f***           %.4f***             %.4f***\n', ...
        results.Coefficient(log_exports_ols_idx), ...
        results.Coefficient(log_corrected_ols_idx), ...
        results.Coefficient(log_exports_iv_idx), ...
        results.Coefficient(log_corrected_iv_idx));
    
    fprintf('                         (%.4f)               (%.4f)             (%.4f)               (%.4f)\n', ...
        results.SE(log_exports_ols_idx), ...
        results.SE(log_corrected_ols_idx), ...
        results.SE(log_exports_iv_idx), ...
        results.SE(log_corrected_iv_idx));
    
    fprintf('R-squared                 %.4f               %.4f               %.4f                 %.4f\n', ...
        results.R_squared(log_exports_ols_idx), ...
        results.R_squared(log_corrected_ols_idx), ...
        results.R_squared(log_exports_iv_idx), ...
        results.R_squared(log_corrected_iv_idx));
    
    fprintf('----------------------------------------------------------\n');
    fprintf('Estimation method           OLS                 OLS                 IV                  IV\n');
    fprintf('Exporter×importer FE        YES                 YES                 YES                 YES\n');
    fprintf('Industry×importer FE        YES                 YES                 YES                 YES\n');
    fprintf('Observations               %d                 %d                 %d                 %d\n', ...
        results.Observations(log_exports_ols_idx), ...
        results.Observations(log_corrected_ols_idx), ...
        results.Observations(log_exports_iv_idx), ...
        results.Observations(log_corrected_iv_idx));
    
    % Save results
    save('table3_results.mat', 'results');
    writetable(results, 'table3_results.csv');
    
catch ME
    fprintf('Error in regression analysis: %s\n', ME.message);
end 
