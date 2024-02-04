clear all;
close all;
filepath = '{Your file path}'

load(filepath)
try
    spikes = fieldnames(result_bin);
catch
    disp
    Q=load(filepath);
    spikes = fieldnames(Q);
end

binsize = 60; %60s per bin
avg_val = struct;
%baseline
first_p1 = 1;
first_p2 = 30;
%postInjection
second_p1 = 241;
second_p2 = 270;
third_p1 = 271;
third_p2 = 300;
fourth_p1 = 301;
fourth_p2 = 330;
avg_result = []

pval_set1_p1 = 1
pval_set1_p2 = 30

pval_set2_p1 = 271 % post injection 4h-4:30h
pval_set2_p2 = 300

pval_set3_p1 = 301 % post injection 4:30h-5h
pval_set3_p2 = 330

qnames = fieldnames(Q) % all raw data are stored in Q

cellArray = [];
pvalTable = table();
for k= [1:10]
 % channel#
    text_out = ['Number of channel, ', num2str(k)];
    disp(text_out)
    current_spike = Q.(string(spikes(k)));
    last_point = current_spike(end);
    bin_counter = [];
    for binpoint = binsize:binsize:last_point
        temp_array = find((current_spike < binpoint ) & (current_spike >= (binpoint - binsize)));
        counter = numel(temp_array);
        bin_counter = [bin_counter counter];
    end
    avg_val.(string(spikes(k))).all = bin_counter
    avg_val.(string(spikes(k))).first = sum(bin_counter(1,first_p1:first_p2))/((first_p2-first_p1+1)*binsize);
    avg_val.(string(spikes(k))).second = sum(bin_counter(1,second_p1:second_p2))/((second_p2-second_p1+1)*binsize);
    avg_val.(string(spikes(k))).third = sum(bin_counter(1,third_p1:third_p2))/((third_p2-third_p1+1)*binsize);
    avg_val.(string(spikes(k))).fourth = sum(bin_counter(1,fourth_p1:fourth_p2))/((fourth_p2-fourth_p1+1)*binsize);
    avg_result = [avg_result; [qnames(k), avg_val.(string(spikes(k))).first, avg_val.(string(spikes(k))).second, avg_val.(string(spikes(k))).third, avg_val.(string(spikes(k))).fourth]];
    text_out = ['Total Time, ', num2str(numel(bin_counter))];
    disp(text_out)
    
    figure('name', strcat(string(spikes(k)), ' Timeline'))
    plotting_result = bin_counter/binsize;
    plot(binsize/60:binsize/60:(binsize/60)*numel(bin_counter), plotting_result,'color','k','marker','s','markersize',1,'markerfacecolor','k','linewidth',2)
    xlabel('Time (Min)') 
    ylabel('Frequency (Spikes/Sec)')     
    pval.(string(spikes(k))).all = plotting_result;
    pval.(string(spikes(k))).baseline = plotting_result(pval_set1_p1:pval_set1_p2);
    pval.(string(spikes(k))).ppx_1 = plotting_result(pval_set2_p1:pval_set2_p2);
    pval.(string(spikes(k))).ppx_2 = plotting_result(pval_set3_p1:pval_set3_p2);
    pval1 = ranksum(pval.(string(spikes(k))).baseline, pval.(string(spikes(k))).ppx_1);
    pval2 = ranksum(pval.(string(spikes(k))).baseline, pval.(string(spikes(k))).ppx_2);
    pval.(string(spikes(k))).result = [pval1,  pval2];
    pvalRow = table(qnames(k),pval.(string(spikes(k))).result);
    pvalTable = [pvalTable; pvalRow];
    plotting_result_trimmed = plotting_result(1:330)
    newRow = table(qnames(k), plotting_result_trimmed);
    cellArray = [cellArray; newRow];
end
