% Define fault types with 'on'/'off' settings
faultTypes = {
    'Three_Phase_to_Ground_Fault_ABC_Ground', {'on', 'on', 'on', 'on'};
    'Three_Phase_Short_CKT_Fault_ABC', {'on', 'on', 'on', 'off'};
    'Double_Line_to_Ground_Fault_AB_Ground', {'on', 'on', 'off', 'on'};
    'Double_Line_to_Ground_Fault_AC_Ground', {'on', 'off', 'on', 'on'};
    'Double_Line_to_Ground_Fault_BC_Ground', {'off', 'on', 'on', 'on'};
    'Line_to_Line_Fault_AB', {'on', 'on', 'off', 'off'};
    'Line_to_Line_Fault_AC', {'on', 'off', 'on', 'off'};
    'Line_to_Line_Fault_BC', {'off', 'on', 'on', 'off'};
    'Single_Line_to_Ground_Fault_A_Ground', {'on', 'off', 'off', 'on'};
    'Single_Line_to_Ground_Fault_B_Ground', {'off', 'on', 'off', 'on'};
    'Single_Line_to_Ground_Fault_C_Ground', {'off', 'off', 'on', 'on'};
    'No_Fault', {'off', 'off', 'off', 'off'};
};

% Range of ground resistance values
GroundResistance_values = 0.1:0.1:1;

% Initialize cell array to store results
csvData = {};

% Header for CSV file
csvData{1, 1} = 'FaultType';
csvData{1, 2} = 'GroundResistance';
csvData{1, 3} = 'PhaseA_Max';
csvData{1, 4} = 'PhaseB_Max';
csvData{1, 5} = 'PhaseC_Max';
csvData{1, 6} = 'Ground_Max';

rowCounter = 2; % Start at the second row for data

% Loop through all ground resistance values
for GroundResistance = GroundResistance_values
    % Convert GroundResistance to a valid field name by removing the decimal point
    GroundResistanceField = strrep(num2str(GroundResistance), '.', '_');

    % Loop through all fault types
    for i = 1:length(faultTypes)
        faultName = faultTypes{i, 1};
        faultVector = faultTypes{i, 2};

        % Load the Simulink model
        model = 'TESCOK'; % replace with your model name
        open_system(model);

        % Set fault configuration in the Simulink model
        set_param([model, '/Three-Phase Fault'], 'FaultA', faultVector{1});
        set_param([model, '/Three-Phase Fault'], 'FaultB', faultVector{2});
        set_param([model, '/Three-Phase Fault'], 'FaultC', faultVector{3});
        set_param([model, '/Three-Phase Fault'], 'GroundFault', faultVector{4});
        set_param([model, '/Three-Phase Fault'], 'GroundResistance', num2str(GroundResistance)); % Set ground resistance

        % Run the simulation
        sim(model);

        % Extract current signals from workspace
        currentA = evalin('base', 'current1');
        currentB = evalin('base', 'current2');
        currentC = evalin('base', 'current3');
        currentG = evalin('base', 'current4');

        % Perform wavelet decomposition
        [cA, LA] = wavedec(currentA, 1, 'db4');
        [cB, LB] = wavedec(currentB, 1, 'db4');
        [cC, LC] = wavedec(currentC, 1, 'db4');
        [cG, LG] = wavedec(currentG, 1, 'db4');

        % Extract detailed coefficients
        coefA = detcoef(cA, LA, 1);
        coefB = detcoef(cB, LB, 1);
        coefC = detcoef(cC, LC, 1);
        coefG = detcoef(cG, LG, 1);

        % Save the maximum values
        csvData{rowCounter, 1} = faultName;
        csvData{rowCounter, 2} = GroundResistance;
        csvData{rowCounter, 3} = max(coefA);
        csvData{rowCounter, 4} = max(coefB);
        csvData{rowCounter, 5} = max(coefC);
        csvData{rowCounter, 6} = max(coefG);
        
        rowCounter = rowCounter + 1; % Move to the next row for the next data

        % Display the results for this fault and ground resistance value
        disp(['Simulation for ', faultName, ' with GroundResistance = ', num2str(GroundResistance), ' completed.']);
        disp(['Phase A: ', num2str(csvData{rowCounter-1, 3})]);
        disp(['Phase B: ', num2str(csvData{rowCounter-1, 4})]);
        disp(['Phase C: ', num2str(csvData{rowCounter-1, 5})]);
        disp(['Ground: ', num2str(csvData{rowCounter-1, 6})]);

        % Close the Simulink model to avoid saving unwanted changes
        close_system(model, 0);
    end
end

% Convert cell array to table
resultTable = cell2table(csvData(2:end, :), 'VariableNames', csvData(1, :));

% Save the table to a CSV file
writetable(resultTable, 'fault_simulation_results_with_GroundResistance_before_transmission.csv');

disp('All fault simulations completed and results saved to CSV.');
