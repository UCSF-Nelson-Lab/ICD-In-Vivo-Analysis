%% processing all the raw data
clear all;
close all;
% Specify the Excel file path
filePath = '{Your file path}';
% Get the sheet names in the Excel file
[~, sheetNames] = xlsfinfo(filePath);
% Initialize the data struct
data = struct();

%% Loop through each sheet and extract data
for sheetIndex = 1:numel(sheetNames)
    sheetName = sheetNames{sheetIndex};   
    % Read data from the current sheet
    [~, ~, raw] = xlsread(filePath, sheetName);  
    % Replace all NaN cells with empty cells in the 'raw' variable
    for i = 1:size(raw, 1)
        for j = 1:size(raw, 2)
            if isnan(raw{i, j})
                raw{i, j} = '';
            end
        end
    end
    % Extract relevant columns from the raw data
       animalIDs = raw(2:end, 1);          % Assuming Animal ID is in 1st column, excluding header
       changeTypes = raw(2:end, 8);        % Assuming Type of Change is 8th column , excluding header
       opticalUnits = raw(2:end, 7);       % Assuming Optical Units is 7th column , excluding header
       channelNumbers = raw(2:end, 4);     % Assuming Channel Number is 4th column , excluding header
    
    % Convert numeric strings to actual numbers in the raw data
    % need to make sure start from 9th column of the raw cell need to
    % convert numeric string to actual numbers
    numericData = cell(size(raw, 1) - 1, size(raw, 2) - 8);
    for i = 1:size(numericData, 1)
        for j = 1:size(numericData, 2)
            if isnumeric(raw{i + 1, j + 8})
                numericData{i, j} = raw{i + 1, j + 8};
            else
                numericData{i, j} = str2double(raw{i + 1, j + 8});
            end
        end
    end   
    % Convert the numeric cell array to a numeric matrix
    values = cell2mat(numericData);%%
    % Process data based on Animal ID and Type of Change
    uniqueIDs = unique(animalIDs);
    uniqueChanges = unique(changeTypes);   
    % Initialize a struct to store sheet-specific calculations
    sheetData = struct();  
end

    %% Calculate the average for each individual "Type of Change" category
    for changeIndex = 1:length(uniqueChanges)
        currentChange = uniqueChanges{changeIndex};       
    % Find rows that match the current Type of Change
        matchingChangeType = strcmp(changeTypes, currentChange);  
    % Extract the corresponding values
        matchingchangeTypeValues = values(matchingChangeType, :);   
    % Calculate average and standard error
        avgValue = mean(matchingchangeTypeValues, 1, 'omitnan');
        stdErrValue = std(matchingchangeTypeValues, 0, 1, 'omitnan') / sqrt(sum(matchingChangeType));
    % Store calculated values in the sheet-specific struct
        fieldname = genvarname(['AllAnimals_' currentChange]);
        sheetData.(fieldname).AnimalID = 'AllAnimals';
        sheetData.(fieldname).ChangeType = currentChange;
        sheetData.(fieldname).Average = avgValue;
        sheetData.(fieldname).StandardError = stdErrValue;
    end
    
    %% Calculate the average for all rows, grouped by each 'Animal ID' and 'Type of Change'
    for idIndex = 1:length(uniqueIDs)
        for changeIndex = 1:length(uniqueChanges)
            currentID = uniqueIDs{idIndex};
            currentChange = uniqueChanges{changeIndex};         
            % Find rows that match the current Animal ID and Change Type
            matchingRows = strcmp(animalIDs, currentID) & strcmp(changeTypes, currentChange);                   
            % Extract the corresponding values
            matchingIDChangeType = values(matchingRows, :);         
            % Calculate average and standard error
            avgValue = mean(matchingIDChangeType, 1, 'omitnan');
            stdErrValue = std(matchingIDChangeType, 0, 1, 'omitnan') / sqrt(sum(matchingRows));
            
            % Store calculated values in the sheet-specific struct
            fieldname = genvarname([currentID '_' currentChange]);
            sheetData.(fieldname).AnimalID = currentID;
            sheetData.(fieldname).ChangeType = currentChange;
            sheetData.(fieldname).Average = avgValue;
            sheetData.(fieldname).StandardError = stdErrValue;
        end
    end
    % all analysed data is stored in data struct
    data.(sheetName) = sheetData;

%% plotting the average FR across sessions
% Define colors for each dataset
colors = {'b', 'g', 'r'};
% Loop through each sheet and extract data
for sheetIndex = 1:numel(sheetNames)
    sheetName = sheetNames{sheetIndex};   
    % Check if the sheet name starts with "saline" or "Park"
    if startsWith(sheetName, 'saline', 'IgnoreCase', true) || startsWith(sheetName, 'Park', 'IgnoreCase', true)      
        % Extract the relevant data for this sheet
        firingRateData = data.(sheetName);     
        % Check if the field "AllAnimals_d" exists in the data
        if isfield(firingRateData, 'AllAnimals_d')
            % Get the Average and StandardError values
            avgFiringRate_d = firingRateData.AllAnimals_d.Average;
            stdErrorFiringRate_d = firingRateData.AllAnimals_d.StandardError;
            % Calculate time in minutes (assuming data points are 1 minute apart)
            timeInMinutes = 1 * (0:(length(avgFiringRate_d) - 1));
            % Create a new figure for each dataset
            figure;
            % Create a shaded area for the standard error for d
            fill([timeInMinutes, fliplr(timeInMinutes)], [avgFiringRate_d - stdErrorFiringRate_d, fliplr(avgFiringRate_d + stdErrorFiringRate_d)], 'b', 'FaceAlpha', 0.5);
            hold on;
                % Plot the average firing rate for d
                plot(timeInMinutes, avgFiringRate_d, colors{1},'DisplayName', 'AllAnimals_d');
                % Add labels and legend for this figure
                xlabel('Time (minutes)');
                ylabel('Firing Rate');
                title([sheetName, ' - AllAnimals_d']); % Set the figure title
                % Create a new figure for AllAnimals_i if it exists
                if isfield(firingRateData, 'AllAnimals_i')
                % Get the Average and StandardError values for i
                avgFiringRate_i = firingRateData.AllAnimals_i.Average;
                stdErrorFiringRate_i = firingRateData.AllAnimals_i.StandardError;
                % Create a new figure for AllAnimals_i
                figure;
                % Create a shaded area for the standard error for i
                fill([timeInMinutes, fliplr(timeInMinutes)], [avgFiringRate_i - stdErrorFiringRate_i, fliplr(avgFiringRate_i + stdErrorFiringRate_i)], 'g', 'FaceAlpha', 0.5);
                hold on;
                % Plot the average firing rate for i
                plot(timeInMinutes, avgFiringRate_i, colors{2}, 'DisplayName', 'AllAnimals_i');
                % Add labels and legend for this figure
                xlabel('Time (minutes)');
                ylabel('Firing Rate');
                title([sheetName, ' - AllAnimals_i']); % Set the figure title
            end
                % Create a new figure for AllAnimals_n if it exists
                if isfield(firingRateData, 'AllAnimals_n')
                % Get the Average and StandardError values for n
                avgFiringRate_n = firingRateData.AllAnimals_n.Average;
                stdErrorFiringRate_n = firingRateData.AllAnimals_n.StandardError;
                % Create a new figure for AllAnimals_n
                figure;
                % Create a shaded area for the standard error for n
                fill([timeInMinutes, fliplr(timeInMinutes)], [avgFiringRate_n - stdErrorFiringRate_n, fliplr(avgFiringRate_n + stdErrorFiringRate_n)], 'r', 'FaceAlpha', 0.5);
                hold on;
                % Plot the average firing rate for n
                plot(timeInMinutes, avgFiringRate_n, colors{3}, 'DisplayName', 'AllAnimals_n');
                % Add labels and legend for this figure
                xlabel('Time (minutes)');
                ylabel('Firing Rate');
                title([sheetName, ' - AllAnimals_n']); % Set the figure title
            end
        end
    end
end

%% count the number of channels belong to each 'Type of change'
% Initialize a struct to store the counts
sheetChangeCounts = struct();
% Loop through each sheet
for sheetIndex = 1:numel(sheetNames)
    sheetName = sheetNames{sheetIndex};   
    % Read data from the current sheet
    [~, ~, raw] = xlsread(filePath, sheetName);  
    % Replace all NaN cells with empty cells in the 'raw' variable
    for i = 1:size(raw, 1)
        for j = 1:size(raw, 2)
            if isnan(raw{i, j})
                raw{i, j} = '';
            end
        end
    end  
    % Extract the 'type of change' column (assuming it's in the 8th column,
    changeTypes = raw(2:end, 8);   
    % Initialize counts for each change type (n, i, d)
    NoChangeCount = sum(contains(changeTypes, 'n'));
    IncreaseCount = sum(contains(changeTypes, 'i'));
    DecreaseCount = sum(contains(changeTypes, 'd')); 
    % Store the counts for the current sheet in the sheetChangeCounts struct
    sheetChangeCounts.(sheetName).n = NoChangeCount;
    sheetChangeCounts.(sheetName).i = IncreaseCount;
    sheetChangeCounts.(sheetName).d = DecreaseCount;
end
% Create a pie chart for each sheet
for sheetIndex = 1:numel(sheetNames)
    sheetName = sheetNames{sheetIndex};  
    % Get the counts for the current sheet
    counts = [sheetChangeCounts.(sheetName).n, sheetChangeCounts.(sheetName).i, sheetChangeCounts.(sheetName).d]; 
    % Create a pie chart
    figure;
    pie(counts, {'NA', 'increase', 'decrease'});
    title(['Type of change - ' sheetName]);
    % Calculate percentages
    percentages = counts / sum(counts) * 100;
    % Format percentages as strings
    labels = cellstr(num2str(percentages', '%.1f%%'));
    % Add percentages as text labels to the pie chart
    legend(labels, 'Location', 'BestOutside');
end
% Print out the counts for each sheet
for sheetIndex = 1:numel(sheetNames)
    sheetName = sheetNames{sheetIndex};
    fprintf('Sheet Name: %s\n', sheetName);
    fprintf('Number of "No Change" channels (n): %d\n', sheetChangeCounts.(sheetName).n);
    fprintf('Number of "Increase" channels (i): %d\n', sheetChangeCounts.(sheetName).i);
    fprintf('Number of "Decrease" channels (d): %d\n', sheetChangeCounts.(sheetName).d);
    fprintf('\n');
end
