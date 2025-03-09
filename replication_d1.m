% Compute Import Penetratiuon Ratio

% Clear workspace and command window
clear; clc;

% Load data from Excel files
exports = readtable('exports.xlsx', 'Sheet', 1, 'VariableNamingRule', 'preserve');
imports = readtable('imports.xlsx', 'Sheet', 1, 'VariableNamingRule', 'preserve');
gross_output = readtable('gross_output.xlsx', 'Sheet', 1, 'VariableNamingRule', 'preserve');

% Aggregate imports and exports by 'cou' (country) and 'industry' (across all partner countries)
imports = varfun(@sum, imports, 'InputVariables', 'OBS_VALUE', 'GroupingVariables', {'cou', 'industry'});
exports = varfun(@sum, exports, 'InputVariables', 'OBS_VALUE', 'GroupingVariables', {'cou', 'industry'});

% Convert Imports and Exports from thousands to millions
imports.sum_OBS_VALUE = imports.sum_OBS_VALUE / 1000;
exports.sum_OBS_VALUE = exports.sum_OBS_VALUE / 1000;

% Rename columns for consistency
imports = renamevars(imports, {'cou', 'industry', 'sum_OBS_VALUE'}, {'country', 'industry', 'imports'});
exports = renamevars(exports, {'cou', 'industry', 'sum_OBS_VALUE'}, {'country', 'industry', 'exports'});
gross_output = renamevars(gross_output, {'cou', 'industry', 'OBS_VALUE'}, {'country', 'industry', 'gross_output'});

% 🚀 NEW METHOD: Merge using `innerjoin` instead of `outerjoin`
data = innerjoin(gross_output, imports, 'Keys', {'country', 'industry'});
data = innerjoin(data, exports, 'Keys', {'country', 'industry'});

% Fill missing values with zero (to handle missing data)
data.gross_output(isnan(data.gross_output)) = 0;
data.imports(isnan(data.imports)) = 0;
data.exports(isnan(data.exports)) = 0;

% Compute Total Demand
data.total_demand = data.gross_output + data.imports - data.exports;

% Compute Import Penetration Ratio (IPR)
data.IPR = data.imports ./ data.total_demand;

% Display first few rows of the result
disp(data(1:10, :));

% Save results to Excel
writetable(data, 'ipr_final.xlsx', 'Sheet', 1);

% Extract data for the 4 industries: Mining, Manufacturing, Electricity, and Agriculture
industries = {'Mining', 'Manufacturing', 'Electricity', 'Agriculture'};
industry_data = data(ismember(data.industry, industries), :);

% Save the filtered data to a separate file
writetable(industry_data, 'ipr_filtered.xlsx', 'Sheet', 1);

% Plot Import Penetration Ratio for visualization
figure;
hold on;
for i = 1:length(industries)
    subset = industry_data(strcmp(industry_data.industry, industries{i}), :);
    bar(categorical(subset.country), subset.IPR);
end
hold off;
legend(industries, 'Location', 'BestOutside');
xlabel('Country');
ylabel('Import Penetration Ratio (IPR)');
title('Import Penetration Ratio by Country and Industry');
grid on;
