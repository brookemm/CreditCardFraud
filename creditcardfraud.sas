dm 'log;clear;odsresults;clear';

*import data from CSV file;
proc import datafile = 'creditcard.csv'
	dbms = csv
	out = cc
	replace;
	getnames = yes;
run;

*print first 10 observations (don't use full dataset bc it is too large, > 200k rows);
proc print data = work.cc(obs=10);
title 'First 10 Observations';
run;

*Percentage of Class 0 (99.8%) Class 1 (0.2%);
title 'Descriptive Statistics of Amount, Class 0 (99.8%) Class 1 (0.2%)';
proc means data = work.cc;
	class Class;
	var Amount;
run;

*Plot: frequency of transactions by class;
proc sgplot data = work.cc;
	vbar Class;
	title 'Class Frequency';
run;

*Plot: Distribution of Amount by Class;
proc sgpanel data = work.cc;
	panelby Class / columns = 1;
	histogram Amount;
	density Amount / type = kernel;
	colaxis min = 0 max = 1000;
	title 'Distributions of Amount by Class';
run;

*Plot: Principal Component 1 vs Principal Component 2;
title "Score Plot";
title2 "Observations Projected onto PC1 and PC2";
proc sgplot data = work.cc aspect = 1;
   scatter x = V1 y = V2 / group = Class;
   xaxis grid label = "Component 1";
   yaxis grid label = "Component 2";
run;

proc sort data = work.cc
		out = work.cc_sorted;
	by class;
run;

proc surveyselect data = work.cc_sorted
		out = work.cc_survey outall
		samprate = 0.67 seed = 12345;
	strata class;
run;

*verifying correct data partition;
proc freq data = cc_survey;
	table Selected*class;
run;

*creating logistic regression model;
proc logistic data = cc_survey descending;
	where selected=1;
	class time amount v1-v28 class;
	model class(event='1') = time amount v1-v28 /
		selection=stepwise expb stb lackfit;
	output out = temp p=new;
	store cc_logistic;
run;
