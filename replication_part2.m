% Clear workspace and command window
clear; clc;

% Load the GGDC PLD dataset
pld_ggdc = readtable('pld_ggdc.xlsx', 'Sheet', 1, 'VariableNamingRule', 'preserve');

% Step 1: Compute raw productivity as the inverse of PPP_va
pld_ggdc.raw_productivity = 1 ./ pld_ggdc.PPP_va;

% Step 2: Normalize by setting U.S. productivity to 1 for all industries
us_rows = strcmp(pld_ggdc.countrycode, 'USA');
unique_sectors = unique(pld_ggdc.sector);

for i = 1:length(unique_sectors)
    sector = unique_sectors{i};
    us_prod = pld_ggdc.raw_productivity(us_rows & strcmp(pld_ggdc.sector, sector));
    
    % Normalize all countries' productivity by U.S. value
    pld_ggdc.normalized_productivity(strcmp(pld_ggdc.sector, sector)) = ...
        pld_ggdc.raw_productivity(strcmp(pld_ggdc.sector, sector)) ./ us_prod;
end

% Step 3: Normalize by setting Food industry productivity to 1 for all countries
food_rows = strcmp(pld_ggdc.sector, 'agr'); % Assuming 'agr' corresponds to Food
unique_countries = unique(pld_ggdc.countrycode);

for i = 1:length(unique_countries)
    country = unique_countries{i};
    food_prod = pld_ggdc.normalized_productivity(food_rows & strcmp(pld_ggdc.countrycode, country));
    
    % Normalize all industries for this country by Food industry value
    pld_ggdc.final_productivity(strcmp(pld_ggdc.countrycode, country)) = ...
        pld_ggdc.normalized_productivity(strcmp(pld_ggdc.countrycode, country)) ./ food_prod;
end

% Step 4: Reshape the table to match Table 2 format
industries = unique(pld_ggdc.sector);
countries = unique(pld_ggdc.countrycode);
table2_format = array2table(NaN(length(countries), length(industries)), 'VariableNames', industries, 'RowNames', countries);

for i = 1:height(pld_ggdc)
    row_country = pld_ggdc.countrycode{i};
    col_sector = pld_ggdc.sector{i};
    table2_format{row_country, col_sector} = pld_ggdc.final_productivity(i);
end

% Display final productivity table
disp(table2_format);

% Save results to Excel
writetable(table2_format, 'table2_productivity.xlsx', 'WriteRowNames', true, 'Sheet', 1);

% Plot Relative Productivity by Industry
figure;
hold on;
bar(categorical(countries), table2_format.Variables);
hold off;
legend(industries, 'Location', 'BestOutside');
xlabel('Country');
ylabel('Relative Productivity (Normalized)');
title('Relative Productivity Levels by Country and Industry (Table 2)');
grid on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clear workspace and command window
clear; clc;

% Load the productivity table from Excel
table2 = readtable('table2_productivity.xlsx', 'Sheet', 1, 'ReadRowNames', true);

% Define full column names (Update these based on your dataset)
full_col_names = { ...
    'Agriculture', 'Business', 'Construction', 'Real Estate', 'Finance', ...
    'Manufacturing', 'Mining', 'Other Services', 'Utilities', ...
    'Public Administration', 'Transport', 'Trade' ...
};

% Open file to write LaTeX table
fileID = fopen('table2_productivity.tex', 'w');

% Write LaTeX table header
fprintf(fileID, '\\begin{table}[htbp]\n');
fprintf(fileID, '\\centering\n');
fprintf(fileID, '\\caption{Relative Productivity Levels by Country and Industry}\n');
fprintf(fileID, '\\label{tab:productivity_table}\n');
fprintf(fileID, '\\begin{tabular}{l%s}\n', repmat('c', 1, width(table2)));
fprintf(fileID, '\\toprule\n');

% Write column headers
fprintf(fileID, 'Country & %s \\\\\n', strjoin(full_col_names, ' & '));
fprintf(fileID, '\\midrule\n');

% Write row data (Countries and Productivity values)
for i = 1:height(table2)
    country = table2.Properties.RowNames{i};  % Get country name
    values = table2{i, :};  % Extract row values

    % Convert values to string and format with proper spacing
    value_str = sprintf('%.2f & ', values);
    value_str = value_str(1:end-2); % Remove the last unnecessary '&'

    % Print row to LaTeX file
    fprintf(fileID, '%s & %s \\\\\n', country, value_str);
end

% Write LaTeX table footer
fprintf(fileID, '\\bottomrule\n');
fprintf(fileID, '\\end{tabular}\n');
fprintf(fileID, '\\end{table}\n');

% Close file
fclose(fileID);

% Display success message
disp('LaTeX table saved as table2_productivity.tex');

